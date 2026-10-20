class_name Combat
extends RefCounted
## Wolf attacks. [brief] Packs come from the edge to the furnace, detour to working Jans,
## and stop to fight guards or Meagan. Everyone autofights whatever is in range.


static func update(s: GameState, dt: float, rng: RandomNumberGenerator, events: Array) -> void:
	_schedule(s, rng, events)
	if s.wolves.is_empty():
		_guards_return(s, dt)
		return
	for wolf in s.wolves.duplicate():
		_wolf(s, wolf, dt, events)
	_spread(s, dt)
	_guards_fight(s, dt)
	_meagan_fights(s, dt)
	_collect_dead(s, events)
	if s.wolves.is_empty():
		_attack_over(s, events)


static func _schedule(s: GameState, rng: RandomNumberGenerator, events: Array) -> void:
	if s.attack_at < 0.0:
		if Economy.furnace_level(s) >= Balance.ATTACK_MIN_FURNACE_LEVEL:
			s.attack_at = s.time + rng.randf_range(Balance.ATTACK_GAP_MIN, Balance.ATTACK_GAP_MAX)
		return
	if not s.wolves.is_empty():
		return
	# A Watchtower spots them coming. [brief] Not while a blizzard would hold them off anyway.
	var warning := Economy.attack_warning(s)
	if warning > 0.0 and not s.attack_warned and not s.blizzard_active and s.time >= s.attack_at - warning:
		s.attack_warned = true
		events.append({"type": "attack_warning", "starts_in": maxf(s.attack_at - s.time, 0.0)})
	if s.time < s.attack_at:
		return
	if s.blizzard_active:
		s.attack_at = s.blizzard_ends_at + 30.0
		s.attack_warned = false
		return
	spawn_pack(s, rng, events)
	s.attack_warned = false
	s.attack_at = s.time + rng.randf_range(Balance.ATTACK_GAP_MIN, Balance.ATTACK_GAP_MAX)


static func spawn_pack(s: GameState, rng: RandomNumberGenerator, events: Array, count := -1) -> void:
	if count < 0:
		count = rng.randi_range(Balance.WOLF_PACK_MIN, Balance.WOLF_PACK_MAX)
	var home: Vector2 = s.wolf_spawns[rng.randi_range(0, s.wolf_spawns.size() - 1)]
	var scale := Economy.wolf_scale(s)
	for i in count:
		var offset := Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))
		var pos := (home + offset).clamp(s.bounds.position, s.bounds.end)
		s.wolves.append({
			"id": s.new_id(), "pos": pos, "home": home,
			"hp": Balance.WOLF_HP * scale, "max_hp": Balance.WOLF_HP * scale,
			"damage": Balance.WOLF_DAMAGE_PER_SECOND * scale, "loot_scale": scale,
			"mode": "furnace", "target": -1, "scare_timer": 0.0, "scared": false,
		})
	events.append({"type": "wolves_arrived", "count": count, "pos": home})


