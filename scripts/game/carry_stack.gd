class_name CarryStack
extends Node3D
## What Meagan carries, stacked on her back: one piece per few units, grouped by resource.
## Pieces fly in from where they came from and fly off to where they're going, one at a time,
## each with a "+N" pop.

## At most this many pieces, so a full stack stays below her head.
const MAX_PIECES := 8
## Seconds between pieces joining or leaving, for the one-by-one feel.
const STEP_TIME := 0.07
const ORDER := ["wood", "food", "materials"]
const ITEMS := {"wood": "log", "food": "fish", "materials": "materials"}
## Pieces are drawn at this size, so a full stack doesn't hide the chibi model behind it.
const PIECE_SCALE := 0.8
## How much stack height each item takes, at that size.
const HEIGHTS := {"wood": 0.18, "food": 0.13, "materials": 0.19}
const COLORS := {"wood": Color(1.0, 0.85, 0.6), "food": Color(1.0, 0.7, 0.65), "materials": Color(0.8, 0.85, 0.95)}

var _pieces: Array = []  # {res, node}, bottom first
var _incoming := {"wood": 0, "food": 0, "materials": 0}
var _cooldown := 0.0
var _time := 0.0


## Called every frame with the engine's bag. `source` and `dest` (Vector3.INF for none) are
## where new pieces come from and where leaving pieces go; `landed(resource)` runs as each one
## arrives.
func sync(bag: Dictionary, cap: float, source: Vector3, dest: Vector3, landed: Callable, moving: float, delta: float) -> void:
	_time += delta
	_layout(moving, delta)
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var unit := ceilf(cap / MAX_PIECES)
	for res in ORDER:
		var want: int = ceili(bag[res] / unit - 0.001) if bag[res] > 0.01 else 0
		var have: int = _count(res) + _incoming[res]
		if want < have and _count(res) > 0:
			_remove(res, unit, dest, landed)
			_cooldown = STEP_TIME
			return
		if want > have:
			_add(res, unit, source)
			_cooldown = STEP_TIME
			return


## The top of the stack, for the counter and for things landing on it.
func top_position() -> Vector3:
	return global_transform * Vector3(0, _height(), 0)


func _count(res: String) -> int:
	var n := 0
	for p in _pieces:
		if p.res == res:
			n += 1
	return n


func _height() -> float:
	var h := 0.0
	for p in _pieces:
		h += HEIGHTS[p.res]
	return h


func _add(res: String, unit: float, source: Vector3) -> void:
	if source == Vector3.INF:
		_place(res, unit, false)
		return
	_incoming[res] += 1
	var arrive := func() -> void:
		_incoming[res] -= 1
		_place(res, unit, true)
	Fx.throw(ITEMS[res], source, top_position(), 0.3, 1.0, arrive)


func _place(res: String, unit: float, pop: bool) -> void:
	var node := Tools.make(ITEMS[res])
	add_child(node)
	node.rotation.y = randf_range(-0.25, 0.25)
	# Keep each resource together: a new piece goes on top of its own kind.
	var at := 0
	for p in _pieces:
		if ORDER.find(p.res) <= ORDER.find(res):
			at += 1
	_pieces.insert(at, {"res": res, "node": node})
	node.position = Vector3(0, _offset(at), 0)
	node.scale = Vector3.ONE * PIECE_SCALE * 1.4
	create_tween().tween_property(node, "scale", Vector3.ONE * PIECE_SCALE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if pop:
		# The pop climbs in pitch as the stack grows, which feels great to fill up.
		Audio.play("pop", top_position(), 0.85 + 0.04 * _pieces.size())
		# The "+N" comes with each blow instead (main.gd, AFK N5): one per catch or chop.


func _remove(res: String, unit: float, dest: Vector3, landed: Callable) -> void:
	for i in range(_pieces.size() - 1, -1, -1):
		if _pieces[i].res != res:
			continue
		var node: Node3D = _pieces[i].node
		_pieces.remove_at(i)
		var from := node.global_position
		node.queue_free()
		if dest != Vector3.INF:
			Audio.play("whoosh", from)
			# No "+N" per piece (AFK V5): the stockpile or pad sums it up once.
			var arrive := func() -> void:
				Audio.play("drop", dest)
				if landed.is_valid():
					landed.call(res)
			Fx.throw(ITEMS[res], from, dest, 0.35, 1.2, arrive)
		return


func _offset(index: int) -> float:
	var h := 0.0
	for i in index:
		h += HEIGHTS[_pieces[i].res]
	return h + HEIGHTS[_pieces[index].res] / 2.0


## Pieces settle into place, and the stack wobbles more towards the top while she runs.
func _layout(moving: float, delta: float) -> void:
	for i in _pieces.size():
		var node: Node3D = _pieces[i].node
		var sway := sin(_time * 9.0 + i * 0.5) * 0.012 * i * moving
		var target := Vector3(sway, _offset(i), -0.02 * i * moving)
		node.position = node.position.lerp(target, minf(1.0, 18.0 * delta))
