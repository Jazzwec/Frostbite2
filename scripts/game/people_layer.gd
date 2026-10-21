class_name PeopleLayer
extends Node3D
## Keeps a JanView for every frozen and rescued Jan in the engine state, and wolves too.
## Workers stand in front of their building, idle Jans round the furnace, guards where the engine puts them.

var _frozen := {}  # arrival id -> JanView
var _jans := {}  # jan id -> JanView
var _wolves := {}  # wolf id -> WolfView
var _chatter_in := 20.0
var _guard_foes := {}  # JanView -> id of the wolf he's fighting
var _beaten := {}  # ids of wolves killed, so their views tumble away rather than vanish


func on_event(ev: Dictionary) -> void:
	match ev.type:
		"thawed":
			var view: JanView = _frozen.get(ev.arrival)
			_frozen.erase(ev.arrival)
			if view == null:
				view = _new_jan(Vector3(ev.pos.x, 0, ev.pos.y), false)
			view.thaw(ev.jan, Game.random_rescue_line())
			_jans[ev.jan] = view
		"wolf_killed":
			_beaten[ev.wolf] = true
		"guard_strike":
			var guard: JanView = _jans.get(ev.jan)
			if guard:
				guard.strike()
		"wolf_bite":
			if ev.hit and ev.victim >= 0:
				var bitten: JanView = _jans.get(ev.victim)
				if bitten:
					bitten.hurt()
		"jan_scared", "jan_starved":
			var view: JanView = _jans.get(ev.jan)
			_jans.erase(ev.jan)
			if view:
				view.say("Wolf!!" if ev.type == "jan_scared" else "No food...", 2.0)
				view.flee()


## The rescued Jans' views, for their footprints.
func jan_views() -> Array:
	return _jans.values()


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
		wolf_hit(_guard_foes[view], view.global_position)


## A blow from `from` lands on a wolf: it flinches.
func wolf_hit(wolf_id: int, from := Vector3.INF) -> void:
	var view: WolfView = _wolves.get(wolf_id)
	if view:
		view.hit(from)
		if from != Vector3.INF:
			Fx.impact(view.contact_point(from), 0.8)


func _sync_frozen(s: GameState) -> void:
	var seen := {}
	for a in s.arrivals:
		seen[a.id] = true
		if not _frozen.has(a.id):
			var p: Vector2 = a.pos
			_frozen[a.id] = _new_jan(Vector3(p.x, 0, p.y), true, a.id)
	# A camp's frozen Jans stand close together: only the first of a huddle says so.
	for a in s.arrivals:
		_frozen[a.id].show_frozen_label(not s.arrivals.any(func(b): return b.id < a.id and b.pos.distance_to(a.pos) < 3.0))
	for id in _frozen.keys():
		if not seen.has(id):
			_frozen[id].queue_free()
			_frozen.erase(id)


func _sync_jans(s: GameState, delta: float) -> void:
	var nav := get_world_3d().navigation_map
	var slots := {}
	var guards := 0
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
			view.guard(jan.hp / Economy.guard_hp(s), jan.ko, Vector3(foe.pos.x, 0, foe.pos.y) if not foe.is_empty() else Vector3.INF)
			continue
		# Workers stand at their own producer and haul their work to a stockpile (the engine's
		# CarryRules decides when, agreed 2026-10-20); idle Jans stand round the furnace.
		var site: int = jan.get("site", -1)
		var key: Variant = site if site >= 0 else job
		var slot: int = slots.get(key, 0)
		slots[key] = slot + 1
		var trip: String = jan.get("trip", "")
		if site >= 0 and trip == "out":
			# Each hauler drops at his own spot along the stockpile's front, so a crowd of them
			# never merges into one shape (Astra animation review, 2026-10-20).
			var pad := _drop_spot(s, jan.dest, jan.id)
			view.haul(Balance.JOBS[job].resource)
			view.go_to(Vector3(pad.x, 0, pad.y), nav)
			continue
		view.haul("")
		view.go_to(_post(s, site, slot), nav)
		view.work(job if jan.get("working", false) else "", speed)
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


## Where Jan number `slot` at plot `site` stands: beside its pad, or round the furnace if idle.
func _post(s: GameState, site: int, slot: int) -> Vector3:
	if site < 0:
		var angle := 0.7 + slot * 0.9
		var r := 4.5 + (slot / 7) * 1.2
		return Vector3(cos(angle) * r, 0, sin(angle) * r)
	var p := MapData.jan_post(s, site, slot)
	return Vector3(p.x, 0, p.y)


## At most this many enemy views are built a frame (each is 1-2 ms; a wave's group of six all at
## once was a hitch, F3 2026-10-21). They come in at the map's edge, so a frame's wait is unseen.
const NEW_WOLF_VIEWS_PER_FRAME := 2


func _sync_wolves(s: GameState, delta: float) -> void:
	var seen := {}
	var thief := ThreatArrows.nearest_thief(s)
	var built := 0
	for wolf in s.wolves:
		seen[wolf.id] = true
		var view: WolfView = _wolves.get(wolf.id)
		if view == null:
			if built >= NEW_WOLF_VIEWS_PER_FRAME:
				continue
			built += 1
			view = WolfView.new(wolf.kind)
			add_child(view)
			view.global_position = Vector3(wolf.pos.x, 0, wolf.pos.y)
			_wolves[wolf.id] = view
		view.rest = _rest(s, wolf)
		view.set_engaged(wolf.bite_t >= 0.0 or wolf.id == s.meagan_foe)
		view.badge = not thief.is_empty() and thief.id == wolf.id
		view.sync(wolf, delta)
	_nudge_wolves(s, delta)
	for id in _wolves.keys():
		if not seen.has(id):
			# Beaten ones tumble and run off; ones that left just go.
			if _beaten.has(id):
				_wolves[id].die()
				_beaten.erase(id)
			else:
				_wolves[id].queue_free()
			_wolves.erase(id)


