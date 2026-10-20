class_name MeaganRules
extends RefCounted
## What happens around Meagan: hand-gathering, the bag magnet (furnace, build pads, Stockpile),
## and thawing Jans.

## Which of her activities shows when several happen in one tick.
const ACTIVITY_PRIORITY := {"": -1, "full": 0, "gather": 1, "store": 2, "fuel": 3, "build": 3, "fight": 4}


## Records what she's doing this tick, unless something more important already happened.
static func set_activity(s: GameState, activity: String, target: int, pos: Vector2) -> void:
	if ACTIVITY_PRIORITY[activity] < ACTIVITY_PRIORITY[s.meagan_activity]:
		return
	s.meagan_activity = activity
	s.meagan_target = target
	s.meagan_target_pos = pos


## She gathers automatically at the nearest resource node in range, into her bag. [brief]
static func gather(s: GameState, dt: float) -> void:
	if s.meagan_injured:
		return
	var nearest := -1
	var nearest_d := Balance.GATHER_RANGE
	for i in s.node_defs.size():
		var d: float = s.meagan_pos.distance_to(MapData.node_pos(s, i))
		if d <= nearest_d and s.nodes[i] > 0.0:
			nearest = i
			nearest_d = d
	if nearest < 0:
		return
	var def: Dictionary = Balance.NODES[MapData.node_kind(s, nearest)]
	var room := Economy.bag_cap(s) - Economy.bag_total(s)
	var amount := minf(minf(Balance.GATHER_RATE[def.resource] * dt, s.nodes[nearest]), room)
	var pos := MapData.node_pos(s, nearest)
	if amount <= 0.0:
		set_activity(s, "full", nearest, pos)
		return
	s.bag[def.resource] += amount
	s.nodes[nearest] -= amount
	set_activity(s, "gather", nearest, pos)


## Every node grows back steadily, full again `regrow` seconds after being emptied. [brief]
static func regrow(s: GameState, dt: float) -> void:
	for i in s.node_defs.size():
		var def: Dictionary = Balance.NODES[MapData.node_kind(s, i)]
		s.nodes[i] = minf(def.stock, s.nodes[i] + def.stock / def.regrow * dt)


## Resources jump out of her bag where she stands: Wood into the furnace when she's near it,
## whatever a build pad needs (topped up from the Stockpile), and everything into the Stockpile
## on its pad. [brief, Stockpile agreed 2026-10-19]
static func magnet(s: GameState, dt: float, events: Array) -> void:
	if s.meagan_injured:
		return
	var budget := Balance.MAGNET_PER_SECOND * dt
	if s.meagan_pos.distance_to(MapData.site_pos(s, 0)) <= Balance.SITE_REACH:
		var into_fuel := minf(minf(s.bag.wood, Economy.fuel_cap(s) - s.fuel), budget)
		if into_fuel > 0.0:
			s.bag.wood -= into_fuel
			s.fuel += into_fuel
			budget -= into_fuel
			set_activity(s, "fuel", 0, MapData.site_pos(s, 0))
	for i in s.sites.size():
		if budget <= 0.0:
			return
		if s.sites[i].upgrading and s.meagan_pos.distance_to(MapData.pad_pos(s, i)) <= Balance.PAD_RADIUS:
			budget = _deliver_to_site(s, i, budget, events)
	# A gate she's chosen to open takes its cost the same way. [agreed 2026-10-20]
	for i in range(s.gates.size() - 1, -1, -1):
		var gate: Dictionary = s.gates[i]
		if budget > 0.0 and gate.paying and s.meagan_pos.distance_to(gate.pad) <= Balance.PAD_RADIUS:
			budget = pay(s, gate.cost, gate.progress, budget, "build", -1, gate.pos)
			if is_paid(gate.cost, gate.progress):
				WorldRules.open_tile(s, i, events)
	if s.meagan_pos.distance_to(MapData.stockpile_pad()) <= Balance.PAD_RADIUS:
		var caps := Economy.caps(s)
		for res in ["wood", "food", "materials"]:
			var into_store := minf(minf(s.bag[res], caps[res] - s.piles[res]), budget)
			if into_store > 0.0:
				s.bag[res] -= into_store
				s.piles[res] += into_store
				budget -= into_store
				set_activity(s, "store", -1, MapData.STOCKPILE_POS)


## Moves what `need` still lacks into `progress`, from her bag first, then from the Stockpile,
## within the tick's budget. Returns the budget left.
static func pay(s: GameState, need: Dictionary, progress: Dictionary, budget: float, activity: String, target: int, pos: Vector2) -> float:
	for res in need:
		for source in [s.bag, s.piles]:
			var have: float = progress.get(res, 0.0)
			var give := minf(minf(need[res] - have, source[res]), budget)
			if give > 0.0:
				source[res] -= give
				progress[res] = have + give
				budget -= give
				set_activity(s, activity, target, pos)
	return budget


static func is_paid(need: Dictionary, progress: Dictionary) -> bool:
	for res in need:
		if progress.get(res, 0.0) < need[res] - 0.0001:
			return false
	return true


## Pays a site from her bag first, then from the Stockpile.
static func _deliver_to_site(s: GameState, i: int, budget: float, events: Array) -> float:
	var site: Dictionary = s.sites[i]
	var need := Economy.site_cost(s, i)
	budget = pay(s, need, site.progress, budget, "build", i, MapData.site_pos(s, i))
	if is_paid(need, site.progress):
		site.level += 1
		site.upgrading = false
		site.progress = {}
		events.append({"type": "built" if site.level == 1 else "levelled", "site": i, "building": site.building, "level": site.level})
	return budget


## She thaws any frozen Jan she reaches. A full city leaves him frozen; the one she was sent to says so. [brief]
static func rescue(s: GameState, events: Array) -> void:
	if s.meagan_injured:
		return
	for a in s.arrivals.duplicate():
		var pos: Vector2 = a.pos
		if s.meagan_pos.distance_to(pos) > Balance.RESCUE_RANGE:
			continue
		if s.jans.size() >= Economy.jan_cap(s):
			if s.rescue_target == a.id:
				s.rescue_target = -1
				events.append({"type": "no_room", "arrival": a.id, "pos": pos})
			continue
		var jan := {"id": s.new_id(), "job": "", "site": -1, "hp": Balance.GUARD_HP, "ko": false, "pos": pos}
		JobRules.assign(s, jan, Economy.neediest_job(s))
		var job: String = jan.job
		s.jans.append(jan)
		s.arrivals.erase(a)
		s.rescued_total += 1
		if s.rescue_target == a.id:
			s.rescue_target = -1
		events.append({"type": "thawed", "arrival": a.id, "jan": jan.id, "job": job, "pos": pos})
