extends Node3D
## Builds the town from MapData, wires taps to Meagan and the sheet, and turns engine events
## into feedback (banners, floating text, bounces). Reads engine state; only calls engine actions.

const BLIZZARD_BLUE := UiTheme.COLD_WASH
const GOOD_GREEN := UiTheme.GOOD_WASH
const GROUND_SHADER := preload("res://scripts/game/ink/ink_ground.gdshader")
const SNOW_WASH := preload("res://assets/textures/snow_wash.png")

var _env: Environment
var _sun: DirectionalLight3D
## The ink-and-watercolour look, on by default (DEV → Ink look compares; `-- --no-ink` starts without it).
var _ink: InkLook
## The painted snowfield (`ink_ground`), kept to give InkLook the furnace's warmth.
var _ground: ShaderMaterial
var _nav: NavigationRegion3D
var _nav_dirty := false
var _baking := false
var _sites: Array[SiteView] = []
var _nodes: Array[NodeView] = []
## The open tiles' ground, and the frontier round it (raised snow over closed tiles, gates),
## rebuilt whenever a tile opens. [agreed 2026-10-20]
var _tiles_root: Node3D
var _frontier: Node3D
var _gates: Array[GateView] = []
var _stoves: Array[StoveView] = []
var _chests: Array[ChestView] = []
var _outposts: Array[OutpostView] = []
## Closed tiles are deep, cold drifts: cooler than the trodden snow and raised above it.
const VEIL_COLOR := Color(0.6, 0.68, 0.82)
const VEIL_HEIGHT := 1.2
var _people: PeopleLayer
var _footprints: Footprints
var _stockpiles: Array[StockpileView] = []
## Woodpiles, fences, rocks and shrubs round the plots and over open snow. [ink_v3, 2026-10-20]
var _dressing: SetDressing
## For showing a build pad or gate taking from the Stockpile: each one's progress last frame.
var _last_progress := {}
var _drop_in := 0.0
## How much of her hand-gathering has been shown, by resource.
var _last_bag := 0.0
## One emptying of her bag at a stockpile, summed up once it's over (AFK V5): what it took by
## resource, at which stockpile, and her bag last frame.
var _stored := {}
var _stored_at := 0
var _stored_idle := 0.0
var _store_bag := {}
## Seconds since her last activity, for CARRY_GRACE.
var _work_age := 0.0
var _meagan: Meagan
var _rig: CameraRig
var _hud: Hud
var _snow: GPUParticles3D
var _snow_mat: ParticleProcessMaterial
var _storm := 0.0
## Below LOW_FPS for LOW_FPS_TIME seconds the snowfall thins out (and comes back once it's fine).
const LOW_FPS := 40.0
const LOW_FPS_TIME := 3.0
var _low_fps_for := 0.0
var _snow_quality := 1.0
## What Meagan last worked at: {activity, target}. Hit moments use it after the tick has moved on.
var _work := {}
## The build pad she's standing on (-1 for none), how long she's been still on it, and which
## pad's sheet we opened.
var _pad_site := -1
var _pad_still := 0.0
var _pad_opened := -1


func _ready() -> void:
	_build_environment()
	_build_ground()
	_dressing = SetDressing.new()
	add_child(_dressing)
	for i in Game.engine.state.sites.size():
		_add_site_view(i)
	for i in Game.engine.state.node_defs.size():
		_add_node_view(i)
	for i in Game.engine.state.stoves.size():
		_add_stove_view(i)
	for i in Game.engine.state.chests.size():
		_add_chest_view(i)
	for den in Game.engine.state.dens:
		_add_den_view(den.pos)
	for i in Game.engine.state.outposts.size():
		_add_outpost_view(i)
	_rebuild_frontier()
	for k in Game.engine.state.stockpiles.size():
		_add_stockpile_view(k)
	_people = PeopleLayer.new()
	add_child(_people)
	_footprints = Footprints.new()
	add_child(_footprints)

	_meagan = Meagan.new()
	add_child(_meagan)
	var start: Vector2 = Game.engine.state.meagan_pos
	_meagan.global_position = Vector3(start.x, 0, start.y)

	_rig = CameraRig.new()
	add_child(_rig)
	_rig.follow_target = _meagan
	_rig.global_position = _meagan.global_position
	_rig.bounds = _camera_bounds()
	_rig.tapped.connect(_on_tap)
	_rig.steered.connect(_meagan.steer)
	_meagan.worked.connect(_on_meagan_worked)
	add_child(Fx.new())
	_build_snow()

	_hud = Hud.new()
	add_child(_hud)
	_rig.ui_blocker = _hud.blocks
	_rig.joystick = _hud.joystick
	_hud.hints.setup(_rig.camera, _meagan, Game.tips.get("hints", {}))
	_hud.bag_readout.setup(_rig.camera, _meagan)
	_hud.threat_arrows.setup(_rig.camera)
	Audio.listener = _meagan
	Game.engine_event.connect(_on_event)
	_ink = InkLook.new(_env, _sun)
	_ink.painted.append(_ground)
	add_child(_ink)
	_hud.ink_toggled.connect(_ink.toggle)

	# Draw everything once so the first navmesh bake sees every building.
	_refresh_views(0.0)
	_nav.bake_navigation_mesh(false)
	_nav_dirty = false
	if not OS.get_cmdline_user_args().has("--no-ink"):
		_ink.set_enabled(true)
	# A saved winter that had already ended shows its card again.
	var s := Game.engine.state
	if s.game_over:
		_hud.show_game_over(s.time, Game.best_time(), false)


func _process(delta: float) -> void:
	_footprints.track(_meagan, _meagan.moving, true)
	for v in _people.jan_views():
		_footprints.track(v, v.is_walking())
	_refresh_views(delta)
	_update_meagan_activity(delta)
	_update_down_label()
	_update_pad_stop(delta)
	_update_pad_payments(delta)
	_update_ground_marks()
	if _nav_dirty and not _baking:
		_nav_dirty = false
		_baking = true
		_nav.bake_navigation_mesh(true)
	var s := Game.engine.state
	_storm = move_toward(_storm, 1.0 if s.blizzard_active else 0.0, delta * 0.5)
	_low_fps_for = _low_fps_for + delta if Engine.get_frames_per_second() < LOW_FPS else 0.0
	_snow_quality = move_toward(_snow_quality, 0.4 if _low_fps_for > LOW_FPS_TIME else 1.0, delta * 0.2)
	_snow.amount_ratio = lerpf(0.3, 1.0, _storm) * _snow_quality
	_snow_mat.gravity = Vector3(lerpf(0.0, 9.0, _storm), -3.0 - 4.0 * _storm, 0.0)
	# The camera sits about 40 m from the ground, so even light fog builds up fast.
	_env.fog_density = lerpf(0.002, 0.011, _storm)


