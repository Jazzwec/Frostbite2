extends Node3D
## Builds the town from MapData, wires taps to Meagan and the sheet, and turns engine events
## into feedback (banners, floating text, bounces). Reads engine state; only calls engine actions.

const BLIZZARD_BLUE := Color(0.15, 0.3, 0.55, 0.92)
const GOOD_GREEN := Color(0.15, 0.45, 0.25, 0.92)

var _env: Environment
var _nav: NavigationRegion3D
var _nav_dirty := false
var _baking := false
var _sites: Array[SiteView] = []
var _nodes: Array[NodeView] = []
var _people: PeopleLayer
var _meagan: Meagan
var _rig: CameraRig
var _hud: Hud
var _snow: GPUParticles3D
var _snow_mat: ParticleProcessMaterial
var _storm := 0.0
## What Meagan last worked at: {activity, target}. Hit moments use it after the tick has moved on.
var _work := {}
var _work_age := 0.0
## The build pad she's standing on (-1 for none), how long she's been still on it, and which
## pad's sheet we opened.
var _pad_site := -1
var _pad_still := 0.0
var _pad_opened := -1


func _ready() -> void:
	_build_environment()
	_build_ground()
	for i in MapData.SITES.size():
		var view := SiteView.new()
		_nav.add_child(view)
		view.setup(i)
		view.footprint_changed.connect(func(): _nav_dirty = true)
		_sites.append(view)
	for i in MapData.RESOURCE_NODES.size():
		var view := NodeView.new()
		add_child(view)
		view.setup(i)
		_nodes.append(view)
	_people = PeopleLayer.new()
	add_child(_people)

	_meagan = Meagan.new()
	add_child(_meagan)
	var start: Vector2 = Game.engine.state.meagan_pos
	_meagan.global_position = Vector3(start.x, 0, start.y)

	_rig = CameraRig.new()
	add_child(_rig)
	_rig.follow_target = _meagan
	_rig.global_position = _meagan.global_position
	_rig.tapped.connect(_on_tap)
	_rig.steered.connect(_meagan.steer)
	_meagan.worked.connect(_on_meagan_worked)
	add_child(Fx.new())
	_build_snow()

	_hud = Hud.new()
	add_child(_hud)
	_rig.ui_blocker = _hud.blocks
	_rig.joystick = _hud.joystick
	Game.engine_event.connect(_on_event)

	# Draw everything once so the first navmesh bake sees every building.
	_refresh_views(0.0)
	_nav.bake_navigation_mesh(false)
	_nav_dirty = false


func _process(delta: float) -> void:
	_refresh_views(delta)
	_update_meagan_activity(delta)
	_update_pad_stop(delta)
	if _nav_dirty and not _baking:
		_nav_dirty = false
		_baking = true
		_nav.bake_navigation_mesh(true)
	var s := Game.engine.state
	_storm = move_toward(_storm, 1.0 if s.blizzard_active else 0.0, delta * 0.5)
	_snow.amount_ratio = lerpf(0.3, 1.0, _storm)
	_snow_mat.gravity = Vector3(lerpf(0.0, 9.0, _storm), -3.0 - 4.0 * _storm, 0.0)
	# The camera sits about 40 m from the ground, so even light fog builds up fast.
	_env.fog_density = lerpf(0.002, 0.011, _storm)


func _refresh_views(delta: float) -> void:
	var s := Game.engine.state
	for v in _sites:
		v.refresh(s)
	for v in _nodes:
		v.refresh(s)
	_people.refresh(s, delta)


# ---------- World ----------

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.72, 0.8, 0.9)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.6, 0.68, 0.85)
	_env.ambient_light_energy = 0.55
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.85, 0.9, 1.0)
	_env.fog_density = 0.002
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)


