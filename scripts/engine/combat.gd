class_name Combat
extends RefCounted
## Enemies, waves and fighting (agreed 2026-10-20; numbers in Balance, from ChatGPT's steer).
## - Waves come on a clock that speeds up, each from a budget that grows, spent on a mix of
##   kinds (Balance.ENEMIES: foxes, wolves, bears, raiders, trolls). They head for the store.
## - Fighting is hypercasual: everyone fights on their own, each going for the nearest opponent,
##   in discrete telegraphed attacks. Meagan throws snowballs at range and sweeps her stick up
##   close (her Armory level sets both); guards strike; enemies bite, swipe, slam or throw.
## - An enemy that reaches the furnace or a stockpile steals from the store (Food first) and
##   runs off; killing it gives the loot back. Raids drain the store, starving the town.
## - Outposts in opened tiles hold sleeping defenders that wake when she comes near.
## Enemies live in `state.wolves` (the field keeps its old name), each with a `kind`.


static func update(s: GameState, dt: float, rng: RandomNumberGenerator, events: Array) -> void:
	_get_up(s, events)
	_schedule(s, rng, events)
	_spawn_queued(s, events)
	for enemy in s.wolves.duplicate():
		_enemy(s, enemy, dt, events)
	_spread(s, dt)
	_guards_fight(s, dt, events)
	_meagan_fights(s, dt, events)
	_land_shots(s, dt, events)
	_land_enemy_shots(s, dt, events)
	_collect_dead(s, events)
	if s.raid_on and _raiders(s).is_empty() and s.wave_queue.is_empty():
		_attack_over(s, events)
	if _raiders(s).is_empty():
		_guards_return(s, dt)


# ---------- Waves ----------

## The wave clock: the first after WAVE_FIRST, then ever closer. A Watchtower warns ahead. A wave
## due in a blizzard waits until it's over.
static func _schedule(s: GameState, rng: RandomNumberGenerator, events: Array) -> void:
	if s.attack_at < 0.0:
		s.attack_at = Balance.WAVE_FIRST
	var warning := Economy.attack_warning(s)
	if warning > 0.0 and not s.attack_warned and not s.blizzard_active and s.time >= s.attack_at - warning:
		s.attack_warned = true
		# Drawn now, so the warning can say what's coming and from where (fight_v2 review 1).
		var next := _draw_wave(s, s.wave + 1, rng)
		events.append({"type": "attack_warning", "starts_in": maxf(s.attack_at - s.time, 0.0), "wave": next.n, "mix": next.mix, "sides": next.sides})
	if s.time < s.attack_at:
		return
	if s.blizzard_active:
		s.attack_at = s.blizzard_ends_at + 30.0
		s.attack_warned = false
		return
	s.wave += 1
	plan_wave(s, s.wave, rng, events)
	s.attack_warned = false
	s.attack_at = s.time + wave_gap(s.wave)


## Seconds from wave `n`'s start to the next one's.
static func wave_gap(n: int) -> float:
	return maxf(Balance.WAVE_GAP_MIN, Balance.WAVE_GAP * pow(Balance.WAVE_GAP_SHRINK, n - 1))


## Wave `n`'s budget before the spending cap.
static func wave_budget(n: int) -> float:
	return roundf(Balance.WAVE_BUDGET * pow(Balance.WAVE_GROWTH, n - 1) * pow(Balance.WAVE_STEP, floori((n - 1) / float(Balance.WAVE_STEP_EVERY))))


## What wave `n` brings, by kind: its guaranteed members and a troll every so often first, then
## weighted draws while the budget lasts.
static func wave_mix(n: int, rng: RandomNumberGenerator) -> Dictionary:
	var budget := minf(Balance.WAVE_SPEND_MAX, wave_budget(n))
	var mix := {}
	var add := func(kind: String, count: int) -> void:
		mix[kind] = mix.get(kind, 0) + count
	if n % Balance.WAVE_TROLL_EVERY == 0:
		add.call("troll", 1)
		budget -= Balance.ENEMIES.troll.cost
	for kind in Balance.WAVE_GUARANTEED.get(n, {}):
		var count: int = Balance.WAVE_GUARANTEED[n][kind]
		add.call(kind, count)
		budget -= Balance.ENEMIES[kind].cost * count
	var fox_spent := 0.0
	var total := budget
	for i in 200:
		var weights := {}
		for kind in Balance.WAVE_WEIGHTS:
			var def: Dictionary = Balance.ENEMIES[kind]
			if n < def.first or def.cost > budget:
				continue
			if mix.get(kind, 0) >= Balance.WAVE_MAX.get(kind, 1 << 30):
				continue
			if kind == "fox" and fox_spent + def.cost > total * Balance.WAVE_FOX_SHARE:
				continue
			weights[kind] = Balance.WAVE_WEIGHTS[kind]
		if weights.is_empty():
			break
		var kind := WorldGen.pick(rng, weights)
		add.call(kind, 1)
		budget -= Balance.ENEMIES[kind].cost
		if kind == "fox":
			fox_spent += Balance.ENEMIES.fox.cost
	return mix


