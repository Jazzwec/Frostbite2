class_name JanView
extends Node3D
## One Jan on the map: frozen at the edge, walking to work, working, guarding, or fleeing.

const WALK_SPEED := 3.0
const PARKA := Color(0.78, 0.45, 0.18)

var jan_id := -1
var frozen := false
var leaving := false
var _model: Node3D
var _ice: MeshInstance3D
var _hint: Label3D
var _bubble: Label3D
var _bubble_timer := 0.0
var _spear: MeshInstance3D
var _hp_bar: HpBar
var _tap: Area3D
var _path := PackedVector3Array()
var _target := Vector3.INF
var _bob := 0.0


func setup(is_frozen: bool, arrival_id := -1) -> void:
	frozen = is_frozen
	_model = Node3D.new()
	add_child(_model)
	_model.add_child(Shapes.capsule(0.32, 1.1, PARKA, Vector3(0, 0.55, 0)))
	_model.add_child(Shapes.sphere(0.26, Color(0.95, 0.78, 0.66), Vector3(0, 1.28, 0)))
	_model.add_child(Shapes.sphere(0.08, Color(0.9, 0.15, 0.15), Vector3(0, 1.26, 0.25)))
	_model.add_child(Shapes.cylinder(0.27, 0.22, Color(0.2, 0.35, 0.6), Vector3(0, 1.48, 0), 0.18))
	_spear = Shapes.cylinder(0.035, 1.9, Color(0.45, 0.35, 0.25), Vector3(0.35, 0.9, 0.1))
	_spear.visible = false
	_model.add_child(_spear)
	_bubble = Shapes.label("", Vector3(0, 2.3, 0), 40, Color(0.1, 0.1, 0.15))
	_bubble.outline_modulate = Color(1, 1, 1)
	_bubble.outline_size = 28
	_bubble.width = 600.0
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_bubble)
	_hp_bar = HpBar.new(Color(0.3, 0.75, 0.35))
	_hp_bar.position = Vector3(0, 1.95, 0)
	add_child(_hp_bar)
	if frozen:
		_ice = Shapes.box(Vector3(1.0, 1.9, 1.0), Color(0.7, 0.88, 1.0, 0.55), Vector3(0, 0.95, 0))
		add_child(_ice)
		_hint = Shapes.label("Frozen Jan!", Vector3(0, 2.4, 0), 44, Color(0.75, 0.9, 1.0))
		add_child(_hint)
		_tap = Shapes.tap_area(Vector3(2.2, 2.5, 2.2), "arrival", arrival_id)
		add_child(_tap)
		_model.scale = Vector3(1, 0.97, 1)


func thaw(new_jan_id: int, line: String) -> void:
	frozen = false
	jan_id = new_jan_id
	for n in [_ice, _hint, _tap]:
		if n:
			n.queue_free()
	_ice = null
	_hint = null
	_tap = null
	var t := create_tween()
	t.tween_property(self, "position:y", 0.8, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	say(line, 3.5)


func say(text: String, seconds := 3.0) -> void:
	_bubble.text = text
	_bubble_timer = seconds


## Walks along a navmesh path to `target` unless already heading there.
func go_to(target: Vector3, nav_map: RID) -> void:
	if _target.distance_to(target) < 0.3:
		return
	_target = target
	_path = NavigationServer3D.map_get_path(nav_map, global_position, target, true)
	if _path.is_empty():
		_path = PackedVector3Array([target])


## Guards follow the engine's position directly.
func follow(target: Vector3, delta: float) -> void:
	_path = PackedVector3Array()
	_target = target
	var step := target - global_position
	if step.length() > 0.02:
		_face(step)
	global_position = global_position.move_toward(target, maxf(step.length() * 10.0, Balance.GUARD_SPEED) * delta)


func set_guard(on: bool, hp_fraction: float, knocked_out: bool) -> void:
	_spear.visible = on
	_hp_bar.set_value(hp_fraction if on else 1.0)
	_model.rotation.z = 1.4 if knocked_out else 0.0


## Runs off towards the nearest map edge and disappears.
func flee() -> void:
	leaving = true
	_bubble.text = ""
	var p := global_position
	var edge := Vector3(signf(p.x) * 30.0 if absf(p.x) > 0.1 else 30.0, 0, p.z)
	var t := create_tween()
	t.tween_property(self, "global_position", edge, 4.0)
	t.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.text = ""
	if frozen:
		_model.rotation.z = sin(Time.get_ticks_msec() / 300.0) * 0.03
		return
	if leaving:
		return
	var moving := false
	while not _path.is_empty():
		var next := _path[0]
		var step := next - global_position
		step.y = 0.0
		if step.length() < 0.15:
			_path.remove_at(0)
			continue
		_face(step)
		global_position += step.normalized() * minf(WALK_SPEED * delta, step.length())
		moving = true
		break
	_bob = _bob + delta * 10.0 if moving else 0.0
	_model.position.y = absf(sin(_bob)) * 0.1


func _face(dir: Vector3) -> void:
	_model.rotation.y = atan2(dir.x, dir.z)
