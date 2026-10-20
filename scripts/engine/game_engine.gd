class_name GameEngine
extends RefCounted
## Owns the GameState and runs the rules in fixed ticks. Scenes call the actions below and read
## `state`; they never change it directly. Things the scenes should react to queue up as events.

## Bumped when a save from an older version can't be read as it is.
## 2: the layout lives in the state; 3: tiles, gates and small furnaces; 4: Jans work at a
## producer; 5: chests, boons and gear; 6: camps, the frontier and dens; 7: no bag, gathering
## goes to the Stockpile; 8: no Sled Shed plot; 9: the tighter town layout; 10: global building
## levels, upgrades in `upgrades`; 11: a stockpile per opened tile, the Stockpile's level; 12: the
## bag is back; 13: Jans haul their work; 14: hypercasual fighting (2026-10-20).
const SAVE_VERSION := 14

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
	# The world's seed comes from the engine's seed without drawing from its rolls.
	var seeder := RandomNumberGenerator.new()
	seeder.seed = rng.seed ^ 0x5EED
	state = new_winter(seeder.randi())


## The start of a winter. [brief] Empty city, cold furnace; Furnace, Lumber Yard and Fishing Lodge at Lv 1.
static func new_winter(run_seed := 1) -> GameState:
	var s := GameState.new()
	WorldRules.start(s, run_seed)
	s.stockpiles.append({"pos": MapData.STOCKPILE_POS, "tile": Vector2i.ZERO})
	for def in MapData.START_SITES:
		var b: String = def.type
		s.sites.append({
			"type": b, "pos": def.pos, "building": b if def.built else "",
			"level": Balance.BUILDINGS[b].start if def.built else 0, "upgrading": false, "progress": {},
		})
	for node in MapData.START_NODES:
		s.node_defs.append({"kind": node.kind, "pos": node.pos})
		s.nodes.append(Balance.NODES[node.kind].stock)
	# The furnace starts full; keeping it burning is the goal. [agreed 2026-10-19]
	s.heat = Economy.heat_cap(s)
	return s


## A save: the whole state plus the random generator, as JSON text (Vector2s and ints kept).
func to_json() -> String:
	return JSON.stringify(JSON.from_native({
		"version": SAVE_VERSION,
		"state": state.to_dict(),
		# As text: a 64-bit state doesn't survive a JSON number.
		"rng_seed": str(rng.seed),
		"rng_state": str(rng.state),
	}))


## The engine saved by to_json(), or null if the text isn't a save this version can read.
static func from_json(text: String) -> GameEngine:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary or not json.data.has("type"):
		return null
	var data: Variant = JSON.to_native(json.data)
	if not data is Dictionary or int(data.get("version", 0)) != SAVE_VERSION or not data.get("state") is Dictionary:
		return null
	var e := GameEngine.new()
	e.state = GameState.from_dict(data.state)
	e.rng.seed = String(data.get("rng_seed", "0")).to_int()
	e.rng.state = String(data.get("rng_state", "0")).to_int()
	return e


## Runs whole ticks for `delta` seconds of real time. Long frames are capped, never caught up.
func advance(delta: float) -> void:
	# The world waits while she chooses what a chest gives. [agreed 2026-10-20]
	if paused or state.game_over or not state.offer.is_empty():
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
	MeaganRules.pay_pads(s, dt, _events)
	MeaganRules.store(s, dt)
	MeaganRules.rescue(s, _events)
	TreasureRules.open_near(s, rng, _events)
	_feed_furnace(dt)
	_burn(dt)
	if s.heat <= 0.0:
		# The fire is out: the winter is over. [agreed 2026-10-19]
		s.game_over = true
		_events.append({"type": "game_over", "time": s.time})
		return
	_auto_assign(dt)
	WorldEvents.arrivals(s, dt, rng, _events)
	WorldEvents.blizzard(s, rng, _events)
	Combat.update(s, dt, rng, _events)


