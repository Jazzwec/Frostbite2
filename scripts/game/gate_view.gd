class_name GateView
extends Node3D
## A gate into a closed tile (agreed 2026-10-20): a ring of hearth stones on the border where its
## small furnace will stand, and a pad in front, on the open side, that shows what opening the
## tile costs and fills as she pays.

const STONE := Color(0.55, 0.53, 0.52)

var index := 0
var _pad: MeshInstance3D
var _ring: MeshInstance3D
var _ring_frac := -1.0
var _label: Label3D


func setup(gate_index: int, gate: Dictionary) -> void:
	index = gate_index
	var pos: Vector2 = gate.pos
	position = Vector3(pos.x, 0, pos.y)
	for k in 7:
		var a := TAU * k / 7.0
		add_child(Shapes.sphere(0.24, STONE, Vector3(cos(a) * 0.7, 1.25, sin(a) * 0.7)))
	add_child(Shapes.cylinder(0.75, 1.2, Color(0.9, 0.93, 1.0), Vector3(0, 0.6, 0)))
	var at: Vector2 = gate.pad - pos
	var root := Node3D.new()
	root.position = Vector3(at.x, 0, at.y)
	add_child(root)
	_pad = Shapes.cylinder(SiteView.PAD_RADIUS_SHOWN, 0.03, SiteView.PAD_COLORS.plot, Vector3(0, 0.02, 0))
	root.add_child(_pad)
	_ring = MeshInstance3D.new()
	_ring.position = Vector3(0, 0.05, 0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = SiteView.RING_COLOR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring.material_override = m
	root.add_child(_ring)
	_label = Shapes.label("", Vector3(0, 0.08, 0), 40)
	_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_label.rotation_degrees.x = -90.0
	root.add_child(_label)
	add_child(Shapes.tap_area(Vector3(3.5, 2.0, 3.5), "gate", index, Vector3(at.x / 2.0, 0, at.y / 2.0)))


func refresh(gate: Dictionary) -> void:
	var frac := 0.0
	var lines := []
	var have := 0.0
	var total := 0.0
	for res in gate.cost:
		var got: float = gate.progress.get(res, 0.0)
		have += got
		total += gate.cost[res]
		var name: String = {"wood": "Wood", "food": "Food", "materials": "Mat"}[res]
		lines.append(("%s %s/%s" % [name, Fmt.num(got), Fmt.num(gate.cost[res])]) if gate.paying else ("%s %s" % [name, Fmt.num(gate.cost[res])]))
	if gate.paying:
		frac = have / maxf(total, 1.0)
		_label.text = "\n".join(lines)
	else:
		_label.text = "Open\n" + "  ".join(lines)
	_pad.material_override = Shapes.material(SiteView.PAD_COLORS.paying if gate.paying else SiteView.PAD_COLORS.idle)
	if absf(frac - _ring_frac) > 0.004:
		_ring_frac = frac
		_ring.mesh = SiteView._ring_mesh(frac)
		_ring.visible = frac > 0.0
