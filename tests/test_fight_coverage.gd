extends TestCase
## Fight v2 coverage (BACKLOG F2, 2026-10-21): outposts (waking, rewards by ring, going back to
## sleep), the Armory at every level for Meagan and the guards, getting up and the thieves' grace,
## the new state fields through a save, and hits that land exactly on a tick.


func _quiet(e: GameEngine) -> void:
	put_meagan(e, Vector2(20, 35))
	e.state.heat = Economy.heat_cap(e.state)
	e.state.fuel = 1000.0
	e.state.piles.food = 100.0
	e.state.arrivals.clear()
	e.state.next_arrival_in = 9999.0
	e.state.attack_at = 1e9
	e.state.blizzard_at = 1e9


func _of(events: Array, type: String) -> Array:
	return events.filter(func(ev): return ev.type == type)


## A wolf that won't bite back, at `pos`.
func _dummy(e: GameEngine, pos: Vector2, hp := 1000.0) -> Dictionary:
	var w := Combat.make_enemy(e.state, "wolf", pos, pos)
	w.hp = hp
	w.max_hp = hp
	w.damage = 0.0
	w.bite_cd = 1e9
	e.state.wolves.append(w)
	e.state.raid_on = true
	return w


## One sleeping outpost defender, alone, at `pos`: it doesn't move until OUTPOST_WAKE after
## she comes near, so it stands still for a precise shot.
func _still_target(e: GameEngine, pos: Vector2) -> Dictionary:
	Combat.add_outpost(e.state, "wolf_hollow", pos, Vector2i(1, 2), 2)
	var keep: Dictionary = e.state.wolves[-1]
	e.state.wolves = e.state.wolves.filter(func(w): return w.outpost < 0 or w.id == keep.id)
	keep.pos = pos
	keep.hp = 1000.0
	keep.max_hp = 1000.0
	keep.damage = 0.0
	return keep


# ---------- Outposts ----------

## Rewards and defenders grow with the ring, P = min(2, 1 + 0.15 × (ring − 2)), rounded up.
func test_an_outposts_reward_and_defenders_grow_with_its_ring() -> void:
	for ring in [2, 3, 5, 12]:
		var e := engine()
		_quiet(e)
		Combat.add_outpost(e.state, "bear_cave", Vector2(20, 30), Vector2i(1, 2), ring)
		var p := minf(2.0, 1.0 + 0.15 * maxi(0, ring - 2))
		var post: Dictionary = e.state.outposts[0]
		for res in Balance.OUTPOSTS.bear_cave.pay:
			check_eq(post.pay[res], ceilf(Balance.OUTPOSTS.bear_cave.pay[res] * p), "ring %d: %s" % [ring, res])
		var bear: Dictionary = e.state.wolves.filter(func(w): return w.kind == "bear")[0]
		check_near(bear.max_hp, Balance.ENEMIES.bear.hp * p, 0.01, "ring %d: the bear's HP" % ring)
		check_near(bear.damage, Balance.ENEMIES.bear.damage * sqrt(p), 0.01, "ring %d: its damage" % ring)
		check_eq(e.state.wolves.filter(func(w): return w.outpost == 0).size(), 3, "ring %d: a bear and two wolves" % ring)


## A bear cave leaves a chest of spoils too, and its Food is in it.
func test_a_bear_cave_leaves_a_chest_with_food() -> void:
	var e := engine()
	_quiet(e)
	Combat.add_outpost(e.state, "bear_cave", Vector2(20, 30), Vector2i(1, 2), 2)
	var chests := e.state.chests.size()
	for w in e.state.wolves:
		w.hp = 0.0
	e.skip(0.1)
	check_eq(e.state.chests.size(), chests + 1, "a chest")
	var chest: Dictionary = e.state.chests[-1]
	check_eq(chest.kind, "spoils", "of spoils")
	check_eq(chest.pay.food, Balance.OUTPOSTS.bear_cave.pay.food, "with the cave's Food")


