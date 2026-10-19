class_name HpBar
extends Node3D
## A small billboard health bar that hides itself when full.

const WIDTH := 1.2
const HEIGHT := 0.16

var _fill: MeshInstance3D


func _init(fill_color := Color(0.9, 0.2, 0.2)) -> void:
	var back := _quad(Color(0.1, 0.1, 0.1, 0.8), 0)
	back.mesh.size = Vector2(WIDTH + 0.06, HEIGHT + 0.06)
	add_child(back)
	_fill = _quad(fill_color, 1)
	add_child(_fill)
	visible = false


func _quad(color: Color, priority: int) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(WIDTH, HEIGHT)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = 20 + priority
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func set_value(fraction: float, show_when_full := false) -> void:
	fraction = clampf(fraction, 0.0, 1.0)
	visible = show_when_full or fraction < 0.999
	_fill.scale.x = maxf(fraction, 0.001)
	# The camera never turns around Y, so world X is screen X: keep the bar left-aligned.
	_fill.position.x = -(1.0 - fraction) * WIDTH / 2.0
