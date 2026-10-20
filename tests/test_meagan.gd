extends TestCase


func _has_event(events: Array, type: String) -> bool:
	return events.any(func(ev): return ev.type == type)


func test_gathering_goes_straight_into_the_stockpile() -> void:
	var e := engine()
	e.state.fuel = 1000.0
	var forest := node_index("forest")
	put_meagan(e, MapData.START_NODES[forest].pos)
	e.skip(1.0)
	check_near(e.state.piles.wood, 5.0, 0.01, "5 Wood per second, into the Stockpile")
	check_near(e.state.gathered.wood, 5.0, 0.01, "counted as gathered")
	check_near(e.state.nodes[forest], 55.0, 0.5, "forest stock went down (it regrows a little meanwhile)")


func test_gathering_stops_when_the_stockpile_is_full() -> void:
	var e := engine()
	e.state.fuel = 1000.0
	var forest := node_index("forest")
	e.state.piles.wood = Economy.caps(e.state).wood - 2.0
	put_meagan(e, MapData.START_NODES[forest].pos)
	e.skip(1.0)
	check_near(e.state.piles.wood, Economy.caps(e.state).wood, 0.01, "filled to the cap")
	check_near(e.state.nodes[forest], 58.0, 0.5, "only what fitted was taken")
	check_eq(e.state.meagan_activity, "full", "she shrugs")


func test_nodes_regrow() -> void:
	var e := engine()
	var scrap := node_index("scrap")
	e.state.nodes[scrap] = 0.0
	put_meagan(e, Vector2(0, 30))
	e.skip(120.0)
	check_near(e.state.nodes[scrap], 7.5, 0.05, "half regrown after half of 240 s")


func test_building_on_a_plot() -> void:
	var e := engine()
	check(e.start_construction(3), "storehouse site started")
	check_eq(e.state.sites[3].building, "storehouse", "the plot's own building")
	check(not e.start_construction(3), "already started")
	e.state.fuel = 1000.0
	e.state.piles.wood = 20.0
	put_meagan(e, site_pos(3) + Vector2(0, 3))
	e.skip(1.0)
	check_near(e.state.sites[3].progress.get("wood", 0.0), 20.0, 0.01, "progress")
	check_eq(e.state.sites[3].level, 0, "not built yet")
	var cap: float = Economy.caps(e.state).wood
	e.state.piles.wood = 20.0
	e.state.piles.materials = 5.0
	e.skip(2.0)
	check_eq(e.state.sites[3].level, 1, "built")
	check(_has_event(e.drain_events(), "built"), "built event")
	check_near(Economy.caps(e.state).wood, cap * 1.25, 0.001, "the Stockpile holds more")


func test_upgrading_the_furnace() -> void:
	var e := engine()
	check(e.start_upgrade(0), "upgrade started")
	e.state.fuel = 1000.0
	e.state.piles.wood = 40.0
	put_meagan(e, MapData.pad_pos(e.state, 0))
	e.skip(1.0)
	check_near(e.state.sites[0].progress.get("wood", 0.0), 20.0, 0.01, "the pad takes 20 Wood a second")
	check_near(e.state.piles.wood, 20.0, 0.01, "from the Stockpile")




func test_rescuing_a_jan() -> void:
	var e := engine()
	e.skip(5.1)
	check_eq(e.state.arrivals.size(), 1, "first Jan arrived")
	var spot: Vector2 = e.state.arrivals[0].pos
	put_meagan(e, spot)
	e.skip(0.1)
	check_eq(e.state.jans.size(), 1, "thawed")
	check_eq(e.state.jans[0].job, "chop", "goes chopping")
	check(_has_event(e.drain_events(), "thawed"), "thawed event")


func test_no_room_leaves_him_frozen() -> void:
	var e := engine()
	for i in 4:
		add_jan(e, "")
	e.state.arrivals.append({"id": 99, "spot": 0, "pos": e.state.arrival_spots[0]})
	e.target_arrival(99)
	put_meagan(e, e.state.arrival_spots[0])
	e.skip(0.1)
	check_eq(e.state.jans.size(), 4, "still 4")
	check_eq(e.state.arrivals.size(), 1, "still frozen")
	check(_has_event(e.drain_events(), "no_room"), "no room event")


func test_activity_follows_what_she_does() -> void:
	var e := engine()
	var forest := node_index("forest")
	put_meagan(e, MapData.START_NODES[forest].pos)
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "gather", "gathering at the forest")
	check_eq(e.state.meagan_target, forest, "targets the forest")
	e.state.fuel = 1000.0
	e.state.piles.wood = Economy.caps(e.state).wood
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "full", "Stockpile full")

	put_meagan(e, Vector2(20, 35))
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "", "nothing to do out in the snow")

	e.start_construction(3)
	put_meagan(e, site_pos(3) + Vector2(0, 3))
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "build", "building")
	check_eq(e.state.meagan_target, 3, "at plot 3")




func test_construction_is_paid_only_on_the_pad() -> void:
	var e := engine()
	e.start_construction(3)
	e.state.fuel = 1000.0
	e.state.piles.wood = 20.0
	put_meagan(e, site_pos(3) + Vector2(3.5, 0))
	e.skip(1.0)
	check_eq(e.state.sites[3].progress.get("wood", 0.0), 0.0, "beside the site, off the pad")
	put_meagan(e, MapData.pad_pos(e.state, 3))
	e.skip(1.0)
	check_near(e.state.sites[3].progress.get("wood", 0.0), 20.0, 0.01, "on the pad")


func test_building_pays_from_the_stockpile() -> void:
	var e := engine()
	e.start_construction(3)
	e.state.fuel = 1000.0
	e.state.piles.wood = 50.0
	e.state.piles.materials = 5.0
	put_meagan(e, MapData.pad_pos(e.state, 3))
	e.skip(3.0)
	check_eq(e.state.sites[3].level, 1, "built from the bank alone")
	check_near(e.state.piles.wood, 10.0, 0.5, "40 Wood taken from the Stockpile")


func test_the_furnace_feeds_from_the_stockpile() -> void:
	var e := engine()
	e.state.piles.wood = 20.0
	put_meagan(e, Vector2(0, 30))
	e.skip(2.0)
	check(e.state.heat > 0.0, "warming without Meagan")
	check_near(e.state.piles.wood, 10.0, 0.1, "5 Wood/s fed")