## Wave `n`'s make-up and the sides it comes from, {n, mix, sides}: drawn once, at its warning or
## when it comes, and kept in `state.next_wave` until it's queued.
static func _draw_wave(s: GameState, n: int, rng: RandomNumberGenerator) -> Dictionary:
	if s.next_wave.get("n", -1) == n:
		return s.next_wave
	var sides := [s.wolf_spawns[rng.randi_range(0, s.wolf_spawns.size() - 1)]]
	if n >= Balance.WAVE_TWO_SIDES_FROM and s.wolf_spawns.size() > 1:
		# The spawn furthest round from the first.
		var best: Vector2 = sides[0]
		for p in s.wolf_spawns:
			if absf(angle_difference(p.angle(), sides[0].angle())) > absf(angle_difference(best.angle(), sides[0].angle())):
				best = p
		sides.append(best)
	s.next_wave = {"n": n, "mix": wave_mix(n, rng), "sides": sides}
	return s.next_wave


## Queues wave `n`'s enemies in groups, a few seconds apart, from one or two sides.
static func plan_wave(s: GameState, n: int, rng: RandomNumberGenerator, events: Array) -> void:
	var drawn := _draw_wave(s, n, rng)
	s.next_wave = {}
	var mix: Dictionary = drawn.mix
	var sides: Array = drawn.sides
	var strength := maxf(1.0, wave_budget(n) / Balance.WAVE_SPEND_MAX)
	var order := []
	for kind in mix:
		for i in mix[kind]:
			order.append(kind)
	# Big ones first in the queue, so a wave opens with its threat and its fodder follows.
	order.sort_custom(func(a, b): return Balance.ENEMIES[a].cost > Balance.ENEMIES[b].cost)
	for i in order.size():
		var group := i / Balance.WAVE_GROUP
		s.wave_queue.append({"kind": order[i], "at": s.time + group * Balance.WAVE_GROUP_GAP, "from": sides[group % sides.size()], "strength": strength})
	s.raid_on = true
	events.append({"type": "wolves_arrived", "count": order.size(), "pos": sides[0], "wave": n, "mix": mix})


static func _spawn_queued(s: GameState, events: Array) -> void:
	for q in s.wave_queue.duplicate():
		if s.time < q.at or _raiders(s).size() >= Balance.WAVE_MAX_ALIVE:
			continue
		s.wave_queue.erase(q)
		var rng := RandomNumberGenerator.new()
		rng.seed = s.next_id * 7919
		var pos: Vector2 = (q.from + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))).clamp(s.bounds.position, s.bounds.end)
		s.wolves.append(make_enemy(s, q.kind, pos, q.from, q.strength))


## A new enemy of `kind` at `pos`, going home to `home`; `strength` scales its HP (and its
## damage by the square root).
static func make_enemy(s: GameState, kind: String, pos: Vector2, home: Vector2, strength := 1.0) -> Dictionary:
	var def: Dictionary = Balance.ENEMIES[kind]
	return {
		"id": s.new_id(), "kind": kind, "pos": pos, "home": home,
		"hp": def.hp * strength, "max_hp": def.hp * strength, "damage": def.damage * sqrt(strength),
		"mode": "store", "target": -1, "scare_timer": 0.0, "scared": false, "outpost": -1,
		"bite_t": -1.0, "bite_cd": 0.0, "victim": -1, "carry": {}, "steal_t": 0.0, "stolen": false,
		"fight_for": 0.0, "ignore_until": -1.0,
	}


## A dev shortcut and tests: a pack of `count` of `kind` (wolves by default) from the frontier.
static func spawn_pack(s: GameState, rng: RandomNumberGenerator, events: Array, count := -1, kind := "wolf") -> void:
	if count < 0:
		count = rng.randi_range(2, 4)
	var home: Vector2 = s.wolf_spawns[rng.randi_range(0, s.wolf_spawns.size() - 1)]
	for i in count:
		var offset := Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))
		s.wolves.append(make_enemy(s, kind, (home + offset).clamp(s.bounds.position, s.bounds.end), home))
	s.raid_on = true
	events.append({"type": "wolves_arrived", "count": count, "pos": home, "wave": s.wave, "mix": {kind: count}})


## The enemies of a raid (not an outpost's).
static func _raiders(s: GameState) -> Array:
	return s.wolves.filter(func(w): return w.get("outpost", -1) < 0)


# ---------- Enemies ----------

