class_name GameEngine
extends RefCounted
## Owns the GameState and runs the rules in fixed ticks. Scenes call the actions below and read
## `state`; they never change it directly. Things the scenes should react to queue up as events.

var state: GameState
var rng := RandomNumberGenerator.new()
var paused := false

var _accumulator := 0.0
var _events: Array = []


func _init(seed_value := 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	state = new_winter()


## The start of a winter. [brief] Empty city, cold furnace; Furnace, Lumber Yard and Hunting Lodge at Lv 1.
static func new_winter() -> GameState:
	var s := GameState.new()
	for def in MapData.SITES:
		var b: String = def.fixed
		s.sites.append({"building": b, "level": Balance.BUILDINGS[b].start if b != "" else 0, "upgrading": false, "progress": {}})
	for node in MapData.RESOURCE_NODES:
		s.nodes.append(Balance.NODES[node.kind].stock)
	# The furnace starts full; keeping it burning is the goal. [agreed 2026-10-19]
	s.heat = Economy.heat_cap(s)
	return s


## Runs whole ticks for `delta` seconds of real time. Long frames are capped, never caught up.
func advance(delta: float) -> void:
	if paused or state.game_over:
		return
	_accumulator += minf(delta, Balance.MAX_ADVANCE)
	while _accumulator >= Balance.TICK:
		_accumulator -= Balance.TICK
		_tick(Balance.TICK)


func pause() -> void:
	paused = true
	_accumulator = 0.0


func resume() -> void:
	paused = false


func drain_events() -> Array:
	var out := _events
	_events = []
	return out


func _tick(dt: float) -> void:
	var s := state
	s.time += dt
	s.meagan_activity = ""
	_produce(dt)
	WorldEvents.eat(s, dt)
	MeaganRules.regrow(s, dt)
	MeaganRules.gather(s, dt)
	MeaganRules.magnet(s, dt, _events)
	MeaganRules.rescue(s, _events)
	_feed_furnace(dt)
	_burn(dt)
	if s.heat <= 0.0:
		# The fire is out: the winter is over. [agreed 2026-10-19]
		s.game_over = true
		_events.append({"type": "game_over", "time": s.time})
		return
	WorldEvents.arrivals(s, dt, rng, _events)
	WorldEvents.blizzard(s, rng, _events)
	Combat.update(s, dt, rng, _events)


## Jans' output goes into the Stockpile. [agreed 2026-10-19]
func _produce(dt: float) -> void:
	var caps := Economy.caps(state)
	for job in ["chop", "hunt", "build"]:
		var res: String = Balance.JOBS[job].resource
		var rate := Economy.job_rate(state, job)
		if rate > 0.0:
			state.piles[res] = minf(caps[res], state.piles[res] + rate * dt)


## The furnace tops itself up from the Stockpile's Wood. [agreed 2026-10-19]
func _feed_furnace(dt: float) -> void:
	var s := state
	var feed := minf(minf(s.piles.wood, Economy.fuel_cap(s) - s.fuel), Balance.FURNACE_FEED_PER_SECOND * dt)
	if feed > 0.0:
		s.piles.wood -= feed
		s.fuel += feed


## The furnace burns whatever delivered fuel it needs to stay full, then drains. [f1]
func _burn(dt: float) -> void:
	var s := state
	var drain := Economy.heat_drain(s) * dt
	var per_wood := Economy.heat_per_wood(s)
	var cap := Economy.heat_cap(s)
	var burn := minf(maxf(s.fuel, 0.0), maxf(cap - s.heat + drain, 0.0) / per_wood)
	s.fuel -= burn
	s.burn_rate = burn / dt
	s.heat = clampf(s.heat + burn * per_wood - drain, 0.0, cap)


# ---------- Actions ----------

## The scene reports where Meagan is every frame.
func set_meagan_position(pos: Vector2) -> void:
	state.meagan_pos = pos


func can_meagan_move() -> bool:
	return not state.meagan_injured and not state.game_over


## She's been sent to thaw this frozen Jan.
func target_arrival(arrival_id: int) -> void:
	state.rescue_target = arrival_id


## Turns an empty plot into a construction site for `building`.
func choose_building(site_index: int, building: String) -> bool:
	var site: Dictionary = state.sites[site_index]
	if site.building != "" or not Economy.buildable(state).has(building) or not Economy.is_unlocked(state, building):
		return false
	site.building = building
	site.level = 0
	site.upgrading = true
	site.progress = {}
	_events.append({"type": "site_started", "site": site_index, "building": building})
	return true


## Starts the next level of a built building; Meagan delivers what it needs.
func start_upgrade(site_index: int) -> bool:
	var site: Dictionary = state.sites[site_index]
	if site.building == "" or site.level < 1 or site.upgrading or Economy.is_maxed(state, site_index):
		return false
	site.upgrading = true
	site.progress = {}
	_events.append({"type": "site_started", "site": site_index, "building": site.building})
	return true


## Puts one more Jan on `job`: an idle one first, else one from the job most over its share.
func add_to_job(job: String) -> bool:
	if not Economy.job_open(state, job):
		return false
	var jan := {}
	for j in state.jans:
		if j.job == "":
			jan = j
			break
	if jan.is_empty():
		var donor := ""
		var most := 0.0
		for other in Balance.JOB_SHARES:
			if other == job:
				continue
			var ratio: float = Economy.job_count(state, other) / Balance.JOB_SHARES[other]
			if ratio > most:
				most = ratio
				donor = other
		if donor == "":
			return false
		for j in state.jans:
			if j.job == donor:
				jan = j
				break
	jan.job = job
	if job == "guard":
		jan.hp = Balance.GUARD_HP
		jan.ko = false
		jan.pos = MapData.SITES[MapData.site_of_building(state.sites, "barracks")].pos
	_events.append({"type": "jobs_changed"})
	return true


## Takes one Jan off `job`; he goes idle.
func remove_from_job(job: String) -> bool:
	for i in range(state.jans.size() - 1, -1, -1):
		if state.jans[i].job == job:
			state.jans[i].job = ""
			_events.append({"type": "jobs_changed"})
			return true
	return false


# ---------- Dev shortcuts (the dev panel and tests) ----------

func skip(seconds: float) -> void:
	var ticks := int(round(seconds / Balance.TICK))
	for i in ticks:
		if state.game_over:
			return
		_tick(Balance.TICK)


## Fills the piles and the furnace, and Meagan's bag with Wood and Materials.
func fill() -> void:
	var caps := Economy.caps(state)
	for res in Economy.PILE_KEYS:
		state.piles[res] = caps[res]
	state.fuel = Economy.fuel_cap(state)
	state.heat = Economy.heat_cap(state)
	var half := Economy.bag_cap(state) / 2.0
	state.bag = {"wood": half, "food": 0.0, "materials": half}


func force_blizzard() -> void:
	if state.blizzard_active:
		return
	state.blizzard_at = state.time + Balance.BLIZZARD_FORCED_DELAY
	state.blizzard_warned = true
	_events.append({"type": "blizzard_warning", "starts_in": Balance.BLIZZARD_FORCED_DELAY})


func spawn_wolves(count := -1) -> void:
	Combat.spawn_pack(state, rng, _events, count)


## Finishes the next level of a building (or its construction) straight away.
func dev_level_up(site_index: int) -> void:
	var site: Dictionary = state.sites[site_index]
	if site.building == "" or Economy.is_maxed(state, site_index):
		return
	site.level += 1
	site.upgrading = false
	site.progress = {}
	_events.append({"type": "built" if site.level == 1 else "levelled", "site": site_index, "building": site.building, "level": site.level})


## Thaws a Jan beside Meagan straight away, if there's room.
func dev_add_jan() -> void:
	if state.jans.size() >= Economy.jan_cap(state):
		_events.append({"type": "no_room", "arrival": -1, "pos": state.meagan_pos})
		return
	var job := Economy.neediest_job(state)
	var jan := {"id": state.new_id(), "job": job, "hp": Balance.GUARD_HP, "ko": false, "pos": state.meagan_pos}
	state.jans.append(jan)
	state.rescued_total += 1
	_events.append({"type": "thawed", "arrival": -1, "jan": jan.id, "job": job, "pos": state.meagan_pos})
