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
	if s.arrivals.size() >= Balance.ARRIVAL_MAX_WAITING:
		return
	var free := []
	for i in MapData.ARRIVAL_SPOTS.size():
		if not s.arrivals.any(func(a): return a.spot == i):
			free.append(i)
	if free.is_empty():
		return
	var spot: int = free[rng.randi_range(0, free.size() - 1)]
	var arrival := {"id": s.new_id(), "spot": spot}
	s.arrivals.append(arrival)
	events.append({"type": "arrival", "arrival": arrival.id, "pos": MapData.ARRIVAL_SPOTS[spot]})


## Jans eat from the Stockpile. With none left they're hungry and slower. [brief]
static func eat(s: GameState, dt: float) -> void:
	var eaten := Economy.food_eaten_per_second(s) * dt
	if s.piles.food >= eaten:
		s.piles.food -= eaten
		s.hungry = false
	else:
		s.piles.food = 0.0
		s.hungry = not s.jans.is_empty()




## Idle Jans go first, then workers, guards last.
static func pick_jan_to_lose(s: GameState, job := "") -> Dictionary:
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