static func _enemy(s: GameState, e: Dictionary, dt: float, events: Array) -> void:
	var def: Dictionary = Balance.ENEMIES[e.kind]
	var speed: float = def.speed
	if e.mode == "leave":
		e.pos = e.pos.move_toward(e.home, speed * (Balance.CARRY_SPEED if not e.carry.is_empty() else 1.0) * Balance.SPEED_SCALE * dt)
		# A thief with loot waits at the edge while she's down and a little after (review 3).
		if not e.carry.is_empty() and (s.meagan_injured or s.time < s.meagan_up_at + Balance.CATCH_GRACE):
			return
		if e.pos.distance_to(e.home) < 0.5:
			s.wolves.erase(e)
			events.append({"type": "wolf_left", "wolf": e.id, "carry": e.carry})
		return
	# An outpost's defenders sleep, and once woken take a moment to get up (fight_v2 review 1).
	if e.outpost >= 0 and (not _outpost_awake(s, e) or s.time < s.outposts[e.outpost].get("woke_at", -100.0) + Balance.OUTPOST_WAKE):
		return

	# Fight the nearest defender close by, unless it's given up on them for now.
	# (A thrower engages from beyond where it stands to throw.)
	var engage := maxf(Balance.ENEMY_ENGAGE, def.hold + 1.0) if e.outpost < 0 else Balance.OUTPOST_LEASH
	var foe := _nearest_foe(s, e.pos, engage) if s.time >= e.ignore_until else {}
	var attacking: bool = e.bite_t >= 0.0
	if not foe.is_empty() or attacking:
		if foe.is_empty():
			foe = _victim_of(s, e)
		if not foe.is_empty():
			_fight(s, e, def, foe, dt, events)
			return
	e.bite_t = -1.0
	e.fight_for = 0.0
	if e.mode == "fight":
		e.mode = "store"

	# An outpost's defenders go back to their post.
	if e.outpost >= 0:
		var home: Vector2 = s.outposts[e.outpost].pos
		e.pos = e.pos.move_toward(home, speed * Balance.SPEED_SCALE * dt)
		if e.pos.distance_to(home) < 1.0:
			e.mode = "store"
		return

	# Detour to working Jans it passes (foxes and wolves). Each scares at most one. [brief]
	if not e.scared and e.mode == "store" and (e.kind == "wolf" or e.kind == "fox"):
		var site := _working_site_near(s, e.pos)
		if site >= 0:
			e.mode = "jans"
			e.target = site
	if e.mode == "jans":
		var target: int = e.target
		var job := _job_at_site(s, target)
		if job == "" or Economy.site_jans(s, target) == 0:
			e.mode = "store"
			e.scare_timer = 0.0
		else:
			var site_pos := MapData.site_pos(s, target)
			if e.pos.distance_to(site_pos) > Balance.WOLF_REACH + MapData.SITE_HALF_SIZE:
				e.pos = e.pos.move_toward(site_pos, speed * Balance.SPEED_SCALE * dt)
			else:
				e.scare_timer += dt
				if e.scare_timer >= Balance.WOLF_SCARE_TIME:
					var jan := WorldEvents.pick_jan_to_lose(s, job, target)
					s.jans.erase(jan)
					s.lost_total += 1
					e.scared = true
					e.mode = "store"
					events.append({"type": "jan_scared", "jan": jan.id, "job": job, "pos": site_pos})
			return

	# On to the nearest store, then steal.
	var store := nearest_store(s, e.pos)
	if e.pos.distance_to(store) > Balance.STEAL_REACH:
		e.pos = e.pos.move_toward(store, speed * Balance.SPEED_SCALE * dt)
		return
	_steal(s, e, def, store, dt, events)


## Where an enemy goes to steal: the furnace or whichever stockpile is nearest (they all open
## onto the one store).
static func nearest_store(s: GameState, pos: Vector2) -> Vector2:
	var furnace := MapData.site_pos(s, 0)
	var best: Vector2 = furnace + (pos - furnace).normalized() * (MapData.FURNACE_RADIUS + 0.4)
	for k in s.stockpiles.size():
		var pad := MapData.stockpile_pad(s, k)
		if pos.distance_to(pad) < pos.distance_to(best):
			best = pad
	return best


## Stealing takes a moment (a hit interrupts it, see _land_shots); then it takes Food first
## (never the pantry's last shelf, Balance.STEAL_FOOD_FLOOR_PER_JAN), then Wood, then Materials,
## up to what it carries, and runs off.
static func _steal(s: GameState, e: Dictionary, def: Dictionary, at: Vector2, dt: float, events: Array) -> void:
	e.steal_t += dt
	if e.steal_t < Balance.STEAL_TIME:
		return
	var room: float = def.steal
	var floor := {"food": Balance.STEAL_FOOD_FLOOR_PER_JAN * s.jans.size()}
	for res in ["food", "wood", "materials"]:
		var take := minf(maxf(0.0, s.piles[res] - floor.get(res, 0.0)), room)
		if take > 0.0:
			s.piles[res] -= take
			e.carry[res] = take
			room -= take
	e.stolen = true
	e.mode = "leave"
	events.append({"type": "theft", "wolf": e.id, "kind": e.kind, "carry": e.carry, "pos": at})


