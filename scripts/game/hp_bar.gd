class_name HpBar
extends Node3D
## A small billboard health bar that hides itself when full. Colours say whose it is: green is
## Meagan's (and wider), blue a guard's, red a wolf's.

const WIDTH := 1.2
const HEIGHT := 0.16
const MEAGAN_GREEN := Color(0.35, 0.82, 0.4)
const GUARD_BLUE := Color(0.35, 0.62, 0.95)
const WOLF_RED := Color(0.95, 0.25, 0.2)

var width := WIDTH
var height := HEIGHT
var _fill: MeshInstance3D


func _init(fill_color := WOLF_RED, bar_width := WIDTH, bar_height := HEIGHT) -> void:
	width = bar_width
	height = bar_height
	var back := _quad(Color(0.1, 0.1, 0.1, 0.8), 0)
	back.mesh.size = Vector2(width + 0.06, height + 0.06)
	add_child(back)
	_fill = _quad(fill_color, 1)
	add_child(_fill)
	visible = false


func _quad(color: Color, priority: int) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(width, height)
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
	_fill.position.x = -(1.0 - fraction) * width / 2.0


## The fill's left-aligned scale and offset, for tests.
func fill_transform() -> Vector2:
	return Vector2(_fill.scale.x, _fill.position.x)