func _build_ground() -> void:
	var b := MapData.BOUNDS
	var outer := MeshInstance3D.new()
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = Vector2(160, 200)
	outer.mesh = outer_mesh
	outer.material_override = Shapes.material(Color(0.66, 0.72, 0.82))
	outer.position = Vector3(0, -0.02, 0)
	add_child(outer)
	var field := MeshInstance3D.new()
	var field_mesh := PlaneMesh.new()
	field_mesh.size = b.size
	field.mesh = field_mesh
	field.material_override = Shapes.material(Shapes.SNOW_COLOR)
	field.position = Vector3(b.get_center().x, 0, b.get_center().y)
	add_child(field)
	# Snowbanks mark the edge of the town's snowfield.
	for edge in [Vector3(b.get_center().x, 0, b.position.y), Vector3(b.get_center().x, 0, b.end.y)]:
		add_child(Shapes.box(Vector3(b.size.x + 2.0, 0.8, 1.2), Color(0.9, 0.93, 1.0), edge + Vector3(0, 0.3, 0)))
	for edge in [Vector3(b.position.x, 0, b.get_center().y), Vector3(b.end.x, 0, b.get_center().y)]:
		add_child(Shapes.box(Vector3(1.2, 0.8, b.size.y + 2.0), Color(0.9, 0.93, 1.0), edge + Vector3(0, 0.3, 0)))

	# A few boulders poking out of the snow, clear of plots and paths.
	for spot in [Vector3(-12, 0, -20), Vector3(13, 0, -22), Vector3(-21, 0, 18), Vector3(12, 0, 24), Vector3(-3, 0, 25), Vector3(22, 0, -2), Vector3(-13, 0, 32), Vector3(8, 0, -36)]:
		var rock := Props.make("boulder", randf_range(0.7, 1.3), randf_range(0, 360))
		if rock:
			rock.position = spot + Vector3(0, -0.2, 0)
			add_child(rock)

	_nav = NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask = Layers.GROUND | Layers.OBSTACLE
	# Multiples of the 0.25 m cell size, so the bake doesn't round them.
	mesh.agent_radius = 0.5
	mesh.agent_height = 1.5
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	_nav.navigation_mesh = mesh
	_nav.bake_finished.connect(func(): _baking = false)
	add_child(_nav)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.GROUND
	ground.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(b.size.x, 1.0, b.size.y)
	cs.shape = shape
	cs.position = Vector3(b.get_center().x, -0.5, b.get_center().y)
	ground.add_child(cs)
	_nav.add_child(ground)


func _build_snow() -> void:
	_snow = GPUParticles3D.new()
	_snow.amount = 700
	_snow.lifetime = 5.0
	_snow.preprocess = 5.0
	_snow.position = Vector3(0, 16, 0)
	_snow.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	_snow_mat = ParticleProcessMaterial.new()
	_snow_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_snow_mat.emission_box_extents = Vector3(24, 1, 30)
	_snow_mat.direction = Vector3(0, -1, 0)
	_snow_mat.initial_velocity_min = 1.0
	_snow_mat.initial_velocity_max = 2.0
	_snow_mat.gravity = Vector3(0, -3, 0)
	_snow_mat.scale_min = 0.6
	_snow_mat.scale_max = 1.2
	_snow.process_material = _snow_mat
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	_snow.draw_pass_1 = q
	_rig.add_child(_snow)


# ---------- Taps ----------

func _on_tap(screen_pos: Vector2) -> void:
	var hit := _rig.pick(screen_pos)
	if hit.is_empty():
		return
	var s := Game.engine.state
	match hit.kind:
		"site":
			var i: int = hit.index
			_walk(_v3(MapData.pad_pos(i)))
			_hud.sheet.open_site(i)
		"node":
			_walk(_nodes[hit.index].work_spot(_meagan.global_position))
			_hud.sheet.close()
		"arrival":
			var arrival_id: int = hit.index
			for a in s.arrivals:
				if a.id == arrival_id:
					Game.engine.target_arrival(arrival_id)
					var p: Vector2 = MapData.ARRIVAL_SPOTS[a.spot]
					_walk(Vector3(p.x, 0, p.y + 0.8))
			_hud.sheet.close()
		"ground":
			# The joystick moves her; a tap on open snow just closes the sheet.
			_hud.sheet.close()


