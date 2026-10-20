extends TestCase
## The growing world (agreed 2026-10-20): seeded tiles, gates and small furnaces.


func _gate_to(e: GameEngine, tile: Vector2i) -> int:
	for i in e.state.gates.size():
		if e.state.gates[i].tile == tile:
			return i
	return -1


## Pays a gate in full from the Stockpile while she stands on its pad.
func _open(e: GameEngine, tile: Vector2i) -> void:
	var i := _gate_to(e, tile)
	e.start_gate(i)
	var gate: Dictionary = e.state.gates[i]
	e.state.fuel = 1000.0
	e.state.piles = {"wood": 300.0, "food": 0.0, "materials": 100.0}
	put_meagan(e, gate.pad)
	e.skip(10.0)


func test_a_winter_starts_on_the_3_by_3_grid_with_gates_round_it() -> void:
	var e := engine()
	check_eq(e.state.tiles.size(), 9, "nine open tiles")
	check_eq(e.state.gates.size(), 12, "a gate on every closed tile touching the grid")
	check(e.state.stoves.is_empty(), "no small furnaces yet")
	check_eq(e.state.bounds, Rect2(-30, -30, 60, 60), "the starting grid's ground")


func test_tiles_come_out_the_same_whatever_the_order() -> void:
	for tile in [Vector2i(2, 0), Vector2i(-2, 1), Vector2i(0, -3), Vector2i(4, 4)]:
		check_eq(WorldGen.tile_contents(77, tile), WorldGen.tile_contents(77, tile), "same seed, same tile")
	var a := engine()
	var b := engine()
	check_eq(a.state.run_seed, b.state.run_seed, "the same engine seed gives the same world")
	_open(a, Vector2i(2, 0))
	_open(a, Vector2i(0, 2))
	_open(b, Vector2i(0, 2))
	_open(b, Vector2i(2, 0))
	var where := func(e: GameEngine, tile: Vector2i) -> Array:
		return e.state.node_defs.filter(func(n): return n.has("tile") and n.tile == tile).map(func(n): return [n.kind, n.pos])
	check_eq(where.call(a, Vector2i(2, 0)), where.call(b, Vector2i(2, 0)), "east tile's spots")
	check_eq(where.call(a, Vector2i(0, 2)), where.call(b, Vector2i(0, 2)), "south tile's spots")


func test_a_new_seed_makes_a_new_world() -> void:
	var differ := false
	for x in range(2, 5):
		if WorldGen.tile_contents(1, Vector2i(x, 0)) != WorldGen.tile_contents(2, Vector2i(x, 0)):
			differ = true
	check(differ, "different seeds, different tiles")


func test_generated_tiles_hold_producers_beside_their_spots() -> void:
	for x in range(-4, 5):
		for y in range(-4, 5):
			var tile := Vector2i(x, y)
			if WorldGen.ring(tile) == 0:
				continue
			var c := WorldGen.tile_contents(9, tile)
			var rect := MapData.tile_rect(tile)
			for n in c.nodes:
				check(rect.has_point(n.pos), "spot inside its tile")
			for site in c.sites:
				check(rect.has_point(site.pos), "plot inside its tile")
				check(site.type in ["lumber_yard", "hunting_lodge", "workshop"], "only producers in new tiles")
				var kind := ""
				for k in Balance.PRODUCER_FOR:
					if Balance.PRODUCER_FOR[k] == site.type:
						kind = k
				check(c.nodes.any(func(n): return n.kind == kind), "%s has a %s to work" % [site.type, kind])
			if WorldGen.ring(tile) < Balance.TILE_DEN_MIN_RING:
				check(c.den.is_empty(), "no wolf dens close in")


func test_gate_costs_grow_with_distance() -> void:
	check_eq(WorldRules.gate_cost(Vector2i(2, 0)), {"wood": 40.0}, "first ring: Wood only")
	check_eq(WorldRules.gate_cost(Vector2i(0, -3)), {"wood": 64.0, "materials": 10.0}, "second ring adds Materials")
	check_eq(WorldRules.gate_cost(Vector2i(4, 1)), {"wood": 103.0, "materials": 16.0}, "third ring")


func test_a_gate_only_takes_payment_once_chosen_and_on_its_pad() -> void:
	var e := engine()
	var i := _gate_to(e, Vector2i(2, 0))
	var gate: Dictionary = e.state.gates[i]
	e.state.fuel = 1000.0
	e.state.bag.wood = 20.0
	put_meagan(e, gate.pad)
	e.skip(1.0)
	check_eq(gate.progress.get("wood", 0.0), 0.0, "not chosen: nothing paid")
	e.start_gate(i)
	put_meagan(e, gate.pad + Vector2(-3, 0))
	e.skip(1.0)
	check_eq(gate.progress.get("wood", 0.0), 0.0, "off the pad: nothing paid")
	put_meagan(e, gate.pad)
	e.skip(1.0)
	check_near(gate.progress.get("wood", 0.0), 20.0, 0.01, "on the pad: her bag pays")


func test_opening_a_tile_lights_a_small_furnace_that_adds_to_the_drain() -> void:
	var e := engine()
	var drain := Economy.heat_drain(e.state)
	var sites := e.state.sites.size()
	_open(e, Vector2i(2, 0))
	check(WorldRules.is_open(e.state, Vector2i(2, 0)), "the tile is open")
	check_eq(e.state.stoves.size(), 1, "a small furnace")
	check_eq(e.state.stoves[0].pos, Vector2(30, 0), "on the border it was opened from")
	check_near(Economy.heat_drain(e.state), drain + Balance.STOVE_DRAIN, 0.0001, "+0.15 heat/s")
	check_eq(e.state.bounds, Rect2(-30, -30, 80, 60), "the ground grows")
	check_eq(_gate_to(e, Vector2i(2, 0)), -1, "its gate is gone")
	for t in [Vector2i(3, 0), Vector2i(2, -1), Vector2i(2, 1)]:
		check(_gate_to(e, t) >= 0, "new gates beyond it")
	var c := WorldGen.tile_contents(e.state.run_seed, Vector2i(2, 0))
	check_eq(e.state.sites.size(), sites + c.sites.size(), "its plots are added")
	var events := e.drain_events()
	check(events.any(func(ev): return ev.type == "tile_opened"), "tile_opened event")


func test_new_producer_plots_can_be_built() -> void:
	var e := engine()
	for x in range(2, 8):
		if e.state.sites.size() > MapData.START_SITES.size():
			break
		_open(e, Vector2i(x, 0))
	var i := e.state.sites.size() - 1
	check(i >= MapData.START_SITES.size(), "an opened tile had a producer plot")
	e.state.sites[0].level = 2
	check(e.start_construction(i), "its producer can be built")
	check_eq(Economy.site_cost(e.state, i), Economy.cost(e.state.sites[i].type, 1), "costs like the first one's next level")


func test_the_world_survives_a_save() -> void:
	var e := engine()
	_open(e, Vector2i(-2, 0))
	var loaded := GameEngine.from_json(e.to_json())
	check(loaded != null, "loads")
	check_eq(loaded.state.tiles.size(), 10, "open tiles kept")
	check_eq(loaded.state.stoves.size(), 1, "small furnace kept")
	check_eq(loaded.state.run_seed, e.state.run_seed, "seed kept")
	check_eq(loaded.state.gates.size(), e.state.gates.size(), "gates kept")
	check_eq(loaded.state.bounds, e.state.bounds, "ground kept")
