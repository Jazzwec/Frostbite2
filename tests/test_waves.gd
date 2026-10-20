extends TestCase
## The Armory, the enemy roster, waves, starving and outposts (agreed 2026-10-20).


func _quiet(e: GameEngine) -> void:
	put_meagan(e, Vector2(20, 35))
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 1000.0
	e.state.piles.food = 100.0
	e.state.arrivals.clear()
	e.state.next_arrival_in = 9999.0
	e.state.attack_at = 1e9


func _rng(seed := 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


func _of(e: GameEngine, type: String) -> Array:
	return e.drain_events().filter(func(ev): return ev.type == type)


# ---------- The Armory ----------

func test_every_armory_level_makes_her_stronger() -> void:
	var e := engine()
	var last := {}
	for lv in range(1, 11):
		var w := Economy.meagan_weapon(e.state, lv)
		if not last.is_empty():
			check(w.snow_damage / w.snow_every > last.snow_damage / last.snow_every, "Lv %d: more snowball damage a second" % lv)
			check(w.stick_damage / w.stick_every > last.stick_damage / last.stick_every, "Lv %d: more stick damage a second" % lv)
			check(w.range >= last.range and w.reach >= last.reach, "Lv %d: reaches as far or further" % lv)
		last = w


func test_the_armory_kits_out_the_guards() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "barracks", 1)
	add_jan(e, "")
	e.add_to_job("guard")
	var strike := Economy.guard_strike(e.state)
	var hp := Economy.guard_hp(e.state)
	give_building(e, "armory", 1)
	e.dev_level_up(MapData.site_of_building(e.state.sites, "armory"))
	check(Economy.guard_strike(e.state) > strike, "they hit harder")
	check(Economy.guard_hp(e.state) > hp, "and take more")
	var guard: Dictionary = e.state.jans.filter(func(j): return j.job == "guard")[0]
	check_near(guard.hp, Economy.guard_hp(e.state), 0.01, "at once")


func test_the_armory_is_on_its_own_plot() -> void:
	check_eq(MapData.START_SITES.filter(func(s): return s.type == "armory").size(), 1, "one Armory plot")


# ---------- The roster ----------

func test_her_stick_sweeps_up_to_three_in_front() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	for k in 4:
		e.spawn_wolves(1)
		var w: Dictionary = e.state.wolves[-1]
		w.hp = 1000.0
		w.max_hp = 1000.0
		w.damage = 0.0
	# Three in front (+x), one behind.
	e.state.wolves[0].pos = Vector2(1.2, 20)
	e.state.wolves[1].pos = Vector2(1.0, 20.6)
	e.state.wolves[2].pos = Vector2(1.0, 19.4)
	e.state.wolves[3].pos = Vector2(-1.5, 20)
	e.state.meagan_mode = "melee"
	e.state.shots.append({"wolf": e.state.wolves[0].id, "from": e.state.meagan_pos, "kind": "melee", "aim": e.state.wolves[0].pos, "in": 0.0, "damage": 10.0, "knock": 0.0, "reach": 2.5})
	Combat._land_shots(e.state, 0.1, [])
	var hit := e.state.wolves.filter(func(w): return w.hp < 1000.0)
	check_eq(hit.size(), 3, "three hit")
	check_near(e.state.wolves[3].hp, 1000.0, 0.001, "not the one behind her")


func test_bears_shrug_off_knockback_and_trolls_ignore_it() -> void:
	var e := engine()
	for kind in ["wolf", "bear", "troll"]:
		var en := Combat.make_enemy(e.state, kind, Vector2(1, 20), Vector2(0, 0))
		Combat._damage(e.state, en, 1.0, Vector2(0, 20), 1.0, "melee", [])
		check_near(en.pos.x - 1.0, Balance.ENEMIES[kind].knocked, 0.001, "%s pushed %.2f m" % [kind, Balance.ENEMIES[kind].knocked])


func test_a_trolls_slam_hits_everyone_round_it() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "barracks", 1)
	add_jan(e, "")
	e.add_to_job("guard")
	e.skip(3.0)
	var guard: Dictionary = e.state.jans.filter(func(j): return j.job == "guard")[0]
	put_meagan(e, guard.pos + Vector2(2.0, 0))
	var troll := Combat.make_enemy(e.state, "troll", guard.pos + Vector2(1.0, 1.0), Vector2(0, 0))
	troll.hp = 10000.0
	e.state.wolves.append(troll)
	var hp: float = e.state.meagan_hp
	var ghp: float = guard.hp
	e.skip(Balance.ENEMIES.troll.tell + 0.5)
	check(e.state.meagan_hp < hp, "she's hit")
	check(guard.hp < ghp or guard.ko, "and so is the guard")


