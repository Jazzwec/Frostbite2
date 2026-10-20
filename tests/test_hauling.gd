extends TestCase
## Jans haul their work (agreed 2026-10-20): a load at their post, carried to the nearest
## stockpile, counted in the store only on arrival, then back to work.


func _keep_warm(e: GameEngine) -> void:
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 1000.0
	e.state.piles.food = 100.0


## A chopper already standing at his post at the starting Lumber Yard.
func _chopper(e: GameEngine) -> Dictionary:
	put_meagan(e, Vector2(0, 30))
	var jan := add_jan(e, "chop")
	jan.pos = MapData.jan_post(e.state, jan.site, 0)
	return jan


func test_a_jan_works_up_a_load_then_carries_it_to_the_stockpile() -> void:
	var e := engine()
	var jan := _chopper(e)
	_keep_warm(e)
	e.skip(4.0)
	check_near(e.state.piles.wood, 0.0, 0.001, "nothing in the store while he chops")
	check_near(jan.load, 4.0, 0.05, "1 Wood/s in his arms")
	check(jan.working, "working at his post")
	e.skip(1.1)
	check_eq(jan.trip, "out", "a full load of 5: off to the stockpile")
	check_eq(jan.dest, 0, "the main one, the only one")
	var walk := MapData.jan_post(e.state, jan.site, 0).distance_to(MapData.stockpile_pad(e.state, 0)) / (Balance.JAN_WALK_SPEED / Balance.JAN_PATH_FACTOR)
	e.drain_events()
	e.skip(walk + 0.3)
	check_near(e.state.piles.wood, 5.0, 0.01, "his load lands in the store")
	check_eq(jan.trip, "back", "and he heads back")
	check(e.drain_events().any(func(ev): return ev.type == "jan_delivered" and absf(ev.amount - 5.0) < 0.01), "a delivered event")
	e.skip(walk + 0.3)
	check_eq(jan.trip, "", "back at his post")


func test_he_takes_it_to_the_nearest_stockpile() -> void:
	var e := engine()
	var jan := _chopper(e)
	var post := MapData.jan_post(e.state, jan.site, 0)
	e.state.stockpiles.append({"pos": post + Vector2(0, 1.0), "tile": Vector2i.ZERO})
	_keep_warm(e)
	e.skip(5.2)
	check_eq(jan.dest, 1, "the one right by his work")


func test_a_nearer_stockpile_gets_more_out_of_him() -> void:
	var far := engine()
	_chopper(far)
	var near := engine()
	var jan := _chopper(near)
	near.state.stockpiles.append({"pos": MapData.jan_post(near.state, jan.site, 0) + Vector2(1.5, -1.8), "tile": Vector2i.ZERO})
	for e in [far, near]:
		for k in 60:
			_keep_warm(e)
			e.skip(1.0)
	check(near.state.piles.wood > far.state.piles.wood + 4.0, "more Wood a minute (%.0f against %.0f)" % [near.state.piles.wood, far.state.piles.wood])


func test_jans_rest_when_the_store_is_full() -> void:
	var e := engine()
	var jan := _chopper(e)
	_keep_warm(e)
	e.state.piles.wood = Economy.caps(e.state).wood
	e.skip(3.0)
	check_near(jan.load, 0.0, 0.001, "no load worked up")
	check(not jan.working, "resting")


func test_a_new_job_drops_his_load() -> void:
	var e := engine()
	var jan := _chopper(e)
	_keep_warm(e)
	e.skip(3.0)
	check(jan.load > 0.0, "some Wood in his arms")
	JobRules.assign(e.state, jan, "")
	check_near(jan.load, 0.0, 0.001, "dropped")
	check_eq(jan.trip, "", "no trip")


func test_hauling_survives_a_save() -> void:
	var e := engine()
	var jan := _chopper(e)
	_keep_warm(e)
	e.skip(6.0)
	var loaded := GameEngine.from_json(e.to_json())
	var j: Dictionary = loaded.state.jans[0]
	check_eq(j.trip, jan.trip, "his trip kept")
	check_near(j.load, jan.load, 0.001, "his load kept")
	check(j.pos.distance_to(jan.pos) < 0.001, "where he is kept")
