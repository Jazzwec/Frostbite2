class_name ChestView
extends Node3D
## A chest in an opened tile (agreed 2026-10-20): a rope-tied crate for a resource cache, a teal
## (rare) or ochre (epic) chest for boons, an iron-banded one for gear. Its lid swings open once
## she's opened it. Greybox until its model is made.

const LOOKS := {
	"cache": {"body": Color(0.6, 0.42, 0.25), "trim": Color(0.82, 0.72, 0.5)},
	"boon_rare": {"body": Color(0.37, 0.54, 0.53), "trim": Color(0.79, 0.59, 0.25)},
	"boon_epic": {"body": Color(0.79, 0.59, 0.25), "trim": Color(0.7, 0.25, 0.18)},
	"gear": {"body": Color(0.32, 0.29, 0.28), "trim": Color(0.6, 0.6, 0.62)},
}

var index := 0
var _lid: Node3D
var _opened := false


func setup(chest_index: int, chest: Dictionary) -> void:
	index = chest_index
	position = Vector3(chest.pos.x, 0, chest.pos.y)
	rotation_degrees.y = float((chest_index * 47) % 60) - 30.0
	var look: Dictionary = LOOKS.get(chest.kind if chest.kind != "boon" else "boon_" + chest.rarity, LOOKS.cache)
	add_child(Shapes.box(Vector3(0.95, 0.55, 0.62), look.body, Vector3(0, 0.275, 0)))
	add_child(Shapes.box(Vector3(0.12, 0.57, 0.64), look.trim, Vector3(-0.28, 0.285, 0)))
	add_child(Shapes.box(Vector3(0.12, 0.57, 0.64), look.trim, Vector3(0.28, 0.285, 0)))
	# The lid hinges along the back edge.
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.55, -0.31)
	add_child(_lid)
	_lid.add_child(Shapes.box(Vector3(1.0, 0.2, 0.66), look.body, Vector3(0, 0.1, 0.33)))
	_lid.add_child(Shapes.box(Vector3(0.14, 0.06, 0.08), look.trim, Vector3(0, 0.08, 0.66)))
	add_child(Shapes.tap_area(Vector3(1.6, 1.4, 1.6), "chest", index))
	if chest.opened:
		_open(false)


func refresh(chest: Dictionary) -> void:
	if chest.opened and not _opened:
		_open(true)


func _open(animate: bool) -> void:
	_opened = true
	if animate:
		create_tween().tween_property(_lid, "rotation_degrees:x", -110.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_lid.rotation_degrees.x = -110.0
