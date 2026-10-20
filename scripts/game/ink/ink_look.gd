class_name InkLook
extends Node
## The ink-and-watercolour look (docs/art-direction.md), on from the start. DEV → Ink look
## switches it off and on at runtime, to compare with the plain materials.
##
## It's built from three cheap layers instead of one expensive painterly shader:
## - every opaque material becomes `ink_toon` (banded watercolour washes with pigment granulation),
## - `ink_lines`, a full-screen quad in front of the camera, inks every depth jump and sharp colour
##   change, in a dark blue-brown (an inverted-hull outline tears apart on the Tripo models' split
##   normals),
## - one full-screen `ink_paper` pass adds pigment pooling at edges, uneven washes and paper grain.
## The lighting turns warm sun / cool blue shade, and the snow turns warm paper white. A painted disc
## of warm wash surrounds the furnace, cool blue beyond; it grows and shrinks with the heat.
## Switching it off restores every original material.

const TOON := preload("res://scripts/game/ink/ink_toon.gdshader")
const LINES := preload("res://scripts/game/ink/ink_lines.gdshader")
const PAPER := preload("res://scripts/game/ink/ink_paper.gdshader")
## Greybox colours swapped for the watercolour palette (snow as paper white, etc.).
const RECOLOR := [
	[Shapes.SNOW_COLOR, Color(0.89, 0.92, 0.94)],  # snow caps (the snowfield paints itself, ink_ground)
	[Color(0.66, 0.72, 0.82), Color(0.78, 0.84, 0.9)],  # the snow beyond the field
	[Color(0.9, 0.93, 1.0), Color(0.96, 0.97, 0.98)],  # snowbanks
]
## The most a glowing material may glow in the ink look.
const EMISSION_CAP := 0.85
## How often new and changed meshes are picked up.
const SCAN_INTERVAL := 0.4
## The warm disc's radius (metres) with the furnace cold and full.
const WARM_RADIUS_COLD := 5.0
const WARM_RADIUS_FULL := 12.0
## How fast the disc follows the heat (per second), so it breathes rather than jumps.
const WARM_FOLLOW := 1.5

var enabled := false
## Painted materials made elsewhere (the ground) that also take the furnace's warmth.
var painted: Array[ShaderMaterial] = []

var _env: Environment
var _sun: DirectionalLight3D
var _env_saved := {}
var _sun_saved := {}
var _lines: MeshInstance3D
var _ink_of := {}  # original material -> ink material
var _original_of := {}  # ink material -> original material
var _restore := {}  # MeshInstance3D -> {surface index: original surface override (or null)}
var _paper: CanvasLayer
var _scan_in := 0.0
var _warm_radius := WARM_RADIUS_FULL
## The shaders take this many small furnaces' warm patches (ink_common.gdshaderinc).
const MAX_WARM_SPOTS := 16


func _init(env: Environment, sun: DirectionalLight3D) -> void:
	_env = env
	_sun = sun


func set_enabled(on: bool) -> void:
	if on == enabled:
		return
	enabled = on
	if on:
		_apply_lighting()
		_paper = CanvasLayer.new()
		_paper.layer = 0  # under the HUD (layer 1)
		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = PAPER
		rect.material = m
		_paper.add_child(rect)
		add_child(_paper)
		_add_lines()
		_scan()
	else:
		_restore_lighting()
		_paper.queue_free()
		_paper = null
		_lines.queue_free()
		_lines = null
		_restore_all()


func toggle() -> void:
	set_enabled(not enabled)


func _process(delta: float) -> void:
	if not enabled:
		return
	_scan_in -= delta
	if _scan_in <= 0.0:
		_scan_in = SCAN_INTERVAL
		_scan()
	_update_warmth(delta)


## The warm disc follows the furnace's heat.
func _update_warmth(delta: float) -> void:
	var s := Game.engine.state
	var cap := Economy.heat_cap(s)
	var fraction := clampf(s.heat / cap, 0.0, 1.0) if cap > 0.0 else 0.0
	var target := lerpf(WARM_RADIUS_COLD, WARM_RADIUS_FULL, fraction)
	_warm_radius = lerpf(_warm_radius, target, minf(1.0, delta * WARM_FOLLOW))
	var center := MapData.START_SITES[0].pos as Vector2
	# Each small furnace keeps a smaller warm patch, shrinking with the same heat. [agreed 2026-10-20]
	var spots: Array[Vector4] = []
	for stove in s.stoves.slice(0, MAX_WARM_SPOTS):
		spots.append(Vector4(stove.pos.x, stove.pos.y, Balance.STOVE_WARM_RADIUS * (0.4 + 0.6 * fraction), 0.0))
	for ink in _original_of.keys() + painted:
		ink.set_shader_parameter("warm_radius", _warm_radius)
		ink.set_shader_parameter("warm_center", Vector3(center.x, 0.0, center.y))
		ink.set_shader_parameter("warm_spots", spots)
		ink.set_shader_parameter("warm_spot_count", spots.size())