func _refresh_views(delta: float) -> void:
	var s := Game.engine.state
	# Trees and buildings between the camera and Meagan fade so she's never hidden.
	var cam := _rig.camera.global_transform if _rig else Transform3D()
	var her := _meagan.global_position if _meagan else Vector3.INF
	var hidden := false
	_dressing.refresh(s)
	_update_label_focus(s)
	for v in _sites:
		v.refresh(s)
		if _rig:
			hidden = v.fade_covers(cam, her, delta) or hidden
	for v in _nodes:
		v.refresh(s)
		if _rig:
			hidden = v.fade_covers(cam, her, delta) or hidden
	if _meagan:
		_meagan.show_silhouette(hidden or _enemy_covers_her(s))
	for v in _stockpiles:
		v.refresh(s)
	_people.refresh(s, delta)
	for g in _gates:
		if g.index < s.gates.size():
			g.refresh(s.gates[g.index], s.meagan_pos)
	for v in _stoves:
		v.refresh(s)
	for v in _chests:
		v.refresh(s.chests[v.index])
	for v in _outposts:
		v.refresh(s.outposts[v.index])


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
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-55, -35, 0)
	_sun.light_color = Color(1.0, 0.96, 0.9)
	_sun.light_energy = 0.8
	_sun.shadow_enabled = true
	# The camera only ever shows about 30 m of ground: one shadow split over 45 m instead of the
	# default four over 100 m (about 10% of frame time on desktop, more on a phone).
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 45.0
	add_child(_sun)


## The snowfield's painted material: a watercolour snow wash, cool hollows, and packed paths from
## the furnace to every plot's pad and the Stockpile.
func _ground_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GROUND_SHADER
	m.set_shader_parameter("snow_tex", SNOW_WASH)
	_set_paths(m)
	return m


## Packed paths from the furnace to the Stockpile and every starting plot's pad, and from each
## small furnace to the plots in its tile. The shader takes at most PATH_LIMIT.
const PATH_LIMIT := 64


func _set_paths(m: ShaderMaterial) -> void:
	# One connected network, shared with the set dressing so props keep off it.
	var paths := SetDressing.tracks(Game.engine.state)
	paths.resize(mini(paths.size(), PATH_LIMIT))
	m.set_shader_parameter("paths", paths)
	m.set_shader_parameter("path_count", paths.size())
	_set_contacts(m)


## Soft blue shade pooled round everything standing in the snow: buildings and construction
## sites, the Stockpile, forests and scrap heaps, small furnaces and the boulders. The shader
## takes at most CONTACT_LIMIT. [ink_v3, 2026-10-20]
const CONTACT_LIMIT := 96
const CONTACT_RADIUS := {"forest": 2.6, "scrap": 1.6}
const BOULDERS := [Vector3(-12, 0, -20), Vector3(13, 0, -22), Vector3(-14, 0, 8), Vector3(12, 0, 17), Vector3(-3, 0, 19), Vector3(21, 0, -3), Vector3(-4, 0, -20)]


func _set_contacts(m: ShaderMaterial) -> void:
	var s := Game.engine.state
	var contacts: Array[Vector4] = []
	for i in s.sites.size():
		if s.sites[i].building != "":
			var p := MapData.site_pos(s, i)
			var r := MapData.FURNACE_RADIUS * 1.1 if i == 0 else MapData.SITE_HALF_SIZE * 1.05
			contacts.append(Vector4(p.x, p.y, r, 0.0))
	for k in s.stockpiles.size():
		var p: Vector2 = s.stockpiles[k].pos
		contacts.append(Vector4(p.x, p.y, 2.0 if k == 0 else 1.3, 0.0))
	for i in s.node_defs.size():
		var kind := MapData.node_kind(s, i)
		if CONTACT_RADIUS.has(kind):
			var p := MapData.node_pos(s, i)
			contacts.append(Vector4(p.x, p.y, CONTACT_RADIUS[kind], 0.0))
	for stove in s.stoves:
		contacts.append(Vector4(stove.pos.x, stove.pos.y, 1.0, 0.0))
	for b in BOULDERS:
		contacts.append(Vector4(b.x, b.z, 1.0, 0.0))
	contacts.resize(mini(contacts.size(), CONTACT_LIMIT))
	m.set_shader_parameter("contacts", contacts)
	m.set_shader_parameter("contact_count", contacts.size())


## One label at a time (ink_v3 review): only the labelled thing nearest Meagan within
## SiteView.LABEL_NEAR shows its text (a plot by its pad, a resource spot she isn't working at,
## the Stockpile, a gate).
func _update_label_focus(s: GameState) -> void:
	var me := s.meagan_pos
	# No labels while she fights or lies hurt in a raid: nothing like "Upgrade" over a theft
	# (fight_v2 review 1).
	var camp_fight := s.outposts.any(func(o): return o.awake and not o.cleared and s.meagan_pos.distance_to(o.pos) < 14.0)
	var best := 0.0 if Combat.meagan_busy(s) or s.raid_on or camp_fight or _hud.sheet.visible else SiteView.LABEL_NEAR
	var focus: Node = null
	for v in _sites:
		var d := me.distance_to(MapData.pad_pos(s, v.index))
		if d < best:
			best = d
			focus = v
	for v in _nodes:
		var d := me.distance_to(MapData.node_pos(s, v.index))
		if d > Balance.GATHER_RANGE + 1.0 and d < best:
			best = d
			focus = v
	for v in _stockpiles:
		if me.distance_to(MapData.stockpile_pad(s, v.index)) < best:
			best = me.distance_to(MapData.stockpile_pad(s, v.index))
			focus = v
	for g in _gates:
		if g.index < s.gates.size() and me.distance_to(s.gates[g.index].pad) < best:
			best = me.distance_to(s.gates[g.index].pad)
			focus = g
	for v in _sites:
		v.focused = v == focus
	for v in _nodes:
		v.focused = v == focus
	for v in _stockpiles:
		v.focused = v == focus
	for g in _gates:
		g.focused = g == focus


## The ground's marks change when something is built or a tile opens.
var _marks_key := ""


func _update_ground_marks() -> void:
	var s := Game.engine.state
	var key := "%d/%d/%d" % [s.sites.filter(func(site): return site.building != "").size(), s.node_defs.size(), s.stoves.size()]
	if key != _marks_key:
		_marks_key = key
		_set_paths(_ground)


