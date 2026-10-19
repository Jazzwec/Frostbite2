class_name Meagan
extends CharacterBody3D
## The player character: walks where she's sent along the navmesh and tells the engine where she is.
## Main tells her what she's working at each frame; her rig plays the matching clip.

## At each clip's hit moment (the axe biting, a fish landing), for main's effects.
signal worked(clip: String)

## After an activity stops, its clip plays on for one more cycle at least this long, so quick
## deliveries still show their throw or carry.
const LINGER := 0.35
## Her rigged model (Tripo, prepared in Blender); the greybox stands in if it's missing.
const MODEL_PATH := "res://assets/models/blender/meagan.glb"
## Drawn a little larger than life, so she reads at phone size.
const MODEL_SCALE := 1.2

var _agent: NavigationAgent3D
var _rig: CharacterRig
var _stack: CarryStack
var _count: Label3D
var _hp_bar: HpBar
var _clip := ""
var _face := Vector3.INF
var _linger := 0.0
var _steer := Vector2.ZERO
## Whether she moved this physics frame.
var moving := false
var _source := Vector3.INF
var _dest := Vector3.INF
var _landed := Callable()
var _step_in := 0.0


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

	if ResourceLoader.exists(MODEL_PATH):
		_rig = ModelRig.new(MODEL_PATH)
		_rig.scale = Vector3.ONE * MODEL_SCALE
		add_child(_rig)
	else:
		# Greybox stand-in until her model is there.
		var white := Color(0.95, 0.95, 0.98)
		_rig = GreyboxRig.new({
			"coat": Color(0.62, 0.2, 0.4), "radius": 0.38, "height": 1.25,
			"skin": Color(0.96, 0.8, 0.68), "head_radius": 0.3, "mitten": white,
		})
		add_child(_rig)
		_rig.head.add_child(Shapes.cylinder(0.32, 0.25, white, Vector3(0, 0.42, 0), 0.22))
		_rig.head.add_child(Shapes.sphere(0.12, white, Vector3(0, 0.62, 0)))
		_rig.body.add_child(Shapes.box(Vector3(0.7, 0.12, 0.12), Color(0.9, 0.75, 0.2), Vector3(0, 1.12, 0.2)))
	# Her load stacks up on her back, with a counter above it.
	_stack = CarryStack.new()
	_stack.position = Vector3(0, 0.45, -0.5) if _rig is GreyboxRig else Vector3(0, 0.55, -0.5)
	_rig.body.add_child(_stack)
	_count = Shapes.label("", Vector3(0, 2.6, 0), 44)
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_count)
	_rig.impact.connect(func(clip: String): worked.emit(clip))
	_hp_bar = HpBar.new(Color(0.95, 0.3, 0.5))
	_hp_bar.position = Vector3(0, 1.85, 0)
	add_child(_hp_bar)

	_agent = NavigationAgent3D.new()
	_agent.radius = 0.45
	_agent.path_desired_distance = 0.4
	_agent.target_desired_distance = 0.5
	# The baked navmesh surface sits half a metre above the ground she walks on.
	_agent.path_height_offset = 0.5
	add_child(_agent)
	_agent.target_position = global_position


## The joystick: 0..1 in screen directions. The camera looks north, so screen up is world -Z.
func steer(dir: Vector2) -> void:
	_steer = dir


func walk_to(target: Vector3) -> void:
	if not Game.engine.can_meagan_move():
		return
	_agent.target_position = target


## What she's working at: a clip from `Clips` ("" for nothing), the point to face and where a
## fishing line goes (Vector3.INF for none).
func set_activity(clip: String, face: Vector3, line := Vector3.INF) -> void:
	if clip != "":
		_clip = clip
		_face = face
		_linger = maxf(LINGER, Clips.CLIPS[clip].length)
	_rig.line_target = line


## One-off clips, like warming a Jan she's just reached.
func play_once(clip: String, face := Vector3.INF) -> void:
	_clip = ""
	_agent.target_position = global_position
	if face != Vector3.INF:
		_face = face
		_linger = Clips.CLIPS[clip].length
	_rig.play_once(clip)