func test_raiders_throw_from_range() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var r := Combat.make_enemy(e.state, "raider", Vector2(3.5, 20), Vector2(0, 0))
	r.hp = 10000.0
	e.state.wolves.append(r)
	e.drain_events()
	var hp: float = e.state.meagan_hp
	e.skip(3.0)
	var throws := _of(e, "enemy_throw")
	check(throws.size() >= 1, "it threw")
	check(r.pos.distance_to(e.state.meagan_pos) > 3.0, "keeping its distance")
	check(e.state.meagan_hp < hp, "and hit her standing still")


func test_a_raider_misses_if_she_moves() -> void:
	var e := engine()
	put_meagan(e, Vector2(0, 20))
	var r := Combat.make_enemy(e.state, "raider", Vector2(5, 20), Vector2(0, 0))
	r.hp = 10000.0
	e.state.wolves.append(r)
	var hp: float = e.state.meagan_hp
	for t in 40:
		e.skip(0.1)
		if not e.state.enemy_shots.is_empty():
			put_meagan(e, e.state.meagan_pos + Vector2(0, 2.0))
			break
	e.skip(1.5)
	check(_of(e, "shard_landed").any(func(ev): return not ev.hit), "the shard landed where she was")
	check_near(e.state.meagan_hp, hp, 0.001, "no damage")


# ---------- Waves ----------

func test_wave_mixes_bring_new_kinds_in_order() -> void:
	var rng := _rng()
	var w1 := Combat.wave_mix(1, rng)
	check_eq(w1.keys(), ["wolf"], "wave 1: wolves")
	check_eq(Combat.wave_mix(3, rng).get("fox", 0) >= 4, true, "wave 3: a fox pack")
	check(Combat.wave_mix(4, rng).get("raider", 0) >= 2, "wave 4: raiders")
	check(Combat.wave_mix(5, rng).get("bear", 0) >= 1, "wave 5: a bear")
	check_eq(Combat.wave_mix(6, rng).get("troll", 0), 1, "wave 6: the troll")
	for n in range(1, 30):
		var mix := Combat.wave_mix(n, rng)
		var cost := 0.0
		for kind in mix:
			cost += Balance.ENEMIES[kind].cost * mix[kind]
		check(cost <= Balance.WAVE_SPEND_MAX + Balance.ENEMIES.troll.cost, "wave %d stays in its budget (%d)" % [n, cost])
		check(mix.get("bear", 0) <= Balance.WAVE_MAX.bear, "wave %d: bears capped" % n)


func test_late_waves_get_tougher_not_bigger() -> void:
	var e := engine()
	_quiet(e)
	var n := 30
	check(Combat.wave_budget(n) > Balance.WAVE_SPEND_MAX, "past the spending cap")
	Combat.plan_wave(e.state, n, _rng(), [])
	var q: Dictionary = e.state.wave_queue[0]
	check_near(q.strength, Combat.wave_budget(n) / Balance.WAVE_SPEND_MAX, 0.001, "the overflow makes them stronger")


func test_a_wave_comes_in_groups() -> void:
	var e := engine()
	_quiet(e)
	Combat.plan_wave(e.state, 8, _rng(), [])
	var total: int = e.state.wave_queue.size()
	check(total > Balance.WAVE_GROUP, "a big wave (%d)" % total)
	e.skip(0.2)
	check_eq(e.state.wolves.size(), Balance.WAVE_GROUP, "the first group")
	e.skip(Balance.WAVE_GROUP_GAP)
	check(e.state.wolves.size() > Balance.WAVE_GROUP, "then the next")


# ---------- Starving ----------

func test_with_no_food_jans_leave_one_by_one() -> void:
	var e := engine()
	_quiet(e)
	for i in 3:
		add_jan(e, "")
	e.state.piles.food = 0.0
	e.skip(Balance.STARVE_GRACE - 1.0)
	check_eq(e.state.jans.size(), 3, "a grace first")
	e.skip(2.0)
	check_eq(e.state.jans.size(), 2, "then one leaves")
	check(not _of(e, "jan_starved").is_empty(), "with an event")
	e.skip(Balance.STARVE_LEAVE_EVERY)
	check_eq(e.state.jans.size(), 1, "and another")


# ---------- Outposts ----------

