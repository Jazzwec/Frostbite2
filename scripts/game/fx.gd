class_name Fx
extends Node3D
## One-shot particle bursts, thrown items and "+N" pop numbers, shared by everyone. Bursts and
## pops come from small pools reused in turn, so a hit allocates nothing.

const POOL := 4
const POP_POOL := 16
const POP_RISE := 1.2
const POP_TIME := 0.7
const KINDS := {
	"chips": {"color": Color(0.78, 0.58, 0.32), "amount": 10, "size": 0.09, "speed": Vector2(2.0, 4.0), "spread": 55.0, "gravity": -9.0, "life": 0.6},
	"snow": {"color": Color(0.95, 0.97, 1.0), "amount": 12, "size": 0.12, "speed": Vector2(1.0, 2.5), "spread": 70.0, "gravity": -3.0, "life": 0.7},
	"sparks": {"color": Color(1.0, 0.82, 0.35), "amount": 10, "size": 0.05, "speed": Vector2(3.0, 5.0), "spread": 70.0, "gravity": -9.0, "life": 0.4},
	"splash": {"color": Color(0.6, 0.8, 1.0), "amount": 12, "size": 0.08, "speed": Vector2(2.0, 3.5), "spread": 25.0, "gravity": -9.0, "life": 0.6},
	"flame": {"color": Color(1.0, 0.55, 0.15), "amount": 14, "size": 0.16, "speed": Vector2(1.5, 3.0), "spread": 30.0, "gravity": 2.0, "life": 0.6},
	"shards": {"color": Color(0.75, 0.9, 1.0), "amount": 16, "size": 0.14, "speed": Vector2(2.0, 4.5), "spread": 80.0, "gravity": -9.0, "life": 0.8},
	"steam": {"color": Color(1.0, 1.0, 1.0, 0.7), "amount": 10, "size": 0.2, "speed": Vector2(0.8, 1.6), "spread": 15.0, "gravity": 0.5, "life": 0.9},
	# Her breath in the cold (AFK V8).
	"breath": {"color": Color(1.0, 1.0, 1.0, 0.6), "amount": 4, "size": 0.12, "speed": Vector2(0.2, 0.5), "spread": 20.0, "gravity": 0.3, "life": 0.9},
	# A footstep's kick of snow (AFK V6).
	"step": {"color": Color(0.95, 0.97, 1.0), "amount": 5, "size": 0.07, "speed": Vector2(0.4, 1.0), "spread": 60.0, "gravity": -2.0, "life": 0.2},
	"dust": {"color": Color(0.82, 0.77, 0.68), "amount": 8, "size": 0.15, "speed": Vector2(0.5, 1.5), "spread": 80.0, "gravity": -1.0, "life": 0.6},
	# A building finishing or levelling up.
	"confetti": {"color": Color.WHITE, "amount": 44, "size": 0.32, "speed": Vector2(5.0, 9.0), "spread": 50.0, "gravity": -9.0, "life": 1.1,
		"colors": [Color(1.0, 0.72, 0.1), Color(0.92, 0.2, 0.25), Color(0.15, 0.55, 1.0), Color(0.25, 0.8, 0.3), Color(0.95, 0.35, 0.8)]},
	"snow_big": {"color": Color(0.95, 0.97, 1.0), "amount": 34, "size": 0.18, "speed": Vector2(2.0, 4.5), "spread": 85.0, "gravity": -3.0, "life": 0.9},
	# A hit's secondary flourish (fight_v2 review 1): a few dark ink flecks flung away from the
	# blow, small enough to leave the struck one's shape readable.
	"ink": {"color": Color(0.17, 0.14, 0.17), "amount": 4, "size": 0.08, "speed": Vector2(2.5, 4.0), "spread": 28.0, "gravity": -7.0, "life": 0.32},
}
## Her stick's sweep on the snow (fight_v2 review 2): a pale-gold crescent at her reach that runs
## across exactly the arc it hits in SWEEP_TIME, then fades; no filled sector. Gold is hers; rust
## is theirs.
const SWEEP_COLOR := Color(0.93, 0.74, 0.36, 0.95)
const SWEEP_WIDTH := 0.1
const SWEEP_SPAN := 28.0
const SWEEP_TIME := 0.12
const SWEEP_FADE := 0.1

