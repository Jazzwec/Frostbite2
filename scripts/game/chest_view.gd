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
	add_child(Shapes.tap_area(Vector3(1.6, 1.4, 1.6), "chest", index))
	# The pipeline's chest (cleanup.py cut its lid off as "<name>_lid", hinged at its top back
	# edge), one per kind; an epic boon chest glows warm. Else the greybox chest below.
	var model := Props.make("chest_" + str(chest.kind))
	if model:
		add_child(model)
		var drift_m := Shapes.sphere(0.5, Shapes.SNOW_COLOR, Vector3(0, 0.0, 0.05))
		drift_m.scale = Vector3(1.9, 0.3, 1.5)
		add_child(drift_m)
		_lid = model.find_child("*_lid", true, false) as Node3D
		if chest.kind == "boon" and chest.rarity == "epic":
			var glow := OmniLight3D.new()
			glow.light_color = Color(1.0, 0.75, 0.35)
			glow.light_energy = 1.2
			glow.omni_range = 2.5
			glow.position = Vector3(0, 1.0, 0.4)
			add_child(glow)
		if _lid == null:
			_lid = Node3D.new()
			add_child(_lid)
		if chest.opened:
			_open(false)
		return
	# Chunky, like the house kit (ink_v3 review): a stout box with broad bands, a rounded lid
	# (the ink look snows on its top) and a drift round its foot.
	add_child(Shapes.box(Vector3(1.0, 0.55, 0.66), look.body, Vector3(0, 0.275, 0)))
	for x in [-0.3, 0.3]:
		add_child(Shapes.box(Vector3(0.16, 0.57, 0.68), look.trim, Vector3(x, 0.285, 0)))
	add_child(Shapes.box(Vector3(0.2, 0.2, 0.06), look.trim, Vector3(0, 0.45, 0.34)))
	var drift := Shapes.sphere(0.5, Shapes.SNOW_COLOR, Vector3(0, 0.0, 0.05))
	drift.scale = Vector3(1.9, 0.3, 1.5)
	add_child(drift)
	# The lid hinges along the back edge.
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.55, -0.33)
	add_child(_lid)
	var arch := Shapes.cylinder(0.33, 1.02, look.body, Vector3(0, 0.0, 0.33))
	arch.rotation_degrees.z = 90.0
	_lid.add_child(arch)
	for x in [-0.3, 0.3]:
		var band := Shapes.cylinder(0.35, 0.16, look.trim, Vector3(x, 0.0, 0.33))
		band.rotation_degrees.z = 90.0
		_lid.add_child(band)
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