static func _fight(s: GameState, e: Dictionary, def: Dictionary, foe: Dictionary, dt: float, events: Array) -> void:
	e.mode = "fight"
	e.foe_id = foe.id
	var foe_pos: Vector2 = foe.pos
	var away: Vector2 = e.pos - foe_pos
	var dir := away.normalized() if away.length() > 0.001 else Vector2.RIGHT.rotated(float(e.id))
	var t: float = e.bite_t
	# Only the nearest few strike; the rest wait a body length back.
	var striker: bool = def.shape == "shot" or t >= 0.0 or _is_striker(s, e, foe)
	var hold: float = def.hold if striker else def.hold + def.width * Balance.ENEMY_WAIT_BACK
	if t < 0.0:
		# Hold its distance (a thrower stands off), closing in or backing off.
		e.pos = e.pos.move_toward(foe_pos + dir * hold, def.speed * Balance.SPEED_SCALE * dt)
		e.aim = foe_pos
		e.fight_for = e.fight_for + dt if e.pos.distance_to(foe_pos) > def.hold + 0.4 else 0.0
		if e.fight_for >= Balance.ENEMY_GIVE_UP:
			# It can't land a hit: back to the store, ignoring defenders for a while.
			e.ignore_until = s.time + Balance.ENEMY_IGNORE
			e.fight_for = 0.0
			return
	elif def.shape == "wedge" and t >= def.tell and t < def.tell + Balance.ENEMY_LUNGE:
		# The tell holds still (the window to step away); then a short lunge.
		e.pos = e.pos.move_toward(e.aim + dir * (def.hold - 0.3), Balance.WOLF_BITE_LUNGE_DISTANCE / Balance.ENEMY_LUNGE * dt)
	e.foe_pos = foe_pos
	if striker:
		_attack(s, e, def, foe, dt, events)


## Whether `e` is one of the ENEMY_MAX_ENGAGED melee enemies nearest `foe` (one already winding up
## always counts).
static func _is_striker(s: GameState, e: Dictionary, foe: Dictionary) -> bool:
	var d: float = e.pos.distance_to(foe.pos)
	var ahead := 0
	for w in s.wolves:
		if w.id == e.id or w.hp <= 0.0 or w.mode != "fight" or w.get("foe_id", -99) != foe.id:
			continue
		if Balance.ENEMIES[w.kind].shape == "shot":
			continue
		if w.bite_t >= 0.0 or w.pos.distance_to(foe.pos) < d:
			ahead += 1
	return ahead < Balance.ENEMY_MAX_ENGAGED


## An enemy's attack: its tell (it stands still, turning after its victim until ENEMY_AIM_LOCK
## before the strike, then locked), then it lands (or throws), then it recovers and waits. The
## strike is judged from where its tell was drawn (`tell_from`, `aim`), so what the snow shows
## at the end is exactly what it hits (fight_v2 review 1). Only a couple wind up at once, their
## starts a little apart, so each reads.
static func _attack(s: GameState, e: Dictionary, def: Dictionary, foe: Dictionary, dt: float, events: Array) -> void:
	var t: float = e.bite_t
	e.bite_cd = maxf(0.0, e.bite_cd - dt)
	var strike: float = def.tell + (Balance.ENEMY_LUNGE if def.shape == "wedge" else 0.0)
	if t < 0.0:
		if e.bite_cd > 0.0 or e.pos.distance_to(foe.pos) > def.hold + 0.4:
			return
		if not _may_wind_up(s, def, foe.id):
			return
		e.bite_t = 0.0
		e.victim = foe.id
		e.aim = foe.pos
		e.tell_from = e.pos
		s.wolf_windup_at = s.time
		events.append({"type": "wolf_windup", "wolf": e.id, "kind": e.kind, "pos": e.pos, "aim": e.aim})
		return
	if def.shape != "ring" and t < strike - lock_of(def):
		var victim := _victim_of(s, e)
		if not victim.is_empty():
			e.aim = victim.pos
	e.bite_t = t + dt
	if t < strike and e.bite_t >= strike:
		match def.shape:
			"wedge":
				_wedge_lands(s, e, def, events)
			"ring":
				_ring_lands(s, e, def, events)
			"shot":
				var d: float = e.pos.distance_to(e.aim)
				s.enemy_shots.append({"wolf": e.id, "from": e.pos, "to": e.aim, "in": d / Balance.ENEMY_SHOT_SPEED, "damage": e.damage, "reach": def.reach})
				events.append({"type": "enemy_throw", "wolf": e.id, "from": e.pos, "to": e.aim, "flight": d / Balance.ENEMY_SHOT_SPEED})
	if e.bite_t >= strike + def.recover:
		e.bite_t = -1.0
		e.bite_cd = maxf(0.0, def.cooldown - def.recover)


## How long before its strike a kind's aim locks.
static func lock_of(def: Dictionary) -> float:
	return def.get("lock", Balance.ENEMY_AIM_LOCK)


## A wind-up may start if the global limits allow it and, for a melee one, nobody else is winding
## up against the same defender or struck them less than ENEMY_WINDUP_STAGGER ago.
static func _may_wind_up(s: GameState, def: Dictionary, victim: int) -> bool:
	if s.time - s.wolf_windup_at < Balance.WOLF_WINDUP_GAP:
		return false
	if def.shape != "shot":
		for w in s.wolves:
			var d2: Dictionary = Balance.ENEMIES[w.kind]
			if w.bite_t < 0.0 or w.victim != victim or d2.shape == "shot":
				continue
			if w.bite_t < d2.tell + (Balance.ENEMY_LUNGE if d2.shape == "wedge" else 0.0) + Balance.ENEMY_WINDUP_STAGGER:
				return false
	var melee := 0
	var shots := 0
	for w in s.wolves:
		var d2: Dictionary = Balance.ENEMIES[w.kind]
		var t: float = w.bite_t
		if t < 0.0 or t >= d2.tell + Balance.ENEMY_LUNGE:
			continue
		if d2.shape == "shot":
			shots += 1
		else:
			melee += d2.weight
	if def.shape == "shot":
		return shots < Balance.ENEMY_MAX_SHOT_WINDUP
	return melee + def.weight <= Balance.ENEMY_MAX_MELEE_WINDUP


