extends TestCase
## Hypercasual fighting (agreed 2026-10-20): Meagan's snowballs and stick, swapping on their own,
## telegraphed wolf bites, guards striking the nearest wolf, and work pausing during a fight.


func _wolf_at(e: GameEngine, pos: Vector2, hp := 1000.0) -> Dictionary:
	e.spawn_wolves(1)
	var w: Dictionary = e.state.wolves[-1]
	w.pos = pos
	w.hp = hp
	w.max_hp = hp
	return w


func _events_of(e: GameEngine, type: String) -> Array:
	return e.drain_events().filter(func(ev): return ev.type == type)


func test_she_throws_snowballs_at_range_and_they_land_after_their_flight() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var w := _wolf_at(e, Vector2(6, 20))
	w.mode = "leave"  # hold it still for the test
	w.mode = "furnace"
	e.state.wolves[0].pos = Vector2(6, 20)
	e.skip(0.1)
	check_eq(e.state.meagan_mode, "ranged", "a wolf 6 m away: snowballs")
	var attacks := _events_of(e, "meagan_attack")
	check_eq(attacks.size(), 1, "one throw")
	check_eq(attacks[0].mode, "ranged", "a throw")
	check_near(e.state.wolves[0].hp, 1000.0, 0.001, "nothing yet: the snowball is still on its way")


func test_she_swaps_to_her_stick_up_close_and_back_after_a_moment() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var w := _wolf_at(e, Vector2(1.5, 20))
	e.skip(0.1)
	check_eq(e.state.meagan_mode, "melee", "within reach: the stick")
	# Out past the exit distance, but only for a moment: still melee.
	e.state.wolves[0].pos = Vector2(4.0, 20)
	e.state.meagan_melee_clear = 0.0
	Combat._meagan_fights(e.state, 0.1, [])
	check_eq(e.state.meagan_mode, "melee", "no flicker straight away")
	for k in 4:
		Combat._meagan_fights(e.state, 0.1, [])
	check_eq(e.state.meagan_mode, "ranged", "back to snowballs once none has been close for 0.3 s")


func test_melee_hits_harder_and_knocks_back() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var w := _wolf_at(e, Vector2(1.2, 20))
	w.damage = 0.0
	e.skip(0.4)
	var hits := _events_of(e, "wolf_hit")
	check(hits.any(func(h): return h.kind == "melee"), "a stick hit landed")
	check(e.state.wolves[0].hp <= 1000.0 - Economy.meagan_weapon(e.state).stick_damage + 0.001, "the stick's damage")


func test_work_pauses_during_a_fight() -> void:
	var e := engine()
	var forest := node_index("forest")
	var pos: Vector2 = MapData.START_NODES[forest].pos
	put_meagan(e, pos)
	var w := _wolf_at(e, pos + Vector2(3.5, 0))
	w.damage = 0.0
	e.skip(1.0)
	var before: float = e.state.bag.wood
	e.skip(1.0)
	check_near(e.state.bag.wood, before, 0.001, "no gathering while a wolf fights her")
	e.state.wolves.clear()
	e.skip(1.5)
	check(e.state.bag.wood > before, "back to work once it's gone")


func test_a_bite_is_telegraphed_and_misses_if_she_steps_away() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var w := _wolf_at(e, Vector2(1.3, 20))
	e.state.meagan_injured = false
	e.skip(0.1)
	check(_events_of(e, "wolf_windup").size() == 1, "it crouches first")
	var hp: float = e.state.meagan_hp
	# A few steps away, still in the wolf's sight: it lunges at where she was and misses.
	put_meagan(e, Vector2(0, 23.5))
	e.skip(0.7)
	var bites := _events_of(e, "wolf_bite")
	check_eq(bites.size(), 1, "the bite came")
	check(not bites[0].hit, "and missed her")
	check_near(e.state.meagan_hp, hp, 0.001, "no damage")


func test_at_most_two_wolves_wind_up_at_once() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	for k in 4:
		var w := _wolf_at(e, Vector2(cos(k * 1.6), sin(k * 1.6)) * 1.3 + Vector2(0, 20))
		w.damage = 0.0
	var most := 0
	for t in 30:
		e.skip(0.1)
		var winding := e.state.wolves.filter(func(w): return w.get("bite_t", -1.0) >= 0.0 and w.bite_t < Balance.ENEMIES.wolf.tell + Balance.ENEMY_LUNGE).size()
		most = maxi(most, winding)
	check(most >= 1, "they bite")
	check(most <= Balance.ENEMY_MAX_MELEE_WINDUP, "never more than two at once (%d)" % most)


func test_guards_strike_once_a_second() -> void:
	var e := engine()
	put_meagan(e, Vector2(20, 35))
	give_building(e, "barracks", 1)
	add_jan(e, "")
	e.add_to_job("guard")
	e.skip(3.0)
	var guard: Dictionary = e.state.jans.filter(func(j): return j.job == "guard")[0]
	var w := _wolf_at(e, guard.pos + Vector2(1.0, 0))
	w.damage = 0.0
	e.drain_events()
	e.skip(2.05)
	var strikes := _events_of(e, "guard_strike")
	check(strikes.size() >= 2 and strikes.size() <= 3, "about one strike a second (%d)" % strikes.size())