func _build_ground() -> void:
	var outer := MeshInstance3D.new()
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = Vector2(1000, 1000)
	outer.mesh = outer_mesh
	outer.material_override = Shapes.material(Color(0.66, 0.72, 0.82))
	outer.position = Vector3(0, -0.02, 0)
	add_child(outer)
	_ground = _ground_material()

	# A few boulders poking out of the snow, clear of plots and paths.
	for spot in BOULDERS:
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
	_tiles_root = Node3D.new()
	add_child(_tiles_root)
	for k in Game.engine.state.tiles:
		_add_tile_ground(WorldRules.tile_from_key(k))
	_frontier = Node3D.new()
	add_child(_frontier)


## An open tile's painted snow and the ground under it (the navmesh only covers open tiles).
func _add_tile_ground(tile: Vector2i) -> void:
	var r := MapData.tile_rect(tile)
	var field := MeshInstance3D.new()
	var field_mesh := PlaneMesh.new()
	field_mesh.size = r.size
	field.mesh = field_mesh
	field.material_override = _ground
	field.position = Vector3(r.get_center().x, 0, r.get_center().y)
	_tiles_root.add_child(field)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.GROUND
	ground.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(r.size.x, 1.0, r.size.y)
	cs.shape = shape
	cs.position = Vector3(r.get_center().x, -0.5, r.get_center().y)
	ground.add_child(cs)
	_nav.add_child(ground)


func _add_site_view(i: int) -> void:
	var view := SiteView.new()
	_nav.add_child(view)
	view.setup(i, Game.engine.state)
	view.footprint_changed.connect(func(): _nav_dirty = true)
	_sites.append(view)


func _add_node_view(i: int) -> void:
	var view := NodeView.new()
	add_child(view)
	view.setup(i, Game.engine.state)
	_nodes.append(view)


func _add_den_view(pos: Vector2) -> void:
	var view := DenView.new()
	_nav.add_child(view)
	view.setup(pos)


func _add_outpost_view(i: int) -> void:
	var view := OutpostView.new()
	add_child(view)
	view.setup(i, Game.engine.state.outposts[i])
	_outposts.append(view)


func _add_chest_view(i: int) -> void:
	var view := ChestView.new()
	add_child(view)
	view.setup(i, Game.engine.state.chests[i])
	_chests.append(view)


func _add_stockpile_view(k: int) -> void:
	var view := StockpileView.new()
	_nav.add_child(view)
	view.setup(k, Game.engine.state)
	_stockpiles.append(view)


func _add_stove_view(i: int) -> void:
	var view := StoveView.new()
	_nav.add_child(view)
	view.setup(i, Game.engine.state)
	_stoves.append(view)


## Raised snow over every closed tile round the open ones, and a gate view for each gate.
func _rebuild_frontier() -> void:
	for c in _frontier.get_children():
		c.queue_free()
	_gates.clear()
	var s := Game.engine.state
	var veiled := {}
	for k in s.tiles:
		var t := WorldRules.tile_from_key(k)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n := t + Vector2i(dx, dy)
				if WorldRules.is_open(s, n) or veiled.has(n):
					continue
				veiled[n] = true
				var r := MapData.tile_rect(n)
				_frontier.add_child(Shapes.box(Vector3(r.size.x, VEIL_HEIGHT, r.size.y), VEIL_COLOR, Vector3(r.get_center().x, VEIL_HEIGHT / 2.0, r.get_center().y)))
				_dress_veil(s, n, r)
	for i in s.gates.size():
		var g := GateView.new()
		_frontier.add_child(g)
		g.setup(i, s.gates[i])
		_gates.append(g)


## A closed tile reads as deep, wild snow rather than a slate block (ink_v3, 2026-10-20): soft
## drift lips spill over its edge wherever it meets open ground (clear of the gates), and a few
## dark pines stand on it, seeded by the tile.
const VEIL_LIP_STEP := 2.4
const VEIL_PINES := 4