## Hitting a defender from beyond the alert radius wakes the whole outpost, and starts its
## OUTPOST_WAKE.
func test_a_hit_wakes_an_outpost_from_afar() -> void:
	var e := engine()
	_quiet(e)
	Combat.add_outpost(e.state, "fox_den", Vector2(20, 30), Vector2i(1, 2), 2)
	put_meagan(e, Vector2(20, 30 + Balance.OUTPOST_ALERT + 2.0))
	e.skip(1.0)
	check(not e.state.outposts[0].awake, "asleep with her outside the alert radius")
	Combat._damage(e.state, e.state.wolves[0], 1.0, e.state.meagan_pos, 0.0, "ranged", [])
	check(e.state.outposts[0].awake, "a hit wakes it")
	check_near(e.state.outposts[0].woke_at, e.state.time, 0.001, "from now")
	var other: Dictionary = e.state.wolves[1]
	var before: Vector2 = other.pos
	e.skip(Balance.OUTPOST_WAKE - 0.3)
	check(other.pos.distance_to(before) < 0.01, "its other defenders are still getting up")
	e.skip(1.0)
	check(other.pos.distance_to(before) > 0.1, "then they come too")


## Once she's beyond the leash, an outpost sleeps again and its defenders go back to their post.
func test_an_outpost_sleeps_again_when_she_leaves() -> void:
	var e := engine()
	_quiet(e)
	# Well inside the open ground, so nothing is clamped at its edge.
	var at := Vector2(15, -15)
	Combat.add_outpost(e.state, "wolf_hollow", at, Vector2i(1, 2), 2)
	put_meagan(e, at + Vector2(0, 4.0))
	e.state.meagan_attack_in = 1e9
	e.skip(Balance.OUTPOST_WAKE + 1.0)
	check(e.state.outposts[0].awake, "awake")
	put_meagan(e, at + Vector2(0, Balance.OUTPOST_LEASH + 3.0))
	e.skip(0.2)
	check(not e.state.outposts[0].awake, "asleep again")
	e.skip(10.0)
	for w in e.state.wolves:
		check(w.pos.distance_to(w.home) < 0.01, "wolf %d back on its spot" % w.id)


## Knocked down near an outpost, its defenders leave her be.
func test_an_outposts_defenders_leave_her_be_while_she_is_down() -> void:
	var e := engine()
	_quiet(e)
	var at := Vector2(20, 30)
	Combat.add_outpost(e.state, "wolf_hollow", at, Vector2i(1, 2), 2)
	put_meagan(e, at + Vector2(0, 3.0))
	e.state.meagan_attack_in = 1e9
	e.skip(Balance.OUTPOST_WAKE + 1.5)
	check(e.state.outposts[0].awake, "awake")
	e.state.meagan_hp = 1.0
	Combat._hurt(e.state, {"id": -1, "pos": e.state.meagan_pos}, 5.0, [])
	e.drain_events()
	e.skip(Balance.MEAGAN_DOWN_TIME - 0.5)
	check(e.state.meagan_injured, "still down")
	check(_of(e.drain_events(), "wolf_bite").is_empty(), "nobody bit her while she was down")
	check(e.state.wolves.all(func(w): return w.bite_t < 0.0), "nor is winding up")


# ---------- The Armory, every level ----------

func test_every_armory_level_is_its_row_for_meagan() -> void:
	var e := engine()
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		give_building(e, "armory", lv)
		var row: Dictionary = Balance.ARMORY_LEVELS[lv - 1]
		var w := Economy.meagan_weapon(e.state)
		check_eq([w.range, w.snow_damage, w.snow_every], row.snow, "Lv %d snowball" % lv)
		check_eq([w.reach, w.stick_damage, w.stick_every, w.knock], row.stick, "Lv %d stick" % lv)
	check_eq(Economy.armory_row(e.state, 0), Balance.ARMORY_LEVELS[0], "an Armory not built is Lv 1")
	check_eq(Economy.armory_row(e.state, 99), Balance.ARMORY_LEVELS[-1], "and none beyond the top")


