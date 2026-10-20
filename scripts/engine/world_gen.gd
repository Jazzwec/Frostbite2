class_name WorldGen
extends RefCounted
## What a tile beyond the starting grid holds, worked out from the winter's seed and the tile
## alone, so it comes out the same whatever order tiles are opened in (agreed 2026-10-20). Pure:
## nothing here changes the state. It has its own random numbers, so it never shifts the
## engine's rolls for arrivals, blizzards and wolves.

## Things keep this far inside their tile's edge, clear of the gates and small furnaces there.
const EDGE_MARGIN := 2.5
## Room each kind of thing needs around its middle (a resource spot's pieces spread about 2.8 m;
## a plot is 4 m square with its pad in front).
const ROOM := {"node": 3.0, "site": 2.8, "camp": 1.6, "chest": 1.0, "den": 1.6}
## The small furnace and its pad on each edge's midpoint need this much room.
const GATE_ROOM := 3.0
## A producer stands this far from the resource spot it works.
const PRODUCER_DISTANCE := 6.0
const TRIES := 40


## How many rings of tiles out from the starting grid a tile is: 0 on the starting grid, 1 touching it.
static func ring(tile: Vector2i) -> int:
	return maxi(maxi(absi(tile.x), absi(tile.y)) - MapData.START_RADIUS, 0)


## A tile's own random numbers, from the winter's seed.
static func tile_rng(run_seed: int, tile: Vector2i) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	# A fixed integer mix rather than hash(), so a seed means the same world in every build.
	rng.seed = (run_seed * 1000003) ^ (tile.x * 73856093) ^ (tile.y * 19349663)
	return rng


## {nodes: [{kind, pos}], sites: [{type, pos}], camp: {pos, jans} or {}, chest: {pos, kind, rarity} or {},
## den: {pos} or {}}. Positions are world metres inside the tile.
static func tile_contents(run_seed: int, tile: Vector2i) -> Dictionary:
	var rng := tile_rng(run_seed, tile)
	var rect := MapData.tile_rect(tile)
	var taken: Array = []
	# The midpoints of the tile's edges, where gates and small furnaces go.
	for edge in [Vector2(0.5, 0), Vector2(1, 0.5), Vector2(0.5, 1), Vector2(0, 0.5)]:
		taken.append({"pos": rect.position + rect.size * edge, "room": GATE_ROOM})
	var out := {"nodes": [], "sites": [], "camp": {}, "chest": {}, "den": {}}

	for i in rng.randi_range(Balance.TILE_NODES_MIN, Balance.TILE_NODES_MAX):
		var kind: String = pick(rng, Balance.TILE_NODE_WEIGHTS)
		var pos := _free_spot(rng, rect, taken, ROOM.node)
		if pos != Vector2.INF:
			out.nodes.append({"kind": kind, "pos": pos})

	# Producers stand beside the resource spot they work: forest → Lumber Yard and so on.
	var producers := rng.randi_range(0, mini(Balance.TILE_PRODUCERS_MAX, out.nodes.size()))
	for i in producers:
		var node: Dictionary = out.nodes[i]
		var pos := _spot_near(rng, rect, taken, node.pos, PRODUCER_DISTANCE, ROOM.site)
		if pos != Vector2.INF:
			out.sites.append({"type": Balance.PRODUCER_FOR[node.kind], "pos": pos})

	if rng.randf() < Balance.TILE_CAMP_CHANCE:
		var pos := _free_spot(rng, rect, taken, ROOM.camp)
		if pos != Vector2.INF:
			out.camp = {"pos": pos, "jans": rng.randi_range(Balance.TILE_CAMP_JANS_MIN, Balance.TILE_CAMP_JANS_MAX)}
	if rng.randf() < Balance.TILE_CHEST_CHANCE:
		var pos := _free_spot(rng, rect, taken, ROOM.chest)
		if pos != Vector2.INF:
			var kind: String = pick(rng, Balance.CHEST_KINDS)
			out.chest = {"pos": pos, "kind": kind, "rarity": pick(rng, Balance.CHEST_RARITIES[kind])}
	if ring(tile) >= Balance.TILE_DEN_MIN_RING and rng.randf() < Balance.TILE_DEN_CHANCE:
		var pos := _free_spot(rng, rect, taken, ROOM.den)
		if pos != Vector2.INF:
			out.den = {"pos": pos}
	return out


## A key from {key: weight}, by weight.
static func pick(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for k in weights:
		total += weights[k]
	var roll := rng.randf() * total
	for k in weights:
		roll -= weights[k]
		if roll <= 0.0:
			return k
	return weights.keys()[-1]


## A random point in the tile with `room` clear of everything already placed, or INF.
static func _free_spot(rng: RandomNumberGenerator, rect: Rect2, taken: Array, room: float) -> Vector2:
	var inner := rect.grow(-EDGE_MARGIN - room * 0.5)
	for i in TRIES:
		var p := Vector2(rng.randf_range(inner.position.x, inner.end.x), rng.randf_range(inner.position.y, inner.end.y))
		if _clear(p, room, taken):
			taken.append({"pos": p, "room": room})
			return p
	return Vector2.INF


## A point about `distance` from `near`, inside the tile and clear of everything else, or INF.
static func _spot_near(rng: RandomNumberGenerator, rect: Rect2, taken: Array, near: Vector2, distance: float, room: float) -> Vector2:
	var inner := rect.grow(-EDGE_MARGIN - room * 0.5)
	# A plot's pad is in front of it (+y), so keep that side clear of the edge too.
	inner.size.y -= 2.0
	for i in TRIES:
		var p := near + Vector2.RIGHT.rotated(rng.randf() * TAU) * distance
		if inner.has_point(p) and _clear(p, room, taken):
			taken.append({"pos": p, "room": room})
			return p
	return Vector2.INF


static func _clear(p: Vector2, room: float, taken: Array) -> bool:
	for t in taken:
		if p.distance_to(t.pos) < room + t.room:
			return false
	return true