func _dress_veil(s: GameState, tile: Vector2i, r: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([s.run_seed, tile.x, tile.y, "veil"])
	for side: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not WorldRules.is_open(s, tile + side):
			continue
		var normal := Vector2(side)
		var along := Vector2(-normal.y, normal.x)
		var edge := r.get_center() + normal * MapData.TILE_SIZE / 2.0
		var steps := int(MapData.TILE_SIZE / VEIL_LIP_STEP)
		for i in steps + 1:
			var p := edge + along * (-MapData.TILE_SIZE / 2.0 + i * VEIL_LIP_STEP) - normal * 0.2
			if s.gates.any(func(g): return p.distance_to(g.pos) < 3.2):
				continue
			var lip := Shapes.sphere(0.5, Shapes.SNOW_COLOR, Vector3(p.x, VEIL_HEIGHT * 0.78, p.y))
			lip.scale = Vector3(rng.randf_range(2.4, 3.2), rng.randf_range(0.7, 1.0), rng.randf_range(1.4, 1.9))
			lip.rotation.y = atan2(along.x, along.y) + PI / 2.0
			lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_frontier.add_child(lip)
	for i in VEIL_PINES:
		var p := Vector2(rng.randf_range(r.position.x + 3.0, r.end.x - 3.0), rng.randf_range(r.position.y + 3.0, r.end.y - 3.0))
		var pine_id: String = Props.PINE_HEIGHTS.keys()[rng.randi() % Props.PINE_HEIGHTS.size()]
		var pine := Props.make(pine_id, rng.randf_range(0.8, 1.2), rng.randf_range(0, 360))
		if pine:
			Props.use_vertex_colours(pine)
			pine.position = Vector3(p.x, VEIL_HEIGHT, p.y)
			_frontier.add_child(pine)


## Where the camera may go: the open tiles, plus enough to see the closed ring round them.
func _camera_bounds() -> Rect2:
	return Game.engine.state.bounds.grow(MapData.TILE_SIZE * 0.5)


## A tile opened: its ground, plots, resource spots and small furnace appear, and the frontier
## moves out.
func _open_tile(ev: Dictionary) -> void:
	_add_tile_ground(ev.tile)
	for i in ev.sites:
		_add_site_view(i)
	for i in ev.nodes:
		_add_node_view(i)
	for i in ev.chests:
		_add_chest_view(i)
	for i in ev.dens:
		_add_den_view(Game.engine.state.dens[i].pos)
	for i in ev.get("outposts", []):
		_add_outpost_view(i)
	_add_stove_view(Game.engine.state.stoves.size() - 1)
	_add_stockpile_view(ev.stockpile)
	# The town's fire carries out to the new small furnace, which lights as it lands (AFK V9,
	# from the world_tiles review).
	var stove: StoveView = _stoves[-1]
	stove.set_lit(false)
	_flame_trail(_v3(MapData.site_pos(Game.engine.state, 0)) + Vector3(0, 3.5, 0), stove.global_position + Vector3(0, 1.0, 0), stove.light_up)
	_rebuild_frontier()
	_set_paths(_ground)
	_rig.bounds = _camera_bounds()
	_nav_dirty = true
	_rig.shake(0.2)
	Audio.play("build_done")
	_float_text(Vector3(ev.pos.x, 3.5, ev.pos.y), "New area!", UiTheme.ACCENT, true)
	_float_text(Vector3(ev.pos.x, 2.4, ev.pos.y), "+%.2f heat/s drain" % Balance.STOVE_DRAIN, Color(1.0, 0.75, 0.6))


## An ember that flies in an arc from `from` to `to`, shedding sparks, then calls `landed`.
const TRAIL_TIME := 1.8
const TRAIL_HEIGHT := 4.0
const TRAIL_SPARK_EVERY := 0.04


func _flame_trail(from: Vector3, to: Vector3, landed: Callable) -> void:
	var ember := Shapes.sphere(0.45, Color(1.0, 0.62, 0.22), Vector3.ZERO, 4.0)
	add_child(ember)
	ember.global_position = from
	Audio.play("fire", from)
	var shed := {"left": 0.0}
	var fly := func(t: float) -> void:
		var p := from.lerp(to, t) + Vector3(0, sin(PI * t) * TRAIL_HEIGHT, 0)
		ember.global_position = p
		shed.left -= get_process_delta_time()
		if shed.left <= 0.0:
			shed.left = TRAIL_SPARK_EVERY
			Fx.burst("sparks", p)
	var tween := create_tween()
	tween.tween_method(fly, 0.0, 1.0, TRAIL_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		Fx.burst("flame", to)
		ember.queue_free()
		landed.call())


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
			_walk(_v3(MapData.pad_pos(s, i)))
			_hud.sheet.open_site(i)
		"node":
			_walk(_nodes[hit.index].work_spot(_meagan.global_position))
			_hud.sheet.close()
		"stockpile":
			_walk(_v3(MapData.stockpile_pad(s, hit.index)))
			_hud.sheet.open_stockpile()
		"stove":
			# A small furnace shares the furnace's level: its pad opens the furnace's sheet.
			_walk(_v3(MapData.stove_pad(s, hit.index)))
			_hud.sheet.open_site(0)
		"chest":
			var i: int = hit.index
			_walk(_v3(s.chests[i].pos) + Vector3(0, 0, 0.9))
			_hud.sheet.close()
		"gate":
			var i: int = hit.index
			if i < s.gates.size():
				_walk(_v3(s.gates[i].pad))
				_hud.sheet.open_gate(i)
		"arrival":
			var arrival_id: int = hit.index
			for a in s.arrivals:
				if a.id == arrival_id:
					Game.engine.target_arrival(arrival_id)
					var p: Vector2 = a.pos
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
## The Stockpile's pad and the gates' pads, in the pad-stop logic alongside the plots' indexes.
const STOCKPILE_PAD := 1000
const GATE_PAD := 2000
const STOVE_PAD := 3000


## Stopping on a plot's pad opens its sheet (build list or upgrade panel); leaving closes it.
func _update_pad_stop(delta: float) -> void:
	var me := Vector2(_meagan.global_position.x, _meagan.global_position.z)
	var on := -1
	var s := Game.engine.state
	for i in s.sites.size():
		if me.distance_to(MapData.pad_pos(s, i)) <= Balance.PAD_RADIUS:
			on = i
			break
	for k in s.stockpiles.size():
		if me.distance_to(MapData.stockpile_pad(s, k)) <= Balance.PAD_RADIUS:
			on = STOCKPILE_PAD + k
	for i in s.gates.size():
		if me.distance_to(s.gates[i].pad) <= Balance.PAD_RADIUS:
			on = GATE_PAD + i
	for k in s.stoves.size():
		if me.distance_to(MapData.stove_pad(s, k)) <= Balance.PAD_RADIUS:
			on = STOVE_PAD + k
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
		if on >= STOVE_PAD:
			_hud.sheet.open_site(0)
		elif on >= GATE_PAD:
			_hud.sheet.open_gate(on - GATE_PAD)
		elif on >= STOCKPILE_PAD:
			_hud.sheet.open_stockpile()
		else:
			_hud.sheet.open_site(on)
		Audio.play("tap")
		_pad_opened = on


## Building takes from her bag first (its pieces fly off her back, CarryStack), then from the
## store: each piece of that flies out of its number in the top bar to the building or gate,
## one at a time. [agreed 2026-10-20, from ChatGPT's review]
const PAY_FX_EVERY := 0.15


func _update_pad_payments(delta: float) -> void:
	var s := Game.engine.state
	_drop_in -= delta
	var bag := Economy.bag_total(s)
	if bag < _last_bag - 0.001:
		# Paid from her bag this frame: her stack shows it.
		_drop_in = maxf(_drop_in, 0.0001)
	_last_bag = bag
	for i in s.sites.size():
		if s.sites[i].level == 0:
			_send_from_stockpile("site %d" % i, s.sites[i].progress, _v3(MapData.site_pos(s, i)) + Vector3(0, 1.0, 0), i)
	# A building's upgrade is shared, paid at whichever of its pads she stands on (agreed 2026-10-20):
	# the piece flies to the plot or small furnace she's paying at.
	for building in s.upgrades:
		var at := s.meagan_target if s.meagan_activity == "build" else -1
		var top := _v3(MapData.site_pos(s, at)) + Vector3(0, 1.0, 0) if at >= 0 else _v3(s.meagan_target_pos) + Vector3(0, 1.0, 0)
		_send_from_stockpile("upgrade %s" % building, s.upgrades[building], top, at)
	for gate in s.gates:
		_send_from_stockpile("gate %s" % gate.tile, gate.progress, _v3(gate.pos) + Vector3(0, 0.6, 0), -1)


## Sends a piece from the top bar to `top` when `progress` grew since last frame. `site` is the
## plot that shakes as it lands, or -1.
func _send_from_stockpile(key: String, progress: Dictionary, top: Vector3, site: int) -> void:
	var before: Dictionary = _last_progress.get(key, {})
	_last_progress[key] = progress.duplicate()
	if _drop_in > 0.0:
		return
	for res in progress:
		if progress[res] > before.get(res, progress[res]) + 0.001:
			var landed := func() -> void:
				Fx.burst("dust", top)
				Audio.play("drop", top)
				if site >= 0 and site < _sites.size():
					_sites[site].knock()
			_hud.fly_from_counter(res, func() -> Vector2: return _rig.camera.unproject_position(top), landed)
			_drop_in = PAY_FX_EVERY
			return


## Where her stack's pieces come from (gathering) or go to (a stockpile, a build pad). It keeps the
## last activity's ends for a moment, since the stack catches up one piece at a time. Emptied
## into a stockpile, each piece's icon flies on into its number in the top bar.
func _update_carry() -> void:
	if _work.is_empty() or _work_age > CARRY_GRACE:
		_meagan.carry(Vector3.INF, Vector3.INF)
		return
	var target: int = _work.target
	var me := _meagan.global_position
	match _work.activity:
		"gather":
			_meagan.carry(_nodes[target].focus_point(me) + Vector3(0, 0.6, 0), Vector3.INF)
		"store":
			var pile := _stockpiles[target]
			_meagan.carry(Vector3.INF, pile.drop_point(), func(_res: String) -> void: pile.bump())
		"build":
			var top := _v3(MapData.site_pos(Game.engine.state, target)) if target >= 0 else _v3(_work.pos)
			var knock := func(_res: String) -> void:
				if target >= 0 and target < _sites.size():
					_sites[target].knock()
			_meagan.carry(Vector3.INF, top + Vector3(0, 1.0, 0), knock)
		_:
			_meagan.carry(Vector3.INF, Vector3.INF)


## While her bag empties at a stockpile, adds up what it takes; a moment after it stops, one
## "Stored +20 Wood" by the stockpile and one icon per resource up into the top bar, whose
## number pulses. [AFK V5, from the Astra review, 2026-10-20]
const STORE_SUM_AFTER := 0.2
## A routine deposit's summary is small, not a reward announcement (Astra review).
const STORE_SUM_SIZE := 36
const RESOURCE_WORDS := {"wood": "Wood", "food": "Food", "materials": "Mat"}


func _track_store(s: GameState, delta: float) -> void:
	if s.meagan_activity == "store":
		for res in s.bag:
			var drop: float = _store_bag.get(res, s.bag[res]) - s.bag[res]
			if drop > 0.0:
				_stored[res] = _stored.get(res, 0.0) + drop
		_stored_at = s.meagan_target
		_stored_idle = 0.0
	elif not _stored.is_empty():
		_stored_idle += delta
		if _stored_idle >= STORE_SUM_AFTER:
			_sum_up_store()
	_store_bag = s.bag.duplicate()


func _sum_up_store() -> void:
	var drop := _stockpiles[_stored_at].drop_point()
	var parts := []
	for res in ["wood", "food", "materials"]:
		if _stored.get(res, 0.0) >= 0.5:
			parts.append("+%d %s" % [roundi(_stored[res]), RESOURCE_WORDS[res]])
			_hud.fly_to_counter(res, func() -> Vector2: return _rig.camera.unproject_position(drop))
	_stored.clear()
	if parts.is_empty():
		return
	Fx.pop(" · ".join(parts), drop + Vector3(0, 0.5, 0), Color(1.0, 0.9, 0.68), STORE_SUM_SIZE)
	Audio.play("coin", drop)


# ---------- Meagan at work ----------

const GATHER_CLIPS := {"forest": "chop", "hunting": "fish", "scrap": "scavenge"}
const ACTIVITY_CLIPS := {"full": "full", "store": "carry", "build": "build", "fight": "ready"}
## How long after an activity stops its pieces still fly to or from the same place.
const CARRY_GRACE := 0.8


## Turns what the engine says she did this tick into a clip, a point to face, and where her
## stack's pieces come from or go to.
func _update_meagan_activity(delta: float) -> void:
	var s := Game.engine.state
	var activity := s.meagan_activity
	if activity == "full" and _work.get("activity", "") != "full":
		Audio.play("full")
	_work_age += delta
	_update_carry()
	_track_store(s, delta)
	if activity == "":
		_meagan.set_activity("", Vector3.INF)
		return
	_work = {"activity": activity, "target": s.meagan_target, "pos": s.meagan_target_pos}
	_work_age = 0.0
	var face := _v3(s.meagan_target_pos)
	if activity == "gather":
		var view := _nodes[s.meagan_target]
		var clip: String = GATHER_CLIPS[view.kind]
		face = view.focus_point(_meagan.global_position)
		_meagan.set_activity(clip, face, face + Vector3(0, 0.05, 0) if clip == "fish" else Vector3.INF)
	else:
		if activity == "build":
			# Work at the building's nearest front corner, so the camera sees her side-on.
			var side := signf(_meagan.global_position.x - face.x)
			face += Vector3((side if side != 0.0 else 1.0) * MapData.SITE_HALF_SIZE * 0.8, 0, MapData.SITE_HALF_SIZE * 0.8)
		var clip: String = ACTIVITY_CLIPS[activity]
		if activity == "fight" and s.meagan_mode == "ranged":
			# Her stance says which weapon is next (fight_v2 review 1).
			clip = "ready_throw"
		_meagan.set_activity(clip, face)


## A hit moment in her clip: effects, and the world reacts.
func _on_meagan_worked(clip: String) -> void:
	if clip == "warm":
		Fx.burst("steam", _meagan.head_position(), _meagan.forward() + Vector3.UP * 0.2)
		Audio.play("breath")
		return
	if _work.is_empty():
		return
	var target: int = _work.target
	var me := _meagan.global_position
	var tip := _meagan.tip_position()
	if clip in ["chop", "scavenge", "fish"]:
		_pop_gathered(target, me)
	match clip:
		"chop":
			var tree := _nodes[target].hit(me)
			Fx.burst("chips", tree + Vector3(0, 0.6, 0), (me - tree).normalized() + Vector3.UP)
			Fx.burst("snow", tree + Vector3(0, 2.2, 0), Vector3.DOWN)
			Audio.play("chop", tree)
		"scavenge":
			var heap := _nodes[target].hit(me)
			Fx.burst("sparks", tip, Vector3.UP)
			Fx.burst("dust", heap + Vector3(0, 0.3, 0))
			Audio.play("pick", heap)
		"fish":
			Fx.burst("splash", _nodes[target].focus_point(me) + Vector3(0, 0.05, 0))
			Audio.play("splash", me)
		"build":
			_sites[target].knock()
			Fx.burst("dust", tip)
			Fx.burst("sparks", tip, Vector3.UP)
			Audio.play("hammer", tip)
		"fight":
			_people.wolf_hit(target, me)
			Audio.play("swing_hit", tip)


## One "+N" per blow or catch, what she gathered since the last one, beside the spot rather than
## over her (Astra animation review, AFK N5/N7).
var _gathered_at_blow := -1.0


func _pop_gathered(node: int, me: Vector3) -> void:
	var s := Game.engine.state
	var total: float = s.gathered.wood + s.gathered.food + s.gathered.materials
	var got := total - _gathered_at_blow if _gathered_at_blow >= 0.0 else 0.0
	_gathered_at_blow = total
	if got < 0.5 or node < 0 or node >= _nodes.size():
		return
	var spot := _nodes[node].focus_point(me)
	var res: String = Balance.NODES[_nodes[node].kind].resource
	var side := (spot - me).cross(Vector3.UP).normalized()
	Fx.pop("+%d" % roundi(got), spot + side * 0.9 + Vector3(0, 1.0, 0), CarryStack.COLORS[res], 40)


# ---------- Engine events ----------

func _on_event(ev: Dictionary) -> void:
	_people.on_event(ev)
	match ev.type:
		"game_over":
			var new_best := Game.record_time(ev.time)
			_hud.show_game_over(ev.time, Game.best_time(), new_best)
			Audio.play("crash")
		"thawed":
			_meagan.play_once("warm", _v3(ev.pos))
		"tile_opened":
			_open_tile(ev)
		"jan_delivered":
			# A Jan's load lands in the store: a small "+N" at the stockpile, kept local so it doesn't
			# compete with Meagan's own feedback in the top bar (Astra review, 2026-10-20).
			var drop: Vector3 = _stockpiles[ev.stockpile].drop_point()
			if ev.amount < 0.5:
				return
			Fx.pop("+%d" % roundi(ev.amount), drop + Vector3(0, 0.4, 0), CarryStack.COLORS[ev.resource])
			Audio.play("drop", drop, 1.0, -6.0)
		"chest_opened":
			Audio.play("build_done", _v3(ev.pos))
			# A short reward burst out of the lid, so opening reads at a glance (review phase D/E).
			Fx.burst("sparks", _v3(ev.pos) + Vector3(0, 0.6, 0))
			Fx.burst("snow", _v3(ev.pos) + Vector3(0, 0.3, 0))
		"camp_found":
			_float_text(_v3(ev.pos) + Vector3(0, 2.5, 0), "%d frozen Jans!" % ev.count if ev.count > 1 else "A frozen Jan!", UiTheme.ACCENT, true)
		"cache":
			var name: String = {"wood": "Wood", "food": "Food", "materials": "Materials"}[ev.resource]
			_float_text(_v3(ev.pos) + Vector3(0, 2.0, 0), "+%s %s" % [Fmt.num(ev.amount), name], UiTheme.ACCENT, true)
		"boon_taken":
			_float_text(_meagan.global_position + Vector3(0, 3.0, 0), Balance.BOONS[ev.boon].name + "!", UiTheme.ACCENT, true)
		"gear_equipped":
			_float_text(_meagan.global_position + Vector3(0, 3.0, 0), "New %s!" % Balance.GEAR[ev.slot].name.to_lower(), UiTheme.ACCENT, true)
		"built", "levelled":
			var s := Game.engine.state
			if ev.building == "stockpile":
				# Shared by every stockpile: the words float over the nearest one.
				Audio.play("build_done")
				var sp := MapData.stockpile_pad(s, MapData.nearest_stockpile(s, s.meagan_pos))
				_float_text(Vector3(sp.x, 4.0, sp.y), "Stockpile Lv %d!" % ev.level, UiTheme.ACCENT, true)
				return
			# A level is shared by every plot of the building (agreed 2026-10-20): they all celebrate,
			# and the words float over the one she's nearest.
			var at: int = ev.site
			if ev.type == "levelled":
				for i in s.sites.size():
					if s.sites[i].building == ev.building:
						_sites[i].celebrate()
						if s.meagan_pos.distance_to(MapData.site_pos(s, i)) < s.meagan_pos.distance_to(MapData.site_pos(s, at)):
							at = i
			else:
				_sites[at].celebrate()
			_rig.shake(0.3 if ev.building == "furnace" else 0.14)
			Audio.play("build_done")
			var p := MapData.site_pos(s, at)
			if ev.building == "furnace" and ev.type == "levelled":
				for k in s.stoves.size():
					if s.meagan_pos.distance_to(s.stoves[k].pos) < s.meagan_pos.distance_to(p):
						p = s.stoves[k].pos
			var name: String = Balance.BUILDINGS[ev.building].name
			_float_text(Vector3(p.x, 5.0, p.y), ("%s built!" % name) if ev.type == "built" else ("%s Lv %d!" % [name, ev.level]), UiTheme.ACCENT, true)
		"no_room":
			Audio.play("error")
			_float_text(_v3(ev.pos) + Vector3(0, 2.5, 0), "No room! Upgrade the Furnace\nor build a Bunkhouse", Color(1, 0.8, 0.5))
		"blizzard_warning":
			Audio.play("warning")
			_hud.show_banner(Game.random_message("blizzardWarnings"), 6.0, BLIZZARD_BLUE, "blizzard")
		"blizzard_start":
			_hud.show_banner(Game.random_message("blizzardStart"), 5.0, BLIZZARD_BLUE, "blizzard")
		"blizzard_end":
			_hud.show_banner(Game.random_message("blizzardEnd"), 4.0, GOOD_GREEN)
		"attack_warning":
			Audio.play("warning")
			# A short strip with what's coming; the countdown and the kinds stay in the forecast
			# line, and edge arrows point at the sides (fight_v2 review 1). A troll is louder.
			# The strip counts down to it (Hud), the top panel lists what's in it (review 4); a
			# troll gets a lower horn.
			if ev.mix.get("troll", 0) > 0:
				Audio.play("crash", Vector3.INF, 0.4, -4.0)
		"wolves_arrived":
			Audio.play("howl")
			_hud.show_strip("Wave %d is here!" % ev.wave, "wolves")
		"wolf_windup":
			# Each kind's wind-up has its own sound (the steer's readability rule 2).
			var sound: Array = WINDUP_SOUNDS[ev.kind]
			Audio.play(sound[0], _v3(ev.pos), sound[1], sound[2])
		"enemy_throw":
			var thrower := _people.wolf_view(ev.wolf)
			var from := (thrower.global_position if thrower else _v3(ev.from)) + Vector3(0, 1.9, 0)
			var to := _v3(ev.to) + Vector3(0, 0.3, 0)
			# Clear of the hand at release (review 5: a visible gap), then aimed down its flight.
			var flat := Vector3(to.x - from.x, 0, to.z - from.z)
			if flat.length() > 0.01:
				from += flat.normalized() * 0.3
			Audio.play("whoosh", from, 0.8, -4.0)
			Fx.throw("shard", from, to, maxf(ev.flight, 0.15), 0.9, Callable(), true)
		"shard_landed":
			Fx.burst("shards", _v3(ev.pos) + Vector3(0, 0.2, 0))
			if ev.victim == -1:
				_meagan_hurt(0.04)
		"theft":
			Audio.play("pick", _v3(ev.pos), 0.6)
			_gather_theft(ev)
		"jan_starved":
			Audio.play("warning")
			_hud.show_banner("A Jan left: there's no Food!", 4.0, UiTheme.WARN_WASH, "food")
		"outpost_cleared":
			Audio.play("milestone")
			Fx.burst("confetti", _v3(ev.pos) + Vector3(0, 1.0, 0))
			Fx.pop("Cleared!" if ev.chest else "Cleared! " + _amounts(ev.pay, "+"), _v3(ev.pos) + Vector3(0, 2.4, 0), UiTheme.ACCENT, 44)
		"spoils":
			Audio.play("coin")
			Fx.pop(_amounts(ev.pay, "+"), _v3(ev.pos) + Vector3(0, 1.6, 0), Color(0.75, 1.0, 0.75), 40)
		"meagan_attack":
			var wolf := _people.wolf_view(ev.wolf)
			var at := wolf.global_position if wolf else _v3(ev.pos)
			_meagan.attack(ev.mode, at)
			if wolf:
				wolf.accent()
			if ev.mode == "ranged":
				_throw_snowball(ev.wolf, ev.flight)
			else:
				Audio.play("whoosh", _meagan.global_position, 1.2, -4.0)
				_show_sweep(_v3(ev.pos))
		"wolf_hit":
			var wolf := _people.wolf_view(ev.wolf)
			if wolf:
				var from := _v3(ev.from)
				var killing: bool = Game.engine.state.wolves.all(func(w): return w.id != ev.wolf or w.hp <= 0.0)
				var exposed: bool = ev.get("exposed", false)
				wolf.hit(from, "heavy" if killing else ("sweep" if ev.kind == "melee" else "light"), exposed)
				if exposed and ev.kind == "melee":
					_meagan.hit_stop(WolfView.COUNTER_FREEZE)
				var counter: bool = ev.get("exposed", false)
				# A 13 px core for a hit, bigger for a counter or a kill (reviews 7, 10).
				Fx.impact(wolf.contact_point(from), 1.2 if killing or counter else 1.0, counter, from)
				if counter:
					_show_counter(wolf.global_position)
				# One secondary flourish: ink flecks flung away from the blow (fight_v2 review 1).
				var away := (wolf.global_position - from)
				away.y = 0.0
				Fx.burst("ink", wolf.global_position + Vector3(0, 0.6, 0), away.normalized() + Vector3.UP * 0.4)
				Audio.play("swing_hit", wolf.global_position, 1.0 if ev.kind == "melee" else 1.3, 0.0 if ev.kind == "melee" else -6.0)
		"wolf_bite":
			# Every strike has its own sound, hit or miss; her being hit has another.
			Audio.play("snap", _v3(ev.pos), STRIKE_PITCH.get(ev.kind, 1.0))
			if ev.get("slam", false):
				Audio.play("crash", _v3(ev.pos), 0.55, -2.0)
				Fx.slam_puff(_v3(ev.pos))
				_rig.shake(0.06)
				if -1 in ev.victims:
					_meagan_hurt(0.0)
					_hit_stop(HIT_STOP)
			elif ev.victim < 0 and ev.hit:
				_meagan_hurt(0.05 if ev.kind == "bear" else 0.0)
				if ev.kind == "bear":
					_hit_stop(HIT_STOP)
		"wolf_killed":
			_hit_stop(HIT_STOP)
			Audio.play("yelp", _v3(ev.pos), KILL_PITCH.get(ev.kind, 1.0))
			Audio.play("coin")
			_gather_loot(ev)
		"meagan_up":
			# Back up: if anything's being carried off, that's her job now (review 4).
			var thief := ThreatArrows.nearest_thief(Game.engine.state)
			if not thief.is_empty():
				_hud.show_strip("Recover stolen supplies!", "bag", UiTheme.WARN_WASH, 2.0)
				var view := _people.wolf_view(thief.id)
				if view:
					view.pulse_badge()
		"meagan_injured":
			Audio.play("hurt", Vector3.INF, 0.8)
			_hud.show_strip("Meagan is down for %d s!" % roundi(ev.up_in), "", UiTheme.WARN_WASH, 2.0)
		"attack_over":
			_hud.show_strip("Wave %d held!" % ev.wave, "", GOOD_GREEN)


## Each kind's wind-up sound: [sound, pitch, volume dB].
const WINDUP_SOUNDS := {
	"fox": ["breath", 1.6, -6.0], "wolf": ["breath", 0.9, -4.0], "bear": ["howl", 0.45, -6.0],
	"troll": ["crash", 0.4, -8.0], "raider": ["whoosh", 0.6, -8.0],
}
const KILL_PITCH := {"fox": 1.5, "wolf": 1.0, "bear": 0.6, "troll": 0.45, "raider": 1.2}
const STRIKE_PITCH := {"fox": 1.3, "wolf": 1.0, "bear": 0.7, "troll": 0.5, "raider": 1.1}
## Loot from kills close together is added up for this long, then shown once, above the fight's
## health bars, and flown to the top bar (fight_v2 review 1: "+1 Mat" mustn't drown the hit).
const LOOT_GATHER := 0.5
const LOOT_HEIGHT := 2.6

var _loot := {}
var _loot_at := Vector3.ZERO
var _loot_n := 0


## While she's down, "Up in 4s" on a cream card above her, counting down (fight_v2 reviews 2, 4).
func _update_down_label() -> void:
	var s := Game.engine.state
	if s.meagan_injured and not s.game_over:
		var left := ceili(maxf(0.0, s.meagan_down_at + Balance.MEAGAN_DOWN_TIME - s.time))
		_hud.callout("Up in %ds" % left, _rig.camera.unproject_position(_meagan.global_position + Vector3(0, 1.7, 0)))
	else:
		_hud.callout("", Vector2.ZERO)


## A counter (a hit while it recovers) says so the first few times ever (review 4), then the
## ochre star says it alone. Counted in settings.cfg.
const COUNTER_LABELS := 3
var _counters_shown := -1


func _show_counter(at: Vector3) -> void:
	var cfg := ConfigFile.new()
	if _counters_shown < 0:
		cfg.load(Game.SETTINGS_PATH)
		_counters_shown = cfg.get_value("hints", "counters", 0)
	if _counters_shown >= COUNTER_LABELS:
		return
	_counters_shown += 1
	cfg.load(Game.SETTINGS_PATH)
	cfg.set_value("hints", "counters", _counters_shown)
	cfg.save(Game.SETTINGS_PATH)
	# Above every bar near it, small and brief, so it never hides the next threat (review 5).
	var top := at.y + 2.2
	for w in Game.engine.state.wolves:
		var view := _people.wolf_view(w.id)
		if view and view.global_position.distance_to(at) < 3.0:
			top = maxf(top, view.global_position.y + WolfView.LOOK[w.kind].bar + 0.4)
	var l := Shapes.label("Counter!", Vector3(at.x, top + 0.55, at.z), 34, Color(0.98, 0.82, 0.42))
	add_child(l)
	var t := l.create_tween()
	t.tween_interval(0.3)
	t.tween_property(l, "modulate:a", 0.0, 0.15)
	t.tween_callback(l.queue_free)


## Whether an enemy stands between her and the camera, close enough to hide her (review 10:
## she stays visible beside the big ones).
func _enemy_covers_her(s: GameState) -> bool:
	for e in s.wolves:
		var view := _people.wolf_view(e.id)
		if view == null:
			continue
		var d: Vector3 = view.global_position - _meagan.global_position
		var f: Vector2 = WolfView.FOOTPRINT[e.kind]
		if d.z > -0.2 and d.z < f.y + 1.6 and absf(d.x) < f.y + 0.3:
			return true
	return false


## A beat of stillness on a kill or a heavy blow, and only then (review 2: 35-50 ms).
const HIT_STOP := 0.04
var _stopping := false


func _hit_stop(seconds: float) -> void:
	if _stopping:
		return
	_stopping = true
	var was := Engine.time_scale
	Engine.time_scale = was * 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = was
	_stopping = false


## She's hit: her red flash and her own sound; shake only for heavy blows.
func _meagan_hurt(shake: float) -> void:
	_meagan.hurt()
	Audio.play("hurt", _meagan.global_position)
	if shake > 0.0:
		_rig.shake(shake)


## Her sweep's arc on the snow when it lands, exactly where it hits (Combat._land_shots).
func _show_sweep(at: Vector3) -> void:
	var reach: float = Economy.meagan_weapon(Game.engine.state).reach
	await get_tree().create_timer(Balance.MEAGAN_MELEE_IMPACT).timeout
	var me := _meagan.global_position
	Fx.sweep(me, at - me, reach, Balance.STICK_ARC)


## Thefts close together make one message for the whole store (fight_v2 review 1): "23 Food
## stolen: catch the thieves!", after THEFT_GATHER.
const THEFT_GATHER := 1.0
var _stolen := {}


func _gather_theft(ev: Dictionary) -> void:
	var first := _stolen.is_empty()
	for res in ev.carry:
		_stolen[res] = _stolen.get(res, 0.0) + ev.carry[res]
	if not first:
		return
	await get_tree().create_timer(THEFT_GATHER).timeout
	var what := _amounts(_stolen, "").replace(" · ", ", ")
	_stolen = {}
	if what != "":
		_hud.show_strip("%s stolen: catch the thieves!" % what, "bag", UiTheme.WARN_WASH, 2.5)


## A kill's loot (and anything it stole) joins the pile being gathered; the first one starts
## the clock.
func _gather_loot(ev: Dictionary) -> void:
	var got := {"materials": ev.materials}
	for res in ev.carry:
		got[res] = got.get(res, 0.0) + ev.carry[res]
	for res in got:
		_loot[res] = _loot.get(res, 0.0) + got[res]
		# In the store already: the top bar shows it as its icon lands.
		_hud.hold(res, got[res])
	_loot_at = (_loot_at * _loot_n + _v3(ev.pos)) / (_loot_n + 1)
	_loot_n += 1
	if _loot_n == 1:
		await get_tree().create_timer(LOOT_GATHER).timeout
		var at := _loot_at + Vector3(0, LOOT_HEIGHT, 0)
		Fx.pop(_amounts(_loot, "+"), at, Color(0.75, 1.0, 0.75), 38)
		for res in _loot:
			if _loot[res] >= 0.5:
				_hud.fly_to_counter(res, func() -> Vector2: return _rig.camera.unproject_position(at), _loot[res])
			else:
				_hud.hold(res, -_loot[res])
		_loot = {}
		_loot_n = 0
const ENEMY_NAMES := {"fox": ["a fox", "foxes"], "wolf": ["a wolf", "wolves"], "bear": ["a bear", "bears"],
	"troll": ["an ice troll", "ice trolls"], "raider": ["a raider", "raiders"]}


## "4 foxes, 2 wolves and a bear".
func _mix_text(mix: Dictionary) -> String:
	var parts := []
	for kind in ["troll", "bear", "raider", "wolf", "fox"]:
		var n: int = mix.get(kind, 0)
		if n > 0:
			parts.append(ENEMY_NAMES[kind][0] if n == 1 else "%d %s" % [n, ENEMY_NAMES[kind][1]])
	if parts.size() < 2:
		return "".join(parts)
	return ", ".join(parts.slice(0, -1)) + " and " + parts[-1]


## "+8 Food · +1 Mat" for a dictionary of amounts.
func _amounts(amounts: Dictionary, sign: String) -> String:
	var names := {"food": "Food", "wood": "Wood", "materials": "Mat"}
	var parts := []
	for res in ["food", "wood", "materials"]:
		if amounts.get(res, 0.0) >= 0.5:
			parts.append("%s%s %s" % [sign, Fmt.num(amounts[res]), names[res]])
	return " · ".join(parts)


## A snowball arcs from her hand to the wolf, landing as the engine's hit does.
func _throw_snowball(wolf_id: int, flight: float) -> void:
	await get_tree().create_timer(Balance.MEAGAN_RANGED_RELEASE).timeout
	var wolf := _people.wolf_view(wolf_id)
	if wolf == null:
		return
	Audio.play("whoosh", _meagan.global_position, 1.4, -6.0)
	var to := wolf.global_position + Vector3(0, 0.6, 0)
	Fx.throw("snowball_flying", _meagan.throw_point(), to, maxf(flight, 0.12), 0.6, func() -> void:
		Fx.burst("snow", to))


func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0, p.y)


func _float_text(pos: Vector3, text: String, color := Color.WHITE, pop := false) -> void:
	var l := Shapes.label(text, pos, 40 if pop else 52, color)
	add_child(l)
	var t := create_tween().set_parallel(true)
	if pop:
		# Bursts in big, then settles, for a level-up.
		l.scale = Vector3.ONE * 0.4
		t.tween_property(l, "scale", Vector3.ONE * 1.25, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.chain().tween_property(l, "scale", Vector3.ONE, 0.2)
		t.set_parallel(true)
	t.tween_property(l, "position:y", pos.y + 2.0, 1.8)
	t.tween_property(l, "modulate:a", 0.0, 1.8).set_delay(0.6)
	t.chain().tween_callback(l.queue_free)
