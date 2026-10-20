class_name WolfView
extends Node3D
## A wolf drawn where the engine says it is.
##
## It uses the Tripo wolf (`wolf.glb`) when it's there, posed bone by bone: a trot while it runs
## and a lunge while it fights. Otherwise it's the greybox wolf, which only bobs.

const MODEL_PATH := "res://assets/models/blender/wolf.glb"
## Drawn larger than life (1.3 m long in the file), so it reads from the game camera.
const MODEL_SCALE := 1.25
## The bones the trot and lunge move, by the end of their names (Tripo's auto-rig names them
## `tripo::…` or `bone_N`; Godot turns the colons into underscores). The model faces +Z.
const BONES := {
	"leg_fl": "bone_13", "leg_fr": "bone_19", "leg_hl": "bone_1", "leg_hr": "bone_6",
	"knee_fl": "0_Left_Limb_1", "knee_fr": "0_Right_Limb_1",
	"knee_hl": "1_Left_Limb_1", "knee_hr": "1_Right_Limb_1",
	"back": "Spine_0", "neck": "Spine_3", "tail": "bone_36",
}
## Trot: diagonal pairs move together, so the front left steps with the hind right.
const GAIT_PHASE := {"fl": 0.0, "hr": 0.0, "fr": PI, "hl": PI}
const LEG_SWING := 28.0
const KNEE_LIFT := 35.0
const TAIL_WAG := 18.0
## Trot cycle speed (radians per second): one full stride in about half a second.
const TROT_SPEED := 13.0
## One attack every this many seconds: crouch back, thrust, recover, then wait.
const ATTACK_PERIOD := 1.0
const ATTACK_CROUCH := 0.15
const ATTACK_THRUST := 0.1
const ATTACK_RECOVER := 0.25

var _model: Node3D
var _hp_bar: HpBar
var _t := 0.0
var _attack := -1.0
var _flash: MeshInstance3D
var _knock := 0.0
## The posed model, or null for the greybox wolf.
var _pivot: Node3D
var _skeleton: Skeleton3D
var _bone := {}  # key -> bone index
var _rest := {}  # bone index -> rest Basis in skeleton space
var _skins: Array[MeshInstance3D] = []
var _flash_mat: StandardMaterial3D


func _init() -> void:
	_model = Node3D.new()
	add_child(_model)
	var bar_height := 1.5
	if ResourceLoader.exists(MODEL_PATH):
		_build_model()
		bar_height = 1.35
	else:
		_build_greybox()
	_hp_bar = HpBar.new(HpBar.WOLF_RED)
	_hp_bar.position = Vector3(0, bar_height, 0)
	add_child(_hp_bar)


func _build_model() -> void:
	_pivot = Node3D.new()
	_pivot.scale = Vector3.ONE * MODEL_SCALE
	_model.add_child(_pivot)
	var model: Node3D = load(MODEL_PATH).instantiate()
	_pivot.add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for key in BONES:
		_bone[key] = -1
		for i in _skeleton.get_bone_count():
			var bone_name := _skeleton.get_bone_name(i)
			if bone_name == BONES[key] or bone_name.ends_with("_" + BONES[key]):
				_bone[key] = i
				break
		if _bone[key] < 0:
			push_error("WolfView: %s has no bone %s" % [MODEL_PATH, BONES[key]])
	for i in _skeleton.get_bone_count():
		_rest[i] = _skeleton.get_bone_global_rest(i).basis.orthonormalized()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		_skins.append(mesh)
	# A white overlay, shown for a moment when it's hit.
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.albedo_color = Color(1, 1, 1, 0.75)


func _build_greybox() -> void:
	var fur := Color(0.42, 0.42, 0.46)
	_model.add_child(Shapes.capsule(0.28, 1.2, fur, Vector3(0, 0.55, 0)))
	_model.get_child(-1).rotation_degrees.x = 90.0
	_model.add_child(Shapes.sphere(0.24, fur, Vector3(0, 0.75, 0.6)))
	_model.add_child(Shapes.box(Vector3(0.14, 0.12, 0.3), Color(0.3, 0.3, 0.33), Vector3(0, 0.7, 0.85)))
	_model.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(-0.12, 1.0, 0.55)))
	_model.add_child(Shapes.cone(0.08, 0.22, fur, Vector3(0.12, 1.0, 0.55)))
	_model.add_child(Shapes.sphere(0.04, Color(1, 0.85, 0.2), Vector3(-0.1, 0.8, 0.8), 3.0))
	_model.add_child(Shapes.sphere(0.04, Color(1, 0.85, 0.2), Vector3(0.1, 0.8, 0.8), 3.0))
	for x in [-0.15, 0.15]:
		for z in [-0.35, 0.35]:
			_model.add_child(Shapes.cylinder(0.06, 0.35, fur.darkened(0.2), Vector3(x, 0.17, z)))
	# A white shell over the body, shown for a moment when it's hit.
	_flash = Shapes.capsule(0.32, 1.3, Color(1, 1, 1, 0.8), Vector3(0, 0.55, 0))
	_flash.rotation_degrees.x = 90.0
	_flash.visible = false
	_model.add_child(_flash)


## Struck: a white flash and a small hop back.
func hit() -> void:
	_knock = 1.0
	Fx.burst("snow", global_position + Vector3(0, 0.6, 0))


