class_name SiteView
extends Node3D
## One plot on the map: empty, under construction, or a building (the furnace is plot 0).
## Rebuilds its greybox shapes when the building or level changes; labels update every frame.

signal footprint_changed

const LOOKS := {
	"lumber_yard": {"wall": Color(0.55, 0.36, 0.2), "roof": Color(0.45, 0.16, 0.12)},
	"hunting_lodge": {"wall": Color(0.42, 0.45, 0.25), "roof": Color(0.3, 0.22, 0.14)},
	"sled_shed": {"wall": Color(0.45, 0.55, 0.65), "roof": Color(0.25, 0.3, 0.4)},
	"storehouse": {"wall": Color(0.7, 0.6, 0.42), "roof": Color(0.4, 0.3, 0.2)},
	"workshop": {"wall": Color(0.5, 0.52, 0.56), "roof": Color(0.3, 0.32, 0.36)},
	"barracks": {"wall": Color(0.55, 0.22, 0.2), "roof": Color(0.25, 0.25, 0.28)},
	"bunkhouse": {"wall": Color(0.85, 0.7, 0.4), "roof": Color(0.5, 0.25, 0.15)},
}
const SNOW := Color(0.94, 0.96, 1.0)
## The build pad's look: its disc colour by state, and the progress ring.
const PAD_RADIUS_SHOWN := 1.1
const PAD_COLORS := {
	"plot": Color(1, 1, 1, 0.45), "idle": Color(0.35, 0.6, 0.95, 0.5),
	"paying": Color(1.0, 0.78, 0.3, 0.55), "maxed": Color(0.6, 0.6, 0.65, 0.35),
}
const RING_COLOR := Color(1.0, 0.92, 0.5)

var index := 0
var _signature := ""
var _shapes: Node3D
var _title: Label3D
var _info: Label3D
var _body: StaticBody3D
var _fire: MeshInstance3D
var _light: OmniLight3D
var _embers: GPUParticles3D
var _flare := 0.0
var _pad: MeshInstance3D
var _pad_label: Label3D
var _ring: MeshInstance3D
var _ring_frac := -1.0


func setup(site_index: int) -> void:
	index = site_index
	position = Vector3(MapData.SITES[index].pos.x, 0, MapData.SITES[index].pos.y)
	_shapes = Node3D.new()
	add_child(_shapes)
	_title = Shapes.label("", Vector3(0, 4.4, 0), 56)
	add_child(_title)
	_info = Shapes.label("", Vector3(0, 3.0, 0), 44, Color(1, 0.95, 0.75))
	add_child(_info)
	var size := Vector3(MapData.SITE_HALF_SIZE * 2.0, 3.0, MapData.SITE_HALF_SIZE * 2.0)
	add_child(Shapes.tap_area(size, "site", index))
	_build_pad()


## The pad in front of the plot: where she stands to pay, and where its panel opens.
func _build_pad() -> void:
	var at: Vector2 = MapData.pad_pos(index) - MapData.SITES[index].pos
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


func bounce() -> void:
	var t := create_tween()
	_shapes.scale = Vector3(1.15, 0.8, 1.15)
	t.tween_property(_shapes, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


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
		var plot := Shapes.box(Vector3(3.6, 0.04, 3.6), Color(1, 1, 1, 0.35), Vector3(0, 0.02, 0))
		_shapes.add_child(plot)
		return
	if b == "furnace":
		_build_furnace(site.level)
	elif site.level == 0:
		_build_construction()
	else:
		_build_house(b, site.level)
	_add_body(MapData.FURNACE_RADIUS if b == "furnace" else MapData.SITE_HALF_SIZE)


func _build_house(b: String, level: int) -> void:
	var look: Dictionary = LOOKS[b]
	var h := 1.6 + 0.08 * level
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
		"barracks":
			_shapes.add_child(Shapes.cylinder(0.04, 2.6, Color(0.4, 0.3, 0.2), Vector3(1.5, 1.3, 1.7)))
			_shapes.add_child(Shapes.box(Vector3(0.7, 0.45, 0.04), Color(0.8, 0.2, 0.2), Vector3(1.85, 2.3, 1.7)))


func _build_construction() -> void:
	for x in [-1.5, 1.5]:
		for z in [-1.3, 1.3]:
			_shapes.add_child(Shapes.box(Vector3(0.15, 2.0, 0.15), Color(0.6, 0.45, 0.28), Vector3(x, 1.0, z)))
	_shapes.add_child(Shapes.box(Vector3(3.2, 0.12, 2.8), Color(0.6, 0.45, 0.28), Vector3(0, 0.06, 0)))
	_shapes.add_child(Shapes.box(Vector3(3.1, 1.9, 2.7), Color(0.9, 0.85, 0.7, 0.25), Vector3(0, 1.0, 0)))


func _build_furnace(level: int) -> void:
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


func _make_embers() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 1.6
	p.position = Vector3(0, 1.7, 0)
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


func _update_labels(s: GameState, site: Dictionary) -> void:
	var b: String = site.building
	_update_pad(s, site)
	if b == "":
		_title.text = ""
		_info.text = ""
		return
	var name: String = Balance.BUILDINGS[b].name
	_title.text = name if site.level == 0 else "%s  Lv %d" % [name, site.level]
	var lines := []
	if index == 0:
		lines.append("Fuel %s/%s" % [Fmt.num(s.fuel), Fmt.num(Economy.fuel_cap(s))])
	_info.text = "\n".join(lines)


func _update_pad(s: GameState, site: Dictionary) -> void:
	var state := "plot"
	var frac := 0.0
	if site.building == "":
		_pad_label.text = "+ Build"
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
		_pad_label.text = "Lv %d\nUpgrade" % site.level
	_pad.material_override = Shapes.material(PAD_COLORS[state])
	_pad_label.font_size = 34 if state == "paying" else 46
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
