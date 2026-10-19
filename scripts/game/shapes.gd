class_name Shapes
extends RefCounted
## Greybox building blocks: simple meshes, labels and bars. Real models replace these later.

const SNOW_COLOR := Color(0.8, 0.84, 0.92)

static var _materials := {}


static func material(color: Color, emission := 0.0) -> StandardMaterial3D:
	var key := "%s/%s" % [color.to_html(), emission]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_materials[key] = m
	return m


static func _instance(mesh: Mesh, color: Color, pos: Vector3, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(color, emission)
	mi.position = pos
	return mi


static func box(size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return _instance(m, color, pos)


static func cylinder(radius: float, height: float, color: Color, pos := Vector3.ZERO, top_radius := -1.0, emission := 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = radius
	m.top_radius = radius if top_radius < 0.0 else top_radius
	m.height = height
	m.radial_segments = 16
	return _instance(m, color, pos, emission)


static func cone(radius: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	return cylinder(radius, height, color, pos, 0.0)


static func capsule(radius: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 12
	m.rings = 4
	return _instance(m, color, pos)


static func sphere(radius: float, color: Color, pos := Vector3.ZERO, emission := 0.0) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	return _instance(m, color, pos, emission)


## A gable roof: a triangular prism lying along X.
static func roof(width: float, depth: float, height: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var m := PrismMesh.new()
	m.size = Vector3(depth, height, width)
	var mi := _instance(m, color, pos)
	mi.rotation_degrees.y = 90.0
	return mi


static func label(text: String, pos: Vector3, size := 64, color := Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.outline_size = 18
	l.modulate = color
	l.outline_modulate = Color(0.05, 0.08, 0.15)
	l.pixel_size = 0.016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	return l


## A tappable area for the camera's raycast: physics layer 3, metadata {kind, index}.
static func tap_area(shape_size: Vector3, kind: String, index: int, offset := Vector3.ZERO) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = Layers.TAPPABLE
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("kind", kind)
	area.set_meta("index", index)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = shape_size
	cs.shape = shape
	cs.position = offset + Vector3(0, shape_size.y / 2.0, 0)
	area.add_child(cs)
	return area
