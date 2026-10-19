extends TestCase


func _has_event(events: Array, type: String) -> bool:
	return events.any(func(ev): return ev.type == type)


func test_gathering_fills_the_bag_and_empties_the_node() -> void:
	var e := engine()
	var forest := node_index("forest")
	put_meagan(e, MapData.RESOURCE_NODES[forest].pos)
	e.skip(1.0)
	check_near(e.state.bag.wood, 5.0, 0.01, "5 Wood per second")
	check(e.state.nodes[forest] < 60.0, "forest stock went down")
	e.skip(10.0)
	check_near(Economy.bag_total(e.state), 20.0, 0.01, "bag is full at 20")


func test_nodes_regrow() -> void:
	var e := engine()
	var scrap := node_index("scrap")
	e.state.nodes[scrap] = 0.0
	put_meagan(e, Vector2(0, 30))
	e.skip(120.0)
	check_near(e.state.nodes[scrap], 7.5, 0.05, "half regrown after half of 240 s")


func test_walking_past_the_furnace_fuels_it() -> void:
	var e := engine()
	e.state.bag.wood = 20.0
	put_meagan(e, site_pos(0) + Vector2(0, 3))
	e.skip(1.0)
	check_near(e.state.bag.wood, 0.0, 0.01, "bag emptied into the furnace")
	check(e.state.heat > 0.0, "heat rises")
	check(e.state.fuel + e.state.heat / 10.0 > 19.0, "fuel plus burned wood adds up")


func test_building_on_a_plot() -> void:
	var e := engine()
	check(e.choose_building(3, "sled_shed"), "sled shed site started")
	check(not e.choose_building(4, "sled_shed"), "only one of each")
	e.state.bag.wood = 20.0
	put_meagan(e, site_pos(3) + Vector2(0, 3))
	e.skip(1.0)
	check_near(e.state.sites[3].progress.get("wood", 0.0), 20.0, 0.01, "progress")
	check_eq(e.state.sites[3].level, 0, "not built yet")
	e.state.bag.wood = 10.0
	e.skip(1.0)
	check_eq(e.state.sites[3].level, 1, "built")
	check(_has_event(e.drain_events(), "built"), "built event")
	check_near(Economy.bag_cap(e.state), 30.0, 0.001, "bag grows")


func test_upgrading_the_furnace() -> void:
	var e := engine()
	check(e.start_upgrade(0), "upgrade started")
	e.state.heat = 0.0
	e.state.bag.wood = 20.0
	put_meagan(e, site_pos(0) + Vector2(0, 3))
	e.skip(2.0)
	check_near(e.state.fuel + e.state.heat / 10.0, 20.0, 0.2, "fuel is topped up before the upgrade")
	check_eq(e.state.sites[0].progress.get("wood", 0.0), 0.0, "no upgrade progress while the fuel is low")




func test_rescuing_a_jan() -> void:
	var e := engine()
	e.skip(5.1)
	check_eq(e.state.arrivals.size(), 1, "first Jan arrived")
	var spot: Vector2 = MapData.ARRIVAL_SPOTS[e.state.arrivals[0].spot]
	put_meagan(e, spot)
	e.skip(0.1)
	check_eq(e.state.jans.size(), 1, "thawed")
	check_eq(e.state.jans[0].job, "chop", "goes chopping")
	check(_has_event(e.drain_events(), "thawed"), "thawed event")


func test_no_room_leaves_him_frozen() -> void:
	var e := engine()
	for i in 4:
		add_jan(e, "")
	e.state.arrivals.append({"id": 99, "spot": 0})
	e.target_arrival(99)
	put_meagan(e, MapData.ARRIVAL_SPOTS[0])
	e.skip(0.1)
	check_eq(e.state.jans.size(), 4, "still 4")
	check_eq(e.state.arrivals.size(), 1, "still frozen")
	check(_has_event(e.drain_events(), "no_room"), "no room event")


func test_activity_follows_what_she_does() -> void:
	var e := engine()
	var forest := node_index("forest")
	put_meagan(e, MapData.RESOURCE_NODES[forest].pos)
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "gather", "gathering at the forest")
	check_eq(e.state.meagan_target, forest, "targets the forest")
	e.state.bag.wood = Economy.bag_cap(e.state)
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "full", "bag full")

	put_meagan(e, Vector2(20, 35))
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "", "nothing to do out in the snow")

	e.state.bag.wood = 10.0
	put_meagan(e, site_pos(0) + Vector2(0, 3))
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "fuel", "fuelling the furnace")

	e.choose_building(3, "sled_shed")
	e.state.bag.wood = 10.0
	put_meagan(e, site_pos(3) + Vector2(0, 3))
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "build", "building")
	check_eq(e.state.meagan_target, 3, "at plot 3")




func test_construction_is_paid_only_on_the_pad() -> void:
	var e := engine()
	e.choose_building(3, "sled_shed")
	e.state.bag.wood = 20.0
	put_meagan(e, site_pos(3) + Vector2(3.5, 0))
	e.skip(1.0)
	check_eq(e.state.sites[3].progress.get("wood", 0.0), 0.0, "beside the site, off the pad")
	put_meagan(e, MapData.pad_pos(3))
	e.skip(1.0)
	check_near(e.state.sites[3].progress.get("wood", 0.0), 20.0, 0.01, "on the pad")


func test_the_stockpile_takes_everything() -> void:
	var e := engine()
	e.state.bag = {"wood": 8.0, "food": 6.0, "materials": 2.0}
	put_meagan(e, MapData.stockpile_pad())
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "store", "dropping off")
	e.skip(1.0)
	check_near(Economy.bag_total(e.state), 0.0, 0.01, "bag emptied")
	check_near(e.state.piles.food, 6.0 - 0.1, 0.1, "food stored (Jans aren't eating: none yet)")
	check_near(e.state.piles.materials, 2.0, 0.01, "materials stored")


func test_the_stockpile_fills_only_to_its_cap() -> void:
	var e := engine()
	e.state.fuel = 1000.0
	e.state.piles.wood = Economy.caps(e.state).wood - 5.0
	e.state.bag.wood = 12.0
	put_meagan(e, MapData.stockpile_pad())
	e.skip(1.0)
	check_near(e.state.bag.wood, 7.0, 0.01, "the rest stays in her bag")


func test_building_pays_from_the_stockpile() -> void:
	var e := engine()
	e.choose_building(3, "sled_shed")
	e.state.fuel = 1000.0
	e.state.piles.wood = 40.0
	put_meagan(e, MapData.pad_pos(3))
	e.skip(2.0)
	check_eq(e.state.sites[3].level, 1, "built from the bank alone")
	check_near(e.state.piles.wood, 10.0, 0.5, "30 Wood taken from the Stockpile")


func test_the_furnace_feeds_from_the_stockpile() -> void:
	var e := engine()
	e.state.piles.wood = 20.0
	put_meagan(e, Vector2(0, 30))
	e.skip(2.0)
	check(e.state.heat > 0.0, "warming without Meagan")
	check_near(e.state.piles.wood, 10.0, 0.1, "5 Wood/s fed")
