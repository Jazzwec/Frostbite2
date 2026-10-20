extends TestCase
## Saving and loading a winter.


## A winter well under way: Jans at work, a site being built, wolves out, Wood gathered.
func _mid_game() -> GameEngine:
	var e := engine()
	e.dev_add_jan()
	e.dev_add_jan()
	e.state.jans[0].job = "chop"
	e.start_construction(3)
	e.state.sites[3].progress = {"wood": 12.0}
	e.state.gathered = {"wood": 7.0, "food": 2.0, "materials": 1.0}
	e.state.piles.wood = 40.0
	e.dev_level_up(0)
	e.spawn_wolves(3)
	put_meagan(e, Vector2(4.5, -2.25))
	e.skip(5.0)
	return e


func test_a_save_round_trips_the_whole_state() -> void:
	var e := _mid_game()
	var loaded := GameEngine.from_json(e.to_json())
	check(loaded != null, "the save loads")
	if loaded == null:
		return
	check_eq(JSON.stringify(JSON.from_native(loaded.state.to_dict())), JSON.stringify(JSON.from_native(e.state.to_dict())), "state")
	check_eq(loaded.state.jans.size(), e.state.jans.size(), "Jans")
	check_eq(loaded.state.wolves.size(), e.state.wolves.size(), "wolves")
	check(loaded.state.wolves.size() > 0, "wolves were saved mid-attack")
	check_eq(typeof(loaded.state.sites[0].level), TYPE_INT, "levels stay ints")
	check_eq(typeof(loaded.state.wolves[0].pos), TYPE_VECTOR2, "positions stay Vector2s")
	check_eq(loaded.state.meagan_pos, Vector2(4.5, -2.25), "Meagan's spot")
	check_near(loaded.state.time, e.state.time, 0.0001, "time")
	check_near(loaded.state.blizzard_at, e.state.blizzard_at, 0.0001, "next blizzard")
	check_near(loaded.state.next_arrival_in, e.state.next_arrival_in, 0.0001, "next arrival")


func test_a_loaded_winter_plays_on_the_same() -> void:
	var e := _mid_game()
	var loaded := GameEngine.from_json(e.to_json())
	e.skip(30.0)
	loaded.skip(30.0)
	# JSON keeps about 15 digits, so floats can differ in the last one; random rolls must match.
	var a := loaded.state
	var b := e.state
	check_eq(a.arrivals, b.arrivals, "the same frozen Jans arrived")
	check_eq(a.next_id, b.next_id, "the same ids handed out")
	check_eq(a.jans.size(), b.jans.size(), "Jans")
	check_eq(a.wolves.size(), b.wolves.size(), "wolves")
	check_eq(a.lost_total, b.lost_total, "Jans lost")
	check_near(a.attack_at, b.attack_at, 0.001, "next attack")
	check_near(a.heat, b.heat, 0.001, "heat")
	check_near(a.fuel, b.fuel, 0.001, "fuel")
	check_near(a.piles.food, b.piles.food, 0.001, "food")


func test_a_finished_winter_stays_finished() -> void:
	var e := engine()
	e.state.heat = 0.01
	e.state.fuel = 0.0
	e.skip(2.0)
	check(e.state.game_over, "the fire went out")
	var loaded := GameEngine.from_json(e.to_json())
	check(loaded.state.game_over, "still over after loading")


func test_unreadable_saves_are_refused() -> void:
	check(GameEngine.from_json("") == null, "empty text")
	check(GameEngine.from_json(JSON.stringify(JSON.from_native({"version": 999, "state": {}}))) == null, "a newer version")
	check(GameEngine.from_json("[1, 2]") == null, "not a save")
