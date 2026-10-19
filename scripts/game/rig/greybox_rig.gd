class_name GreyboxRig
extends CharacterRig
## A greybox character built from shapes, with jointed arms. Used for the Jans, and for Meagan
## when her model is missing.

var _arm_r: Node3D
var _arm_l: Node3D


## `spec`: coat (Color), radius and height (of the coat), skin (Color), head_radius, mitten (Color).
func _init(spec: Dictionary) -> void:
	var radius: float = spec.radius
	var height: float = spec.height
	body = Node3D.new()
	add_child(body)
	body.add_child(Shapes.capsule(radius, height, spec.coat, Vector3(0, height / 2.0 + 0.02, 0)))
	head = Node3D.new()
	head.position = Vector3(0, height + 0.01, 0)
	body.add_child(head)
	head.add_child(Shapes.sphere(spec.head_radius, spec.skin, Vector3(0, spec.head_radius * 0.62, 0)))

	var arm_len := height * 0.44
	for side in [-1.0, 1.0]:
		# The character faces +Z, so its right side is -X.
		var arm := Node3D.new()
		arm.position = Vector3(side * (radius + 0.07), height * 0.84, 0)
		body.add_child(arm)
		arm.add_child(Shapes.capsule(0.09, arm_len, spec.coat.darkened(0.08), Vector3(0, -arm_len / 2.0 + 0.06, 0)))
		arm.add_child(Shapes.sphere(0.1, spec.mitten, Vector3(0, -arm_len + 0.04, 0)))
		var hand := Node3D.new()
		hand.position = Vector3(0, -arm_len + 0.04, 0)
		arm.add_child(hand)
		if side < 0.0:
			_arm_r = arm
			_hand_r = hand
		else:
			_arm_l = arm
	_chest = Node3D.new()
	_chest.position = Vector3(0, height * 0.62, radius + 0.3)
	body.add_child(_chest)
	_finish_setup()


func _apply_pose(p: Dictionary, tremble: float) -> void:
	body.position.y = p.rise
	body.rotation_degrees = Vector3(p.lean, p.turn, p.roll + tremble)
	head.rotation_degrees.x = p.head
	_arm_l.rotation_degrees = p.arm_l + Vector3(tremble, 0, 0)
	var r: Vector3 = p.arm_r
	_arm_r.rotation_degrees = Vector3(r.x - tremble, -r.y, -r.z)