static func _wolf(s: GameState, wolf: Dictionary, dt: float, events: Array) -> void:
	if wolf.mode == "leave":
		wolf.pos = wolf.pos.move_toward(wolf.home, Balance.WOLF_SPEED * dt)
		if wolf.pos.distance_to(wolf.home) < 0.5:
			s.wolves.erase(wolf)
			events.append({"type": "wolf_left", "wolf": wolf.id})
		return

	# Fight the nearest guard or Meagan in range.
	var foe := _nearest_foe(s, wolf.pos)
	if not foe.is_empty():
		wolf.mode = "fight"
		# Hold just outside the foe, closing in or backing off; _spread() fans the pack out round them.
		var foe_pos: Vector2 = s.meagan_pos if foe.kind == "meagan" else foe.jan.pos
		var away: Vector2 = wolf.pos - foe_pos
		var dir := away.normalized() if away.length() > 0.001 else Vector2.RIGHT.rotated(float(wolf.id))
		wolf.pos = wolf.pos.move_toward(foe_pos + dir * Balance.WOLF_FIGHT_DISTANCE, Balance.WOLF_SPEED * dt)
		# Where it's facing, for its view.
		wolf.foe_pos = foe_pos
		if foe.kind == "meagan":
			s.meagan_hp -= wolf.damage * dt
			if s.meagan_hp <= 0.0 and not s.meagan_injured:
				s.meagan_hp = 0.0
				s.meagan_injured = true
				events.append({"type": "meagan_injured"})
		else:
			var guard: Dictionary = foe.jan
			guard.hp -= wolf.damage * dt
			if guard.hp <= 0.0:
				guard.hp = 0.0
				guard.ko = true
				events.append({"type": "guard_down", "jan": guard.id})
		return
	if wolf.mode == "fight":
		wolf.mode = "furnace"

	# Detour to working Jans it passes. Each wolf scares at most one.
	if not wolf.scared and wolf.mode == "furnace":
		var site := _working_site_near(s, wolf.pos)
		if site >= 0:
			wolf.mode = "jans"
			wolf.target = site
	if wolf.mode == "jans":
		var target: int = wolf.target
		var job := _job_at_site(s, target)
		if job == "" or Economy.job_count(s, job) == 0:
			wolf.mode = "furnace"
			wolf.scare_timer = 0.0
		else:
			var site_pos := MapData.site_pos(s, target)
			if wolf.pos.distance_to(site_pos) > Balance.WOLF_REACH + MapData.SITE_HALF_SIZE:
				wolf.pos = wolf.pos.move_toward(site_pos, Balance.WOLF_SPEED * dt)
			else:
				wolf.scare_timer += dt
				if wolf.scare_timer >= Balance.WOLF_SCARE_TIME:
					var jan := WorldEvents.pick_jan_to_lose(s, job)
					s.jans.erase(jan)
					s.lost_total += 1
					wolf.scared = true
					wolf.mode = "furnace"
					events.append({"type": "jan_scared", "jan": jan.id, "job": job, "pos": site_pos})
			return

	# Head for the furnace and break through.
	var furnace := MapData.site_pos(s, 0)
	if wolf.pos.distance_to(furnace) > Balance.FURNACE_REACH + MapData.FURNACE_RADIUS:
		wolf.pos = wolf.pos.move_toward(furnace, Balance.WOLF_SPEED * dt)
		return
	s.piles.wood *= 1.0 - Balance.BREAKTHROUGH_WOOD
	s.piles.food *= 1.0 - Balance.BREAKTHROUGH_FOOD
	s.heat *= 1.0 - Balance.BREAKTHROUGH_HEAT
	var scared := 0
	for i in Balance.BREAKTHROUGH_JANS:
		var non_guards := s.jans.filter(func(j): return j.job != "guard")
		if non_guards.is_empty():
			break
		var jan := WorldEvents.pick_jan_to_lose(s)
		s.jans.erase(jan)
		s.lost_total += 1
		scared += 1
	wolf.mode = "leave"
	events.append({"type": "breakthrough", "wolf": wolf.id, "jans": scared, "pos": furnace})


## Wolves at their target (fighting, or menacing a work site) step apart when too close, so the
## pack spreads out round it. Travelling wolves aren't spread, so a pack still meets its foes
## together. Each pair shares the step; wolves on the same spot part in a direction set by their ids.
static func _spread(s: GameState, dt: float) -> void:
	var pack := s.wolves.filter(func(w): return (w.mode == "fight" or w.mode == "jans") and w.hp > 0.0)
	var most := Balance.WOLF_SPEED * dt
	for i in pack.size():
		for j in range(i + 1, pack.size()):
			var a: Dictionary = pack[i]
			var b: Dictionary = pack[j]
			var apart: Vector2 = a.pos - b.pos
			var d := apart.length()
			if d >= Balance.WOLF_SPACING:
				continue
			var dir := apart / d if d > 0.001 else Vector2.RIGHT.rotated(float(a.id * 7 + b.id * 13))
			var step := minf((Balance.WOLF_SPACING - d) / 2.0, most)
			a.pos = (a.pos + dir * step).clamp(s.bounds.position, s.bounds.end)
			b.pos = (b.pos - dir * step).clamp(s.bounds.position, s.bounds.end)


