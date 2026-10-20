class_name SiteView
extends Node3D
## One plot on the map: empty, under construction, or a building (the furnace is plot 0).
## Rebuilds its greybox shapes when the building or level changes; labels update every frame.

signal footprint_changed

const LOOKS := {
	"lumber_yard": {"wall": Color(0.55, 0.36, 0.2), "roof": Color(0.45, 0.16, 0.12)},
	"hunting_lodge": {"wall": Color(0.42, 0.45, 0.25), "roof": Color(0.3, 0.22, 0.14)},
	"storehouse": {"wall": Color(0.7, 0.6, 0.42), "roof": Color(0.4, 0.3, 0.2)},
	"workshop": {"wall": Color(0.5, 0.52, 0.56), "roof": Color(0.3, 0.32, 0.36)},
	"barracks": {"wall": Color(0.55, 0.22, 0.2), "roof": Color(0.25, 0.25, 0.28)},
	"bunkhouse": {"wall": Color(0.85, 0.7, 0.4), "roof": Color(0.5, 0.25, 0.15)},
	"kitchen": {"wall": Color(0.93, 0.88, 0.76), "roof": Color(0.78, 0.38, 0.16)},
	"watchtower": {"wall": Color(0.5, 0.42, 0.34), "roof": Color(0.28, 0.33, 0.42)},
	"hot_springs": {"wall": Color(0.62, 0.66, 0.7), "roof": Color(0.3, 0.5, 0.55)},
}
const SNOW := Color(0.94, 0.96, 1.0)
## The build pad's look: its disc colour by state, and the progress ring.
const PAD_RADIUS_SHOWN := 1.1
const PAD_COLORS := {
	"plot": Color(0.72, 0.8, 0.92, 0.2), "idle": Color(0.55, 0.68, 0.86, 0.22),
	"paying": Color(1.0, 0.78, 0.3, 0.55), "maxed": Color(0.6, 0.6, 0.65, 0.35),
}
const RING_COLOR := Color(1.0, 0.92, 0.5)
## Pads (plots, the Stockpile, gates) show within this distance of her. [ink_v3, 2026-10-20]
const PAD_SHOW := 6.0
## Nameplates: the largest font, and the most of the building's width they may take.
const PLATE_FONT := 36
const PLATE_MIN_FONT := 24
const PLATE_WIDTH := 3.4

var index := 0
var _signature := ""
var _shapes: Node3D
var _title: Label3D
var _body: StaticBody3D
var _fire: MeshInstance3D
var _light: OmniLight3D
var _embers: GPUParticles3D
var _flare := 0.0
## A working Kitchen puffs steam from its chimney every so often.
const STEAM_EVERY := 2.0
## Where the Hot Springs' pool sits, beside the hut and clear of the build pad.
const HOT_SPRINGS_POOL := Vector3(2.75, 0, 0.7)
## On the furnace model (assets/models/blender/furnace.glb): its fire mouth and chimney top.
const FURNACE_MOUTH := Vector3(0.23, 0.82, 0.64)
const FURNACE_CHIMNEY := Vector3(0.29, 4.37, 0.0)
var _steam_in := 0.0
var _pad: MeshInstance3D
var _pad_label: Label3D
var _ring: MeshInstance3D
var _ring_frac := -1.0
## Whether the building is (still) faded because Meagan is behind it.
var _faded := false
## Whether this plot is the one thing nearest Meagan, which alone shows its labels (main.gd).
var focused := false
## The nameplate steps aside for a moment while the level-up line has the stage.
var _resting := false


func setup(site_index: int, s: GameState) -> void:
	index = site_index
	var pos := MapData.site_pos(s, index)
	position = Vector3(pos.x, 0, pos.y)
	_shapes = Node3D.new()
	add_child(_shapes)
	# Above the roof and the furnace's chimney, name and level as one tight block.
	_title = Shapes.label("", Vector3(0, 4.9, 0), PLATE_FONT)
	_title.outline_size = 14
	_title.line_spacing = -10.0
	add_child(_title)
	var size := Vector3(MapData.SITE_HALF_SIZE * 2.0, 3.0, MapData.SITE_HALF_SIZE * 2.0)
	add_child(Shapes.tap_area(size, "site", index))
	_build_pad(s)