func _walk(target: Vector3) -> void:
	if not Game.engine.can_meagan_move():
		_float_text(_meagan.global_position, "Ouch... she can't move yet", Color(1, 0.6, 0.6))
		return
	_meagan.walk_to(target)
	var ring := Shapes.cylinder(0.6, 0.03, Color(1, 1, 1, 0.7), target + Vector3(0, 0.03, 0))
	add_child(ring)
	var t := create_tween()
	t.tween_property(ring, "scale", Vector3(0.2, 1, 0.2), 0.4)
	t.tween_callback(ring.queue_free)


# ---------- Build pads ----------

## How long she must stand still on a pad before its sheet opens.
const PAD_STOP_TIME := 0.25


## Stopping on a plot's pad opens its sheet (build list or upgrade panel); leaving closes it.
func _update_pad_stop(delta: float) -> void:
	var me := Vector2(_meagan.global_position.x, _meagan.global_position.z)
	var on := -1
	for i in MapData.SITES.size():
		if me.distance_to(MapData.pad_pos(i)) <= Balance.PAD_RADIUS:
			on = i
			break
	if on != _pad_site:
		_pad_site = on
		_pad_still = 0.0
		if _pad_opened >= 0 and on != _pad_opened:
			_hud.sheet.close()
			_pad_opened = -1
	if on < 0 or _pad_opened == on:
		return
	_pad_still = 0.0 if _meagan.moving else _pad_still + delta
	if _pad_still >= PAD_STOP_TIME:
		_hud.sheet.open_site(on)
		_pad_opened = on


# ---------- Meagan at work ----------

const GATHER_CLIPS := {"forest": "chop", "hunting": "fish", "scrap": "scavenge"}
## How long after an activity stops its pieces still fly to or from the same place.
const CARRY_GRACE := 0.8
const ACTIVITY_CLIPS := {"full": "full", "load": "carry", "store": "carry", "fuel": "fuel", "build": "build", "fight": "fight"}


## Turns what the engine says she did this tick into a clip, a point to face, and where her
## stack's pieces come from or go to.
func _update_meagan_activity(delta: float) -> void:
	var s := Game.engine.state
	var activity := s.meagan_activity
	_work_age += delta
	_update_carry()
	if activity == "":
		_meagan.set_activity("", Vector3.INF)
		return
	_work = {"activity": activity, "target": s.meagan_target}
	_work_age = 0.0
	var face := _v3(s.meagan_target_pos)
	if activity == "gather":
		var view := _nodes[s.meagan_target]
		var clip: String = GATHER_CLIPS[view.kind]
		face = view.focus_point(_meagan.global_position)
		_meagan.set_activity(clip, face, face + Vector3(0, 0.05, 0) if clip == "fish" else Vector3.INF)
	else:
		if activity in ["build", "load", "store"]:
			# Work at the building's nearest front corner, so the camera sees her side-on.
			var side := signf(_meagan.global_position.x - face.x)
			face += Vector3((side if side != 0.0 else 1.0) * MapData.SITE_HALF_SIZE * 0.8, 0, MapData.SITE_HALF_SIZE * 0.8)
		_meagan.set_activity(ACTIVITY_CLIPS[activity], face)


## Where pieces fly from (gathering, pickups) or to (fuel, construction, the store). It keeps the
## last activity's ends for a moment, since the stack catches up one piece at a time.
func _update_carry() -> void:
	if _work.is_empty() or _work_age > CARRY_GRACE:
		_meagan.carry(Vector3.INF, Vector3.INF)
		return
	var target: int = _work.target
	var me := _meagan.global_position
	var site_top := _v3(MapData.SITES[target].pos) + Vector3(0, 1.0, 0) if _work.activity in ["load", "store", "fuel", "build"] else Vector3.ZERO
	match _work.activity:
		"gather":
			_meagan.carry(_nodes[target].focus_point(me) + Vector3(0, 0.6, 0), Vector3.INF)
		"load":
			_meagan.carry(site_top, Vector3.INF)
		"store", "build":
			_meagan.carry(Vector3.INF, site_top)
		"fuel":
			var mouth := site_top + Vector3(0, 0.4, 0)
			var landed := func() -> void:
				_sites[0].flare()
				Fx.burst("flame", mouth)
			_meagan.carry(Vector3.INF, mouth, landed)
		_:
			_meagan.carry(Vector3.INF, Vector3.INF)


