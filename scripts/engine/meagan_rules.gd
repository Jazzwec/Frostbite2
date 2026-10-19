class_name MeaganRules
extends RefCounted
## What happens around Meagan: hand-gathering, the bag ↔ building magnet, and thawing Jans.

## Which of her activities shows when several happen in one tick.
const ACTIVITY_PRIORITY := {"": -1, "full": 0, "gather": 1, "load": 2, "store": 2, "fuel": 3, "build": 3, "fight": 4}


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
	for i in MapData.RESOURCE_NODES.size():
		var d: float = s.meagan_pos.distance_to(MapData.RESOURCE_NODES[i].pos)
		if d <= nearest_d and s.nodes[i] > 0.0:
			nearest = i
			nearest_d = d
	if nearest < 0:
		return
	var def: Dictionary = Balance.NODES[MapData.RESOURCE_NODES[nearest].kind]
	var room := Economy.bag_cap(s) - Economy.bag_total(s)
	var amount := minf(minf(Balance.GATHER_RATE[def.resource] * dt, s.nodes[nearest]), room)
	var pos: Vector2 = MapData.RESOURCE_NODES[nearest].pos
	if amount <= 0.0:
		set_activity(s, "full", nearest, pos)
		return
	s.bag[def.resource] += amount
	s.nodes[nearest] -= amount
	set_activity(s, "gather", nearest, pos)


## Every node grows back steadily, full again `regrow` seconds after being emptied. [brief]
static func regrow(s: GameState, dt: float) -> void:
	for i in MapData.RESOURCE_NODES.size():
		var def: Dictionary = Balance.NODES[MapData.RESOURCE_NODES[i].kind]
		s.nodes[i] = minf(def.stock, s.nodes[i] + def.stock / def.regrow * dt)


## Resources jump between her bag and every building she stands near. Deliveries go first
## (furnace fuel, then construction, then food into the store), pick-ups after. [brief]
static func magnet(s: GameState, dt: float, events: Array) -> void:
	if s.meagan_injured:
		return
	var budget := Balance.MAGNET_PER_SECOND * dt
	for i in s.sites.size():
		if budget <= 0.0:
			return
		var site: Dictionary = s.sites[i]
		if site.building == "":
			continue
		if s.meagan_pos.distance_to(MapData.SITES[i].pos) > Balance.SITE_REACH:
			continue
		if i == 0:
			var into_fuel := minf(minf(s.bag.wood, Economy.fuel_cap(s) - s.fuel), budget)
			if into_fuel > 0.0:
				s.bag.wood -= into_fuel
				s.fuel += into_fuel
				budget -= into_fuel
				set_activity(s, "fuel", i, MapData.SITES[i].pos)
		if site.upgrading and s.meagan_pos.distance_to(MapData.pad_pos(i)) <= Balance.PAD_RADIUS:
			budget = _deliver_to_site(s, i, budget, events)
		var caps := Economy.caps(s)
		if Economy.pile_site(s, "food") == i:
			var into_store := minf(minf(s.bag.food, caps.food - s.piles.food), budget)
			if into_store > 0.0:
				s.bag.food -= into_store
				s.piles.food += into_store
				budget -= into_store
				set_activity(s, "store", i, MapData.SITES[i].pos)
		for res in ["wood", "materials"]:
			if Economy.pile_site(s, res) != i:
				continue
			var room := Economy.bag_cap(s) - Economy.bag_total(s)
			var take := minf(minf(s.piles[res], room), budget)
			if take > 0.0:
				s.piles[res] -= take
				s.bag[res] += take
				budget -= take
				set_activity(s, "load", i, MapData.SITES[i].pos)


static func _deliver_to_site(s: GameState, i: int, budget: float, events: Array) -> float:
	var site: Dictionary = s.sites[i]
	var need := Economy.site_cost(s, i)
	var done := true
	for res in need:
		var have: float = site.progress.get(res, 0.0)
		var give := minf(minf(need[res] - have, s.bag[res]), budget)
		if give > 0.0:
			s.bag[res] -= give
			site.progress[res] = have + give
			budget -= give
			set_activity(s, "build", i, MapData.SITES[i].pos)
		if site.progress.get(res, 0.0) < need[res] - 0.0001:
			done = false
	if done:
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
		var pos: Vector2 = MapData.ARRIVAL_SPOTS[a.spot]
		if s.meagan_pos.distance_to(pos) > Balance.RESCUE_RANGE:
			continue
		if s.jans.size() >= Economy.jan_cap(s):
			if s.rescue_target == a.id:
				s.rescue_target = -1
				events.append({"type": "no_room", "arrival": a.id, "pos": pos})
			continue
		var job := Economy.neediest_job(s)
		var jan := {"id": s.new_id(), "job": job, "hp": Balance.GUARD_HP, "ko": false, "pos": pos}
		s.jans.append(jan)
		s.arrivals.erase(a)
		s.rescued_total += 1
		if s.rescue_target == a.id:
			s.rescue_target = -1
		events.append({"type": "thawed", "arrival": a.id, "jan": jan.id, "job": job, "pos": pos})
