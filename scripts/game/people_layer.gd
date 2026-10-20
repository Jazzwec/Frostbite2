class_name PeopleLayer
extends Node3D
## Keeps a JanView for every frozen and rescued Jan in the engine state, and wolves too.
## Workers stand in front of their building, idle Jans round the furnace, guards where the engine puts them.

var _frozen := {}  # arrival id -> JanView
var _jans := {}  # jan id -> JanView
var _wolves := {}  # wolf id -> WolfView
var _chatter_in := 20.0
var _guard_foes := {}  # JanView -> id of the wolf he's fighting


func on_event(ev: Dictionary) -> void:
	match ev.type:
		"thawed":
			var view: JanView = _frozen.get(ev.arrival)
			_frozen.erase(ev.arrival)
			if view == null:
				view = _new_jan(Vector3(ev.pos.x, 0, ev.pos.y), false)
			view.thaw(ev.jan, Game.random_rescue_line())
			_jans[ev.jan] = view
		"jan_scared":
			var view: JanView = _jans.get(ev.jan)
			_jans.erase(ev.jan)
			if view:
				view.say("Wolf!!", 2.0)
				view.flee()


func refresh(s: GameState, delta: float) -> void:
	_sync_frozen(s)
	_sync_jans(s, delta)
	_sync_wolves(s, delta)
	_chatter(s, delta)


func _new_jan(pos: Vector3, frozen: bool, arrival_id := -1) -> JanView:
	var view := JanView.new()
	add_child(view)
	view.global_position = pos
	view.setup(frozen, arrival_id)
	view.worked.connect(_on_jan_worked)
	return view


## A guard's spear lands on the wolf he's fighting.
func _on_jan_worked(view: JanView, clip: String) -> void:
	if clip == "guard_attack" and _guard_foes.has(view):
		wolf_hit(_guard_foes[view])


## A blow lands on a wolf: it flinches.
func wolf_hit(wolf_id: int) -> void:
	var view: WolfView = _wolves.get(wolf_id)
	if view:
		view.hit()


func _sync_frozen(s: GameState) -> void:
	var seen := {}
	for a in s.arrivals:
		seen[a.id] = true
		if not _frozen.has(a.id):
			var p: Vector2 = a.pos
			_frozen[a.id] = _new_jan(Vector3(p.x, 0, p.y), true, a.id)
	for id in _frozen.keys():
		if not seen.has(id):
			_frozen[id].queue_free()
			_frozen.erase(id)


func _sync_jans(s: GameState, delta: float) -> void:
	var nav := get_world_3d().navigation_map
	var slots := {}
	var guards := 0
	var caps := Economy.caps(s)
	var speed := Economy.output_mult(s)
	var cold := Economy.is_cold(s)
	_guard_foes.clear()
	for jan in s.jans:
		var view: JanView = _jans.get(jan.id)
		if view == null:
			view = _new_jan(Vector3(jan.pos.x, 0, jan.pos.y), false)
			view.jan_id = jan.id
			_jans[jan.id] = view
		var job: String = jan.job
		view.set_cold(cold)
		if job == "guard":
			guards += 1
			view.follow(Vector3(jan.pos.x, 0, jan.pos.y), delta)
			var foe := _wolf_in_reach(s, jan.pos)
			if not foe.is_empty() and not jan.ko:
				_guard_foes[view] = foe.id
			view.guard(jan.hp / Balance.GUARD_HP, jan.ko, Vector3(foe.pos.x, 0, foe.pos.y) if not foe.is_empty() else Vector3.INF)
			continue
		var slot: int = slots.get(job, 0)
		slots[job] = slot + 1
		view.go_to(_post(s, job, slot), nav)
		# He works while his job produces and its pile has room; otherwise he warms his hands.
		var working := job != "" and Economy.job_rate(s, job) > 0.0
		if working:
			var res: String = Balance.JOBS[job].resource
			working = s.piles[res] < caps[res] - 0.01
		view.work(job if working else "", speed)
	var alive := {}
	for jan in s.jans:
		alive[jan.id] = true
	for id in _jans.keys():
		if not alive.has(id):
			_jans[id].flee()
			_jans.erase(id)


## The living wolf a guard at `pos` can strike, or {}.
func _wolf_in_reach(s: GameState, pos: Vector2) -> Dictionary:
	for wolf in s.wolves:
		if wolf.mode != "leave" and wolf.hp > 0.0 and pos.distance_to(wolf.pos) <= Balance.GUARD_RANGE + 0.1:
			return wolf
	return {}


## Where Jan number `slot` on `job` stands: beside the building's pad, or round the furnace if idle.
func _post(s: GameState, job: String, slot: int) -> Vector3:
	var site := -1
	if job != "":
		site = MapData.site_of_building(s.sites, Balance.JOBS[job].building)
	if site < 0:
		var angle := 0.7 + slot * 0.9
		var r := 4.5 + (slot / 7) * 1.2
		return Vector3(cos(angle) * r, 0, sin(angle) * r)
	# Either side of the building's pad, leaving the pad itself clear for Meagan.
	var base := MapData.site_pos(s, site)
	var side := -1.0 if slot % 2 == 0 else 1.0
	var col := (slot / 2) % 2
	var row := slot / 4
	return Vector3(base.x + side * (2.2 + col * 1.3), 0, base.y + 2.4 + row * 1.1)


func _sync_wolves(s: GameState, delta: float) -> void:
	var seen := {}
	for wolf in s.wolves:
		seen[wolf.id] = true
		var view: WolfView = _wolves.get(wolf.id)
		if view == null:
			view = WolfView.new()
			add_child(view)
			view.global_position = Vector3(wolf.pos.x, 0, wolf.pos.y)
			_wolves[wolf.id] = view
		view.sync(wolf, delta)
	for id in _wolves.keys():
		if not seen.has(id):
			_wolves[id].queue_free()
			_wolves.erase(id)


## Every 20 to 30 s while the city is calm, a working Jan says something. [brief]
func _chatter(s: GameState, delta: float) -> void:
	_chatter_in -= delta
	if _chatter_in > 0.0:
		return
	_chatter_in = randf_range(20.0, 30.0)
	if s.blizzard_active or not s.wolves.is_empty() or _jans.is_empty():
		return
	var view: JanView = _jans.values().pick_random()
	view.say(Game.random_chatter(), 4.0)
