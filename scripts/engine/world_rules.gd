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
	var first_site := s.sites.size()
	var first_node := s.node_defs.size()
	var c := WorldGen.tile_contents(s.run_seed, tile)
	for node in c.nodes:
		s.node_defs.append({"kind": node.kind, "pos": node.pos, "tile": tile})
		s.nodes.append(Balance.NODES[node.kind].stock)
	for site in c.sites:
		s.sites.append({"type": site.type, "pos": site.pos, "tile": tile, "building": "", "level": 0, "upgrading": false, "progress": {}})
	if not c.camp.is_empty():
		s.camps.append({"pos": c.camp.pos, "jans": c.camp.jans, "tile": tile})
	if not c.chest.is_empty():
		s.chests.append({"pos": c.chest.pos, "kind": c.chest.kind, "rarity": c.chest.rarity, "tile": tile, "opened": false})
	if not c.den.is_empty():
		s.dens.append({"pos": c.den.pos, "tile": tile})
	refresh_gates(s)
	events.append({
		"type": "tile_opened", "tile": tile, "pos": gate.pos,
		"sites": range(first_site, s.sites.size()), "nodes": range(first_node, s.node_defs.size()),
	})


static func tile_from_key(k: String) -> Vector2i:
	var parts := k.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


## Sort order for open tiles: nearest the furnace first, then by position, so gates land the same
## way every time.
static func _order(t: Vector2i) -> int:
	return (absi(t.x) + absi(t.y)) * 10000 + (t.y + 50) * 100 + (t.x + 50)
