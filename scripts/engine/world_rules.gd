class_name WorldRules
extends RefCounted
## The growing world (agreed 2026-10-20): which tiles are open, the gates on their border, and
## opening a tile, which lights a small furnace there and adds the tile's contents.


static func key(tile: Vector2i) -> String:
	return "%d,%d" % [tile.x, tile.y]


static func is_open(s: GameState, tile: Vector2i) -> bool:
	return s.tiles.has(key(tile))


## Whether a point is on open ground.
static func is_open_at(s: GameState, pos: Vector2) -> bool:
	return is_open(s, MapData.tile_of(pos))


## The starting grid's tiles open, and gates round them.
static func start(s: GameState, run_seed: int) -> void:
	s.run_seed = run_seed
	for x in range(-MapData.START_RADIUS, MapData.START_RADIUS + 1):
		for y in range(-MapData.START_RADIUS, MapData.START_RADIUS + 1):
			s.tiles[key(Vector2i(x, y))] = true
	s.bounds = MapData.start_bounds()
	refresh_gates(s)
	refresh_edges(s)


## What opening a tile costs. [proto] Wood 40 × 1.6^(d − 1), Materials 10 × 1.6^(d − 2) from d = 2.
static func gate_cost(tile: Vector2i) -> Dictionary:
	var d := WorldGen.ring(tile)
	var out := {"wood": ceilf(Balance.GATE_WOOD * pow(Balance.GATE_GROWTH, d - 1))}
	if d >= 2:
		out["materials"] = ceilf(Balance.GATE_MATERIALS * pow(Balance.GATE_GROWTH, d - 2))
	return out


## Gives every closed tile next to an open one a gate, on the border it shares with the open
## neighbour nearest the furnace. Gates already there stay as they are.
static func refresh_gates(s: GameState) -> void:
	var gated := {}
	for g in s.gates:
		gated[key(g.tile)] = true
	var open_tiles := s.tiles.keys().map(func(k): return tile_from_key(k))
	open_tiles.sort_custom(func(a, b): return _order(a) < _order(b))
	for from in open_tiles:
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var tile: Vector2i = from + dir
			if is_open(s, tile) or gated.has(key(tile)):
				continue
			gated[key(tile)] = true
			var border := (MapData.tile_rect(from).get_center() + MapData.tile_rect(tile).get_center()) / 2.0
			s.gates.append({
				"tile": tile, "pos": border, "pad": border - Vector2(dir) * Balance.GATE_PAD_INSET,
				"cost": gate_cost(tile), "progress": {}, "paying": false,
			})


## Opens the gate's tile once it's fully paid: lights its small furnace and adds what it holds.
static func open_tile(s: GameState, gate_index: int, events: Array) -> void:
	var gate: Dictionary = s.gates[gate_index]
	var tile: Vector2i = gate.tile
	s.gates.remove_at(gate_index)
	s.tiles[key(tile)] = true
	s.bounds = s.bounds.merge(MapData.tile_rect(tile))
	s.stoves.append({"tile": tile, "pos": gate.pos})
	var c := WorldGen.tile_contents(s.run_seed, tile)
	# A small stockpile beside it, another door into the town's store. [agreed 2026-10-20]
	s.stockpiles.append({"pos": stockpile_spot(tile, gate.pos, c), "tile": tile})
	var first_site := s.sites.size()
	var first_node := s.node_defs.size()
	var first_chest := s.chests.size()
	var first_den := s.dens.size()
	for node in c.nodes:
		s.node_defs.append({"kind": node.kind, "pos": node.pos, "tile": tile})
		s.nodes.append(Balance.NODES[node.kind].stock)
	for site in c.sites:
		s.sites.append({"type": site.type, "pos": site.pos, "tile": tile, "building": "", "level": 0, "upgrading": false, "progress": {}})
	if not c.camp.is_empty():
		s.camps.append({"pos": c.camp.pos, "jans": c.camp.jans, "tile": tile})
		# A camp of frozen Jans, waiting to be thawed like any arrival.
		for k in c.camp.jans:
			var at: Vector2 = c.camp.pos + Vector2.RIGHT.rotated(TAU * k / c.camp.jans + 0.4) * (Balance.CAMP_SPREAD if c.camp.jans > 1 else 0.0)
			s.arrivals.append({"id": s.new_id(), "spot": -1, "pos": at, "camp": true})
		events.append({"type": "camp_found", "pos": c.camp.pos, "count": c.camp.jans})
	if not c.chest.is_empty():
		s.chests.append({"pos": c.chest.pos, "kind": c.chest.kind, "rarity": c.chest.rarity, "tile": tile, "opened": false})
	if not c.den.is_empty():
		s.dens.append({"pos": c.den.pos, "tile": tile})
	refresh_gates(s)
	refresh_edges(s)
	events.append({
		"type": "tile_opened", "tile": tile, "pos": gate.pos,
		"sites": range(first_site, s.sites.size()), "nodes": range(first_node, s.node_defs.size()),
		"chests": range(first_chest, s.chests.size()), "dens": range(first_den, s.dens.size()),
		"stockpile": s.stockpiles.size() - 1,
	})