## Her hits deal her Armory row's damage at every level, sweep and snowball.
func test_her_hits_deal_the_armorys_damage_at_every_level() -> void:
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		for mode in ["melee", "ranged"]:
			var e := engine()
			_quiet(e)
			give_building(e, "armory", lv)
			put_meagan(e, Vector2(0, 20))
			_dummy(e, Vector2(1.9 if mode == "melee" else 5.0, 20))
			e.state.meagan_mode = mode
			e.state.meagan_attack_in = 0.0
			e.skip(0.7)
			var hits := _of(e.drain_events(), "wolf_hit")
			var w := Economy.meagan_weapon(e.state)
			check(not hits.is_empty() and hits[0].kind == mode, "Lv %d %s: she hit" % [lv, mode])
			if not hits.is_empty():
				check_near(hits[0].amount, w.stick_damage if mode == "melee" else w.snow_damage, 0.001, "Lv %d %s damage" % [lv, mode])


## The guards' kit at every level: their strike (× the Barracks' growth) and HP, and what a
## strike really deals.
func test_the_guards_kit_at_every_armory_level() -> void:
	for lv in range(1, Balance.ARMORY_LEVELS.size() + 1):
		for barracks in [1, 3]:
			var e := engine()
			_quiet(e)
			give_building(e, "barracks", barracks)
			give_building(e, "armory", lv)
			var guard := add_jan(e, "guard")
			guard.hp = Economy.guard_hp(e.state)
			guard.pos = Combat.guard_post(0, 1)
			var kit: Array = Balance.ARMORY_LEVELS[lv - 1].guard
			var strike: float = kit[0] * pow(Balance.GUARD_GROWTH, barracks - 1)
			check_near(Economy.guard_strike(e.state), strike, 0.001, "Lv %d, Barracks %d: strike" % [lv, barracks])
			check_near(Economy.guard_hp(e.state), kit[1], 0.001, "Lv %d: HP" % lv)
			_dummy(e, guard.pos + Vector2(1.0, 0))
			e.skip(0.3)
			var hits := _of(e.drain_events(), "wolf_hit").filter(func(h): return h.kind == "guard")
			check(not hits.is_empty(), "Lv %d, Barracks %d: the guard struck" % [lv, barracks])
			if not hits.is_empty():
				check_near(hits[0].amount, strike, 0.001, "Lv %d, Barracks %d: for its strike" % [lv, barracks])


# ---------- Getting up, and the thieves' grace ----------

## She's up on the first tick MEAGAN_DOWN_TIME after going down, not before, with a meagan_up
## event and meagan_up_at set.
func test_she_gets_up_on_the_tick_her_down_time_ends() -> void:
	var e := engine()
	_quiet(e)
	put_meagan(e, Vector2(0, 20))
	e.skip(0.35)
	e.state.meagan_hp = 1.0
	Combat._hurt(e.state, {"id": -1, "pos": e.state.meagan_pos}, 5.0, [])
	var down_at := e.state.time
	check_near(e.state.meagan_down_at, down_at, 0.0001, "down_at recorded")
	e.drain_events()
	var up_at := -1.0
	for i in int(Balance.MEAGAN_DOWN_TIME / Balance.TICK) + 3:
		e.skip(Balance.TICK)
		if not _of(e.drain_events(), "meagan_up").is_empty():
			up_at = e.state.time
			break
	check(up_at > 0.0, "she got up")
	check(up_at - down_at >= Balance.MEAGAN_DOWN_TIME - 0.0001, "not before her down time (%.2f s)" % (up_at - down_at))
	check(up_at - down_at < Balance.MEAGAN_DOWN_TIME + Balance.TICK - 0.0001, "within a tick of it (%.2f s)" % (up_at - down_at))
	check_near(e.state.meagan_up_at, up_at, 0.0001, "up_at recorded")


## A thief at the edge with its loot waits while she's down and CATCH_GRACE after she's up, then
## goes.
func test_a_thief_waits_out_her_down_time_and_the_grace() -> void:
	var e := engine()
	_quiet(e)
	put_meagan(e, Vector2(0, 20))
	var home := Vector2(30, 20)
	var thief := Combat.make_enemy(e.state, "fox", home, home)
	thief.mode = "leave"
	thief.carry = {"food": 5.0}
	e.state.wolves.append(thief)
	e.state.raid_on = true
	e.state.meagan_hp = 1.0
	Combat._hurt(e.state, {"id": -1, "pos": e.state.meagan_pos}, 5.0, [])
	e.skip(Balance.MEAGAN_DOWN_TIME - 0.5)
	check(e.state.wolves.has(thief), "it waits while she's down")
	e.skip(1.0)
	check(not e.state.meagan_injured, "she's up")
	var up_at := e.state.meagan_up_at
	e.drain_events()
	var left_at := -1.0
	for i in int(Balance.CATCH_GRACE / Balance.TICK) + 5:
		e.skip(Balance.TICK)
		if not _of(e.drain_events(), "wolf_left").is_empty():
			left_at = e.state.time
			break
	check(left_at > 0.0, "then it goes")
	check(left_at - up_at >= Balance.CATCH_GRACE - 0.0001, "not before the grace is over (%.2f s)" % (left_at - up_at))
	check(left_at - up_at < Balance.CATCH_GRACE + Balance.TICK - 0.0001, "on the tick it's over (%.2f s)" % (left_at - up_at))


