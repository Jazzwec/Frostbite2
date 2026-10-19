class_name ModelRig
extends CharacterRig
## A rigged model (a Mixamo-style skeleton, as Tripo exports) posed bone by bone from the clips.
##
## Every bone it moves gets a rotation in character space (+Y up, +Z forward), on top of its rest
## pose: local = parent_rest⁻¹ · delta · rest. That way the bones' own axes don't matter.
## - `arm_l`, `arm_r` → the upper arms, turned down from the T-pose first, so 0° means arms down
##   as in the greybox.
## - `lean`, `turn` → the spine, bending at the waist.
## - `head` → the head.
## - `leg_l`, `leg_r` → the thighs; a crouch (`rise` below zero) bends the knees so the feet stay
##   on the ground.
## - `rise` (above zero) and `roll` → the whole model; roll lays her down.

const BONES := {
	"spine": "Spine", "head": "Head", "arm_l": "LeftArm", "arm_r": "RightArm", "hand_r": "RightHand",
	"upleg_l": "LeftUpLeg", "upleg_r": "RightUpLeg", "leg_l": "LeftLeg", "leg_r": "RightLeg",
	"foot_l": "LeftFoot",
}
## A crouch this deep (rise in metres, below zero) bends the thighs and knees this far.
const CROUCH_DEPTH := 0.35
const CROUCH_THIGH := 70.0
const CROUCH_KNEE := 120.0
## Where carried things sit in front of her chest, in the body's frame.
const CHEST := Vector3(0, 0.85, 0.42)

var _root: Node3D
var _skeleton: Skeleton3D
var _bone := {}  # key -> bone index
var _rest := {}  # bone index -> rest Basis in skeleton space
var _rest_pos := {}  # key -> rest position in skeleton space
var _thigh := 0.0
var _shin := 0.0


func _init(path: String, bone_prefix := "mixamorig_") -> void:
	_root = Node3D.new()
	add_child(_root)
	var model: Node3D = load(path).instantiate()
	_root.add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	for key in BONES:
		var i := _skeleton.find_bone(bone_prefix + BONES[key])
		if i < 0:
			push_error("ModelRig: %s has no bone %s" % [path, bone_prefix + BONES[key]])
		_bone[key] = i
	for i in _skeleton.get_bone_count():
		_rest[i] = _skeleton.get_bone_global_rest(i).basis.orthonormalized()
	for key in _bone:
		_rest_pos[key] = _skeleton.get_bone_global_rest(_bone[key]).origin
	_thigh = _rest_pos.upleg_l.distance_to(_rest_pos.leg_l)
	_shin = _rest_pos.leg_l.distance_to(_rest_pos.foot_l)

	body = Node3D.new()
	add_child(body)
	head = Node3D.new()
	add_child(head)
	_hand_r = Node3D.new()
	add_child(_hand_r)
	_chest = Node3D.new()
	_chest.position = CHEST
	body.add_child(_chest)
	_finish_setup()


func _apply_pose(p: Dictionary, tremble: float) -> void:
	# Legs first: a crouch bends the knees, and the whole model drops so the feet stay planted.
	var crouch := clampf(-p.rise / CROUCH_DEPTH, 0.0, 1.0)
	var thigh_deg := CROUCH_THIGH * crouch
	var knee_deg := CROUCH_KNEE * crouch
	var drop := (_thigh + _shin) - (_thigh * cos(deg_to_rad(thigh_deg)) + _shin * cos(deg_to_rad(knee_deg - thigh_deg)))
	_root.position = Vector3(0, maxf(p.rise, 0.0) - drop, 0)
	_root.rotation_degrees = Vector3(0, 0, p.roll + tremble * 0.3)
	for side in ["l", "r"]:
		var swing: float = p["leg_" + side]
		# Rotating about +X swings a hanging leg backwards, so forward is negative.
		_turn_bone(_bone["upleg_" + side], Basis(Vector3.RIGHT, deg_to_rad(-(swing + thigh_deg))))
		_turn_bone(_bone["leg_" + side], Basis(Vector3.RIGHT, deg_to_rad(knee_deg)))

	var body_rot := Basis.from_euler(Vector3(deg_to_rad(p.lean), deg_to_rad(p.turn), 0.0))
	_turn_bone(_bone.spine, body_rot)
	_turn_bone(_bone.head, Basis(Vector3.RIGHT, deg_to_rad(p.head)))
	# The greybox arm angles assume an arm hanging down; the model's rest is a T-pose.
	var left: Vector3 = p.arm_l + Vector3(tremble, 0, 0)
	var r: Vector3 = p.arm_r
	var right := Vector3(r.x - tremble, -r.y, -r.z)
	var arm_l := _euler(left)
	var arm_r := _euler(right)
	_turn_bone(_bone.arm_l, arm_l * Basis(Vector3.BACK, deg_to_rad(-90.0)))
	_turn_bone(_bone.arm_r, arm_r * Basis(Vector3.BACK, deg_to_rad(90.0)))

	# Sockets and followers, in the rig's own space.
	var to_rig := global_transform.affine_inverse() * _skeleton.global_transform if is_inside_tree() else _root.transform
	var torso := _root.basis * body_rot
	var spine_now := to_rig * _skeleton.get_bone_global_pose(_bone.spine).origin
	body.basis = torso
	body.position = spine_now - torso * Vector3(0, _rest_pos.spine.y, 0)
	head.position = to_rig * _skeleton.get_bone_global_pose(_bone.head).origin
	head.basis = torso * Basis(Vector3.RIGHT, deg_to_rad(p.head))
	_hand_r.position = to_rig * _skeleton.get_bone_global_pose(_bone.hand_r).origin
	_hand_r.basis = torso * arm_r


## Turns a bone by `delta` (in character space) from its rest pose, relative to its parent's rest.
func _turn_bone(bone: int, delta: Basis) -> void:
	if bone < 0:
		return
	var parent := _skeleton.get_bone_parent(bone)
	var parent_rest: Basis = _rest[parent] if parent >= 0 else Basis.IDENTITY
	var local: Basis = parent_rest.inverse() * delta * _rest[bone]
	_skeleton.set_bone_pose_rotation(bone, local.get_rotation_quaternion())


static func _euler(deg: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(deg.x), deg_to_rad(deg.y), deg_to_rad(deg.z)))
