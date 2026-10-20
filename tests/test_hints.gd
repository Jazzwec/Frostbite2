extends TestCase
## The first-minute hints: when each counts as done, and where its arrow points.


func test_moving_counts_after_a_couple_of_metres() -> void:
	var e := engine()
	var start: Vector2 = e.state.meagan_pos
	check(not HintRules.is_done("move", e.state, start), "not yet")
	put_meagan(e, start + Vector2(0.5, 0))
	check(not HintRules.is_done("move", e.state, start), "half a metre isn't enough")
	put_meagan(e, start + Vector2(3, 0))
	check(HintRules.is_done("move", e.state, start), "three metres is")


func test_chopping_then_fuelling() -> void:
	var e := engine()
	var start: Vector2 = e.state.meagan_pos
	var forest := node_index("forest")
	put_meagan(e, MapData.START_NODES[forest].pos)
	e.skip(1.0)
	check(HintRules.is_done("chop", e.state, start), "Wood in the bag")
	check(not HintRules.is_done("fuel", e.state, start), "not at the furnace yet")
	put_meagan(e, site_pos(0) + Vector2(0, 3))
	e.skip(0.1)
	check(HintRules.is_done("fuel", e.state, start), "feeding the furnace")


func test_thawing_and_storing() -> void:
	var e := engine()
	var start: Vector2 = e.state.meagan_pos
	check(not HintRules.is_done("thaw", e.state, start), "nobody rescued yet")
	e.state.rescued_total = 1
	check(HintRules.is_done("thaw", e.state, start), "after a rescue")
	e.state.bag.food = 5.0
	put_meagan(e, MapData.stockpile_pad())
	e.skip(0.1)
	check(HintRules.is_done("store", e.state, start), "dropping off at the Stockpile")


func test_arrows_point_at_the_nearest_place() -> void:
	var e := engine()
	put_meagan(e, Vector2(-15, -20))
	check_eq(HintRules.target("chop", e.state), Vector2(-18, -16), "the nearest forest")
	check_eq(HintRules.target("fuel", e.state), site_pos(0), "the furnace")
	check_eq(HintRules.target("move", e.state), Vector2.INF, "moving has no target")
	check_eq(HintRules.target("thaw", e.state), Vector2.INF, "no frozen Jan yet")
	e.state.arrivals.append({"id": 99, "spot": 1, "pos": e.state.arrival_spots[1]})
	check_eq(HintRules.target("thaw", e.state), e.state.arrival_spots[1], "the frozen Jan")
