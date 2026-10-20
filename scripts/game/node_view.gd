class_name NodeView
extends Node3D
## A resource spot: a forest, a fishing pond (kind "hunting", for ice fishing) or a scrap heap.
## Its pieces thin out as the stock runs down: trees topple, the rest sink into the snow.

const PIECES := 6
const POND_RADIUS := 2.0
const HOLES := 4
const HOLE_RADIUS := 1.0
## Where she stands to work a tree or crate, and to fish a hole: off to one side and a little
## towards the camera, clear of the canopy.
const WORK_OFFSET := Vector2(1.2, 0.6)
const FISH_OFFSET := Vector2(1.5, 0.3)

var index := 0
var kind := ""
var _pieces: Array[Node3D] = []
var _up: Array[bool] = []
var _holes: Array[Vector3] = []
var _label: Label3D
## The stock label shows only within this distance of her. [ink_v3, 2026-10-20]
const LABEL_NEAR := 11.0
## Whether any crown here is (still) faded for Meagan.
var _faded := false


func setup(node_index: int, s: GameState) -> void:
	index = node_index
	var def: Dictionary = s.node_defs[index]
	kind = def.kind
	position = Vector3(def.pos.x, 0, def.pos.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 7919 + 1
	if kind == "hunting":
		_build_pond()
	for i in PIECES:
		var angle := TAU * i / PIECES + rng.randf_range(-0.3, 0.3)
		var dist := rng.randf_range(2.3, 2.8) if kind == "hunting" else rng.randf_range(1.4, 2.8)
		var piece := _make_piece(rng)
		piece.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		add_child(piece)
		_pieces.append(piece)
		_up.append(true)
	if kind == "forest":
		var fallen := Props.make("log", 0.35, rng.randf_range(0, 180))
		if fallen:
			add_child(fallen)
	_label = Shapes.label("", Vector3(0, 3.2, 0), 44)
	add_child(_label)
	add_child(Shapes.tap_area(Vector3(5, 3, 5), "node", index))


func _build_pond() -> void:
	add_child(Shapes.cylinder(POND_RADIUS, 0.04, Color(0.68, 0.84, 0.95), Vector3(0, 0.02, 0)))
	for i in HOLES:
		var angle := TAU * i / HOLES + PI / 4.0
		var p := Vector3(cos(angle), 0, sin(angle)) * HOLE_RADIUS
		add_child(Shapes.cylinder(0.3, 0.05, Color(0.12, 0.2, 0.32), p + Vector3(0, 0.03, 0)))
		_holes.append(p)


func _make_piece(rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	match kind:
		"forest":
			# A stump that stays, and the tree above it that falls.
			var h := rng.randf_range(2.2, 3.4)
			n.add_child(Shapes.cylinder(0.18, 0.25, Color(0.4, 0.27, 0.15), Vector3(0, 0.125, 0)))
			n.add_child(Shapes.cylinder(0.14, 0.02, Color(0.78, 0.62, 0.42), Vector3(0, 0.26, 0)))
			var crown := Node3D.new()
			crown.name = "Crown"
			crown.set_meta("height", 0.6 + h)
			n.add_child(crown)
			# One of the low-poly pines, sized to the tree's height (the squat one stays squat).
			var pine_id: String = Props.PINE_HEIGHTS.keys()[rng.randi() % Props.PINE_HEIGHTS.size()]
			var pine_scale := (0.6 + h) / 3.4
			var pine := Props.make(pine_id, pine_scale, rng.randf_range(0, 360))
			if pine:
				Props.use_vertex_colours(pine)
				crown.add_child(pine)
				crown.set_meta("height", Props.PINE_HEIGHTS[pine_id] * pine_scale)
			else:
				crown.add_child(Shapes.cylinder(0.15, 0.6, Color(0.4, 0.27, 0.15), Vector3(0, 0.3, 0)))
				crown.add_child(Shapes.cone(0.9, h * 0.6, Color(0.18, 0.38, 0.26), Vector3(0, 0.6 + h * 0.3, 0)))
				crown.add_child(Shapes.cone(0.65, h * 0.45, Color(0.2, 0.42, 0.29), Vector3(0, 0.6 + h * 0.6, 0)))
				crown.add_child(Shapes.cone(0.35, h * 0.25, Shapes.SNOW_COLOR, Vector3(0, 0.6 + h * 0.85, 0)))
		"hunting":
			# Reeds and snowy rocks round the pond's shore.
			var rock := Props.make("boulder", rng.randf_range(0.35, 0.55), rng.randf_range(0, 360)) if rng.randf() < 0.35 else null
			if rock:
				n.add_child(rock)
			else:
				for j in 3:
					var reed := Shapes.cylinder(0.04, rng.randf_range(0.7, 1.1), Color(0.6, 0.5, 0.3), Vector3(j * 0.12 - 0.12, 0.45, rng.randf_range(-0.1, 0.1)))
					reed.rotation_degrees.z = (j - 1) * 12.0
					n.add_child(reed)
				n.add_child(Shapes.sphere(0.22, Shapes.SNOW_COLOR, Vector3(0, 0.05, 0)))
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
	var node_def: Dictionary = Balance.NODES[kind]
	var frac: float = s.nodes[index] / node_def.stock
	var showing := ceili(frac * PIECES)
	for i in PIECES:
		var up := i < showing
		if up != _up[i]:
			_up[i] = up
			if up:
				_grow(_pieces[i])
			else:
				_fall(_pieces[i])
	_label.text = "%s %s" % [str(node_def.resource).capitalize(), Fmt.num(s.nodes[index])]
	# Only as she comes near (the town reads as a picture, ink_v3); while she works here her pops
	# and readout are over her, so the spot's own label steps aside.
	var d := s.meagan_pos.distance_to(MapData.node_pos(s, index))
	_label.visible = d > Balance.GATHER_RANGE + 1.0 and d <= LABEL_NEAR
	_label.modulate = Color(1, 1, 1, 0.9) if frac > 0.05 else Color(0.7, 0.7, 0.75, 0.6)


## Fades the tree crowns that stand between the camera and Meagan. A felled tree comes back to
## solid as it falls, so the topple reads as the reward for chopping. Returns whether any tree
## stands in front of her right now.
func fade_covers(camera: Transform3D, meagan: Vector3, delta: float) -> bool:
	if kind != "forest":
		return false
	var near := global_position.distance_to(meagan) < 9.0
	if not near and not _faded:
		return false
	_faded = false
	var covering := false
	for i in _pieces.size():
		var piece := _pieces[i]
		var crown := piece.get_node_or_null("Crown") as Node3D
		if crown == null:
			continue
		var cover := near and _up[i] and FadeCover.covers(camera, meagan, piece.global_position, crown.get_meta("height", 3.0), 0.9)
		_faded = FadeCover.fade(crown, cover, delta) or _faded
		covering = covering or cover
	return covering


## What Meagan works at from `from`: the nearest standing tree or crate, or the nearest ice hole.
func focus_point(from: Vector3) -> Vector3:
	if kind == "hunting":
		return _nearest(from, _holes.map(func(h): return to_global(h)))
	var standing := []
	for i in PIECES:
		if _up[i]:
			standing.append(_pieces[i].global_position)
	if standing.is_empty():
		# All felled: she works the stumps, or the middle of an empty heap.
		if kind != "forest":
			return global_position
		standing = _pieces.map(func(p): return p.global_position)
	return _nearest(from, standing)


## Where to send her so she's right beside what she'll work at, seen side-on by the camera and
## always within gathering range.
func work_spot(from: Vector3) -> Vector3:
	var targets := []
	if kind == "hunting":
		targets = _holes.map(func(h): return to_global(h))
	else:
		for i in PIECES:
			if _up[i] or kind == "forest":
				targets.append(_pieces[i].global_position)
	var offset := FISH_OFFSET if kind == "hunting" else WORK_OFFSET
	var spots := []
	for t in targets:
		for side in [-1.0, 1.0]:
			var spot: Vector3 = t + Vector3(side * offset.x, 0, offset.y)
			if spot.distance_to(global_position) <= Balance.GATHER_RANGE - 0.3:
				spots.append(spot)
	if spots.is_empty():
		return global_position
	return _nearest(from, spots)


## A blow lands: the nearest standing piece shakes. Returns where it is.
func hit(from: Vector3) -> Vector3:
	var focus := focus_point(from)
	for i in PIECES:
		if _up[i] and _pieces[i].global_position.is_equal_approx(focus):
			var p := _top(_pieces[i])
			var t := create_tween()
			t.tween_property(p, "rotation_degrees:z", 7.0, 0.05)
			t.tween_property(p, "rotation_degrees:z", -4.0, 0.1)
			t.tween_property(p, "rotation_degrees:z", 0.0, 0.15)
			break
	return focus


## The part that falls or sinks: a tree above its stump, or the whole piece.
func _top(piece: Node3D) -> Node3D:
	var crown := piece.get_node_or_null("Crown") as Node3D
	return crown if crown else piece


func _fall(piece: Node3D) -> void:
	var top := _top(piece)
	var t := create_tween()
	if kind == "forest":
		# Timber! It topples away from the middle of the forest.
		var away := piece.position.normalized()
		top.rotation_degrees = Vector3.ZERO
		t.tween_property(top, "rotation_degrees", Vector3(away.z * 85.0, 0, -away.x * 85.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_interval(0.4)
		t.tween_property(top, "scale", Vector3.ONE * 0.01, 0.3)
	else:
		t.tween_property(top, "scale", Vector3.ONE * 0.01, 0.35).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): top.visible = false)


func _grow(piece: Node3D) -> void:
	var top := _top(piece)
	top.rotation_degrees = Vector3.ZERO
	top.scale = Vector3.ONE * 0.01
	top.visible = true
	create_tween().tween_property(top, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func _nearest(from: Vector3, points: Array) -> Vector3:
	var best: Vector3 = points[0]
	for p in points:
		if from.distance_to(p) < from.distance_to(best):
			best = p
	return best