static var instance: Fx

var _pools := {}  # kind -> Array of CPUParticles3D
var _next := {}  # kind -> int
var _sweeps := {}  # "reach" -> crescent MeshInstance3D
## Impact marks: a cream star with a rust rim where a blow lands, for IMPACT_TIME, drawn over
## bodies and bars: the brightest thing in a fight (fight_v2 reviews 2 and 3: about 24 px on the
## phone, 30 px for a kill, 150 ms).
const IMPACT_SIZE := 0.72
const IMPACT_TIME := 0.14
## A counter (a hit while it recovers) gets ochre rays instead of terracotta (review 4).
const IMPACT_RAYS := Color(0.66, 0.27, 0.16)
const COUNTER_RAYS := Color(0.86, 0.62, 0.22)
## A troll's slam: one broken ring of snow puffing out on the ground (review 4: 70-90 px, ~200 ms).
const SLAM_PUFF_SIZE := 1.9
const SLAM_PUFF_TIME := 0.2
const IMPACT_POOL := 8
var _impacts: Array[Sprite3D] = []
var _next_impact := 0
static var _stars := {}
var _puff: MeshInstance3D
var _pops: Array[Label3D] = []
var _pop_tweens := {}  # Label3D -> its running Tween
var _next_pop := 0


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


## A burst of `kind` at `pos`, flying out around `dir`.
static func burst(kind: String, pos: Vector3, dir := Vector3.UP) -> void:
	if instance:
		instance._burst(kind, pos, dir)


## Throws a greybox item (from `Tools`) in an arc, then calls `landed`. An `aimed` one (a raider's
## shard) points along its flight instead of tumbling, so its trail shows where it's going.
static func throw(item: String, from: Vector3, to: Vector3, seconds := 0.45, height := 1.2, landed := Callable(), aimed := false) -> void:
	if instance == null:
		return
	var node := Tools.make(item)
	instance.add_child(node)
	node.global_position = from
	var spin := Vector3(randf_range(-8, 8), randf_range(-4, 4), randf_range(-8, 8))
	var arc := func(u: float) -> Vector3: return from.lerp(to, u) + Vector3.UP * height * 4.0 * u * (1.0 - u)
	var fly := func(u: float) -> void:
		node.global_position = arc.call(u)
		if aimed:
			var ahead: Vector3 = arc.call(minf(u + 0.05, 1.0)) - arc.call(maxf(u - 0.05, 0.0))
			if ahead.length() > 0.001:
				node.look_at(node.global_position + ahead, Vector3.UP if absf(ahead.normalized().y) < 0.99 else Vector3.RIGHT)
		else:
			node.rotation = spin * u
	var land := func() -> void:
		node.queue_free()
		if landed.is_valid():
			landed.call()
	var t := instance.create_tween()
	t.tween_method(fly, 0.0, 1.0, seconds)
	t.tween_callback(land)


## A blow's impact mark at `pos`, `size` times the usual size, its rays flung away from `from`
## (review 5: a few unequal rays pointing away from the contact); a counter's rays are ochre.
static func impact(pos: Vector3, size := 1.0, counter := false, from := Vector3.INF) -> void:
	if instance:
		instance._impact(pos, size, counter, from)