## How far an outpost's defender is lying down: asleep, getting up for OUTPOST_WAKE once woken,
## then up.
func _rest(s: GameState, wolf: Dictionary) -> float:
	if wolf.outpost < 0:
		return 0.0
	var post: Dictionary = s.outposts[wolf.outpost]
	if not post.awake:
		return 1.0
	return clampf(1.0 - (s.time - post.get("woke_at", -100.0)) / Balance.OUTPOST_WAKE, 0.0, 1.0)


## A wolf view, if it's on the map.
func wolf_view(id: int) -> WolfView:
	return _wolves.get(id)


## A Jan's view, if he's on the map.
func jan_view(id: int) -> JanView:
	return _jans.get(id)


## Where hauler `id` drops his load at stockpile `k`: one of a row of spots along its front,
## DROP_GAP apart (fewer at a small stockpile).
const DROP_GAP := 0.75


func _drop_spot(s: GameState, k: int, id: int) -> Vector2:
	var slots := 5 if k == 0 else 3
	var col := (id * 7) % slots - (slots - 1) / 2
	return MapData.stockpile_pad(s, k) + Vector2(col * DROP_GAP, 0.3 + 0.5 * float((id / slots) % 2))


## Wolves closer than this share of the engine's spacing (by kind) are drawn apart (view only),
## and how quickly the nudge settles.
const WOLF_VIEW_SPACING := 0.9
const WOLF_NUDGE_EASE := 6.0
static var _most_spacing := -1.0
## Health bars that would overlap on screen step up, one bar plus an 8 px gap each (review 2):
## two enemies this close across (world X is screen X) and this close in depth.
const BAR_CLEAR_X := 1.35
const BAR_CLEAR_Z := 0.6
const BAR_STEP := 0.36


func _nudge_wolves(s: GameState, delta: float) -> void:
	# The widest pair's spacing: anything farther apart on either axis can't need a nudge, which
	# skips most pairs before the per-kind spacing (F3: the n² lookups were most of this).
	if _most_spacing < 0.0:
		for a in Balance.ENEMIES:
			_most_spacing = maxf(_most_spacing, Combat.spacing_of(a, a) * WOLF_VIEW_SPACING)
	for wolf in s.wolves:
		var view: WolfView = _wolves.get(wolf.id)
		if view == null:
			continue
		var push := Vector2.ZERO
		for other in s.wolves:
			if other.id == wolf.id:
				continue
			var apart: Vector2 = wolf.pos - other.pos
			if absf(apart.x) >= _most_spacing or absf(apart.y) >= _most_spacing:
				continue
			var d := apart.length()
			var spacing := Combat.spacing_of(wolf.kind, other.kind) * WOLF_VIEW_SPACING
			if d < spacing:
				var dir := apart / d if d > 0.001 else Vector2.RIGHT.rotated(float(wolf.id * 7 - other.id * 3))
				push += dir * (spacing - d) * 0.5
		view.nudge = view.nudge.lerp(Vector3(push.x, 0, push.y), minf(1.0, WOLF_NUDGE_EASE * delta))
	_stack_bars(s)


## Health bars never collide on screen (review 6): working in screen terms (world X across; the
## ground's depth and a bar's height foreshortened by the camera's pitch), each bar from the
## lowest on screen up steps clear of the ones already placed, Meagan's bar and her head with a
## 6 px gap, two steps at most.
const PITCH := deg_to_rad(52.0)
const BAR_HALF := 0.63
const BAR_TALL := 0.2
## Her bar is wider (HpBar 1.8 m); the gap kept between bars, about 6 px (review 9: sideways too).
const MEAGAN_BAR_HALF := 0.93
const BAR_GAP := 0.14
const HEAD_CLEAR := Vector2(0.55, 1.0)


func _stack_bars(s: GameState) -> void:
	var screen := func(p: Vector2, height: float) -> Vector2:
		return Vector2(p.x, p.y * sin(PITCH) - height * cos(PITCH))
	# What's fixed: her bar and her head.
	# Her head, with 8 px to spare above it whatever her clip does (review 7).
	var placed := [[screen.call(s.meagan_pos, 2.45), Vector2(MEAGAN_BAR_HALF, BAR_TALL + 0.06)], [screen.call(s.meagan_pos, 1.95), HEAD_CLEAR]]
	var bars := []
	for wolf in s.wolves:
		var view: WolfView = _wolves.get(wolf.id)
		if view and wolf.hp > 0.0 and wolf.hp < wolf.max_hp:
			bars.append([view, screen.call(wolf.pos, WolfView.LOOK[wolf.kind].bar)])
	bars.sort_custom(func(a, b): return a[1].y > b[1].y)
	for bar in bars:
		var at: Vector2 = bar[1]
		var lift := 0
		for step in 3:
			var clash := false
			for p in placed:
				if absf(p[0].x - at.x) < BAR_HALF + p[1].x + BAR_GAP and absf(p[0].y - at.y) < (BAR_TALL + p[1].y) / 2.0 + BAR_GAP:
					clash = true
					break
			if not clash or lift == 2:
				break
			lift += 1
			at.y -= BAR_STEP * cos(PITCH)
		bar[0].bar_lift = BAR_STEP * lift
		placed.append([at, Vector2(BAR_HALF, BAR_TALL)])
	for wolf in s.wolves:
		var view: WolfView = _wolves.get(wolf.id)
		if view and not (wolf.hp > 0.0 and wolf.hp < wolf.max_hp):
			view.bar_lift = 0.0


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
