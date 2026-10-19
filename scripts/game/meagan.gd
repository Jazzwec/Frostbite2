class_name Meagan
extends CharacterBody3D
## The player character: walks where she's sent along the navmesh and tells the engine where she is.

signal started_walking

var _agent: NavigationAgent3D
var _model: Node3D
var _bag: MeshInstance3D
var _hp_bar: HpBar
var _walk_time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.OBSTACLE
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	cs.shape = shape
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)

	_model = Node3D.new()
	add_child(_model)
	_model.add_child(Shapes.capsule(0.38, 1.25, Color(0.62, 0.2, 0.4), Vector3(0, 0.65, 0)))
	_model.add_child(Shapes.sphere(0.3, Color(0.96, 0.8, 0.68), Vector3(0, 1.45, 0)))
	_model.add_child(Shapes.cylinder(0.32, 0.25, Color(0.95, 0.95, 0.98), Vector3(0, 1.68, 0), 0.22))
	_model.add_child(Shapes.sphere(0.12, Color(0.95, 0.95, 0.98), Vector3(0, 1.88, 0)))
	_model.add_child(Shapes.box(Vector3(0.7, 0.12, 0.12), Color(0.9, 0.75, 0.2), Vector3(0, 1.15, 0.2)))
	_bag = Shapes.box(Vector3(0.6, 0.6, 0.35), Color(0.55, 0.4, 0.25), Vector3(0, 0.95, -0.42))
	_model.add_child(_bag)
	add_child(Shapes.label("Meagan", Vector3(0, 2.4, 0), 40, Color(1, 0.85, 0.95)))
	_hp_bar = HpBar.new(Color(0.95, 0.3, 0.5))
	_hp_bar.position = Vector3(0, 2.15, 0)
	add_child(_hp_bar)

	_agent = NavigationAgent3D.new()
	_agent.radius = 0.45
	_agent.path_desired_distance = 0.4
	_agent.target_desired_distance = 0.5
	# The baked navmesh surface sits half a metre above the ground she walks on.
	_agent.path_height_offset = 0.5
	add_child(_agent)
	_agent.target_position = global_position


func walk_to(target: Vector3) -> void:
	if not Game.engine.can_meagan_move():
		return
	_agent.target_position = target
	started_walking.emit()


func _physics_process(delta: float) -> void:
	var s := Game.engine.state
	var moving := false
	if Game.engine.can_meagan_move() and not Game.engine.paused and not _agent.is_navigation_finished():
		var next := _agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0.0
		if dir.length() > 0.05:
			velocity = dir.normalized() * Balance.MEAGAN_WALK_SPEED
			move_and_slide()
			moving = true
			_model.rotation.y = lerp_angle(_model.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
	if not moving:
		velocity = Vector3.ZERO
	global_position.y = 0.0
	Game.engine.set_meagan_position(Vector2(global_position.x, global_position.z))

	# A little walking bob, a bag that swells with what she carries, and a tumble when she's hurt.
	_walk_time = _walk_time + delta * 10.0 if moving else 0.0
	_model.position.y = absf(sin(_walk_time)) * 0.12
	var fill := Economy.bag_total(s) / Economy.bag_cap(s)
	_bag.visible = fill > 0.01
	_bag.scale = Vector3.ONE * (0.5 + 0.9 * fill)
	_bag.material_override = Shapes.material(_bag_color(s))
	_model.rotation.z = lerpf(_model.rotation.z, 1.4 if s.meagan_injured else 0.0, 6.0 * delta)
	_hp_bar.set_value(s.meagan_hp / Balance.MEAGAN_HP)


func _bag_color(s: GameState) -> Color:
	var b: Dictionary = s.bag
	if b.materials >= b.wood and b.materials >= b.food:
		return Color(0.55, 0.55, 0.6)
	if b.food >= b.wood:
		return Color(0.75, 0.35, 0.3)
	return Color(0.6, 0.42, 0.25)