static func _nearest_foe(s: GameState, pos: Vector2) -> Dictionary:
	var best := {}
	var best_d := Balance.WOLF_ENGAGE_RANGE
	if not s.meagan_injured:
		var d := pos.distance_to(s.meagan_pos)
		if d <= best_d:
			best = {"kind": "meagan"}
			best_d = d
	for jan in s.jans:
		if jan.job != "guard" or jan.ko:
			continue
		var d: float = pos.distance_to(jan.pos)
		if d <= best_d:
			best = {"kind": "guard", "jan": jan}
			best_d = d
	return best


static func _working_site_near(s: GameState, pos: Vector2) -> int:
	for job in ["chop", "hunt", "build"]:
		if Economy.job_count(s, job) == 0:
			continue
		var i := MapData.site_of_building(s.sites, Balance.JOBS[job].building)
		if i >= 0 and pos.distance_to(MapData.site_pos(s, i)) <= Balance.WOLF_DETOUR_RANGE:
			return i
	return -1


static func _job_at_site(s: GameState, site: int) -> String:
	for job in ["chop", "hunt", "build"]:
		if Balance.JOBS[job].building == s.sites[site].building:
			return job
	return ""


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


static func _guards_fight(s: GameState, dt: float) -> void:
	var damage := Economy.guard_damage(s)
	for guard in _guards(s):
		if guard.ko:
			continue
		var target := _nearest_wolf(s, guard.pos)
		if target.is_empty():
			continue
		if guard.pos.distance_to(target.pos) > Balance.GUARD_RANGE:
			guard.pos = guard.pos.move_toward(target.pos, Balance.GUARD_SPEED * dt)
		else:
			target.hp -= damage * dt


static func _meagan_fights(s: GameState, dt: float) -> void:
	if s.meagan_injured:
		return
	var target := _nearest_wolf(s, s.meagan_pos)
	if not target.is_empty() and s.meagan_pos.distance_to(target.pos) <= Balance.MEAGAN_ATTACK_RANGE:
		target.hp -= Balance.MEAGAN_DAMAGE_PER_SECOND * dt
		MeaganRules.set_activity(s, "fight", target.id, target.pos)


static func _nearest_wolf(s: GameState, pos: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for wolf in s.wolves:
		if wolf.mode == "leave" or wolf.hp <= 0.0:
			continue
		var d: float = pos.distance_to(wolf.pos)
		if d < best_d:
			best = wolf
			best_d = d
	return best


## Every kill drops Food and Materials into the stores. [brief]
static func _collect_dead(s: GameState, events: Array) -> void:
	var caps := Economy.caps(s)
	for wolf in s.wolves.duplicate():
		if wolf.hp > 0.0:
			continue
		s.wolves.erase(wolf)
		var food: float = Balance.WOLF_LOOT.food * wolf.loot_scale
		var materials: float = Balance.WOLF_LOOT.materials * wolf.loot_scale
		s.piles.food = minf(caps.food, s.piles.food + food)
		s.piles.materials = minf(caps.materials, s.piles.materials + materials)
		events.append({"type": "wolf_killed", "wolf": wolf.id, "pos": wolf.pos, "food": food, "materials": materials})


## Knocked-out guards get up and Meagan heals once the last wolf is gone. [brief]
static func _attack_over(s: GameState, events: Array) -> void:
	for guard in _guards(s):
		guard.hp = Balance.GUARD_HP
		guard.ko = false
	s.meagan_hp = Balance.MEAGAN_HP
	s.meagan_injured = false
	s.attacks_repelled += 1
	events.append({"type": "attack_over"})
