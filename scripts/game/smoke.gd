class_name Smoke
extends Node3D
## A soft watercolour smoke column, like the agreed visual's (AFK V7, 2026-10-20): a few
## billboard puffs of a radial wash that rise, drift with the wind and swell, growing in and
## shrinking away so none pops. Scripted rather than GPU particles: see-through particles with a
## colour ramp didn't draw here (2026-10-20). `rate` (0 to 1) thins it; unshaded and see-through,
## so the ink look leaves it as it is. `Smoke.halo` makes a faint warm halo (lanterns). No lights.

static var _puff_tex: GradientTexture2D

## How many puffs the column holds, each one's life (s), how fast it climbs (m/s) and how wide
## it starts (m).
var puffs := 10
var life := 4.5
var rise := 0.9
var width := 0.9
## 0 to 1: how much of the column is showing.
var rate := 1.0
## Drift with the wind, in m/s.
var drift := Vector3(0.22, 0.0, -0.06)

var _quads: Array[MeshInstance3D] = []
var _ages: PackedFloat32Array = []


static func column(w := 0.9, count := 10, climb := 0.9, seconds := 4.5) -> Smoke:
	var s := Smoke.new()
	s.width = w
	s.puffs = count
	s.rise = climb
	s.life = seconds
	return s


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width)
	quad.material = _billboard(Color(0.6, 0.62, 0.67, 0.95))
	for i in puffs:
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_quads.append(mi)
	_ages.resize(puffs)
	# Spread over a life, so the column is already up when it appears.
	for i in puffs:
		_ages[i] = life * float(i) / puffs


func _process(delta: float) -> void:
	for i in puffs:
		_ages[i] = fmod(_ages[i] + delta, life)
		var t := _ages[i] / life
		var mi := _quads[i]
		# A puff shows only while the column is thick enough for it.
		var shown := float(i) / puffs < rate
		mi.visible = shown and visible
		if not mi.visible:
			continue
		mi.position = Vector3(0, rise * _ages[i], 0) + drift * _ages[i] + Vector3(sin(i * 2.3) * 0.12, 0, cos(i * 1.7) * 0.12)
		# Grows in, swells as it climbs, and shrinks away.
		var swell := lerpf(0.55, 2.3, t)
		mi.scale = Vector3.ONE * swell * smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.7, 1.0, t))


## A faint warm halo, `size` metres across, facing the camera.
static func halo(size := 0.9, color := Color(0.95, 0.7, 0.4, 0.4)) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = _billboard(color)
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _billboard(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.albedo_color = color
	m.albedo_texture = _soft_puff()
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


## A radial wash: full in the middle, soft to nothing at the edge.
static func _soft_puff() -> GradientTexture2D:
	if _puff_tex:
		return _puff_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.75))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	_puff_tex = t
	return t