func sync(wolf: Dictionary, delta: float) -> void:
	var target := Vector3(wolf.pos.x, 0, wolf.pos.y)
	var step := target - global_position
	var fighting: bool = wolf.mode == "fight"
	if fighting and wolf.has("foe_pos"):
		# Face whoever it's fighting, not the way it last stepped.
		step = Vector3(wolf.foe_pos.x, 0, wolf.foe_pos.y) - global_position
	if step.length() > 0.01:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(step.x, step.z), 10.0 * delta)
	global_position = global_position.lerp(target, minf(1.0, 12.0 * delta))
	if _attack < 0.0:
		# Each wolf's lunge starts at its own point in the cycle, so a pack doesn't strike in unison.
		_attack = fmod(float(wolf.id) * 0.37, ATTACK_PERIOD)
	_knock = move_toward(_knock, 0.0, delta * 5.0)
	if _pivot:
		_t += delta * (14.0 if fighting else TROT_SPEED)
		if fighting:
			_attack = fmod(_attack + delta, ATTACK_PERIOD)
		_model.position = -_model.basis.z * 0.1 * _knock
		_pose(fighting)
		var flashing := _knock > 0.6
		for mesh in _skins:
			mesh.material_overlay = _flash_mat if flashing else null
	else:
		_t += delta * (14.0 if fighting else 9.0)
		_model.position = -_model.basis.z * 0.25 * _knock
		_flash.visible = _knock > 0.6
		_model.position.y = absf(sin(_t)) * (0.05 if fighting else 0.12)
	_hp_bar.set_value(wolf.hp / wolf.max_hp)


## Poses the model: a trot while it runs, a lunge and snap while it fights.
func _pose(fighting: bool) -> void:
	var lunge := _lunge() if fighting else 0.0
	for leg in GAIT_PHASE:
		var swing := 0.0
		var lift := 0.0
		if fighting:
			# Front paws reach out and hind legs push off as it strikes.
			swing = (-35.0 if leg.begins_with("f") else 25.0) * lunge
			# Crouching back bends every knee.
			lift = 25.0 * maxf(0.0, -lunge)
		else:
			var phase: float = _t + GAIT_PHASE[leg]
			swing = -LEG_SWING * sin(phase)
			# The paw lifts while the leg swings forward.
			lift = KNEE_LIFT * maxf(0.0, -cos(phase))
		# Rotating about +X swings a hanging leg backwards, so forward is negative.
		_turn_bone(_bone["leg_" + leg], Basis(Vector3.RIGHT, deg_to_rad(swing)))
		_turn_bone(_bone["knee_" + leg], Basis(Vector3.RIGHT, deg_to_rad(lift)))
	var bob := absf(sin(_t))
	if fighting:
		_turn_bone(_bone.back, Basis(Vector3.RIGHT, deg_to_rad(6.0 * lunge)))
		_turn_bone(_bone.neck, Basis(Vector3.RIGHT, deg_to_rad(-10.0 + 30.0 * absf(lunge))))
		# Tail up and stiff (rotating about +X lifts a tail that points back).
		_turn_bone(_bone.tail, Basis(Vector3.RIGHT, deg_to_rad(15.0)) * Basis(Vector3.UP, deg_to_rad(8.0 * sin(_t))))
		_pivot.position = Vector3(0, 0.02 * bob - 0.06 * maxf(0.0, -lunge), 0.3 * lunge)
		_pivot.rotation_degrees.x = 8.0 * lunge
	else:
		_turn_bone(_bone.back, Basis(Vector3.RIGHT, deg_to_rad(3.0 * sin(_t * 2.0))))
		_turn_bone(_bone.neck, Basis(Vector3.RIGHT, deg_to_rad(4.0 * sin(_t * 2.0 + 0.6))))
		_turn_bone(_bone.tail, Basis(Vector3.UP, deg_to_rad(TAIL_WAG * sin(_t))))
		_pivot.position = Vector3(0, 0.03 * bob, 0)
		_pivot.rotation_degrees.x = 0.0


## How far into an attack it is: -0.4 crouched back, 1 at full stretch, 0 at rest.
func _lunge() -> float:
	var t := _attack
	if t < ATTACK_CROUCH:
		return -0.4 * smoothstep(0.0, 1.0, t / ATTACK_CROUCH)
	t -= ATTACK_CROUCH
	if t < ATTACK_THRUST:
		return lerpf(-0.4, 1.0, smoothstep(0.0, 1.0, t / ATTACK_THRUST))
	t -= ATTACK_THRUST
	if t < ATTACK_RECOVER:
		return 1.0 - smoothstep(0.0, 1.0, t / ATTACK_RECOVER)
	return 0.0


## Turns a bone by `delta` (in the wolf's space) from its rest pose, relative to its parent's rest,
## as `ModelRig` does, so the auto-rig's bone axes don't matter.
func _turn_bone(bone: int, delta: Basis) -> void:
	if bone < 0:
		return
	var parent := _skeleton.get_bone_parent(bone)
	var parent_rest: Basis = _rest[parent] if parent >= 0 else Basis.IDENTITY
	var local: Basis = parent_rest.inverse() * delta * _rest[bone]
	_skeleton.set_bone_pose_rotation(bone, local.get_rotation_quaternion())
