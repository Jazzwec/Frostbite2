class_name StoveView
extends Node3D
## A small furnace on the border of an opened tile (agreed 2026-10-20): it never upgrades and
## burns from the main furnace's heat, so its glow and light dim with that heat. Greybox until its
## model is made.

const STONE := Color(0.5, 0.48, 0.47)
const IRON := Color(0.22, 0.2, 0.22)
const FIRE := Color(1.0, 0.55, 0.15)

var _glow: MeshInstance3D
var _light: OmniLight3D
var _embers: GPUParticles3D


func setup(pos: Vector2) -> void:
	position = Vector3(pos.x, 0, pos.y)
	# The house kit's fieldstone stove (ink_v3); its fire sits in the mouth facing the camera.
	var model := Props.make("prop_stove")
	if model:
		Props.use_vertex_colours(model)
		add_child(model)
		_glow = Shapes.sphere(0.2, FIRE, Vector3(0, 0.42, 0.56), 4.0)
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
	p.position = Vector3(0.25, 1.75, -0.2)
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