func _impact(pos: Vector3, size: float, counter := false, from := Vector3.INF) -> void:
	if _impacts.is_empty():
		for i in IMPACT_POOL:
			var s := Sprite3D.new()
			s.texture = _impact_star(IMPACT_RAYS)
			s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			s.no_depth_test = true
			s.render_priority = 30
			s.shaded = false
			s.visible = false
			add_child(s)
			_impacts.append(s)
	var mark := _impacts[_next_impact]
	_next_impact = (_next_impact + 1) % IMPACT_POOL
	mark.global_position = pos
	mark.texture = _impact_star(COUNTER_RAYS if counter else IMPACT_RAYS)
	mark.pixel_size = IMPACT_SIZE * size / 128.0
	# Turn its rays (drawn along +X) away from the blow, on screen.
	var camera := get_viewport().get_camera_3d()
	if camera and from != Vector3.INF:
		var away := camera.unproject_position(pos) - camera.unproject_position(from)
		mark.rotation.z = -away.angle() if away.length() > 0.5 else 0.0
	else:
		mark.rotation.z = randf() * TAU
	mark.modulate = Color.WHITE
	mark.scale = Vector3.ONE * 0.6
	mark.visible = true
	var t := mark.create_tween().set_parallel()
	t.tween_property(mark, "scale", Vector3.ONE * 1.1, IMPACT_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(mark, "modulate:a", 0.0, IMPACT_TIME * 0.5).set_delay(IMPACT_TIME * 0.5)
	t.chain().tween_callback(mark.hide)


## The impact mark: an opaque cream centre with four unequal rays in `rays` fanned along +X (away
## from the blow once turned), drawn once per colour (reviews 4 and 5).
const IMPACT_RAY_SET := [[-48.0, 0.78], [-14.0, 1.0], [20.0, 0.86], [52.0, 0.62]]


static func _impact_star(rays: Color) -> Texture2D:
	var key := rays.to_html()
	if not _stars.has(key):
		var size := 128
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var c := Vector2(size, size) / 2.0
		for y in size:
			for x in size:
				var v := Vector2(x + 0.5, y + 0.5) - c
				var d := v.length()
				var col := Color(0, 0, 0, 0)
				# A ray: a tapering wedge from the centre out to its length.
				for ray in IMPACT_RAY_SET:
					var off := absf(rad_to_deg(angle_difference(deg_to_rad(ray[0]), v.angle())))
					var length: float = 62.0 * ray[1]
					var half := 16.0 * (1.0 - d / length)
					if d <= length and off <= half:
						col = rays
						col.a = clampf((half - off) * 0.5, 0.0, 1.0)
				if d <= 22.0:
					col = Color(1.0, 0.96, 0.86)
					col.a = clampf(22.5 - d, 0.0, 1.0) if d > 21.0 else 1.0
				img.set_pixel(x, y, col)
		_stars[key] = ImageTexture.create_from_image(img)
	return _stars[key]


## A troll's slam on the snow at `pos`: one broken ring puffing out and fading.
static func slam_puff(pos: Vector3) -> void:
	if instance:
		instance._slam_puff(pos)


func _slam_puff(pos: Vector3) -> void:
	if _puff == null:
		_puff = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		quad.orientation = PlaneMesh.FACE_Y
		_puff.mesh = quad
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = broken_ring_texture()
		_puff.material_override = m
		_puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_puff)
	_puff.global_position = pos + Vector3(0, 0.06, 0)
	_puff.scale = Vector3.ONE * SLAM_PUFF_SIZE * 0.5
	_puff.visible = true
	var m := _puff.material_override as StandardMaterial3D
	m.albedo_color = Color.WHITE
	var t := _puff.create_tween().set_parallel()
	t.tween_property(_puff, "scale", Vector3.ONE * SLAM_PUFF_SIZE * 2.0, SLAM_PUFF_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(m, "albedo_color:a", 0.0, SLAM_PUFF_TIME).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(_puff.hide)


## The broken ring, white: the slam puff tints it snow, the counter halo ochre.
static var _ring: Texture2D


static func broken_ring_texture() -> Texture2D:
	if _ring == null:
		_ring = _broken_ring()
	return _ring


## A ring of snow broken into chunks, white with a blue-grey edge.
static func _broken_ring() -> Texture2D:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var v := Vector2(x + 0.5, y + 0.5) - c
			var d := v.length() / 64.0
			var a := v.angle()
			var gap := absf(sin(a * 5.0 + 0.7)) < 0.22
			var col := Color(0, 0, 0, 0)
			if not gap and d > 0.62 and d < 0.98:
				col = Color(0.62, 0.7, 0.8) if d > 0.9 or d < 0.68 else Color(0.97, 0.98, 1.0)
				col.a = 0.95
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


## Her stick's sweep from `pos`, facing `dir` (on the ground), `reach` metres and `arc` degrees.
static func sweep(pos: Vector3, dir: Vector3, reach: float, arc: float) -> void:
	if instance:
		instance._sweep(pos, dir, reach, arc)


func _sweep(pos: Vector3, dir: Vector3, reach: float, arc: float) -> void:
	var key := "%.2f" % reach
	if not _sweeps.has(key):
		var mi := MeshInstance3D.new()
		mi.mesh = WolfView.sector(reach - SWEEP_WIDTH, reach, SWEEP_SPAN)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color = SWEEP_COLOR
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_sweeps[key] = mi
	var crescent: MeshInstance3D = _sweeps[key]
	var flat := Vector3(dir.x, 0.0, dir.z)
	var facing := atan2(flat.x, flat.z) if flat.length() > 0.01 else 0.0
	var half := deg_to_rad((arc - SWEEP_SPAN) / 2.0)
	crescent.global_position = Vector3(pos.x, 0.05, pos.z)
	crescent.visible = true
	var m := crescent.material_override as StandardMaterial3D
	m.albedo_color = SWEEP_COLOR
	var t := crescent.create_tween()
	# Across the arc, her right to her left, then gone.
	t.tween_method(func(a: float) -> void: crescent.rotation.y = a, facing + half, facing - half, SWEEP_TIME)
	t.tween_property(m, "albedo_color:a", 0.0, SWEEP_FADE)
	t.tween_callback(crescent.hide)


## A number (or short word) that pops up at `pos`, rises and fades.
static func pop(text: String, pos: Vector3, color := Color.WHITE, size := POP_SIZE) -> void:
	if instance:
		instance._pop(text, pos, color, size)


## The pop numbers' font size.
const POP_SIZE := 54


func _pop(text: String, pos: Vector3, color: Color, size := POP_SIZE) -> void:
	if _pops.is_empty():
		for i in POP_POOL:
			var l := Shapes.label("", Vector3.ZERO, 54)
			l.visible = false
			add_child(l)
			_pops.append(l)
	var l := _pops[_next_pop]
	_next_pop = (_next_pop + 1) % POP_POOL
	l.text = text
	l.font_size = size
	l.modulate = color
	l.global_position = pos
	l.scale = Vector3.ONE * 0.6
	l.visible = true
	if _pop_tweens.has(l) and _pop_tweens[l].is_valid():
		_pop_tweens[l].kill()
	var t := l.create_tween().set_parallel(true)
	_pop_tweens[l] = t
	t.tween_property(l, "global_position:y", pos.y + POP_RISE, POP_TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(POP_TIME - 0.3)
	t.chain().tween_callback(func(): l.visible = false)


func _burst(kind: String, pos: Vector3, dir: Vector3) -> void:
	if not _pools.has(kind):
		var pool := []
		for i in POOL:
			pool.append(_make(KINDS[kind]))
		_pools[kind] = pool
		_next[kind] = 0
	var e: CPUParticles3D = _pools[kind][_next[kind]]
	_next[kind] = (_next[kind] + 1) % POOL
	e.global_position = pos
	e.direction = dir
	e.restart()


func _make(def: Dictionary) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.emitting = false
	e.one_shot = true
	e.explosiveness = 0.9
	e.local_coords = false
	e.amount = def.amount
	e.lifetime = def.life
	e.spread = def.spread
	e.initial_velocity_min = def.speed.x
	e.initial_velocity_max = def.speed.y
	e.gravity = Vector3(0, def.gravity, 0)
	e.angular_velocity_min = -360.0
	e.angular_velocity_max = 360.0
	e.scale_amount_min = 0.6
	e.scale_amount_max = 1.3
	var ramp := Gradient.new()
	var c: Color = def.color
	ramp.set_color(0, c)
	ramp.set_color(1, Color(c, 0.0))
	e.color_ramp = ramp
	if def.has("colors"):
		# Each piece picks one of these colours (the ramp above then fades it out).
		var pick := Gradient.new()
		pick.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		var colors: Array = def.colors
		pick.offsets = PackedFloat32Array(range(colors.size()).map(func(i): return float(i) / colors.size()))
		pick.colors = PackedColorArray(colors)
		e.color_initial_ramp = pick
	# Soft round flecks, like dabs of paint, facing the camera (fighting review, 2026-10-20: square
	# bursts erased the wolves' shapes).
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * def.size * 1.4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = Smoke.soft_puff()
	mesh.material = m
	e.mesh = mesh
	add_child(e)
	return e
