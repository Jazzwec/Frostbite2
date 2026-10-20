extends TestCase
## Engine rules that had no tests yet: the blizzard cycle, attacks held off by a blizzard, guards
## going back to their posts, Storehouse caps, wolf strength, unlocks and the fire's countdown.


func _has_event(events: Array, type: String) -> bool:
	return events.any(func(ev): return ev.type == type)


## A quiet winter: Meagan out of the way, the fire stocked, nobody arriving.
func _quiet(e: GameEngine) -> void:
	put_meagan(e, Vector2(20, 35))
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 100000.0
	e.state.piles.food = 1000.0
	e.state.arrivals.clear()
	e.state.next_arrival_in = 99999.0


func test_the_next_blizzard_comes_20_to_40_minutes_after_the_last() -> void:
	var e := engine()
	_quiet(e)
	e.state.blizzard_at = 30.0
	e.skip(30.1 + Balance.BLIZZARD_DURATION + 0.2)
	check(not e.state.blizzard_active, "the first one is over")
	var gap := e.state.blizzard_at - e.state.time
	check(gap >= Balance.BLIZZARD_GAP_MIN - 1.0 and gap <= Balance.BLIZZARD_GAP_MAX, "next one in %.0f s" % gap)
	check(not e.state.blizzard_warned, "the warning re-arms")
	e.drain_events()
	e.skip(gap - Balance.BLIZZARD_WARNING + 0.2)
	check(_has_event(e.drain_events(), "blizzard_warning"), "the second one is warned too")


func test_a_blizzard_triples_the_drain() -> void:
	var e := engine()
	var calm := Economy.heat_drain(e.state)
	e.state.blizzard_active = true
	check_near(Economy.heat_drain(e.state), calm * Balance.BLIZZARD_DRAIN_MULT, 0.0001, "drain in a blizzard")


func test_an_attack_due_in_a_blizzard_waits_until_after_it() -> void:
	var e := engine()
	_quiet(e)
	e.state.blizzard_at = 1.0
	e.state.attack_at = 5.0
	e.skip(6.0)
	check(e.state.blizzard_active, "blizzard on")
	check(e.state.wolves.is_empty(), "no wolves in the blizzard")
	check_near(e.state.attack_at, e.state.blizzard_ends_at + 30.0, 0.01, "attack pushed to after it")


func test_guards_go_back_to_their_posts_after_an_attack() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "barracks", 1)
	for i in 2:
		add_jan(e, "guard")
	for jan in e.state.jans:
		jan.pos = Vector2(15, 15)
	e.skip(10.0)
	var guards := e.state.jans.filter(func(j): return j.job == "guard")
	for i in guards.size():
		var post := Combat.guard_post(i, guards.size())
		check(guards[i].pos.distance_to(post) < 0.1, "guard %d is back at his post" % i)
		check_near(post.distance_to(site_pos(0)), Balance.GUARD_RING_RADIUS, 0.01, "posts ring the furnace")


func test_a_level_2_storehouse_raises_every_cap() -> void:
	var e := engine()
	give_building(e, "storehouse", 2)
	var caps := Economy.caps(e.state)
	var grow := Balance.STOREHOUSE_CAP_GROWTH * Balance.STOREHOUSE_CAP_GROWTH
	check_near(caps.wood, Balance.CAP_WOOD * grow, 0.01, "wood")
	check_near(caps.food, Balance.CAP_FOOD * grow, 0.01, "food")
	check_near(caps.materials, Balance.CAP_MATERIALS * grow, 0.01, "materials")


func test_waves_grow_and_come_closer_together() -> void:
	check_eq(Combat.wave_budget(1), 10.0, "wave 1's budget")
	for n in range(1, 20):
		check(Combat.wave_budget(n + 1) > Combat.wave_budget(n), "wave %d's budget grows" % (n + 1))
		check(Combat.wave_gap(n + 1) <= Combat.wave_gap(n), "and it comes sooner")
	check_near(Combat.wave_gap(40), Balance.WAVE_GAP_MIN, 0.001, "never closer than the minimum")


