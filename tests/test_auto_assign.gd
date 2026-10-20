extends TestCase
## Auto-assign: unlocking, rebalancing with few moves, guards left alone, and hand moves turning it off.


func _city(e: GameEngine) -> void:
	put_meagan(e, Vector2(20, 35))
	e.state.fuel = 100000.0
	e.state.piles.food = 1000.0
	e.state.arrivals.clear()
	e.state.next_arrival_in = 99999.0
	e.state.sites[0].level = Balance.AUTO_ASSIGN_FURNACE_LEVEL
	e.state.heat = Economy.heat_cap(e.state)
	give_building(e, "workshop", 1)
	give_building(e, "barracks", 1)


func test_it_unlocks_at_furnace_4() -> void:
	var e := engine()
	check(not e.set_auto_assign(true), "not at Furnace Lv 1")
	check(not e.state.auto_assign, "still off")
	e.state.sites[0].level = 4
	check(e.set_auto_assign(true), "at Furnace Lv 4")
	check(e.state.auto_assign, "on")


func test_idle_jans_go_to_work() -> void:
	var e := engine()
	_city(e)
	for i in 6:
		add_jan(e, "")
	e.set_auto_assign(true)
	e.skip(0.2)
	check_eq(Economy.idle_count(e.state), 0, "nobody idle")
	check(Economy.job_count(e.state, "chop") >= 1, "someone chops")


func test_it_moves_one_jan_at_a_time_towards_the_shares() -> void:
	var e := engine()
	_city(e)
	for i in 7:
		add_jan(e, "chop")
	e.set_auto_assign(true)
	e.skip(0.2)
	check_eq(Economy.job_count(e.state, "chop"), 6, "one Jan moved in the first rebalance")
	e.skip(Balance.AUTO_ASSIGN_EVERY * 10.0)
	var counts := [Economy.job_count(e.state, "chop"), Economy.job_count(e.state, "hunt"), Economy.job_count(e.state, "build")]
	check_eq(counts[0] + counts[1] + counts[2], 7, "nobody lost")
	check(counts[0] >= 2 and counts[1] >= 2 and counts[2] >= 2, "spread over the jobs: %s" % str(counts))


func test_it_settles_instead_of_shuffling() -> void:
	var e := engine()
	_city(e)
	for i in 7:
		add_jan(e, "")
	e.set_auto_assign(true)
	e.skip(Balance.AUTO_ASSIGN_EVERY * 8.0)
	var before := e.state.jans.map(func(j): return j.job)
	e.skip(Balance.AUTO_ASSIGN_EVERY * 4.0)
	check_eq(e.state.jans.map(func(j): return j.job), before, "the same jobs four rebalances later")


func test_it_never_touches_guards() -> void:
	var e := engine()
	_city(e)
	for i in 3:
		add_jan(e, "guard")
	for i in 2:
		add_jan(e, "")
	e.set_auto_assign(true)
	e.skip(Balance.AUTO_ASSIGN_EVERY * 6.0)
	check_eq(Economy.job_count(e.state, "guard"), 3, "guards stay guards")


func test_moving_a_jan_by_hand_switches_it_off() -> void:
	var e := engine()
	_city(e)
	for i in 4:
		add_jan(e, "chop")
	e.set_auto_assign(true)
	e.remove_from_job("chop")
	check(not e.state.auto_assign, "off after a hand move")
	e.skip(Balance.AUTO_ASSIGN_EVERY * 2.0)
	check_eq(Economy.idle_count(e.state), 1, "the idle Jan stays idle")