## The pad in front of the plot: where she stands to pay, and where its panel opens.
func _build_pad(s: GameState) -> void:
	var at: Vector2 = MapData.pad_pos(s, index) - MapData.site_pos(s, index)
	var root := Node3D.new()
	root.position = Vector3(at.x, 0, at.y)
	add_child(root)
	_pad = Shapes.cylinder(PAD_RADIUS_SHOWN, 0.03, PAD_COLORS.plot, Vector3(0, 0.02, 0))
	root.add_child(_pad)
	_ring = MeshInstance3D.new()
	_ring.position = Vector3(0, 0.05, 0)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = RING_COLOR
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring.material_override = m
	root.add_child(_ring)
	# Lying flat on the pad, so it reads as part of the ground.
	_pad_label = Shapes.label("", Vector3(0, 0.08, 0), 46)
	_pad_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_pad_label.rotation_degrees.x = -90.0
	root.add_child(_pad_label)


func refresh(s: GameState) -> void:
	var site: Dictionary = s.sites[index]
	var sig := "%s/%d/%s" % [site.building, site.level, site.upgrading]
	if sig != _signature:
		var had_body := _body != null
		_signature = sig
		_rebuild(site)
		if had_body != (_body != null):
			footprint_changed.emit()
	_update_labels(s, site)
	if index == 0:
		_update_fire(s)
	if site.level > 0 and (site.building == "kitchen" or site.building == "hot_springs"):
		_steam_in -= get_process_delta_time()
		if _steam_in <= 0.0:
			# The springs steam all the time; the Kitchen's chimney now and then.
			_steam_in = STEAM_EVERY if site.building == "kitchen" else STEAM_EVERY / 2.0
			if site.building == "kitchen":
				Fx.burst("steam", global_position + _chimney)
			else:
				Fx.burst("steam", global_position + HOT_SPRINGS_POOL + Vector3(0.3, 0.3, 0.2))
				Fx.burst("steam", global_position + HOT_SPRINGS_POOL + Vector3(-0.4, 0.3, -0.3))


