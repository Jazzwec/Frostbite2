extends TestCase


func _has_event(events: Array, type: String) -> bool:
	return events.any(func(ev): return ev.type == type)


func _quiet(e: GameEngine) -> void:
	put_meagan(e, Vector2(20, 35))
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 1000.0
	e.state.piles.food = 100.0
	e.state.arrivals.clear()
	e.state.next_arrival_in = 9999.0


func test_the_first_wave_comes_after_four_minutes() -> void:
	var e := engine()
	_quiet(e)
	e.skip(Balance.WAVE_FIRST - 1.0)
	check(e.state.wolves.is_empty(), "no enemies yet")
	e.skip(2.0)
	check_eq(e.state.wave, 1, "wave 1")
	check(not e.state.wolves.is_empty(), "it came")
	check_near(e.state.attack_at, Balance.WAVE_FIRST + Combat.wave_gap(1), 0.2, "the next one is booked")


func test_a_raider_steals_food_first_and_a_kill_gives_it_back() -> void:
	var e := engine()
	_quiet(e)
	e.state.piles.food = 100.0
	e.state.piles.wood = 100.0
	e.spawn_wolves(1)
	e.skip(20.0)
	var events := e.drain_events()
	check(_has_event(events, "theft"), "it reached the store and stole")
	check_near(e.state.piles.food, 100.0 - Balance.ENEMIES.wolf.steal, 0.5, "Food first")
	check_near(e.state.piles.wood, 100.0, 0.001, "Wood left while there's Food")
	check_eq(e.state.wolves[0].mode, "leave", "running off with it")
	e.state.wolves[0].hp = 0.0
	e.skip(0.1)
	check_near(e.state.piles.food, 100.0, 0.5, "killed: the Food is back")


func test_with_no_food_it_takes_wood_then_materials() -> void:
	var e := engine()
	_quiet(e)
	e.state.piles.food = 0.0
	e.state.piles.wood = 3.0
	e.state.piles.materials = 10.0
	e.spawn_wolves(1, "bear")
	e.state.wolves[0].pos = MapData.site_pos(e.state, 0) + Vector2(0, 3)
	e.skip(6.0)
	check(_has_event(e.drain_events(), "theft"), "stole")
	check_near(e.state.wolves[0].carry.get("wood", 0.0), 3.0, 0.01, "all the Wood")
	check_near(e.state.piles.materials, 0.0, 0.01, "then Materials")


func test_a_hit_interrupts_a_theft() -> void:
	var e := engine()
	_quiet(e)
	e.spawn_wolves(1)
	var w: Dictionary = e.state.wolves[0]
	w.pos = MapData.site_pos(e.state, 0) + Vector2(0, 2.2)
	w.hp = 1000.0
	e.skip(1.5)
	check(w.steal_t > 0.5, "stealing")
	Combat._damage(e.state, w, 1.0, w.pos + Vector2(0, 1), 0.0, "guard", [])
	check_near(w.steal_t, 0.0, 0.001, "started over")


func test_a_wolf_detours_and_scares_a_worker() -> void:
	var e := engine()
	_quiet(e)
	add_jan(e, "chop")
	e.spawn_wolves(1)
	e.state.wolves[0].pos = site_pos(1) + Vector2(0, -6)
	e.skip(2.0)
	check_eq(e.state.wolves[0].mode, "jans", "detoured")
	e.skip(3.5)
	check(_has_event(e.drain_events(), "jan_scared"), "scared a Jan")
	check_eq(Economy.job_count(e.state, "chop"), 0, "the chopper fled")


func test_guards_kill_wolves_for_loot() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "barracks", 1)
	for i in 3:
		add_jan(e, "")
		e.add_to_job("guard")
	e.skip(5.0)
	e.spawn_wolves(1)
	e.state.wolves[0].pos = Vector2(0, -8)
	e.state.piles.materials = 0.0
	e.skip(20.0)
	var events := e.drain_events()
	check(_has_event(events, "wolf_killed"), "killed")
	check(_has_event(events, "attack_over"), "attack over")
	check(e.state.piles.materials > 0.0, "loot")


func test_meagan_fights_and_heals() -> void:
	var e := engine()
	_quiet(e)
	put_meagan(e, Vector2(0, 20))
	e.spawn_wolves(1)
	e.state.wolves[0].pos = Vector2(0, 21)
	e.skip(3.0)
	check(_has_event(e.drain_events(), "wolf_killed"), "she killed it")
	check_near(e.state.meagan_hp, Balance.MEAGAN_HP, 0.001, "healed after the attack")