# ---------- Saving ----------

## The fight's new state fields come back from a save, with their types, and the winter plays on
## the same.
func test_the_fight_state_survives_a_save() -> void:
	var e := engine()
	_quiet(e)
	# A wave drawn at its warning.
	e.state.wave = 5
	e.state.attack_at = e.state.time + 10.0
	e.skip(0.2)
	check(not e.state.next_wave.is_empty(), "a wave drawn")
	# An awake outpost, with her fighting it.
	var at := Vector2(20, 30)
	Combat.add_outpost(e.state, "raider_camp", at, Vector2i(1, 2), 3)
	put_meagan(e, at + Vector2(0, 4.0))
	e.skip(0.5)
	check(e.state.outposts[0].awake, "an awake outpost")
	check(e.state.meagan_foe >= 0, "she has a foe")
	# Down and up once, and down again.
	e.state.meagan_hp = 1.0
	Combat._hurt(e.state, {"id": -1, "pos": e.state.meagan_pos}, 5.0, [])
	e.skip(Balance.MEAGAN_DOWN_TIME + 0.2)
	e.state.meagan_hp = 1.0
	Combat._hurt(e.state, {"id": -1, "pos": e.state.meagan_pos}, 5.0, [])
	e.skip(0.3)
	check(e.state.meagan_up_at > 0.0 and e.state.meagan_down_at > e.state.meagan_up_at, "down after getting up once")

	var copy := GameEngine.from_json(e.to_json())
	check(copy != null, "it loads")
	if copy == null:
		return
	var s := copy.state
	check_eq(s.next_wave.n, e.state.next_wave.n, "next_wave's number")
	check_eq(s.next_wave.mix, e.state.next_wave.mix, "and its mix")
	check_eq(s.next_wave.sides, e.state.next_wave.sides, "and its sides")
	check_eq(typeof(s.next_wave.sides[0]), TYPE_VECTOR2, "sides stay Vector2s")
	check_near(s.meagan_down_at, e.state.meagan_down_at, 0.0001, "meagan_down_at")
	check_near(s.meagan_up_at, e.state.meagan_up_at, 0.0001, "meagan_up_at")
	check_eq(s.meagan_foe, e.state.meagan_foe, "meagan_foe")
	check_eq(s.outposts, e.state.outposts, "the outposts")
	check_eq(typeof(s.outposts[0].tile), TYPE_VECTOR2I, "tiles stay Vector2is")
	check_eq(typeof(s.outposts[0].pos), TYPE_VECTOR2, "spots stay Vector2s")
	# And on from there, the same: she gets up at the same moment, the wave comes the same. (JSON
	# keeps about 15 digits, so floats can differ in the last one, as in test_save.gd.)
	for eng in [e, copy]:
		eng.skip(Balance.MEAGAN_DOWN_TIME + 12.0)
	check_eq(s.meagan_injured, e.state.meagan_injured, "up the same")
	check_near(s.meagan_up_at, e.state.meagan_up_at, 0.0001, "at the same moment")
	check_eq(s.wave, e.state.wave, "the same wave came")
	check_eq(s.next_id, e.state.next_id, "the same ids handed out")
	check_eq(s.wolves.map(func(w): return w.kind), e.state.wolves.map(func(w): return w.kind), "the same enemies")
	for i in mini(s.wolves.size(), e.state.wolves.size()):
		check(s.wolves[i].pos.distance_to(e.state.wolves[i].pos) < 0.001, "enemy %d in the same spot" % i)
	check_eq(s.outposts.map(func(o): return o.awake), e.state.outposts.map(func(o): return o.awake), "the outpost as awake")


