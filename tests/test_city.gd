extends TestCase


func _has_event(events: Array, type: String) -> bool:
	return events.any(func(ev): return ev.type == type)


func _keep_warm(e: GameEngine) -> void:
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 1000.0


func test_jans_produce_into_piles() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 30))
	add_jan(e, "chop")
	e.state.piles.food = 100.0
	_keep_warm(e)
	e.skip(10.0)
	check_near(e.state.piles.wood, 10.0, 0.2, "1 Wood/s")


func test_at_most_three_waiting() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 30))
	e.skip(400.0)
	check_eq(e.state.arrivals.size(), Balance.ARRIVAL_MAX_WAITING, "capped")


func test_jans_eat_and_go_hungry() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 30))
	for i in 3:
		add_jan(e, "")
	e.state.piles.food = 1.0
	_keep_warm(e)
	e.skip(15.0)
	check_near(e.state.piles.food, 0.25, 0.02, "3 Jans eat 0.05/s")
	e.skip(10.0)
	check(e.state.hungry, "hungry when the store is empty")


func test_a_jan_leaves_each_minute_at_zero_heat() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 30))
	add_jan(e, "chop")
	add_jan(e, "")
	e.skip(60.05)
	check_eq(e.state.jans.size(), 1, "one left")
	check_eq(e.state.jans[0].job, "chop", "the idle one went first")
	check(_has_event(e.drain_events(), "jan_left"), "event")


func test_pause_stops_time_without_catch_up() -> void:
	var e := engine()
	e.pause()
	e.advance(5.0)
	check_eq(e.state.time, 0.0, "nothing while paused")
	e.resume()
	e.advance(5.0)
	check_near(e.state.time, 1.0, 0.001, "one long frame is capped at 1 s")


func test_add_and_remove_jobs() -> void:
	var e := engine()
	add_jan(e, "")
	add_jan(e, "chop")
	add_jan(e, "chop")
	check(e.add_to_job("hunt"), "idle Jan to hunting")
	check_eq(Economy.job_count(e.state, "hunt"), 1, "hunt")
	check(e.add_to_job("hunt"), "takes from chopping")
	check_eq(Economy.job_count(e.state, "chop"), 1, "chop")
	check(not e.add_to_job("build"), "no Workshop yet")
	check(e.remove_from_job("hunt"), "remove")
	check_eq(Economy.idle_count(e.state), 1, "idle")


func test_blizzard_is_warned_then_hits() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 30))
	e.skip(Balance.BLIZZARD_FIRST_AT - Balance.BLIZZARD_WARNING + 0.1)
	check(_has_event(e.drain_events(), "blizzard_warning"), "warned 3 minutes ahead")
	check(not e.state.blizzard_active, "not yet")
	e.skip(Balance.BLIZZARD_WARNING)
	check(e.state.blizzard_active, "blizzard")
	var waiting := e.state.arrivals.size()
	e.skip(Balance.BLIZZARD_DURATION - 1.0)
	check_eq(e.state.arrivals.size(), waiting, "no arrivals in a blizzard")
	e.skip(1.1)
	check(not e.state.blizzard_active, "over")
	check_eq(e.state.blizzards_survived, 1, "survived")
	check(e.state.blizzard_at >= e.state.time + Balance.BLIZZARD_GAP_MIN - 0.2, "next one 20+ minutes away")


func test_forced_blizzard() -> void:
	var e := engine()
	e.force_blizzard()
	e.skip(Balance.BLIZZARD_FORCED_DELAY + 0.1)
	check(e.state.blizzard_active, "forced blizzard started")