## Where a newly opened tile's small stockpile stands: a little way into the tile from its small
## furnace on the border, to one side of its pad, at whichever of a few spots leaves the most room
## round what the tile holds (the tile's layout is seeded and doesn't know where she'll come in).
## [proto, agreed 2026-10-20]
static func stockpile_spot(tile: Vector2i, stove_pos: Vector2, c: Dictionary) -> Vector2:
	var into := (MapData.tile_rect(tile).get_center() - stove_pos).normalized()
	var side := into.rotated(PI / 2.0)
	var things := []  # [pos, room it needs]
	for node in c.nodes:
		things.append([node.pos, STOCKPILE_ROOM.node])
	for site in c.sites:
		things.append([site.pos, STOCKPILE_ROOM.site])
	for key in ["camp", "chest", "den"]:
		if not c[key].is_empty():
			things.append([c[key].pos, STOCKPILE_ROOM.thing])
	var best := Vector2.ZERO
	var best_room := -INF
	for inset in Balance.STOCKPILE_STOVE_INSETS:
		for aside in Balance.STOCKPILE_STOVE_SIDES:
			for sign in [1.0, -1.0]:
				var p: Vector2 = stove_pos + into * inset + side * aside * sign
				var room := INF
				for t in things:
					room = minf(room, p.distance_to(t[0]) - t[1])
				if room > best_room + 0.001:
					best_room = room
					best = p
	return best


## How far a small stockpile keeps from what a tile holds, by kind.
const STOCKPILE_ROOM := {"node": 3.5, "site": 4.0, "thing": 2.5}


## Where single frozen Jans wait and wolf packs come in from: along every edge between open and
## closed ground, to either side of its gate, plus the wolf dens in opened tiles. [agreed 2026-10-20]
static func refresh_edges(s: GameState) -> void:
	var spots := []
	var spawns := []
	var open_tiles := s.tiles.keys().map(func(k): return tile_from_key(k))
	open_tiles.sort_custom(func(a, b): return _order(a) < _order(b))
	for from in open_tiles:
		for dir in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			if is_open(s, from + dir):
				continue
			var border := (MapData.tile_rect(from).get_center() + MapData.tile_rect(from + dir).get_center()) / 2.0
			var d := Vector2(dir)
			var side := Vector2(-d.y, d.x)
			spots.append(border - d * Balance.ARRIVAL_INSET + side * Balance.ARRIVAL_SIDE)
			spawns.append(border - side * Balance.WOLF_SPAWN_SIDE)
	for den in s.dens:
		spawns.append(den.pos)
	s.arrival_spots = spots
	s.wolf_spawns = spawns


static func tile_from_key(k: String) -> Vector2i:
	var parts := k.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


## Sort order for open tiles: nearest the furnace first, then by position, so gates land the same
## way every time.
static func _order(t: Vector2i) -> int:
	return (absi(t.x) + absi(t.y)) * 10000 + (t.y + 50) * 100 + (t.x + 50)