## While auto-assign is on, Jans are rebalanced every few seconds. [brief]
func _auto_assign(dt: float) -> void:
	var s := state
	if not s.auto_assign:
		return
	s.auto_assign_in -= dt
	if s.auto_assign_in > 0.0:
		return
	s.auto_assign_in = Balance.AUTO_ASSIGN_EVERY
	if JobRules.rebalance(s) > 0:
		_events.append({"type": "jobs_changed"})


## Jans' output reaches the store when they carry it to a stockpile. [agreed 2026-10-20]
func _produce(dt: float) -> void:
	CarryRules.haul(state, dt, _events)


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
	return not state.meagan_injured and not state.game_over and state.offer.is_empty()


## She takes boon `index` of the open boon chest's offer.
func choose_boon(index: int) -> bool:
	return TreasureRules.choose_boon(state, index, _events)


## She equips the offered gear, or leaves it and keeps what she has.
func choose_gear(equip: bool) -> bool:
	return TreasureRules.choose_gear(state, equip, _events)


## She's been sent to thaw this frozen Jan.
func target_arrival(arrival_id: int) -> void:
	state.rescue_target = arrival_id


## Starts building what a plot holds (the game decides which building; agreed 2026-10-20).
func start_construction(site_index: int) -> bool:
	var site: Dictionary = state.sites[site_index]
	if site.building != "" or not Economy.is_unlocked(state, site.type):
		return false
	site.building = site.type
	site.level = 0
	site.upgrading = true
	site.progress = {}
	_events.append({"type": "site_started", "site": site_index, "building": site.building})
	return true


## She's chosen to open the tile behind gate `i`: standing on its pad now pays for its small
## furnace. [agreed 2026-10-20]
func start_gate(gate_index: int) -> bool:
	if gate_index < 0 or gate_index >= state.gates.size() or state.gates[gate_index].paying:
		return false
	state.gates[gate_index].paying = true
	_events.append({"type": "gate_started", "gate": gate_index})
	return true


## Starts the next level of a built building; Meagan delivers what it needs.
func start_upgrade(site_index: int) -> bool:
	var site: Dictionary = state.sites[site_index]
	if site.building == "" or site.level < 1:
		return false
	return start_upgrade_of(site.building, site_index)


## Starts the next level of `building`, shared by all its plots (agreed 2026-10-20): it can be paid
## on any of their pads, and raises them all.
func start_upgrade_of(building: String, site_index := -1) -> bool:
	if state.upgrades.has(building) or Economy.level(state, building) < 1:
		return false
	if Economy.level(state, building) >= Balance.BUILDINGS[building].max:
		return false
	state.upgrades[building] = {}
	for i in state.sites.size():
		var site: Dictionary = state.sites[i]
		if site.building == building and site.level >= 1:
			site.upgrading = true
			if site_index < 0:
				site_index = i
	_events.append({"type": "site_started", "site": site_index, "building": building})
	return true


## Puts one more Jan on `job`: an idle one first, else one from the job most over its share.
## Whether the auto-assign switch is available yet. [brief] Furnace Lv 4.
func can_auto_assign() -> bool:
	return Economy.furnace_level(state) >= Balance.AUTO_ASSIGN_FURNACE_LEVEL


## Turns auto-assign on (it rebalances straight away) or off.
func set_auto_assign(on: bool) -> bool:
	if on and not can_auto_assign():
		return false
	state.auto_assign = on
	state.auto_assign_in = 0.0
	return true


## The player puts a Jan on `job` by hand (which switches auto-assign off). [brief] He goes to
## the producer with the most room; with every one full, nothing happens.
func add_to_job(job: String) -> bool:
	if not Economy.job_has_room(state, job):
		return false
	state.auto_assign = false
	var jan := _spare_jan(job)
	if jan.is_empty() or not JobRules.assign(state, jan, job):
		return false
	if job == "guard":
		jan.hp = Balance.GUARD_HP
		jan.ko = false
		jan.pos = MapData.site_pos(state, MapData.site_of_building(state.sites, "barracks"))
	_events.append({"type": "jobs_changed"})
	return true