func test_an_outpost_sleeps_until_she_comes_near() -> void:
	var e := engine()
	_quiet(e)
	var at := Vector2(20, 30)
	Combat.add_outpost(e.state, "fox_den", at, Vector2i(1, 2), 2)
	check_eq(e.state.wolves.size(), 6, "six foxes")
	var before: Vector2 = e.state.wolves[0].pos
	put_meagan(e, at + Vector2(0, 20))
	e.skip(3.0)
	check(e.state.wolves[0].pos.distance_to(before) < 0.01, "asleep")
	put_meagan(e, at + Vector2(0, 4.5))
	e.skip(0.5)
	check(e.state.outposts[0].awake, "awake")


func test_clearing_an_outpost_pays_once() -> void:
	var e := engine()
	_quiet(e)
	e.state.piles.materials = 0.0
	Combat.add_outpost(e.state, "wolf_hollow", Vector2(20, 30), Vector2i(1, 2), 2)
	for w in e.state.wolves:
		w.hp = 0.0
	e.skip(0.1)
	var cleared := _of(e, "outpost_cleared")
	check_eq(cleared.size(), 1, "cleared")
	check(e.state.outposts[0].cleared, "marked")
	# Its four wolves' loot plus the hollow's.
	check_near(e.state.piles.materials, 4.0 * Balance.ENEMIES.wolf.loot + Balance.OUTPOSTS.wolf_hollow.pay.materials, 0.01, "paid")
	e.skip(1.0)
	check(_of(e, "outpost_cleared").is_empty(), "only once")


func test_a_camp_leaves_a_chest_of_spoils() -> void:
	var e := engine()
	_quiet(e)
	Combat.add_outpost(e.state, "raider_camp", Vector2(20, 30), Vector2i(1, 2), 4)
	for w in e.state.wolves:
		w.hp = 0.0
	e.skip(0.1)
	var chest: Dictionary = e.state.chests[-1]
	check_eq(chest.kind, "spoils", "a chest")
	check(chest.pay.materials > Balance.OUTPOSTS.raider_camp.pay.materials, "ring 4 pays more")
	e.state.piles.wood = 0.0
	put_meagan(e, chest.pos)
	e.skip(0.2)
	check(e.state.piles.wood > 0.0, "opened into the store")


func test_outpost_defenders_dont_count_as_a_raid() -> void:
	var e := engine()
	_quiet(e)
	Combat.add_outpost(e.state, "fox_den", Vector2(20, 30), Vector2i(1, 2), 2)
	e.skip(1.0)
	check(not e.state.raid_on, "no raid")
	check(not Combat.meagan_busy(e.state) or e.state.meagan_pos.distance_to(Vector2(20, 30)) < 8.0, "she's free to work")


func test_outposts_survive_a_save() -> void:
	var e := engine()
	_quiet(e)
	Combat.add_outpost(e.state, "bear_cave", Vector2(20, 30), Vector2i(1, 2), 3)
	var copy := GameEngine.from_json(e.to_json())
	check_eq(copy.state.outposts.size(), 1, "kept")
	check_eq(copy.state.wolves.filter(func(w): return w.outpost == 0).size(), 3, "with its defenders")


## Review 1: woken, they take OUTPOST_WAKE to get up before they move.
func test_woken_defenders_take_a_moment_to_get_up() -> void:
	var e := engine()
	_quiet(e)
	var at := Vector2(20, 30)
	Combat.add_outpost(e.state, "wolf_hollow", at, Vector2i(1, 2), 2)
	var before: Vector2 = e.state.wolves[0].pos
	put_meagan(e, at + Vector2(0, 4.5))
	e.skip(Balance.OUTPOST_WAKE - 0.3)
	check(e.state.outposts[0].awake, "awake")
	check(e.state.wolves[0].pos.distance_to(before) < 0.01, "still getting up")
	e.skip(1.0)
	check(e.state.wolves[0].pos.distance_to(before) > 0.1, "then it comes")


# ---------- The warning ----------

## Review 1: the warning says what's coming and from where, and that's what comes.
func test_the_warning_names_the_wave_that_comes() -> void:
	var e := engine()
	_quiet(e)
	e.state.wave = 6
	e.state.attack_at = e.state.time + Balance.WAVE_WARNING + 1.0
	e.skip(2.0)
	var warnings := _of(e, "attack_warning")
	check_eq(warnings.size(), 1, "warned")
	var warned: Dictionary = warnings[0]
	check_eq(warned.wave, 7, "the next wave")
	check(warned.sides.size() == 2, "from two sides by wave 7")
	e.skip(Balance.WAVE_WARNING)
	var came := _of(e, "wolves_arrived")
	check_eq(came.size(), 1, "it came")
	check_eq(came[0].mix, warned.mix, "as warned")
	check(e.state.next_wave.is_empty(), "and the drawn wave is used up")
