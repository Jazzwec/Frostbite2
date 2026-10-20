class_name Meagan
extends CharacterBody3D
## The player character: walks where she's sent along the navmesh and tells the engine where she is.
## Main tells her what she's working at each frame; her rig plays the matching clip.

## At each clip's hit moment (the axe biting, a fish landing), for main's effects.
signal worked(clip: String)

## After an activity stops, its clip plays on for one more cycle at least this long, so quick
## jobs still show their swing.
const LINGER := 0.35
## Her rigged model (Tripo, prepared in Blender); the greybox stands in if it's missing.
const MODEL_PATH := "res://assets/models/blender/meagan.glb"
## Drawn a little larger than life, so she reads at phone size.
const MODEL_SCALE := 1.45
const SILHOUETTE := preload("res://scripts/game/ink/silhouette.gdshader")
## Hit: a short red rim flash round her (fight_v2 review 1: "I was hit" reads apart from "my hit
## landed", which is the enemies' warm rim).
const HURT_FLASH := 0.14
const HURT_RIM := Color(0.95, 0.25, 0.2)

var _agent: NavigationAgent3D
var _rig: CharacterRig
var _stack: CarryStack
var _source := Vector3.INF
var _dest := Vector3.INF
var _landed := Callable()
var _hp_bar: HpBar
var _silhouette: ShaderMaterial
var _silhouette_on := false
var _hurt_mat: ShaderMaterial
var _hurt := 0.0
var _clip := ""
var _face := Vector3.INF
var _linger := 0.0
var _steer := Vector2.ZERO
## Whether she moved this physics frame.
var moving := false
var _step_in := 0.0
## Seconds to her next breath puff while it's cold (AFK V8).
var _breath_in := 0.0
## Her attack's target, turned to for a moment even while she walks (agreed 2026-10-20).
var _aim := Vector3.INF
var _aim_left := 0.0
## How full her bag must be for the loaded walk.
const HEAVY_BAG := 0.6
const BREATH_EVERY := 2.4


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
	# Her load stacks up on her back (the bag is back, agreed 2026-10-20); the HUD's BagReadout
	# shows how much above it.
	_stack = CarryStack.new()
	# Snug against her back, so it reads as carried, not floating beside her (AFK N4).
	_stack.position = Vector3(0, 0.45, -0.5) if _rig is GreyboxRig else Vector3(0, 0.55, -0.34)
	_rig.body.add_child(_stack)
	# Each piece leaving her back dips her body a little (AFK N6).
	_stack.piece_left.connect(func() -> void: _rig.dip(5.0))
	_rig.impact.connect(func(clip: String): worked.emit(clip))
	_silhouette = ShaderMaterial.new()
	_silhouette.shader = SILHOUETTE
	# After the faded cover (0), so the cover doesn't dim her; under the labels (10).
	_silhouette.render_priority = 6
	_hp_bar = HpBar.new(HpBar.MEAGAN_GREEN, 1.8, 0.22)
	# A little higher than a wolf's or guard's, so hers stays clear of theirs in a fight.
	_hp_bar.position = Vector3(0, 1.7 * MODEL_SCALE, 0)
	add_child(_hp_bar)

	_agent = NavigationAgent3D.new()
	_agent.radius = 0.45
	_agent.path_desired_distance = 0.4
	_agent.target_desired_distance = 0.5
	# The baked navmesh surface sits half a metre above the ground she walks on.
	_agent.path_height_offset = 0.5
	add_child(_agent)
	_agent.target_position = global_position


## While a tree or building stands in front of her, her hidden parts show through it as a flat
## silhouette in her red (on top of the cover's own fading), so she's never lost.
func show_silhouette(on: bool) -> void:
	if on == _silhouette_on:
		return
	_silhouette_on = on
	if _hurt <= 0.0:
		_set_overlay(_silhouette if on else null)


func _set_overlay(m: Material) -> void:
	for mi in _rig.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = m


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


## An attack: the sweep or the throw over whatever her legs are doing, turned to the wolf.
func attack(mode: String, at: Vector3) -> void:
	_aim = at
	_aim_left = 0.45
	_rig.play_overlay("sweep" if mode == "melee" else "throw")


## Where a thrown snowball leaves from: her raised hand, about.
func throw_point() -> Vector3:
	return global_position + Vector3(0, 1.7, 0) + forward() * 0.3


## A bite landed on her: a flinch and a red rim flash.
func hurt() -> void:
	_rig.flinch()
	if _hurt_mat == null:
		_hurt_mat = ShaderMaterial.new()
		_hurt_mat.shader = WolfView.RIM_FLASH
		_hurt_mat.set_shader_parameter("rim_color", HURT_RIM)
	_hurt = HURT_FLASH
	_set_overlay(_hurt_mat)


