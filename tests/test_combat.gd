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


func test_no_attacks_before_furnace_level_2() -> void:
	var e := engine()
	_quiet(e)
	e.skip(20.0 * 60.0)
	check(e.state.wolves.is_empty(), "no wolves")
	e.state.sites[0].level = 2
	e.skip(0.1)
	check(e.state.attack_at >= e.state.time + Balance.ATTACK_GAP_MIN - 0.2, "first attack scheduled 8+ minutes out")


func test_wolves_break_through_at_the_furnace() -> void:
	var e := engine()
	_quiet(e)
	e.state.piles.wood = 100.0
	add_jan(e, "")
	e.spawn_wolves(1)
	e.skip(15.0)
	var events := e.drain_events()
	check(_has_event(events, "breakthrough"), "reached the furnace")
	check_eq(e.state.jans.size(), 0, "scared the idle Jan off")
	check(e.state.piles.wood < 100.0, "took Wood")


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
	e.state.piles.food = 0.0
	e.skip(20.0)
	var events := e.drain_events()
	check(_has_event(events, "wolf_killed"), "killed")
	check(_has_event(events, "attack_over"), "attack over")
	check(e.state.piles.food > 0.0, "loot")


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
	var pos: Vector2 = MapData.RESOURCE_NODES[forest].pos
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
		check(w.pos.distance_to(e.state.meagan_pos) <= Balance.WOLF_ENGAGE_RANGE, "wolf %d stays in reach" % w.id)
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
