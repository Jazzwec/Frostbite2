class_name StoveView
extends Node3D
## A small furnace on the border of an opened tile (agreed 2026-10-20): it burns from the main
## furnace's heat, so its glow and light dim with that heat, and it shares the furnace's level.
## Its pad opens the furnace's sheet, and the furnace's upgrade can be paid there.

const STONE := Color(0.5, 0.48, 0.47)
const IRON := Color(0.22, 0.2, 0.22)
const FIRE := Color(1.0, 0.55, 0.15)

var index := -1
var _glow: MeshInstance3D
var _pad: MeshInstance3D
var _pad_label: Label3D
var _pad_at := Vector2.ZERO
var _light: OmniLight3D
var _embers: GPUParticles3D
## Where its embers rise: the model's chimney top (measured on the mesh), or the greybox one.
var _chimney := Vector3(0.25, 1.75, -0.2)


func setup(stove_index: int, s: GameState) -> void:
	index = stove_index
	var pos: Vector2 = s.stoves[index].pos
	position = Vector3(pos.x, 0, pos.y)
	_pad_at = MapData.stove_pad(s, index)
	var pad_local := _pad_at - pos
	_pad = Shapes.cylinder(SiteView.PAD_RADIUS_SHOWN, 0.03, SiteView.PAD_COLORS.idle, Vector3(pad_local.x, 0.02, pad_local.y))
	add_child(_pad)
	_pad_label = Shapes.label("", Vector3(pad_local.x, 0.08, pad_local.y), 30)
	_pad_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_pad_label.rotation_degrees.x = -90.0
	add_child(_pad_label)
	add_child(Shapes.tap_area(Vector3(2.0, 2.2, 2.0), "stove", index, Vector3(0, 1.0, 0)))
	# The house kit's fieldstone stove (ink_v3); its fire sits in the mouth facing the camera.
	var model := Props.make("prop_stove")
	if model:
		Props.use_vertex_colours(model)
		add_child(model)
		_glow = Shapes.sphere(0.24, FIRE, Vector3(0, 0.55, 0.62), 4.0)
		_chimney = Vector3(-0.1, 1.9, -0.21)
	else:
		add_child(Shapes.cylinder(0.75, 0.9, STONE, Vector3(0, 0.45, 0), 0.6))
		add_child(Shapes.cylinder(0.68, 0.14, IRON, Vector3(0, 0.95, 0)))
		add_child(Shapes.cylinder(0.16, 0.7, IRON, Vector3(0.25, 1.35, -0.2)))
		_glow = Shapes.sphere(0.32, FIRE, Vector3(0, 0.55, 0.45), 4.0)
	add_child(_glow)
	_light = OmniLight3D.new()
	_light.position = Vector3(0, 1.2, 0.6)
	_light.light_color = Color(1.0, 0.6, 0.3)
	_light.omni_range = 6.0
	_light.shadow_enabled = false
	add_child(_light)
	_embers = _make_embers()
	add_child(_embers)
	# Jans walk round it.
	var body := StaticBody3D.new()
	body.collision_layer = Layers.OBSTACLE
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = 1.2
	cs.shape = shape
	cs.position = Vector3(0, 0.6, 0)
	body.add_child(cs)
	add_child(body)


func refresh(s: GameState) -> void:
	# Its pad shows as she comes near, like the plots': the shared furnace's level and upgrade.
	var near := s.meagan_pos.distance_to(_pad_at) <= SiteView.PAD_SHOW
	var paying := s.upgrades.has("furnace")
	_pad.visible = near or paying
	_pad_label.visible = near
	if near:
		var lv := Economy.furnace_level(s)
		var state := "paying" if paying else ("maxed" if lv >= Balance.BUILDINGS.furnace.max else "idle")
		_pad.material_override = Shapes.material(SiteView.PAD_COLORS[state])
		var line: String = {"maxed": "Max", "idle": "Upgrade"}.get(state, "")
		if state == "paying":
			var need := Economy.cost("furnace", lv)
			var got: Dictionary = s.upgrades.furnace
			line = "Paying %s/%s Wood" % [Fmt.num(got.get("wood", 0.0)), Fmt.num(need.get("wood", 0.0))]
		_pad_label.text = ("Furnace · Lv %d\n%s" % [lv, line])
	var cap := Economy.heat_cap(s)
	var frac := clampf(s.heat / cap, 0.0, 1.0) if cap > 0.0 else 0.0
	_glow.scale = Vector3.ONE * (0.2 + 0.8 * frac)
	_glow.visible = frac > 0.01
	_light.light_energy = 0.2 + 1.6 * frac
	_embers.emitting = frac > 0.05


func _make_embers() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 1.4
	p.position = _chimney
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.4
	pm.gravity = Vector3(0, 0.4, 0)
	pm.scale_min = 0.4
	pm.scale_max = 0.8
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.1)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.7, 0.3)
	q.material = m
	p.draw_pass_1 = q
	return p