func tip_position() -> Vector3:
	return _rig.tip_position()


## Where her load is going and coming from this frame (Vector3.INF for nowhere). `landed` runs as
## each delivered piece arrives.
func carry(source: Vector3, dest: Vector3, landed := Callable()) -> void:
	_source = source
	_dest = dest
	_landed = landed


func bag_position() -> Vector3:
	return _stack.top_position()


func head_position() -> Vector3:
	return _rig.head.global_position + Vector3(0, 0.2, 0)


## Which way she's facing, flat on the ground.
func forward() -> Vector3:
	return _rig.global_basis.z


func _physics_process(delta: float) -> void:
	var s := Game.engine.state
	moving = false
	var can_move := Game.engine.can_meagan_move() and not Game.engine.paused
	if can_move and _steer != Vector2.ZERO:
		var dir := Vector3(_steer.x, 0, _steer.y)
		velocity = dir.normalized() * Balance.MEAGAN_WALK_SPEED * _steer.length()
		move_and_slide()
		moving = true
		_turn_towards(dir, delta)
		# Steering replaces any tap-walk in progress.
		_agent.target_position = global_position
	elif can_move and not _agent.is_navigation_finished():
		var next := _agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0.0
		if dir.length() > 0.05:
			velocity = dir.normalized() * Balance.MEAGAN_WALK_SPEED
			move_and_slide()
			moving = true
			_turn_towards(dir, delta)
	if not moving:
		velocity = Vector3.ZERO
	# The snowbanks round the town are her edge.
	var b := MapData.BOUNDS.grow(-1.5)
	global_position = Vector3(clampf(global_position.x, b.position.x, b.end.x), 0.0, clampf(global_position.z, b.position.y, b.end.y))
	Game.engine.set_meagan_position(Vector2(global_position.x, global_position.z))

	# Footsteps crunching in the snow.
	_step_in -= delta
	if moving and _step_in <= 0.0:
		Audio.play("step", global_position)
		_step_in = 0.3
	_linger -= delta
	if s.meagan_injured:
		_rig.cancel_once()
		_rig.play("down")
	elif moving:
		_rig.cancel_once()
		_linger = 0.0
		_rig.play("walk")
	else:
		_rig.play(_clip if _linger > 0.0 and _clip != "" else "idle")
		if _linger > 0.0 and _face != Vector3.INF:
			_turn_towards(_face - global_position, delta)

	var cap := Economy.bag_cap(s)
	_stack.sync(s.bag, cap, _source, _dest, _landed, 1.0 if moving else 0.0, delta)
	_update_counter(s, cap)
	# Health only matters in a fight.
	_hp_bar.visible = not s.wolves.is_empty() or s.meagan_hp < Balance.MEAGAN_HP
	_hp_bar.set_value(s.meagan_hp / Balance.MEAGAN_HP)


## "12/20" above her load, "MAX" in red when the bag is full, and what's in it underneath.
func _update_counter(s: GameState, cap: float) -> void:
	var total := Economy.bag_total(s)
	_count.position.y = maxf(2.3, _stack.top_position().y - global_position.y + 0.3)
	_count.visible = total > 0.01
	var full := total >= cap - 0.01
	var parts := []
	for res in CarryStack.ORDER:
		if s.bag[res] >= 1.0:
			parts.append("%s %s" % [Fmt.num(floorf(s.bag[res])), {"wood": "Wood", "food": "Food", "materials": "Mat"}[res]])
	var head := "MAX" if full else "%s/%s" % [Fmt.num(floorf(total)), Fmt.num(cap)]
	_count.text = "%s\n%s" % [head, " · ".join(parts)]
	_count.modulate = Color(1.0, 0.45, 0.4) if full else Color.WHITE


func _turn_towards(dir: Vector3, delta: float) -> void:
	dir.y = 0.0
	if dir.length() > 0.05:
		_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