func test_buildings_unlock_with_the_furnace_and_stop_at_their_max() -> void:
	var e := engine()
	for b in Balance.BUILDINGS:
		var unlock: int = Balance.BUILDINGS[b].unlock
		e.state.sites[0].level = maxi(unlock - 1, 1)
		if unlock > 1:
			check(not Economy.is_unlocked(e.state, b), "%s locked below Furnace Lv %d" % [b, unlock])
		e.state.sites[0].level = unlock
		check(Economy.is_unlocked(e.state, b), "%s unlocked at Furnace Lv %d" % [b, unlock])
	var i := give_building(e, "kitchen", Balance.BUILDINGS.kitchen.max)
	check(Economy.is_maxed(e.state, i), "a Kitchen at its max level")
	e.state.sites[i].level -= 1
	check(not Economy.is_maxed(e.state, i), "one below it")


func test_the_fire_counts_down_only_without_fuel() -> void:
	var e := engine()
	e.state.fuel = 5.0
	check_eq(Economy.seconds_until_cold(e.state), INF, "fuel to burn")
	e.state.fuel = 0.0
	e.state.heat = 60.0
	check_near(Economy.seconds_until_cold(e.state), 60.0 / Economy.heat_drain(e.state), 0.001, "heat ÷ drain")


func test_every_plot_holds_its_own_building() -> void:
	var e := engine()
	var types := MapData.START_SITES.map(func(d): return d.type)
	check(not types.has("sled_shed"), "no Sled Shed for now")
	for b in ["storehouse", "kitchen", "barracks", "bunkhouse", "watchtower", "hot_springs"]:
		check_eq(types.count(b), 1, "one %s plot on the starting grid" % b)
	check(not types.has("workshop"), "producers only in opened tiles")
	var kitchen: int = types.find("kitchen")
	check(not e.start_construction(kitchen), "the Kitchen waits for Furnace Lv 2")
	e.state.sites[0].level = 2
	check(e.start_construction(kitchen), "then it can start")
	check_eq(e.state.sites[kitchen].building, "kitchen", "and it's a Kitchen")
	check(not e.start_construction(0), "the furnace is never a construction site")


func test_a_watchtower_warns_of_blizzards_a_minute_sooner_per_level() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "watchtower", 3)
	check_near(Economy.blizzard_warning(e.state), Balance.BLIZZARD_WARNING + 180.0, 0.01, "3 + 3 minutes")
	e.state.blizzard_at = 400.0
	e.skip(400.0 - 360.0 + 0.2)
	check(e.state.blizzard_warned, "warned 6 minutes ahead")
	check(not e.state.blizzard_active, "not here yet")


func test_hot_springs_cut_the_drain_10_percent_a_level() -> void:
	var e := engine()
	for i in 5:
		add_jan(e, "")
	var plain := Economy.heat_drain(e.state)
	var i := give_building(e, "hot_springs", 1)
	# The Hot Springs are a building level themselves, which adds a little drain first.
	var base := plain + Balance.DRAIN_PER_BUILDING_LEVEL
	check_near(Economy.heat_drain(e.state), base * 0.9, 0.0001, "Lv 1: 10% less")
	e.state.sites[i].level = 5
	base = plain + Balance.DRAIN_PER_BUILDING_LEVEL * 5
	check_near(Economy.heat_drain(e.state), base * 0.5, 0.0001, "Lv 5: half")
	e.state.blizzard_active = true
	check_near(Economy.heat_drain(e.state), base * Balance.BLIZZARD_DRAIN_MULT * 0.5, 0.0001, "and in a blizzard")


func test_hot_springs_unlock_at_furnace_7() -> void:
	var e := engine()
	e.state.sites[0].level = 6
	check(not Economy.is_unlocked(e.state, "hot_springs"), "locked at Furnace Lv 6")
	e.state.sites[0].level = 7
	check(Economy.is_unlocked(e.state, "hot_springs"), "open at Furnace Lv 7")
	check(MapData.START_SITES.any(func(d): return d.type == "hot_springs"), "the starting grid has a Hot Springs plot")
	check_eq(Balance.BUILDINGS.hot_springs.max, 5, "five levels")
