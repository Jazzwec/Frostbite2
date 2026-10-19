class_name NodeView
extends Node3D
## A resource spot: a forest, hunting ground or scrap heap. Its pieces thin out as the stock runs down.

const PIECES := 6

var index := 0
var _pieces: Array[Node3D] = []
var _label: Label3D


func setup(node_index: int) -> void:
	index = node_index
	var def: Dictionary = MapData.RESOURCE_NODES[index]
	position = Vector3(def.pos.x, 0, def.pos.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 7919 + 1
	for i in PIECES:
		var angle := TAU * i / PIECES + rng.randf_range(-0.3, 0.3)
		var dist := rng.randf_range(1.2, 2.4)
		var piece := _make_piece(def.kind, rng)
		piece.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		add_child(piece)
		_pieces.append(piece)
	if def.kind == "forest":
		var fallen := Props.make("log", 0.35, rng.randf_range(0, 180))
		if fallen:
			add_child(fallen)
	_label = Shapes.label("", Vector3(0, 3.2, 0), 44)
	add_child(_label)
	add_child(Shapes.tap_area(Vector3(5, 3, 5), "node", index))


func _make_piece(kind: String, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	match kind:
		"forest":
			var h := rng.randf_range(2.2, 3.4)
			n.add_child(Shapes.cylinder(0.15, 0.6, Color(0.4, 0.27, 0.15), Vector3(0, 0.3, 0)))
			n.add_child(Shapes.cone(0.9, h * 0.6, Color(0.18, 0.38, 0.26), Vector3(0, 0.6 + h * 0.3, 0)))
			n.add_child(Shapes.cone(0.65, h * 0.45, Color(0.2, 0.42, 0.29), Vector3(0, 0.6 + h * 0.6, 0)))
			n.add_child(Shapes.cone(0.35, h * 0.25, Shapes.SNOW_COLOR, Vector3(0, 0.6 + h * 0.85, 0)))
		"hunting":
			var rock := Props.make("boulder", rng.randf_range(0.35, 0.6), rng.randf_range(0, 360)) if rng.randf() < 0.35 else null
			if rock:
				n.add_child(rock)
			else:
				n.add_child(Shapes.sphere(rng.randf_range(0.4, 0.7), Color(0.3, 0.38, 0.25), Vector3(0, 0.3, 0)))
				n.add_child(Shapes.sphere(0.2, Shapes.SNOW_COLOR, Vector3(0.1, 0.65, 0)))
		"scrap":
			var prop := Props.make("crate" if rng.randf() < 0.6 else "boulder", rng.randf_range(1.0, 1.4), rng.randf_range(0, 360))
			if prop:
				n.add_child(prop)
			else:
				var c := Color(0.45, 0.43, 0.42).lerp(Color(0.55, 0.38, 0.25), rng.randf())
				var b := Shapes.box(Vector3(rng.randf_range(0.4, 0.9), rng.randf_range(0.3, 0.6), rng.randf_range(0.4, 0.9)), c, Vector3(0, 0.25, 0))
				b.rotation_degrees.y = rng.randf_range(0, 90)
				n.add_child(b)
	return n


func refresh(s: GameState) -> void:
	var def: Dictionary = MapData.RESOURCE_NODES[index]
	var node_def: Dictionary = Balance.NODES[def.kind]
	var frac: float = s.nodes[index] / node_def.stock
	var showing := ceili(frac * PIECES)
	for i in PIECES:
		_pieces[i].visible = i < showing
	_label.text = "%s %s" % [str(node_def.resource).capitalize(), Fmt.num(s.nodes[index])]
	_label.modulate = Color(1, 1, 1, 0.9) if frac > 0.05 else Color(0.7, 0.7, 0.75, 0.6)