## Whether `pos` stands inside an attack's wedge: within `reach` of `from` and inside `arc`
## degrees about the line to `aim` (the shape its tell draws).
static func in_wedge(pos: Vector2, from: Vector2, aim: Vector2, reach: float, arc: float) -> bool:
	var to := pos - from
	var facing := aim - from
	if to.length() > reach:
		return false
	return to.length() < 0.01 or facing.length() < 0.01 or absf(rad_to_deg(facing.angle_to(to))) <= arc / 2.0


## A bite or swipe lands on its victim if it's still inside the wedge its tell showed.
static func _wedge_lands(s: GameState, e: Dictionary, def: Dictionary, events: Array) -> void:
	var victim := _victim_of(s, e)
	var hit := false
	if not victim.is_empty():
		hit = in_wedge(victim.pos, e.get("tell_from", e.pos), e.aim, def.reach, def.arc)
		if hit:
			_hurt(s, victim, e.damage, events)
	events.append({"type": "wolf_bite", "wolf": e.id, "kind": e.kind, "victim": e.victim, "hit": hit, "pos": victim.get("pos", e.aim)})


## A troll's slam hits every defender inside its ring.
static func _ring_lands(s: GameState, e: Dictionary, def: Dictionary, events: Array) -> void:
	var victims := []
	var centre: Vector2 = e.get("tell_from", e.pos)
	for foe in _defenders(s):
		if foe.pos.distance_to(centre) <= def.reach:
			_hurt(s, foe, e.damage, events)
			victims.append(foe.id)
	events.append({"type": "wolf_bite", "wolf": e.id, "kind": e.kind, "victim": e.victim, "hit": not victims.is_empty(), "pos": e.pos, "slam": true, "victims": victims})


## Thrown shards land where they were aimed: whoever is still that close is hit.
static func _land_enemy_shots(s: GameState, dt: float, events: Array) -> void:
	for shot in s.enemy_shots.duplicate():
		shot.in -= dt
		if shot.in > 0.0:
			continue
		s.enemy_shots.erase(shot)
		var victim := -2
		for foe in _defenders(s):
			if foe.pos.distance_to(shot.to) <= shot.reach:
				_hurt(s, foe, shot.damage, events)
				victim = foe.id
				break
		events.append({"type": "shard_landed", "wolf": shot.wolf, "pos": shot.to, "hit": victim != -2, "victim": victim})


## Meagan and the guards who can be hurt: {id (-1 for Meagan), pos}.
static func _defenders(s: GameState) -> Array:
	var out := []
	if not s.meagan_injured:
		out.append({"id": -1, "pos": s.meagan_pos})
	for jan in _guards(s):
		if not jan.ko:
			out.append({"id": jan.id, "pos": jan.pos})
	return out


static func _victim_of(s: GameState, e: Dictionary) -> Dictionary:
	for foe in _defenders(s):
		if foe.id == e.victim:
			return foe
	return {}


static func _hurt(s: GameState, foe: Dictionary, damage: float, events: Array) -> void:
	if foe.id < 0:
		s.meagan_hp -= damage
		if s.meagan_hp <= 0.0 and not s.meagan_injured:
			s.meagan_hp = 0.0
			s.meagan_injured = true
			s.meagan_down_at = s.time
			events.append({"type": "meagan_injured", "up_in": Balance.MEAGAN_DOWN_TIME})
		return
	for guard in _guards(s):
		if guard.id == foe.id:
			guard.hp -= damage
			if guard.hp <= 0.0:
				guard.hp = 0.0
				guard.ko = true
				events.append({"type": "guard_down", "jan": guard.id})
	# Whoever hit lands a hit: it keeps at the fight.
	for e in s.wolves:
		if e.victim == foe.id and e.bite_t >= 0.0:
			e.fight_for = 0.0


## Enemies at their target step apart when too close, so a pack spreads out round it: about
## ENEMY_GAP of a body width between bodies (fight_v2 review 1). One winding up takes its tell
## along.
static func _spread(s: GameState, dt: float) -> void:
	var pack := s.wolves.filter(func(w): return (w.mode == "fight" or w.mode == "jans") and w.hp > 0.0)
	var most := Balance.WOLF_SPEED * dt
	for i in pack.size():
		for j in range(i + 1, pack.size()):
			var a: Dictionary = pack[i]
			var b: Dictionary = pack[j]
			var spacing := spacing_of(a.kind, b.kind)
			var apart: Vector2 = a.pos - b.pos
			var d := apart.length()
			if d >= spacing:
				continue
			var dir := apart / d if d > 0.001 else Vector2.RIGHT.rotated(float(a.id * 7 + b.id * 13))
			var step := minf((spacing - d) / 2.0, most)
			_shift(s, a, dir * step)
			_shift(s, b, -dir * step)


