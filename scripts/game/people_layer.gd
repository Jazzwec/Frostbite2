class_name PeopleLayer
extends Node3D
## Keeps a JanView for every frozen and rescued Jan in the engine state, and wolves too.
## Workers stand in front of their building, idle Jans round the furnace, guards where the engine puts them.

var _frozen := {}  # arrival id -> JanView
var _jans := {}  # jan id -> JanView
var _wolves := {}  # wolf id -> WolfView
var _chatter_in := 20.0


func on_event(ev: Dictionary) -> void:
	match ev.type:
		"thawed":
			var view: JanView = _frozen.get(ev.arrival)
			_frozen.erase(ev.arrival)
			if view == null:
				view = _new_jan(Vector3(ev.pos.x, 0, ev.pos.y), false)
			view.thaw(ev.jan, Game.random_rescue_line())
			_jans[ev.jan] = view
		"jan_left", "jan_scared":
			var view: JanView = _jans.get(ev.jan)
			_jans.erase(ev.jan)
			if view:
				view.say("Brrr, I'm off!" if ev.type == "jan_left" else "Wolf!!", 2.0)
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
	return view


func _sync_frozen(s: GameState) -> void:
	var seen := {}
	for a in s.arrivals:
		seen[a.id] = true
		if not _frozen.has(a.id):
			var p: Vector2 = MapData.ARRIVAL_SPOTS[a.spot]
			_frozen[a.id] = _new_jan(Vector3(p.x, 0, p.y), true, a.id)
	for id in _frozen.keys():
		if not seen.has(id):
			_frozen[id].queue_free()
			_frozen.erase(id)


func _sync_jans(s: GameState, delta: float) -> void:
	var nav := get_world_3d().navigation_map
	var slots := {}
	var guards := 0
	for jan in s.jans:
		var view: JanView = _jans.get(jan.id)
		if view == null:
			view = _new_jan(Vector3(jan.pos.x, 0, jan.pos.y), false)
			view.jan_id = jan.id
			_jans[jan.id] = view
		var job: String = jan.job
		if job == "guard":
			guards += 1
			view.follow(Vector3(jan.pos.x, 0, jan.pos.y), delta)
			view.set_guard(true, jan.hp / Balance.GUARD_HP, jan.ko)
			continue
		view.set_guard(false, 1.0, false)
		var slot: int = slots.get(job, 0)
		slots[job] = slot + 1
		view.go_to(_post(s, job, slot), nav)
	var alive := {}
	for jan in s.jans:
		alive[jan.id] = true
	for id in _jans.keys():
		if not alive.has(id):
			_jans[id].flee()
			_jans.erase(id)


## Where Jan number `slot` on `job` stands: rows in front of the building, or round the furnace if idle.
func _post(s: GameState, job: String, slot: int) -> Vector3:
	var site := -1
	if job != "":
		site = MapData.site_of_building(s.sites, Balance.JOBS[job].building)
	if site < 0:
		var angle := 0.7 + slot * 0.9
		var r := 4.5 + (slot / 7) * 1.2
		return Vector3(cos(angle) * r, 0, sin(angle) * r)
	var base: Vector2 = MapData.SITES[site].pos
	var col := slot % 4
	var row := slot / 4
	return Vector3(base.x - 1.5 + col * 1.0, 0, base.y + 2.9 + row * 0.9)


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
