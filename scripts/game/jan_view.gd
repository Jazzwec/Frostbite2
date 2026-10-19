class_name JanView
extends Node3D
## One Jan on the map: frozen at the edge, walking to work, working at his station, resting,
## guarding, or fleeing.

## At each clip's hit moment, for effects that reach beyond him (a guard's spear hitting a wolf).
signal worked(view: JanView, clip: String)

const WALK_SPEED := 3.0
## His rigged model (Tripo, prepared in Blender); the greybox stands in if it's missing.
const MODEL_PATH := "res://assets/models/blender/jan.glb"
## A little smaller than Meagan's 1.2, so she stands out.
const MODEL_SCALE := 1.15
const PARKA := Color(0.78, 0.45, 0.18)
const JOB_CLIPS := {"chop": "chop", "hunt": "fish", "build": "build"}
## Where his station sits in front of him, by job.
const STATION_GAP := {"chop": 0.85, "hunt": 1.4, "build": 0.65}

var jan_id := -1
var frozen := false
var leaving := false
var _rig: CharacterRig
var _rig_scale := Vector3.ONE
var _ice: MeshInstance3D
var _hint: Label3D
var _bubble: Label3D
var _bubble_timer := 0.0
var _hp_bar: HpBar
var _tap: Area3D
var _path := PackedVector3Array()
var _target := Vector3.INF
var _moving := false
var _path_walking := false
var _station: Node3D
var _station_job := ""


func setup(is_frozen: bool, arrival_id := -1) -> void:
	frozen = is_frozen
	# How tall he stands, for the ice block, bubble and health bar above him.
	var height := 1.6
	if ResourceLoader.exists(MODEL_PATH):
		_rig = ModelRig.new(MODEL_PATH)
		_rig_scale = Vector3.ONE * MODEL_SCALE
		height = 1.6 * MODEL_SCALE
	else:
		_rig = GreyboxRig.new({
			"coat": PARKA, "radius": 0.32, "height": 1.1,
			"skin": Color(0.95, 0.78, 0.66), "head_radius": 0.26, "mitten": Color(0.2, 0.35, 0.6),
		})
		_rig.head.add_child(Shapes.sphere(0.08, Color(0.9, 0.15, 0.15), Vector3(0, 0.15, 0.25)))
		_rig.head.add_child(Shapes.cylinder(0.27, 0.22, Color(0.2, 0.35, 0.6), Vector3(0, 0.37, 0), 0.18))
	_rig.scale = _rig_scale
	add_child(_rig)
	_rig.impact.connect(_on_impact)
	_bubble = Shapes.label("", Vector3(0, height + 0.7, 0), 40, Color(0.1, 0.1, 0.15))
	_bubble.outline_modulate = Color(1, 1, 1)
	_bubble.outline_size = 28
	_bubble.width = 600.0
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_bubble)
	_hp_bar = HpBar.new(Color(0.3, 0.75, 0.35))
	_hp_bar.position = Vector3(0, height + 0.35, 0)
	add_child(_hp_bar)
	if frozen:
		var ice := Vector3(maxf(1.0, height * 0.7), height + 0.3, maxf(1.0, height * 0.6))
		_ice = Shapes.box(ice, Color(0.7, 0.88, 1.0, 0.55), Vector3(0, ice.y / 2.0, 0))
		add_child(_ice)
		_hint = Shapes.label("Frozen Jan!", Vector3(0, height + 0.8, 0), 44, Color(0.75, 0.9, 1.0))
		add_child(_hint)
		_tap = Shapes.tap_area(Vector3(2.2, 2.5, 2.2), "arrival", arrival_id)
		add_child(_tap)
		# Frozen mid-shiver, hugging himself.
		_rig.play("warm_hands", 0.0)
		_rig.scale = _rig_scale * Vector3(1, 0.97, 1)