## Moves an enemy by `by`, inside the world, and its tell with it if it's winding up.
static func _shift(s: GameState, e: Dictionary, by: Vector2) -> void:
	var was: Vector2 = e.pos
	e.pos = (e.pos + by).clamp(s.bounds.position, s.bounds.end)
	if e.bite_t >= 0.0 and e.has("tell_from"):
		e.tell_from += e.pos - was


## How far apart two enemies' middles keep: half of each one's width, plus the gap.
static func spacing_of(a: String, b: String) -> float:
	var wa: float = Balance.ENEMIES[a].width
	var wb: float = Balance.ENEMIES[b].width
	return (wa + wb) / 2.0 * (1.0 + Balance.ENEMY_GAP)


## The nearest defender within `range`, as {id, pos}, or {}.
static func _nearest_foe(s: GameState, pos: Vector2, range: float) -> Dictionary:
	var best := {}
	var best_d := range
	for foe in _defenders(s):
		var d: float = pos.distance_to(foe.pos)
		if d <= best_d:
			best = foe
			best_d = d
	return best


static func _working_site_near(s: GameState, pos: Vector2) -> int:
	for i in s.sites.size():
		if _job_at_site(s, i) == "" or Economy.site_jans(s, i) == 0:
			continue
		if pos.distance_to(MapData.site_pos(s, i)) <= Balance.WOLF_DETOUR_RANGE:
			return i
	return -1


static func _job_at_site(s: GameState, site: int) -> String:
	for job in ["chop", "hunt", "build"]:
		if Balance.JOBS[job].building == s.sites[site].building:
			return job
	return ""


# ---------- Outposts ----------

## An outpost's defenders sleep until she comes within its alert radius, or one is hurt; then
## the whole outpost is awake until she's gone beyond its leash.
static func _outpost_awake(s: GameState, e: Dictionary) -> bool:
	var post: Dictionary = s.outposts[e.outpost]
	var near := s.meagan_pos.distance_to(post.pos) <= Balance.OUTPOST_ALERT
	if (near or e.hp < e.max_hp) and not post.awake:
		post.awake = true
		post.woke_at = s.time
	elif s.meagan_pos.distance_to(post.pos) > Balance.OUTPOST_LEASH or s.meagan_injured:
		post.awake = false
	return post.awake


## An outpost with no defenders left is cleared: its reward, once.
static func _check_outposts(s: GameState, events: Array) -> void:
	for i in s.outposts.size():
		var post: Dictionary = s.outposts[i]
		if post.cleared or s.wolves.any(func(w): return w.outpost == i):
			continue
		post.cleared = true
		var pay: Dictionary = post.pay
		if post.chest:
			s.chests.append({"pos": post.pos, "kind": "spoils", "rarity": "common", "tile": post.tile, "opened": false, "pay": pay})
		else:
			var caps := Economy.caps(s)
			for res in pay:
				s.piles[res] = minf(caps[res], s.piles[res] + pay[res])
		events.append({"type": "outpost_cleared", "outpost": i, "pos": post.pos, "pay": pay, "chest": post.chest, "chest_index": s.chests.size() - 1 if post.chest else -1})


## Wakes an outpost's defenders (and the town's guards stay home: they're leashed to their posts).
static func add_outpost(s: GameState, kind: String, pos: Vector2, tile: Vector2i, ring: int) -> void:
	var def: Dictionary = Balance.OUTPOSTS[kind]
	var p := minf(2.0, 1.0 + 0.15 * maxi(0, ring - 2))
	var pay := {}
	for res in def.pay:
		pay[res] = ceilf(def.pay[res] * p)
	var index := s.outposts.size()
	s.outposts.append({"kind": kind, "pos": pos, "tile": tile, "awake": false, "woke_at": -100.0, "cleared": false, "pay": pay, "chest": def.chest})
	var n := 0
	for kind2 in def.defenders:
		for k in def.defenders[kind2]:
			var at := pos + Vector2.RIGHT.rotated(TAU * n / 6.0 + 0.3) * 1.6
			var e := make_enemy(s, kind2, at, at, p)
			e.outpost = index
			e.mode = "store"
			s.wolves.append(e)
			n += 1


# ---------- Guards and Meagan ----------

static func _guards(s: GameState) -> Array:
	return s.jans.filter(func(j): return j.job == "guard")


## Where guard number `i` of `n` waits around the furnace.
static func guard_post(i: int, n: int) -> Vector2:
	var angle := TAU * i / maxi(n, 1)
	# The furnace never moves: it's the starting grid's plot 0.
	return MapData.START_SITES[0].pos + Vector2(cos(angle), sin(angle)) * Balance.GUARD_RING_RADIUS


