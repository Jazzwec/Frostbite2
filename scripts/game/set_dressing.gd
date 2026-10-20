class_name SetDressing
extends Node3D
## The small things that make the town a place (ink_v3, 2026-10-20): woodpiles, fences, sleds,
## benches and lantern posts clustered behind and beside the plots, snowy rocks and bare shrubs
## scattered over open snow. Models come from the house kit (tools/blender/house_kit.py).
## Each open tile is dressed once, seeded from the winter's seed and the tile, so a tile looks the
## same however often the game loads. Everything stays clear of pads, paths, plots' fronts,
## resource spots, the Stockpile, gates, chests, camps and dens. Visual only: no collision, no
## state.

## By a plot: one or two of these at its back corners (fences run along the back wall, where the
## camera sees them side-on) or beside it (no fences: end-on they'd read as poles).
const BY_PLOT_BACK := ["prop_fence", "prop_fence", "prop_woodpile", "prop_sled"]
const BY_PLOT_SIDE := ["prop_woodpile", "prop_bench", "prop_lantern_post", "prop_sled", "prop_rock_b"]
## Out in the open snow.
const SCATTER := ["prop_rock_a", "prop_rock_b", "prop_rock_b", "prop_shrub", "prop_shrub", "prop_shrub"]
## Where by a plot, from its centre (Godot x, z; the pad is at +z): behind and beside it.
const PLOT_SPOTS := [Vector2(-2.6, -2.2), Vector2(2.6, -2.2), Vector2(-2.9, 0.2), Vector2(2.9, 0.2)]
const BY_PLOT_MAX := 2
const SCATTER_TRIES := 14
const SCATTER_PER_TILE := 6
## Clearances in metres.
const CLEAR_PATH := 1.5
const CLEAR_PAD := 2.0
const CLEAR_SITE := 3.2
const CLEAR_NODE := 3.6
const CLEAR_STOCKPILE := 3.4
const CLEAR_FURNACE := 4.5
const CLEAR_THING := 2.2
const TILE_INSET := 1.6

var _dressed := {}


func refresh(s: GameState) -> void:
	for k in s.tiles:
		if not _dressed.has(k):
			_dressed[k] = true
			_dress(s, WorldRules.tile_from_key(k))


func _dress(s: GameState, tile: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([s.run_seed, tile.x, tile.y, "dressing"])
	var rect := MapData.tile_rect(tile).grow(-TILE_INSET)
	var paths := _paths(s)
	for i in range(1, s.sites.size()):
		var at := MapData.site_pos(s, i)
		if MapData.tile_of(at) != tile:
			continue
		var spots := PLOT_SPOTS.duplicate()
		_shuffle(spots, rng)
		var placed := 0
		for spot: Vector2 in spots:
			if placed >= BY_PLOT_MAX:
				break
			var p := at + spot
			if rect.has_point(p) and _clear(s, p, paths, i):
				var pool: Array = BY_PLOT_BACK if spot.y < -1.0 else BY_PLOT_SIDE
				_place(pool[rng.randi() % pool.size()], p, rng, spot)
				placed += 1
	var count := 0
	for t in SCATTER_TRIES:
		if count >= SCATTER_PER_TILE:
			break
		var p := Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
		if _clear(s, p, paths, -1):
			_place(SCATTER[rng.randi() % SCATTER.size()], p, rng, Vector2.ZERO)
			count += 1


## A prop at `p`; fences, benches and sleds by a plot face the camera side-on, the rest turn freely.
func _place(id: String, p: Vector2, rng: RandomNumberGenerator, spot: Vector2) -> void:
	var yaw := rng.randf_range(0.0, 360.0)
	if spot != Vector2.ZERO and id in ["prop_fence", "prop_bench", "prop_sled"]:
		yaw = rng.randf_range(-10.0, 10.0)
	var node := Props.make(id, rng.randf_range(0.9, 1.1), yaw)
	if node == null:
		return
	Props.use_vertex_colours(node)
	node.position = Vector3(p.x, 0.0, p.y)
	add_child(node)


func _clear(s: GameState, p: Vector2, paths: Array, own_site: int) -> bool:
	if p.distance_to(MapData.site_pos(s, 0)) < CLEAR_FURNACE:
		return false
	for k in s.stockpiles.size():
		if p.distance_to(s.stockpiles[k].pos) < (CLEAR_STOCKPILE if k == 0 else CLEAR_THING + 0.6):
			return false
	for i in range(1, s.sites.size()):
		if p.distance_to(MapData.pad_pos(s, i)) < CLEAR_PAD:
			return false
		if i != own_site and p.distance_to(MapData.site_pos(s, i)) < CLEAR_SITE:
			return false
	for i in s.node_defs.size():
		if p.distance_to(MapData.node_pos(s, i)) < CLEAR_NODE:
			return false
	var things: Array = s.stoves + s.chests + s.camps + s.dens
	for thing in things:
		if p.distance_to(thing.pos) < CLEAR_THING:
			return false
	for gate in s.gates:
		if p.distance_to(gate.pad) < CLEAR_THING or p.distance_to(gate.pos) < CLEAR_THING:
			return false
	for spot in s.arrival_spots:
		if p.distance_to(spot) < CLEAR_THING:
			return false
	for seg: Vector4 in paths:
		if _segment_distance(p, Vector2(seg.x, seg.y), Vector2(seg.z, seg.w)) < CLEAR_PATH:
			return false
	return true


## The trodden tracks, one connected network (main.gd paints them on the snow; props keep off
## them): from the furnace's rim to the Stockpile, every starting plot's pad and the starting
## resource spots' edges, and from each small furnace to its tile's plots and spots.
## [ink_v3 review, 2026-10-20]
const TRACK_SPOT_GAP := 2.4


static func tracks(s: GameState) -> Array[Vector4]:
	var out: Array[Vector4] = []
	var furnace := MapData.site_pos(s, 0)
	var ends: Array[Vector2] = [MapData.stockpile_pad(s, 0)]
	for i in range(1, s.sites.size()):
		if not s.sites[i].has("tile"):
			ends.append(MapData.pad_pos(s, i))
	for i in s.node_defs.size():
		if not s.node_defs[i].has("tile"):
			var p := MapData.node_pos(s, i)
			ends.append(p + (furnace - p).normalized() * TRACK_SPOT_GAP)
	for end in ends:
		# From the furnace's rim, so the tracks don't pool into one blot in the middle.
		var start := furnace + (end - furnace).normalized() * (MapData.FURNACE_RADIUS + 1.0)
		out.append(Vector4(start.x, start.y, end.x, end.y))
	for k in range(1, s.stockpiles.size()):
		# From each small furnace to its tile's stockpile.
		for stove in s.stoves:
			if stove.tile == s.stockpiles[k].tile:
				var end := MapData.stockpile_pad(s, k)
				out.append(Vector4(stove.pos.x, stove.pos.y, end.x, end.y))
	for stove in s.stoves:
		for i in s.sites.size():
			if s.sites[i].get("tile", Vector2i(9999, 9999)) == stove.tile:
				var end := MapData.pad_pos(s, i)
				out.append(Vector4(stove.pos.x, stove.pos.y, end.x, end.y))
		for i in s.node_defs.size():
			if s.node_defs[i].get("tile", Vector2i(9999, 9999)) == stove.tile:
				var p := MapData.node_pos(s, i)
				var from: Vector2 = stove.pos
				var end := p + (from - p).normalized() * TRACK_SPOT_GAP
				out.append(Vector4(stove.pos.x, stove.pos.y, end.x, end.y))
	return out


static func _paths(s: GameState) -> Array:
	return tracks(s)


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.dot(ab), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