func _fade_hurt(delta: float) -> void:
	if _hurt <= 0.0:
		return
	_hurt -= delta
	_hurt_mat.set_shader_parameter("strength", maxf(0.0, _hurt / HURT_FLASH))
	if _hurt <= 0.0:
		_set_overlay(_silhouette if _silhouette_on else null)


## Where her load is going and coming from this frame (Vector3.INF for nowhere). `landed(res)`
## runs as each delivered piece arrives.
func carry(source: Vector3, dest: Vector3, landed := Callable()) -> void:
	_source = source
	_dest = dest
	_landed = landed


func bag_position() -> Vector3:
	return _stack.top_position()


func head_position() -> Vector3:
	return _rig.head.global_position + Vector3(0, 0.2, 0)


## How close she may come to a closed tile.
const EDGE_CLEARANCE := 1.5


## Whether she can stand here: on an open tile, and not right up against a closed one.
static func _walkable(s: GameState, p: Vector3) -> bool:
	var at := Vector2(p.x, p.z)
	for d in [Vector2.ZERO, Vector2(EDGE_CLEARANCE, 0), Vector2(-EDGE_CLEARANCE, 0), Vector2(0, EDGE_CLEARANCE), Vector2(0, -EDGE_CLEARANCE)]:
		if not WorldRules.is_open_at(s, at + d):
			return false
	return true


## Which way she's facing, flat on the ground.
func forward() -> Vector3:
	return _rig.global_basis.z


func _physics_process(delta: float) -> void:
	_fade_hurt(delta)
	var s := Game.engine.state
	var before := global_position
	moving = false
	var can_move := Game.engine.can_meagan_move() and not Game.engine.paused
	if can_move and _steer != Vector2.ZERO:
		var dir := Vector3(_steer.x, 0, _steer.y)
		velocity = dir.normalized() * Economy.walk_speed(s) * _steer.length()
		move_and_slide()
		moving = true
		if _aim_left <= 0.0:
			_turn_towards(dir, delta)
		# Steering replaces any tap-walk in progress.
		_agent.target_position = global_position
	elif can_move and not _agent.is_navigation_finished():
		var next := _agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0.0
		if dir.length() > 0.05:
			velocity = dir.normalized() * Economy.walk_speed(s)
			move_and_slide()
			moving = true
			if _aim_left <= 0.0:
				_turn_towards(dir, delta)
	if _aim_left > 0.0:
		_aim_left -= delta
		_turn_towards(_aim - global_position, delta * 2.0)
	if not moving:
		velocity = Vector3.ZERO
	# Closed tiles are deep snow: she stays on the open ones, sliding along their edge.
	var b := s.bounds.grow(-EDGE_CLEARANCE)
	var p := Vector3(clampf(global_position.x, b.position.x, b.end.x), 0.0, clampf(global_position.z, b.position.y, b.end.y))
	if not _walkable(s, p):
		var slide_x := Vector3(p.x, 0.0, before.z)
		var slide_z := Vector3(before.x, 0.0, p.z)
		p = slide_x if _walkable(s, slide_x) else (slide_z if _walkable(s, slide_z) else Vector3(before.x, 0.0, before.z))
	global_position = p
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
		# A bag over 60% full weighs her down (AFK N4).
		_rig.play("walk_loaded" if Economy.bag_total(s) >= Economy.bag_cap(s) * HEAVY_BAG else "walk")
	else:
		_rig.play(_clip if _linger > 0.0 and _clip != "" else "idle")
		if _linger > 0.0 and _face != Vector3.INF:
			_turn_towards(_face - global_position, delta)

	_stack.sync(s.bag, Economy.bag_cap(s), _source, _dest, _landed, 1.0 if moving else 0.0, delta)
	if Economy.is_cold(s):
		_breath_in -= delta
		if _breath_in <= 0.0:
			_breath_in = BREATH_EVERY
			Fx.burst("breath", head_position() + _rig.global_transform.basis.z.normalized() * 0.3, _rig.global_transform.basis.z.normalized() + Vector3.UP * 0.3)
	# Health only matters in a fight.
	_hp_bar.visible = not s.wolves.is_empty() or s.meagan_hp < Balance.MEAGAN_HP
	_hp_bar.set_value(s.meagan_hp / Balance.MEAGAN_HP)


func _turn_towards(dir: Vector3, delta: float) -> void:
	dir.y = 0.0
	if dir.length() > 0.05:
		_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(dir.x, dir.z), 12.0 * delta)