# ---------- Materials ----------

func _scan() -> void:
	for node in get_tree().current_scene.find_children("*", "MeshInstance3D", true, false):
		_convert(node as MeshInstance3D)


func _convert(mi: MeshInstance3D) -> void:
	if mi.material_override:
		var ink := _ink(mi.material_override)
		if ink:
			mi.material_override = ink
		return
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var current := mi.get_surface_override_material(i)
		var source := current if current else mi.mesh.surface_get_material(i)
		var ink := _ink(source)
		if ink == null:
			continue
		# Snow doesn't settle on people and wolves (their rigged meshes have a skin).
		# Nor on a warm furnace (its meshes carry the "no_snow" meta, set by SiteView).
		if mi.skin != null or mi.get_parent() is Skeleton3D or mi.has_meta("no_snow"):
			ink.set_shader_parameter("snow_caps", 0.0)
		if not _restore.has(mi):
			_restore[mi] = {}
		if not _restore[mi].has(i):
			_restore[mi][i] = current
		mi.set_surface_override_material(i, ink)


## The ink version of a material, or null if it should stay as it is (already ink, transparent,
## unshaded or billboarded: labels, bars, ice, flashes).
func _ink(m: Material) -> ShaderMaterial:
	if m == null or _original_of.has(m):
		return null
	if _ink_of.has(m):
		return _ink_of[m]
	var base := m as BaseMaterial3D
	if base == null or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
			or base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED \
			or base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return null
	var ink := ShaderMaterial.new()
	ink.shader = TOON
	var color := base.albedo_color
	for pair in RECOLOR:
		if color.is_equal_approx(pair[0]):
			color = pair[1]
	ink.set_shader_parameter("albedo", color)
	if base.albedo_texture:
		ink.set_shader_parameter("albedo_tex", base.albedo_texture)
	ink.set_shader_parameter("use_vertex_color", base.vertex_color_use_as_albedo)
	# Vertex-painted models (the house kit, the pines) carry their own painted snow.
	if base.vertex_color_use_as_albedo:
		ink.set_shader_parameter("snow_caps", 0.0)
	if base.emission_enabled:
		ink.set_shader_parameter("emission_color", base.emission)
		# Glows stay paint, not light: capped so the fire reads orange instead of clipping to yellow.
		ink.set_shader_parameter("emission_energy", minf(base.emission_energy_multiplier, EMISSION_CAP))
	_ink_of[m] = ink
	_original_of[ink] = m
	return ink


func _restore_all() -> void:
	for node in get_tree().current_scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.material_override and _original_of.has(mi.material_override):
			mi.material_override = _original_of[mi.material_override]
	for mi in _restore:
		if is_instance_valid(mi):
			for i in _restore[mi]:
				mi.set_surface_override_material(i, _restore[mi][i])
	_restore.clear()


## The ink-line quad, on the camera so it's never culled.
func _add_lines() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var m := ShaderMaterial.new()
	m.shader = LINES
	m.render_priority = 5  # after other see-through things, under the labels (10)
	_lines = MeshInstance3D.new()
	_lines.mesh = quad
	_lines.material_override = m
	_lines.extra_cull_margin = 16384.0
	_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lines.position = Vector3(0, 0, -1)
	get_viewport().get_camera_3d().add_child(_lines)


# ---------- Light ----------

func _apply_lighting() -> void:
	for key in ["background_color", "ambient_light_color", "ambient_light_energy", "tonemap_mode", "fog_light_color"]:
		_env_saved[key] = _env.get(key)
	for key in ["light_color", "light_energy", "shadow_opacity"]:
		_sun_saved[key] = _sun.get(key)
	_env.background_color = Color(0.86, 0.88, 0.88)
	# Shade is a cool blue wash; the sun is warm.
	_env.ambient_light_color = Color(0.62, 0.7, 0.88)
	_env.ambient_light_energy = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_env.fog_light_color = Color(0.93, 0.93, 0.92)
	_sun.light_color = Color(1.0, 0.95, 0.87)
	_sun.light_energy = 0.95
	_sun.shadow_opacity = 0.7


func _restore_lighting() -> void:
	for key in _env_saved:
		_env.set(key, _env_saved[key])
	for key in _sun_saved:
		_sun.set(key, _sun_saved[key])