func thaw(new_jan_id: int, line: String) -> void:
	frozen = false
	jan_id = new_jan_id
	Fx.burst("shards", global_position + Vector3(0, 1.0, 0))
	Audio.play("thaw", global_position)
	for n in [_ice, _hint, _tap]:
		if n:
			n.queue_free()
	_ice = null
	_hint = null
	_tap = null
	_rig.scale = _rig_scale
	_rig.rotation.z = 0.0
	var t := create_tween()
	t.tween_property(self, "position:y", 0.8, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	say(line, 3.5)


func say(text: String, seconds := 3.0) -> void:
	_bubble.text = text
	_bubble_timer = seconds
	if text != "":
		Audio.play("blip", global_position)


## Walks along a navmesh path to `target` unless already heading there.
func go_to(target: Vector3, nav_map: RID) -> void:
	if _target.distance_to(target) < 0.3:
		return
	_target = target
	_path = NavigationServer3D.map_get_path(nav_map, global_position, target, true)
	if _path.is_empty():
		_path = PackedVector3Array([target])


## At his post: works `job` at its station ("" rests instead), `speed` showing cold and hunger.
func work(job: String, speed: float) -> void:
	if _moving or not _path.is_empty():
		return
	_place_station(job)
	if job == "":
		_rig.play("warm_hands")
		return
	_rig.rotation.y = 0.0
	_rig.play(JOB_CLIPS[job], speed)
	_rig.line_target = _station.global_position + Vector3(0, 0.05, 0) if job == "hunt" else Vector3.INF


## Guards follow the engine's position directly.
func follow(target: Vector3, delta: float) -> void:
	_path = PackedVector3Array()
	_target = target
	_place_station("")
	var step := target - global_position
	_moving = step.length() > 0.05
	if step.length() > 0.02:
		_face(step)
	global_position = global_position.move_toward(target, maxf(step.length() * 10.0, Balance.GUARD_SPEED) * delta)


## A guard's stance: knocked out, thrusting at the wolf at `foe`, or standing ready.
func guard(hp_fraction: float, knocked_out: bool, foe := Vector3.INF) -> void:
	_hp_bar.set_value(hp_fraction)
	if knocked_out:
		_rig.play("down")
	elif foe != Vector3.INF:
		_face(foe - global_position)
		_rig.play("guard_attack")
	elif _moving:
		_rig.play("walk")
	else:
		_rig.play("guard_idle")


func set_cold(cold: bool) -> void:
	_rig.shiver = 1.0 if cold and not frozen else 0.0


## Runs off towards the nearest map edge and disappears.
func flee() -> void:
	leaving = true
	_bubble.text = ""
	_place_station("")
	var p := global_position
	var edge := Vector3(signf(p.x) * 30.0 if absf(p.x) > 0.1 else 30.0, 0, p.z)
	_face(edge - p)
	_rig.play("walk", 1.6)
	var t := create_tween()
	t.tween_property(self, "global_position", edge, 4.0)
	t.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.text = ""
	if frozen:
		_rig.rotation.z = sin(Time.get_ticks_msec() / 300.0) * 0.03
		return
	if leaving:
		return
	if _path.is_empty():
		if _path_walking:
			_path_walking = false
			_moving = false
			_rig.play("idle")
		return
	_path_walking = true
	_moving = true
	_place_station("")
	_rig.play("walk")
	while not _path.is_empty():
		var next := _path[0]
		var step := next - global_position
		step.y = 0.0
		if step.length() < 0.15:
			_path.remove_at(0)
			continue
		_face(step)
		global_position += step.normalized() * minf(WALK_SPEED * delta, step.length())
		break


func _place_station(job: String) -> void:
	if job == _station_job:
		return
	_station_job = job
	if _station:
		_station.queue_free()
		_station = null
	if job == "":
		return
	_station = Node3D.new()
	match job:
		"chop":
			# Dark bark and a golden cut, so the stump stands out against the snow.
			_station.add_child(Shapes.cylinder(0.3, 0.45, Color(0.33, 0.2, 0.1), Vector3(0, 0.225, 0)))
			_station.add_child(Shapes.cylinder(0.24, 0.02, Color(0.72, 0.52, 0.25), Vector3(0, 0.46, 0)))
			var log := Shapes.cylinder(0.1, 0.45, Color(0.5, 0.33, 0.18), Vector3(0, 0.5, 0))
			log.rotation_degrees.z = 90.0
			_station.add_child(log)
		"hunt":
			_station.add_child(Shapes.cylinder(0.55, 0.03, Color(0.68, 0.84, 0.95), Vector3(0, 0.015, 0)))
			_station.add_child(Shapes.cylinder(0.25, 0.04, Color(0.12, 0.2, 0.32), Vector3(0, 0.025, 0)))
		"build":
			_station.add_child(Shapes.box(Vector3(0.35, 0.3, 0.3), Color(0.35, 0.3, 0.28), Vector3(0, 0.15, 0)))
			_station.add_child(Shapes.box(Vector3(0.55, 0.12, 0.25), Color(0.32, 0.34, 0.38), Vector3(0, 0.36, 0)))
	add_child(_station)
	_station.position = Vector3(0, 0, STATION_GAP[job])


## Jans' work sounds, a little quieter than Meagan's.
const WORK_SOUNDS := {"chop": "chop", "fish": "splash", "build": "hammer", "guard_attack": "swing_hit"}


func _on_impact(clip: String) -> void:
	if WORK_SOUNDS.has(clip):
		Audio.play(WORK_SOUNDS[clip], global_position, 1.0, -5.0)
	if _station == null and clip != "guard_attack":
		return
	match clip:
		"chop":
			Fx.burst("chips", _station.global_position + Vector3(0, 0.5, 0))
		"fish":
			Fx.burst("splash", _station.global_position)
			Fx.throw("fish", _station.global_position, global_position + Vector3(0, 0.2, -1.4), 0.5, 1.4)
		"build":
			Fx.burst("sparks", _station.global_position + Vector3(0, 0.45, 0))
	worked.emit(self, clip)


func _face(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length() > 0.001:
		_rig.rotation.y = atan2(dir.x, dir.z)