func bounce() -> void:
	var t := create_tween()
	_shapes.scale = Vector3(1.15, 0.8, 1.15)
	t.tween_property(_shapes, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## A building finished or levelled up: it bounces and confetti and snow fly (main.gd pops the
## "Lumber Yard Lv 2!" line). The furnace also flares twice as hard and sends out a ring of
## warm light.
func celebrate() -> void:
	bounce()
	# The nameplate steps aside while the level-up line has the stage.
	_resting = true
	get_tree().create_timer(1.0).timeout.connect(func(): _resting = false)
	Fx.burst("confetti", global_position + Vector3(0, 3.6, 0))
	Fx.burst("snow_big", global_position + Vector3(0, 0.4, 0))
	if index == 0:
		_flare = 2.0
		_light_ring()


## A ring of warm light that spreads out from the furnace and fades.
func _light_ring() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 6
	ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1.0, 0.72, 0.3, 0.45)
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(0, 0.3, 0)
	ring.scale = Vector3(1.5, 0.4, 1.5)
	add_child(ring)
	var t := create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector3(7.0, 0.4, 7.0), 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(m, "albedo_color:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(ring.queue_free)


## A small knock, for each hammer blow on a construction site.
func knock() -> void:
	var t := create_tween()
	_shapes.scale = Vector3(1.03, 0.96, 1.03)
	t.tween_property(_shapes, "scale", Vector3.ONE, 0.15).set_ease(Tween.EASE_OUT)


## A log landed in the furnace: the fire flares for a moment.
func flare() -> void:
	_flare = 1.0


func _rebuild(site: Dictionary) -> void:
	for c in _shapes.get_children():
		c.queue_free()
	if _body:
		_body.queue_free()
		_body = null
	var b: String = site.building
	if b == "":
		_build_plot()
		return
	if b == "furnace":
		_build_furnace(site.level)
	else:
		if site.level == 0:
			_build_construction()
		else:
			_build_house(b, site.level)
		_add_drifts()
	_add_body(MapData.FURNACE_RADIUS if b == "furnace" else MapData.SITE_HALF_SIZE)


## An empty plot: a staked-out square of trodden snow with a rope round it. [ink_v3 paintover]
func _build_plot() -> void:
	var half := MapData.SITE_HALF_SIZE * 0.85
	var rope := Color(0.62, 0.5, 0.36)
	for x in [-half, half]:
		for z in [-half, half]:
			_shapes.add_child(Shapes.cylinder(0.07, 0.7, Color(0.5, 0.36, 0.24), Vector3(x, 0.35, z)))
	for side in 4:
		var along := side < 2
		var at := half if side % 2 == 0 else -half
		var size := Vector3(half * 2.0, 0.035, 0.035) if along else Vector3(0.035, 0.035, half * 2.0)
		_shapes.add_child(Shapes.box(size, rope, Vector3(0, 0.55, at) if along else Vector3(at, 0.55, 0)))


## Low snow drifts banked against the walls, so the building sits in the snow instead of on it.
## Kept off the front middle, where the door and pad are. [ink_v3 paintover]
## A few broad, uneven lobes (back, sides, front corners), not a ring of stamps (ink_v3 review).
const DRIFT_SPOTS := [
	Vector3(-0.8, -1.5, 0.0), Vector3(1.0, -1.55, 0.2), Vector3(-1.75, 0.2, 1.57),
	Vector3(1.75, 0.5, 1.57), Vector3(-1.45, 1.55, 0.3), Vector3(1.5, 1.55, -0.3),
]


func _add_drifts() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 7919 + 13
	for spot: Vector3 in DRIFT_SPOTS:
		# x and y place it; z turns it, so each lobe lies along its wall and tapers off.
		var drift := Shapes.sphere(rng.randf_range(0.5, 0.65), Shapes.SNOW_COLOR, Vector3(spot.x, 0.0, spot.y))
		drift.scale = Vector3(rng.randf_range(2.0, 2.6), rng.randf_range(0.28, 0.38), rng.randf_range(0.9, 1.1))
		drift.rotation.y = spot.z + rng.randf_range(-0.2, 0.2)
		drift.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shapes.add_child(drift)


## Where the Kitchen model's chimney top is (tools/blender/house_kit.py, after its centring), for
## the steam.
const KITCHEN_CHIMNEY := Vector3(0.7, 4.95, -0.89)
## Where the Kitchen's steam rises from: its model's chimney, or the greybox one.
var _chimney := Vector3.ZERO


func _build_house(b: String, level: int) -> void:
	var model := Props.make("house_" + b)
	if model:
		# The ink_v3 house kit, painted with the palette's vertex colours; the Hot Springs' pool
		# stays in code (it's water).
		Props.use_vertex_colours(model)
		_shapes.add_child(model)
		_chimney = KITCHEN_CHIMNEY
		if b == "hot_springs":
			_add_pool()
		return
	var look: Dictionary = LOOKS[b]
	var h := 1.6 + 0.08 * level
	_chimney = Vector3(-1.0, h + 1.6, -0.6)
	_shapes.add_child(Shapes.box(Vector3(3.4, h, 3.0), look.wall, Vector3(0, h / 2.0, 0)))
	_shapes.add_child(Shapes.roof(3.7, 3.3, 1.1, look.roof, Vector3(0, h + 0.55, 0)))
	_shapes.add_child(Shapes.roof(3.75, 0.9, 0.25, SNOW, Vector3(0, h + 1.02, 0)))
	_shapes.add_child(Shapes.box(Vector3(0.8, 1.1, 0.05), Color(0.2, 0.13, 0.08), Vector3(0, 0.55, 1.52)))
	# A sign of what it does, readable from the angled camera.
	match b:
		"lumber_yard":
			for i in 3:
				var log := Props.make("log", 0.4, 0.0)
				if log:
					log.position = Vector3(-0.6, 0.35 * i, 1.9 + (0.15 if i == 1 else 0.0))
					_shapes.add_child(log)
				else:
					_shapes.add_child(Shapes.cylinder(0.18, 1.6, Color(0.6, 0.42, 0.25), Vector3(-1.2 + 0.4 * i, 0.2, 1.9)))
					_shapes.get_child(-1).rotation_degrees.z = 90.0
		"storehouse", "workshop":
			for i in 2:
				var crate := Props.make("crate", 0.8, 15.0 * i)
				if crate:
					crate.position = Vector3(1.0, 0.37 * i, 1.9)
					_shapes.add_child(crate)
		"hunting_lodge":
			_shapes.add_child(Shapes.cone(0.35, 0.7, Color(0.75, 0.7, 0.6), Vector3(1.3, 0.35, 1.9)))
		"kitchen":
			# A big cooking pot over a little fire by the door, a ladle in it, and a chimney (it steams).
			_shapes.add_child(Shapes.cone(0.45, 0.45, Color(1.0, 0.5, 0.15), Vector3(1.05, 0.22, 2.0)))
			_shapes.add_child(Shapes.cylinder(0.62, 0.75, Color(0.14, 0.14, 0.17), Vector3(1.05, 0.8, 2.0), 0.7))
			_shapes.add_child(Shapes.cylinder(0.6, 0.05, Color(0.9, 0.62, 0.3), Vector3(1.05, 1.16, 2.0)))
			var ladle := Shapes.cylinder(0.05, 1.2, Color(0.55, 0.38, 0.22), Vector3(1.25, 1.5, 2.0))
			ladle.rotation_degrees.z = -25.0
			_shapes.add_child(ladle)
			_shapes.add_child(Shapes.box(Vector3(0.5, 1.4, 0.5), Color(0.45, 0.32, 0.25), Vector3(-1.0, h + 0.9, -0.6)))
		"watchtower":
			# A tall wooden lookout beside the hut: four legs, a platform, a little roof and a flag.
			var wood := Color(0.45, 0.32, 0.2)
			var top := 4.6 + 0.12 * level
			for x in [-0.45, 0.45]:
				for z in [-0.45, 0.45]:
					_shapes.add_child(Shapes.box(Vector3(0.26, top, 0.26), wood, Vector3(1.1 + x, top / 2.0, 1.2 + z)))
			_shapes.add_child(Shapes.box(Vector3(1.8, 0.18, 1.8), wood.lightened(0.15), Vector3(1.1, top, 1.2)))
			_shapes.add_child(Shapes.box(Vector3(1.8, 0.55, 0.1), wood, Vector3(1.1, top + 0.32, 2.05)))
			_shapes.add_child(Shapes.cone(1.3, 0.9, LOOKS.watchtower.roof, Vector3(1.1, top + 1.4, 1.2)))
			_shapes.add_child(Shapes.cylinder(0.04, 0.9, wood, Vector3(1.1, top + 2.2, 1.2)))
			_shapes.add_child(Shapes.box(Vector3(0.75, 0.42, 0.04), Color(0.95, 0.15, 0.15), Vector3(1.5, top + 2.4, 1.2)))
		"hot_springs":
			_add_pool()
		"barracks":
			_shapes.add_child(Shapes.cylinder(0.04, 2.6, Color(0.4, 0.3, 0.2), Vector3(1.5, 1.3, 1.7)))
			_shapes.add_child(Shapes.box(Vector3(0.7, 0.45, 0.04), Color(0.8, 0.2, 0.2), Vector3(1.85, 2.3, 1.7)))


## A steaming pool ringed with stones beside the bath house, clear of the build pad.
func _add_pool() -> void:
	var pool := HOT_SPRINGS_POOL
	_shapes.add_child(Shapes.cylinder(1.4, 0.14, Color(0.56, 0.55, 0.53), pool + Vector3(0, 0.07, 0)))
	_shapes.add_child(Shapes.cylinder(1.15, 0.16, Color(0.37, 0.54, 0.53), pool + Vector3(0, 0.09, 0), -1.0, 0.35))
	for i in 10:
		var a := TAU * i / 10.0
		_shapes.add_child(Shapes.sphere(0.27, Color(0.56, 0.55, 0.53), pool + Vector3(cos(a) * 1.35, 0.16, sin(a) * 1.35)))


func _build_construction() -> void:
	for x in [-1.5, 1.5]:
		for z in [-1.3, 1.3]:
			_shapes.add_child(Shapes.box(Vector3(0.15, 2.0, 0.15), Color(0.6, 0.45, 0.28), Vector3(x, 1.0, z)))
	_shapes.add_child(Shapes.box(Vector3(3.2, 0.12, 2.8), Color(0.6, 0.45, 0.28), Vector3(0, 0.06, 0)))
	_shapes.add_child(Shapes.box(Vector3(3.1, 1.9, 2.7), Color(0.9, 0.85, 0.7, 0.25), Vector3(0, 1.0, 0)))


func _build_furnace(level: int) -> void:
	var model := Props.make("furnace")
	var embers_at := Vector3(0, 1.7, 0)
	if model != null:
		# The Meshy model (assets/models/meshy/furnace.meshy.json): the glow sits in its fire
		# mouth and the embers rise from its chimney.
		_shapes.add_child(model)
		# A hot furnace holds no snow (the ink look's snow caps skip it).
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			mi.set_meta("no_snow", true)
		_fire = Shapes.sphere(0.52, Color(1.0, 0.55, 0.15), FURNACE_MOUTH, 4.0)
		embers_at = FURNACE_CHIMNEY
	else:
		var r := MapData.FURNACE_RADIUS
		_shapes.add_child(Shapes.cylinder(r, 1.3, Color(0.32, 0.3, 0.32), Vector3(0, 0.65, 0), r * 0.85))
		_shapes.add_child(Shapes.cylinder(r * 0.9, 0.25, Color(0.2, 0.18, 0.2), Vector3(0, 1.4, 0)))
		var chimney_h := 1.5 + 0.25 * level
		_shapes.add_child(Shapes.cylinder(0.35, chimney_h, Color(0.25, 0.23, 0.25), Vector3(0.9, 1.3 + chimney_h / 2.0, -0.6)))
		_fire = Shapes.sphere(0.9, Color(1.0, 0.55, 0.15), Vector3(0, 1.5, 0), 4.0)
	_shapes.add_child(_fire)
	if _light == null:
		_light = OmniLight3D.new()
		_light.position = Vector3(0, 2.5, 0)
		_light.light_color = Color(1.0, 0.6, 0.3)
		_light.omni_range = 14.0
		_light.shadow_enabled = false
		add_child(_light)
		_embers = _make_embers()
		add_child(_embers)
	_embers.position = embers_at


func _make_embers() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.6
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.5
	pm.gravity = Vector3(0, 0.5, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.7, 0.3)
	q.material = m
	p.draw_pass_1 = q
	return p


func _add_body(half: float) -> void:
	_body = StaticBody3D.new()
	_body.collision_layer = Layers.OBSTACLE
	_body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(half * 2.0, 2.0, half * 2.0)
	cs.shape = shape
	cs.position = Vector3(0, 1.0, 0)
	_body.add_child(cs)
	add_child(_body)


## Nameplates and pad text fade in only while she's this close (or the plot is being paid for), so
## the town reads as a picture rather than a sign board. [ink_v3, 2026-10-20]
const LABEL_NEAR := 9.0
const LABEL_FADE := 4.0
var _label_alpha := 0.0


func _update_labels(s: GameState, site: Dictionary) -> void:
	var b: String = site.building
	_update_pad(s, site)
	# Only the one thing nearest her shows its labels (main.gd sets `focused`), so unrelated labels
	# never stack (ink_v3 review).
	var show := focused
	_label_alpha = move_toward(_label_alpha, 1.0 if show else 0.0, get_process_delta_time() * LABEL_FADE)
	for label: Label3D in [_title, _pad_label]:
		label.modulate.a = _label_alpha
		label.outline_modulate.a = _label_alpha
		label.visible = _label_alpha > 0.01 and (label != _title or not _resting)
	# One compact line: the name and level (an empty plot shows what it will hold). Numbers
	# (fuel, stores, costs) are in the building's sheet.
	var name: String = Balance.BUILDINGS[site.type if b == "" else b].name
	var text := name if site.level == 0 else "%s · Lv %d" % [name, site.level]
	if text != _title.text:
		_title.text = text
		_title.font_size = fit_font(text, PLATE_FONT, PLATE_MIN_FONT, PLATE_WIDTH, _title.pixel_size)


## Fades the building while it stands between the camera and Meagan.
## Returns whether the building stands in front of her right now.
func fade_covers(camera: Transform3D, meagan: Vector3, delta: float) -> bool:
	var near := _body != null and global_position.distance_to(meagan) < 8.0
	if not near and not _faded:
		return false
	var cover := near and FadeCover.covers(camera, meagan, global_position, 4.0, MapData.SITE_HALF_SIZE)
	_faded = FadeCover.fade(_shapes, cover, delta)
	return cover


## The biggest font size (down to `smallest`) at which `text` is no wider than `width` metres.
static func fit_font(text: String, largest: int, smallest: int, width: float, pixel_size: float) -> int:
	var font := ThemeDB.fallback_font
	var size := largest
	while size > smallest and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * pixel_size > width:
		size -= 1
	return size


func _update_pad(s: GameState, site: Dictionary) -> void:
	var state := "plot"
	var frac := 0.0
	if site.building == "":
		# The plot's own building (the game decides, agreed 2026-10-20), or what it waits for.
		var plot: String = site.type
		var name: String = Balance.BUILDINGS[plot].name
		_pad_label.text = "+ Build" if Economy.is_unlocked(s, plot) else ("Needs Furnace Lv %d" % Balance.BUILDINGS[plot].unlock)
	elif site.upgrading:
		state = "paying"
		var need := Economy.site_cost(s, index)
		var have := 0.0
		var total := 0.0
		var lines := []
		for res in need:
			var got: float = site.progress.get(res, 0.0)
			have += got
			total += need[res]
			lines.append("%s %s/%s" % [{"wood": "Wood", "food": "Food", "materials": "Mat"}[res], Fmt.num(got), Fmt.num(need[res])])
		_pad_label.text = "\n".join(lines)
		frac = have / maxf(total, 1.0)
	elif Economy.is_maxed(s, index):
		state = "maxed"
		_pad_label.text = "Max"
	else:
		state = "idle"
		_pad_label.text = "Upgrade"
	_pad.material_override = Shapes.material(PAD_COLORS[state])
	# The disc shows only as she comes near or while it's being paid for; otherwise the building
	# or staked plot is the cue (ink_v3 review: no placement circles all over the town).
	_pad.visible = state == "paying" or s.meagan_pos.distance_to(MapData.pad_pos(s, index)) <= PAD_SHOW
	_pad_label.font_size = 30 if state == "paying" else 34
	if absf(frac - _ring_frac) > 0.004:
		_ring_frac = frac
		_ring.mesh = _ring_mesh(frac)
		_ring.visible = frac > 0.0


## A flat ring round the pad's rim, filled clockwise from the top to `frac`.
static func _ring_mesh(frac: float) -> ImmediateMesh:
	var m := ImmediateMesh.new()
	if frac <= 0.0:
		return m
	var inner := PAD_RADIUS_SHOWN - 0.16
	var outer := PAD_RADIUS_SHOWN + 0.02
	var steps := maxi(2, int(56 * frac))
	m.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for k in steps + 1:
		var a := -PI / 2.0 + TAU * frac * k / steps
		var d := Vector3(cos(a), 0, sin(a))
		m.surface_add_vertex(d * inner)
		m.surface_add_vertex(d * outer)
	m.surface_end()
	return m


func _update_fire(s: GameState) -> void:
	if _fire == null:
		return
	var frac := s.heat / maxf(Economy.heat_cap(s), 1.0)
	var size := 0.15 + 0.85 * frac
	_flare = move_toward(_flare, 0.0, get_process_delta_time() * 2.5)
	_fire.scale = Vector3.ONE * size * (1.0 + 0.5 * _flare)
	_fire.visible = frac > 0.01 or _flare > 0.0
	_light.light_energy = 0.3 + 4.0 * frac + 3.0 * _flare
	_embers.emitting = frac > 0.05
	_embers.amount_ratio = clampf(frac, 0.1, 1.0)