static func _guards_return(s: GameState, dt: float) -> void:
	var guards := _guards(s)
	for i in guards.size():
		guards[i].pos = guards[i].pos.move_toward(guard_post(i, guards.size()), Balance.GUARD_SPEED * dt)


static func _guards_fight(s: GameState, dt: float, events: Array) -> void:
	var guards := _guards(s)
	var damage := Economy.guard_strike(s)
	for i in guards.size():
		var guard: Dictionary = guards[i]
		if guard.ko:
			continue
		guard.strike_in = maxf(0.0, guard.get("strike_in", 0.0) - dt)
		var post := guard_post(i, guards.size())
		# The nearest enemy it can see and may chase.
		var target := {}
		var best := Balance.GUARD_SIGHT
		for e in s.wolves:
			if e.mode == "leave" and e.carry.is_empty() or e.hp <= 0.0 or e.pos.distance_to(post) > Balance.GUARD_LEASH:
				continue
			var d: float = guard.pos.distance_to(e.pos)
			if d <= best:
				best = d
				target = e
		if target.is_empty():
			guard.pos = guard.pos.move_toward(post, Balance.GUARD_SPEED * dt)
			continue
		if guard.pos.distance_to(target.pos) > Balance.GUARD_RANGE:
			guard.pos = guard.pos.move_toward(target.pos, Balance.GUARD_SPEED * dt)
		elif guard.strike_in <= 0.0:
			guard.strike_in = Balance.GUARD_STRIKE_EVERY
			_damage(s, target, damage, guard.pos, 0.0, "guard", events)
			events.append({"type": "guard_strike", "jan": guard.id, "wolf": target.id, "pos": target.pos})


## Meagan fights on her own: snowballs at range, a stick sweep up close (up to 3 enemies in
## front), swapping with hysteresis (in at her reach, out beyond MELEE_EXIT_MULT of it); she
## keeps a target at least MEAGAN_TARGET_HOLD before turning to a nearer one, so her choice is
## predictable (fight_v2 review 1). Each attack lands its hit a moment later (_land_shots).
static func _meagan_fights(s: GameState, dt: float, events: Array) -> void:
	if s.meagan_injured:
		return
	s.meagan_attack_in = maxf(0.0, s.meagan_attack_in - dt)
	var w := Economy.meagan_weapon(s)
	var target := _meagan_target(s, w)
	var d := INF if target.is_empty() else s.meagan_pos.distance_to(target.pos)
	# The mode follows the nearest enemy, whichever she's aiming at.
	var nearest := _nearest_enemy(s, s.meagan_pos)
	var near_d := INF if nearest.is_empty() else s.meagan_pos.distance_to(nearest.pos)
	if near_d <= Balance.FIGHT_PAUSE_RANGE:
		s.meagan_fight_at = s.time
	if near_d <= w.reach:
		s.meagan_mode = "melee"
		s.meagan_melee_clear = 0.0
	elif s.meagan_mode == "melee":
		s.meagan_melee_clear = s.meagan_melee_clear + dt if near_d > w.reach * Balance.MELEE_EXIT_MULT else 0.0
		if s.meagan_melee_clear >= Balance.MEAGAN_MELEE_EXIT_TIME:
			s.meagan_mode = "ranged"
	var melee := s.meagan_mode == "melee"
	if melee and d > w.reach:
		# Up close she sweeps at whatever's nearest.
		target = nearest
		d = near_d
	if d > (w.reach if melee else w.range):
		return
	MeaganRules.set_activity(s, "fight", target.id, target.pos)
	if s.meagan_attack_in > 0.0:
		return
	s.meagan_attack_in = w.stick_every if melee else w.snow_every
	var flight := 0.0 if melee else d / Balance.SNOWBALL_SPEED
	s.shots.append({
		"wolf": target.id, "from": s.meagan_pos, "kind": s.meagan_mode, "aim": target.pos,
		"in": Balance.MEAGAN_MELEE_IMPACT if melee else Balance.MEAGAN_RANGED_RELEASE + flight,
		"damage": w.stick_damage if melee else w.snow_damage,
		"knock": w.knock if melee else Balance.MEAGAN_RANGED_KNOCK, "reach": w.reach,
	})
	events.append({"type": "meagan_attack", "mode": s.meagan_mode, "wolf": target.id, "pos": target.pos, "flight": flight})


## Her hits arrive. A snowball hits its wolf; the stick sweeps the up-to-3 nearest in its arc.
static func _land_shots(s: GameState, dt: float, events: Array) -> void:
	for shot in s.shots.duplicate():
		shot.in -= dt
		if shot.in > 0.0:
			continue
		s.shots.erase(shot)
		if shot.kind == "melee":
			var facing: Vector2 = shot.aim - s.meagan_pos
			# Exactly the arc the view draws (fight_v2 review 1).
			var hits := s.wolves.filter(func(e): return e.hp > 0.0 and in_wedge(e.pos, s.meagan_pos, shot.aim, shot.reach, Balance.STICK_ARC))
			hits.sort_custom(func(a, b): return a.pos.distance_to(s.meagan_pos) < b.pos.distance_to(s.meagan_pos))
			for e in hits.slice(0, Balance.STICK_TARGETS):
				_damage(s, e, shot.damage, s.meagan_pos, shot.knock, "melee", events)
			continue
		for e in s.wolves:
			if e.id == shot.wolf and e.hp > 0.0:
				_damage(s, e, shot.damage, shot.from, shot.knock, "ranged", events)


