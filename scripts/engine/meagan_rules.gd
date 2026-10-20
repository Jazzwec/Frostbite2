class_name MeaganRules
extends RefCounted
## What happens around Meagan: hand-gathering straight into the Stockpile, paying build pads and
## gates from it, and thawing Jans. She has no bag (agreed 2026-10-20).

## Which of her activities shows when several happen in one tick.
const ACTIVITY_PRIORITY := {"": -1, "full": 0, "gather": 1, "build": 2, "fight": 3}


## Records what she's doing this tick, unless something more important already happened.
static func set_activity(s: GameState, activity: String, target: int, pos: Vector2) -> void:
	if ACTIVITY_PRIORITY[activity] < ACTIVITY_PRIORITY[s.meagan_activity]:
		return
	s.meagan_activity = activity
	s.meagan_target = target
	s.meagan_target_pos = pos


## She gathers automatically at the nearest resource node in range, straight into the Stockpile,
## and stops (a shrug) once its pile is full. [brief, no bag agreed 2026-10-20]
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
	var res: String = Balance.NODES[MapData.node_kind(s, nearest)].resource
	var room: float = Economy.caps(s)[res] - s.piles[res]
	var amount := minf(minf(Economy.gather_rate(s, res) * dt, s.nodes[nearest]), room)
	var pos := MapData.node_pos(s, nearest)
	if amount <= 0.0:
		set_activity(s, "full", nearest, pos)
		return
	s.piles[res] += amount
	s.gathered[res] += amount
	s.nodes[nearest] -= amount
	set_activity(s, "gather", nearest, pos)


## Every node grows back steadily, full again `regrow` seconds after being emptied. [brief]
static func regrow(s: GameState, dt: float) -> void:
	for i in s.node_defs.size():
		var def: Dictionary = Balance.NODES[MapData.node_kind(s, i)]
		s.nodes[i] = minf(def.stock, s.nodes[i] + def.stock / def.regrow * dt)


## A build pad or gate she stands on takes what it needs from the Stockpile. [brief, Stockpile
## agreed 2026-10-19, no bag 2026-10-20]
static func pay_pads(s: GameState, dt: float, events: Array) -> void:
	if s.meagan_injured:
		return
	var budget := Economy.pay_rate(s) * dt
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


## Moves what `need` still lacks into `progress` from the Stockpile, within the tick's budget.
## Returns the budget left.
static func pay(s: GameState, need: Dictionary, progress: Dictionary, budget: float, activity: String, target: int, pos: Vector2) -> float:
	for res in need:
		var have: float = progress.get(res, 0.0)
		var give := minf(minf(need[res] - have, s.piles[res]), budget)
		if give > 0.0:
			s.piles[res] -= give
			progress[res] = have + give
			budget -= give
			set_activity(s, activity, target, pos)
	return budget


static func is_paid(need: Dictionary, progress: Dictionary) -> bool:
	for res in need:
		if progress.get(res, 0.0) < need[res] - 0.0001:
			return false
	return true


## Pays a site from the Stockpile.
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
