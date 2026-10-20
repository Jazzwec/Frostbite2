class_name WorldEvents
extends RefCounted
## Things that happen to the city on their own: arrivals, eating, blizzards.


## A frozen Jan turns up at a free spot on the edge every arrival_interval seconds. None come in a blizzard. [brief]
static func arrivals(s: GameState, dt: float, rng: RandomNumberGenerator, events: Array) -> void:
	if s.blizzard_active:
		return
	s.next_arrival_in -= dt
	if s.next_arrival_in > 0.0:
		return
	s.next_arrival_in = Economy.arrival_interval(s)
	# Camps' frozen Jans wait as well, but only single arrivals count towards the most at once.
	if s.arrivals.filter(func(a): return not a.get("camp", false)).size() >= Balance.ARRIVAL_MAX_WAITING:
		return
	# Spots move out with the frontier, so a spot is free when nobody waits on it.
	var free := []
	for i in s.arrival_spots.size():
		var spot: Vector2 = s.arrival_spots[i]
		if not s.arrivals.any(func(a): return a.pos.distance_to(spot) < 1.0):
			free.append(i)
	if free.is_empty():
		return
	var spot: int = free[rng.randi_range(0, free.size() - 1)]
	var arrival := {"id": s.new_id(), "spot": spot, "pos": s.arrival_spots[spot]}
	s.arrivals.append(arrival)
	events.append({"type": "arrival", "arrival": arrival.id, "pos": arrival.pos})


## Jans eat from the Stockpile. With none left they're hungry and slower, and after a grace
## they start leaving, idle ones first, one every so often, until Food has stayed up a while.
## [brief; leaving agreed 2026-10-20]
static func eat(s: GameState, dt: float, events := []) -> void:
	var eaten := Economy.food_eaten_per_second(s) * dt
	if s.piles.food >= eaten:
		s.piles.food -= eaten
		s.hungry = false
	else:
		s.piles.food = 0.0
		s.hungry = not s.jans.is_empty()
	if s.hungry:
		s.fed_t = 0.0
		s.starve_t += dt
		if s.starve_t < Balance.STARVE_GRACE:
			return
		s.starve_next -= dt
		if s.starve_next <= 0.0 and not s.jans.is_empty():
			s.starve_next = Balance.STARVE_LEAVE_EVERY
			var jan := pick_jan_to_lose(s)
			s.jans.erase(jan)
			s.lost_total += 1
			events.append({"type": "jan_starved", "jan": jan.id, "job": jan.job, "pos": jan.pos})
	elif s.starve_t > 0.0:
		s.fed_t = s.fed_t + dt if s.piles.food >= Balance.STARVE_FED else 0.0
		if s.fed_t >= Balance.STARVE_FED_FOR:
			s.starve_t = 0.0
			s.starve_next = 0.0




## Idle Jans go first, then workers, guards last.
static func pick_jan_to_lose(s: GameState, job := "", site := -1) -> Dictionary:
	if site >= 0:
		for jan in s.jans:
			if jan.get("site", -1) == site:
				return jan
	if job != "":
		for jan in s.jans:
			if jan.job == job:
				return jan
	for want in ["", "chop", "hunt", "build", "guard"]:
		for jan in s.jans:
			if jan.job == want:
				return jan
	return s.jans.back()


## Warned Economy.blizzard_warning() ahead (longer with a Watchtower), heat drain ×3 while it lasts, then the next one is 20 to 40 minutes later. [brief]
static func blizzard(s: GameState, rng: RandomNumberGenerator, events: Array) -> void:
	if s.blizzard_active:
		if s.time >= s.blizzard_ends_at:
			s.blizzard_active = false
			s.blizzard_warned = false
			s.blizzards_survived += 1
			s.blizzard_at = s.time + rng.randf_range(Balance.BLIZZARD_GAP_MIN, Balance.BLIZZARD_GAP_MAX)
			events.append({"type": "blizzard_end"})
		return
	if not s.blizzard_warned and s.time >= s.blizzard_at - Economy.blizzard_warning(s):
		s.blizzard_warned = true
		events.append({"type": "blizzard_warning", "starts_in": s.blizzard_at - s.time})
	if s.time >= s.blizzard_at:
		s.blizzard_active = true
		s.blizzard_ends_at = s.time + Balance.BLIZZARD_DURATION
		events.append({"type": "blizzard_start"})