# ---------- Hits on the tick ----------

## A snowball whose release and flight add up to a whole number of ticks lands on that tick,
## not one later (float leftovers mustn't push it over).
func test_a_snowball_due_on_a_tick_lands_on_it() -> void:
	for d in [3.96, 4.86]:  # 0.18 + d / 18 = 0.40 s and 0.45 s
		var e := engine()
		_quiet(e)
		put_meagan(e, Vector2(0, 20))
		_still_target(e, Vector2(d, 20))
		e.state.meagan_mode = "ranged"
		e.state.meagan_attack_in = 0.0
		var attacked_at := -1.0
		var hit_at := -1.0
		for i in 12:
			e.skip(Balance.TICK)
			for ev in e.drain_events():
				if ev.type == "meagan_attack" and attacked_at < 0.0:
					attacked_at = e.state.time
				elif ev.type == "wolf_hit" and hit_at < 0.0:
					hit_at = e.state.time
		var due: float = Balance.MEAGAN_RANGED_RELEASE + d / Balance.SNOWBALL_SPEED
		var ticks: float = ceilf(due / Balance.TICK - 0.001)
		check(attacked_at >= 0.0 and hit_at >= 0.0, "%.2f m: she threw and hit" % d)
		check_near(hit_at - attacked_at, ticks * Balance.TICK, 0.001, "%.2f m: lands on the first tick at or after %.2f s" % [d, due])


## A raider's shard lands when the throw event said it would (the view flies it that long), on
## the tick it's due.
func test_a_shard_lands_when_its_throw_said() -> void:
	var e := engine()
	_quiet(e)
	put_meagan(e, Vector2(0, 20))
	e.state.meagan_attack_in = 1e9
	var raider := Combat.make_enemy(e.state, "raider", Vector2(5.0, 20), Vector2(30, 20))
	e.state.wolves.append(raider)
	e.state.raid_on = true
	var thrown := {}
	var landed_at := -1.0
	for i in 60:
		e.state.meagan_attack_in = 1e9
		e.skip(Balance.TICK)
		for ev in e.drain_events():
			if ev.type == "enemy_throw" and thrown.is_empty():
				thrown = ev
				thrown.at = e.state.time
			elif ev.type == "shard_landed" and landed_at < 0.0 and not thrown.is_empty():
				landed_at = e.state.time
		if landed_at > 0.0:
			break
	check(not thrown.is_empty() and landed_at > 0.0, "it threw and the shard landed")
	if landed_at > 0.0:
		check_near(landed_at - thrown.at, thrown.flight, 0.001, "after the flight the throw announced (%.2f s)" % thrown.flight)


## Her sweeps and the guards' strikes come exactly as often as the Armory says: 0.8 s and 1 s
## counted down in 0.1 s ticks leave a float hair over 0, which used to cost a tick each time.
func test_attacks_come_as_often_as_the_armory_says() -> void:
	var e := engine()
	_quiet(e)
	give_building(e, "barracks", 1)
	var guard := add_jan(e, "guard")
	guard.pos = Combat.guard_post(0, 1)
	put_meagan(e, Vector2(0, 20))
	_dummy(e, Vector2(1.9, 20))
	_dummy(e, guard.pos + Vector2(1.0, 0))
	e.state.meagan_mode = "melee"
	var sweeps := []
	var strikes := []
	for i in 60:
		e.skip(Balance.TICK)
		for ev in e.drain_events():
			if ev.type == "meagan_attack":
				sweeps.append(e.state.time)
			elif ev.type == "guard_strike":
				strikes.append(e.state.time)
	var w := Economy.meagan_weapon(e.state)
	check(sweeps.size() >= 4 and strikes.size() >= 4, "she swept and the guard struck")
	for i in range(1, sweeps.size()):
		check_near(sweeps[i] - sweeps[i - 1], ceilf(w.stick_every / Balance.TICK - 0.001) * Balance.TICK, 0.001, "sweep %d on time" % i)
	for i in range(1, strikes.size()):
		check_near(strikes[i] - strikes[i - 1], Balance.GUARD_STRIKE_EVERY, 0.001, "strike %d on time" % i)