## Damage to an enemy: knocked back (as much as it takes), its theft interrupted, its outpost
## woken.
static func _damage(s: GameState, e: Dictionary, damage: float, from: Vector2, knock: float, kind: String, events: Array) -> void:
	# Caught recovering from its own strike, it takes more (review 3).
	var def: Dictionary = Balance.ENEMIES[e.kind]
	var exposed: bool = e.bite_t >= def.tell + (Balance.ENEMY_LUNGE if def.shape == "wedge" else 0.0)
	if exposed:
		damage *= Balance.RECOVERY_DAMAGE_MULT
	e.hp -= damage
	e.steal_t = 0.0 if not e.stolen else e.steal_t
	var away: Vector2 = e.pos - from
	var k: float = knock * Balance.ENEMIES[e.kind].knocked
	if away.length() > 0.001 and k > 0.0:
		_shift(s, e, away.normalized() * k)
	if e.outpost >= 0 and not s.outposts[e.outpost].awake:
		s.outposts[e.outpost].awake = true
		s.outposts[e.outpost].woke_at = s.time
	events.append({"type": "wolf_hit", "wolf": e.id, "kind": kind, "pos": e.pos, "from": from, "amount": damage, "exposed": exposed})


## Whether a fight keeps Meagan from working (gathering, storing, paying pads). [agreed 2026-10-20]
static func meagan_busy(s: GameState) -> bool:
	return s.time - s.meagan_fight_at < Balance.FIGHT_RESUME


## The nearest enemy worth fighting: awake, alive, not a robber running off empty-handed.
static func _nearest_enemy(s: GameState, pos: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for e in s.wolves:
		if not _worth_fighting(s, e, pos):
			continue
		var d: float = pos.distance_to(e.pos)
		if d < best_d:
			best = e
			best_d = d
	return best


static func _worth_fighting(s: GameState, e: Dictionary, pos: Vector2) -> bool:
	if e.hp <= 0.0 or (e.mode == "leave" and e.carry.is_empty()):
		return false
	return not (e.outpost >= 0 and not s.outposts[e.outpost].awake and pos.distance_to(e.pos) > Balance.OUTPOST_ALERT)


## Her target: the one she has, while it's still worth fighting and in range and she's held it
## less than MEAGAN_TARGET_HOLD; otherwise the nearest.
static func _meagan_target(s: GameState, w: Dictionary) -> Dictionary:
	for e in s.wolves:
		if e.id != s.meagan_foe:
			continue
		var reach: float = w.reach if s.meagan_mode == "melee" else w.range
		if _worth_fighting(s, e, s.meagan_pos) and s.meagan_pos.distance_to(e.pos) <= reach \
				and s.time - s.meagan_foe_at < Balance.MEAGAN_TARGET_HOLD:
			return e
	var best := _nearest_enemy(s, s.meagan_pos)
	if not best.is_empty() and best.id != s.meagan_foe:
		s.meagan_foe = best.id
		s.meagan_foe_at = s.time
	return best


## Kills drop Materials (and give back anything carried). [brief, agreed 2026-10-20]
static func _collect_dead(s: GameState, events: Array) -> void:
	var caps := Economy.caps(s)
	var any := false
	for e in s.wolves.duplicate():
		if e.hp > 0.0:
			continue
		s.wolves.erase(e)
		any = true
		var materials: float = Balance.ENEMIES[e.kind].loot
		s.piles.materials = minf(caps.materials, s.piles.materials + materials)
		for res in e.carry:
			s.piles[res] = minf(caps[res], s.piles[res] + e.carry[res])
		events.append({"type": "wolf_killed", "wolf": e.id, "kind": e.kind, "pos": e.pos, "food": 0.0, "materials": materials, "carry": e.carry})
	if any:
		_check_outposts(s, events)


## Knocked down, she gets up after a while with part of her HP, so a raid's thieves can still be
## caught (fight_v2 review 2).
static func _get_up(s: GameState, events: Array) -> void:
	if s.meagan_injured and s.time >= s.meagan_down_at + Balance.MEAGAN_DOWN_TIME:
		s.meagan_injured = false
		s.meagan_up_at = s.time
		s.meagan_hp = Balance.MEAGAN_HP * Balance.MEAGAN_GETUP_HP
		events.append({"type": "meagan_up"})


## Knocked-out guards get up and Meagan heals once the raid is over. [brief]
static func _attack_over(s: GameState, events: Array) -> void:
	for guard in _guards(s):
		guard.hp = Economy.guard_hp(s)
		guard.ko = false
	s.meagan_hp = Balance.MEAGAN_HP
	s.meagan_injured = false
	s.attacks_repelled += 1
	s.raid_on = false
	events.append({"type": "attack_over", "wave": s.wave})