## The player puts a Jan at producer `i` by hand, from its building's sheet.
func add_to_site(i: int) -> bool:
	var job := Economy.site_job(state.sites[i].building)
	if job == "" or job == "guard" or Economy.site_jans(state, i) >= Economy.site_slots(state, i):
		return false
	state.auto_assign = false
	var jan := _spare_jan(job, i)
	if jan.is_empty() or not JobRules.assign_to_site(state, jan, i):
		return false
	_events.append({"type": "jobs_changed"})
	return true


## Takes one Jan off producer `i`; he goes idle.
func remove_from_site(i: int) -> bool:
	state.auto_assign = false
	for k in range(state.jans.size() - 1, -1, -1):
		if state.jans[k].get("site", -1) == i:
			JobRules.assign(state, state.jans[k], "")
			_events.append({"type": "jobs_changed"})
			return true
	return false


## A Jan to put on `job`: an idle one first, else one from the job most over its share (not one
## already at `site`).
func _spare_jan(job: String, site := -1) -> Dictionary:
	for j in state.jans:
		if j.job == "":
			return j
	var donor := ""
	var most := 0.0
	for other in Balance.JOB_SHARES:
		if other == job:
			continue
		var ratio: float = Economy.job_count(state, other) / Balance.JOB_SHARES[other]
		if ratio > most:
			most = ratio
			donor = other
	for j in state.jans:
		if donor != "" and j.job == donor and j.get("site", -1) != site:
			return j
	return {}


## Takes one Jan off `job` by hand; he goes idle (and auto-assign switches off). [brief]
func remove_from_job(job: String) -> bool:
	state.auto_assign = false
	for i in range(state.jans.size() - 1, -1, -1):
		if state.jans[i].job == job:
			JobRules.assign(state, state.jans[i], "")
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


## Fills the piles and the furnace.
func fill() -> void:
	var caps := Economy.caps(state)
	for res in Economy.PILE_KEYS:
		state.piles[res] = caps[res]
	state.fuel = Economy.fuel_cap(state)
	state.heat = Economy.heat_cap(state)
	var cap := Economy.bag_cap(state)
	state.bag = {"wood": cap / 2.0, "food": 0.0, "materials": cap / 2.0}


func force_blizzard() -> void:
	if state.blizzard_active:
		return
	state.blizzard_at = state.time + Balance.BLIZZARD_FORCED_DELAY
	state.blizzard_warned = true
	_events.append({"type": "blizzard_warning", "starts_in": Balance.BLIZZARD_FORCED_DELAY})


func spawn_wolves(count := -1) -> void:
	Combat.spawn_pack(state, rng, _events, count)


## Finishes a plot's construction, or its building's next level, straight away.
func dev_level_up(site_index: int) -> void:
	var site: Dictionary = state.sites[site_index]
	if site.building == "" or Economy.is_maxed(state, site_index):
		return
	if site.level == 0:
		MeaganRules.finish_construction(state, site_index, _events)
	else:
		MeaganRules.level_up(state, site.building, _events)


## Thaws a Jan beside Meagan straight away, if there's room.
func dev_add_jan() -> void:
	if state.jans.size() >= Economy.jan_cap(state):
		_events.append({"type": "no_room", "arrival": -1, "pos": state.meagan_pos})
		return
	var jan := {"id": state.new_id(), "job": "", "site": -1, "hp": Balance.GUARD_HP, "ko": false, "pos": state.meagan_pos}
	JobRules.assign(state, jan, Economy.neediest_job(state))
	var job: String = jan.job
	state.jans.append(jan)
	state.rescued_total += 1
	_events.append({"type": "thawed", "arrival": -1, "jan": jan.id, "job": job, "pos": state.meagan_pos})
