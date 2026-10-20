extends TestCase


func test_new_winter_starts_empty_with_a_full_furnace() -> void:
	var e := engine()
	check_eq(e.state.heat, Economy.heat_cap(e.state), "heat")
	check_eq(e.state.jans.size(), 0, "jans")
	check_eq(Economy.furnace_level(e.state), 1, "furnace")
	check_eq(Economy.level(e.state, "lumber_yard"), 1, "lumber yard")
	check_eq(Economy.level(e.state, "hunting_lodge"), 1, "hunting lodge")
	check_eq(Economy.level(e.state, "workshop"), 0, "workshop")


func test_costs_follow_base_times_growth() -> void:
	check_eq(Economy.cost("lumber_yard", 1), {"wood": 15.0}, "lumber 1→2")
	check_eq(Economy.cost("lumber_yard", 2), {"wood": 17.0}, "lumber 2→3")
	check_eq(Economy.cost("furnace", 1), {"wood": 100.0}, "furnace 1→2 is Wood only")
	check_eq(Economy.cost("furnace", 2), {"wood": 180.0, "materials": 36.0}, "furnace 2→3")
	check_eq(Economy.cost("sled_shed", 0), {"wood": 30.0}, "sled shed build")
	check_eq(Economy.cost("workshop", 0), {"wood": 60.0, "materials": 10.0}, "workshop build")


func test_caps() -> void:
	var e := engine()
	check_eq(Economy.caps(e.state), {"wood": 300.0, "food": 150.0, "materials": 100.0}, "start")
	give_building(e, "lumber_yard", 3)
	give_building(e, "storehouse", 1)
	var caps := Economy.caps(e.state)
	check_near(caps.wood, 500.0, 0.01, "wood")
	check_near(caps.food, 187.5, 0.01, "food")


func test_jan_cap() -> void:
	var e := engine()
	check_eq(Economy.jan_cap(e.state), 4, "furnace 1")
	give_building(e, "bunkhouse", 2)
	e.state.sites[0].level = 2
	check_eq(Economy.jan_cap(e.state), 12, "furnace 2 + bunkhouse 2")


func test_heat_drain() -> void:
	var e := engine()
	add_jan(e, "chop")
	add_jan(e, "")
	check_near(Economy.heat_drain(e.state), 0.5 + 0.2 + 0.1, 0.0001, "two Jans, two building levels")
	e.state.blizzard_active = true
	check_near(Economy.heat_drain(e.state), 0.8 * 3.0, 0.0001, "blizzard")


func test_arrival_interval_slows_as_the_city_fills() -> void:
	var e := engine()
	check_near(Economy.arrival_interval(e.state), 60.0, 0.001, "empty")
	for i in 4:
		add_jan(e, "")
	check_near(Economy.arrival_interval(e.state), 180.0, 0.001, "at cap")


func test_cold_and_hunger_slow_jobs() -> void:
	var e := engine()
	add_jan(e, "chop")
	e.state.heat = 100.0
	check_near(Economy.job_rate(e.state, "chop"), 1.0, 0.0001, "warm")
	e.state.heat = 10.0
	check_near(Economy.job_rate(e.state, "chop"), 0.5, 0.0001, "cold")
	e.state.hungry = true
	check_near(Economy.job_rate(e.state, "chop"), 0.375, 0.0001, "cold and hungry")


func test_neediest_job() -> void:
	var e := engine()
	check_eq(Economy.neediest_job(e.state), "chop", "first Jan chops")
	add_jan(e, "chop")
	check_eq(Economy.neediest_job(e.state), "hunt", "then hunting while eating outruns it")
	add_jan(e, "hunt")
	add_jan(e, "chop")
	add_jan(e, "chop")
	check_eq(Economy.neediest_job(e.state), "hunt", "by share")
	check_eq(Economy.buildable(e.state).has("workshop"), true, "workshop is a buildable type")
	check_eq(Economy.is_unlocked(e.state, "workshop"), false, "but locked until Furnace Lv 2")


func test_a_kitchen_cuts_what_jans_eat() -> void:
	var e := engine()
	for i in 6:
		add_jan(e, "")
	var plain := Economy.food_eaten_per_second(e.state)
	check_near(plain, 6.0 / 60.0, 0.0001, "6 Jans eat 6 Food a minute")
	give_building(e, "kitchen", 1)
	check_near(Economy.food_eaten_per_second(e.state), plain * 0.95, 0.0001, "Lv 1: 5% less")
	give_building(e, "kitchen", 10)
	check_near(Economy.food_eaten_per_second(e.state), plain * 0.5, 0.0001, "Lv 10: half")


func test_the_kitchen_unlocks_at_furnace_2() -> void:
	var e := engine()
	check(Economy.buildable(e.state).has("kitchen"), "on the build list")
	check(not Economy.is_unlocked(e.state, "kitchen"), "locked at Furnace Lv 1")
	e.state.sites[0].level = 2
	check(Economy.is_unlocked(e.state, "kitchen"), "open at Furnace Lv 2")
	check_eq(Economy.cost("kitchen", 0), {"wood": 40.0, "materials": 5.0}, "first cost")
	check_eq(Economy.cost("kitchen", 1), {"wood": 46.0, "materials": 6.0}, "second cost, ×1.15 rounded up")


func test_a_kitchen_slows_the_stores_running_down() -> void:
	var a := engine()
	var b := engine()
	for e in [a, b]:
		for i in 8:
			add_jan(e, "")
		e.state.piles.food = 100.0
		e.state.fuel = 10000.0
		put_meagan(e, Vector2(20, 35))
	give_building(b, "kitchen", 4)
	a.skip(60.0)
	b.skip(60.0)
	check(b.state.piles.food > a.state.piles.food + 1.0, "more Food left with a Kitchen (%.1f vs %.1f)" % [b.state.piles.food, a.state.piles.food])