## A hit moment in her clip: effects, and the world reacts.
func _on_meagan_worked(clip: String) -> void:
	if clip == "warm":
		Fx.burst("steam", _meagan.head_position(), _meagan.forward() + Vector3.UP * 0.2)
		return
	if _work.is_empty():
		return
	var target: int = _work.target
	var me := _meagan.global_position
	var tip := _meagan.tip_position()
	match clip:
		"chop":
			var tree := _nodes[target].hit(me)
			Fx.burst("chips", tree + Vector3(0, 0.6, 0), (me - tree).normalized() + Vector3.UP)
			Fx.burst("snow", tree + Vector3(0, 2.2, 0), Vector3.DOWN)
		"scavenge":
			var heap := _nodes[target].hit(me)
			Fx.burst("sparks", tip, Vector3.UP)
			Fx.burst("dust", heap + Vector3(0, 0.3, 0))
		"fish":
			Fx.burst("splash", _nodes[target].focus_point(me) + Vector3(0, 0.05, 0))
		"build":
			_sites[target].knock()
			Fx.burst("dust", tip)
			Fx.burst("sparks", tip, Vector3.UP)
		"fight":
			_people.wolf_hit(target)
			Fx.burst("snow", tip, Vector3.UP)


# ---------- Engine events ----------

func _on_event(ev: Dictionary) -> void:
	_people.on_event(ev)
	match ev.type:
		"thawed":
			_meagan.play_once("warm", _v3(ev.pos))
		"built", "levelled":
			_sites[ev.site].bounce()
			var p: Vector2 = MapData.SITES[ev.site].pos
			var name: String = Balance.BUILDINGS[ev.building].name
			_float_text(Vector3(p.x, 3, p.y), ("%s built!" % name) if ev.type == "built" else ("%s Lv %d!" % [name, ev.level]), UiTheme.ACCENT)
		"no_room":
			_float_text(_v3(ev.pos) + Vector3(0, 2.5, 0), "No room! Upgrade the Furnace\nor build a Bunkhouse", Color(1, 0.8, 0.5))
		"blizzard_warning":
			_hud.show_banner(Game.random_message("blizzardWarnings"), 6.0, BLIZZARD_BLUE)
		"blizzard_start":
			_hud.show_banner(Game.random_message("blizzardStart"), 5.0, BLIZZARD_BLUE)
		"blizzard_end":
			_hud.show_banner(Game.random_message("blizzardEnd"), 4.0, GOOD_GREEN)
		"wolves_arrived":
			_hud.show_banner("Wolves! %d of them, heading for the furnace." % ev.count, 4.0)
		"breakthrough":
			_float_text(Vector3(0, 3.5, 0), "Wolves raided the furnace!", Color(1, 0.5, 0.4))
		"wolf_killed":
			_float_text(_v3(ev.pos) + Vector3(0, 1.5, 0), "+%s Food  +%s Mat" % [Fmt.num(ev.food), Fmt.num(ev.materials)], Color(0.7, 1, 0.7))
		"meagan_injured":
			_hud.show_banner("Meagan is hurt! She'll be back up when the wolves are gone.", 4.0)
		"attack_over":
			_hud.show_banner("The wolves are gone.", 3.0, GOOD_GREEN)
		"jan_left":
			_float_text(Vector3(0, 3.5, 0), "Too cold! A Jan wandered off.", UiTheme.COLD)


func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0, p.y)


func _float_text(pos: Vector3, text: String, color := Color.WHITE) -> void:
	var l := Shapes.label(text, pos, 52, color)
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", pos.y + 2.0, 1.8)
	t.tween_property(l, "modulate:a", 0.0, 1.8).set_delay(0.6)
	t.chain().tween_callback(l.queue_free)