func test_meagan_can_be_injured() -> void:
	var e := engine()
	_quiet(e)
	put_meagan(e, Vector2(0, 20))
	e.spawn_wolves(1)
	e.state.wolves[0].pos = Vector2(0, 21)
	e.state.wolves[0].hp = 10000.0
	e.state.wolves[0].damage = 200.0
	e.skip(1.0)
	check(e.state.meagan_injured, "injured")
	check(not e.can_meagan_move(), "can't move")


func test_fighting_shows_over_gathering() -> void:
	var e := engine()
	var forest := node_index("forest")
	var pos: Vector2 = MapData.START_NODES[forest].pos
	put_meagan(e, pos)
	e.spawn_wolves(1)
	e.state.wolves[0].pos = pos + Vector2(1, 0)
	e.skip(0.1)
	check_eq(e.state.meagan_activity, "fight", "fighting wins")
	check_eq(e.state.meagan_target, e.state.wolves[0].id, "targets the wolf")


func test_a_pack_spreads_round_meagan_instead_of_piling_up() -> void:
	var e := engine()
	put_meagan(e, Vector2(-4, 8))
	e.spawn_wolves(3)
	for w in e.state.wolves:
		w.pos = Vector2(-4, 10.2)
		w.hp = 1000.0
		w.max_hp = 1000.0
	e.skip(2.0)
	var wolves: Array = e.state.wolves
	check_eq(wolves.size(), 3, "all three still fighting")
	for w in wolves:
		check_eq(w.mode, "fight", "wolf %d fights" % w.id)
		check(w.pos.distance_to(e.state.meagan_pos) <= Balance.ENEMY_ENGAGE, "wolf %d stays in reach" % w.id)
		check(w.pos.distance_to(e.state.meagan_pos) >= Balance.WOLF_FIGHT_DISTANCE - 0.3, "wolf %d isn't on top of her" % w.id)
	for i in wolves.size():
		for j in range(i + 1, wolves.size()):
			var d: float = wolves[i].pos.distance_to(wolves[j].pos)
			check(d >= Balance.WOLF_SPACING * 0.85, "wolves %d and %d are %.2f m apart" % [wolves[i].id, wolves[j].id, d])


func test_spreading_doesnt_push_a_wolf_out_of_the_fight() -> void:
	var e := engine()
	put_meagan(e, Vector2(-4, 8))
	e.spawn_wolves(4)
	var i := 0
	for w in e.state.wolves:
		w.pos = Vector2(-4.0 + i * 0.3, 13.0)
		w.hp = 1000.0
		w.max_hp = 1000.0
		i += 1
	e.skip(4.0)
	for w in e.state.wolves:
		check_eq(w.mode, "fight", "wolf %d is still fighting" % w.id)
		check(w.pos.distance_to(e.state.meagan_pos) >= Balance.WOLF_FIGHT_DISTANCE - 0.3, "wolf %d isn't on top of her" % w.id)


func test_no_attack_warning_without_a_watchtower() -> void:
	var e := engine()
	_quiet(e)
	e.state.sites[0].level = 2
	e.state.attack_at = 20.0
	e.skip(19.0)
	check(not e.drain_events().any(func(ev): return ev.type == "attack_warning"), "no warning")
	e.skip(1.5)
	check(not e.state.wolves.is_empty(), "the wolves still come")


func test_a_watchtower_warns_15_s_per_level() -> void:
	var e := engine()
	_quiet(e)
	e.state.sites[0].level = 4
	give_building(e, "watchtower", 2)
	e.state.attack_at = 60.0
	e.skip(60.0 - 30.0 - 0.2)
	check(not e.state.attack_warned, "not yet")
	e.skip(0.4)
	var warn: Array = e.drain_events().filter(func(ev): return ev.type == "attack_warning")
	check_eq(warn.size(), 1, "warned once, 30 s ahead")
	if not warn.is_empty():
		check_near(warn[0].starts_in, 30.0, 0.15, "how long until they come")
	e.skip(30.0)
	check(not e.state.wolves.is_empty(), "then they come")
	check(not e.state.attack_warned, "the warning re-arms for the next attack")
