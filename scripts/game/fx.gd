class_name Fx
extends Node3D
## One-shot particle bursts and thrown items, shared by everyone. Each kind keeps a few emitters
## and reuses them in turn, so a hit allocates nothing.

const POOL := 4
const KINDS := {
	"chips": {"color": Color(0.78, 0.58, 0.32), "amount": 10, "size": 0.09, "speed": Vector2(2.0, 4.0), "spread": 55.0, "gravity": -9.0, "life": 0.6},
	"snow": {"color": Color(0.95, 0.97, 1.0), "amount": 12, "size": 0.12, "speed": Vector2(1.0, 2.5), "spread": 70.0, "gravity": -3.0, "life": 0.7},
	"sparks": {"color": Color(1.0, 0.82, 0.35), "amount": 10, "size": 0.05, "speed": Vector2(3.0, 5.0), "spread": 70.0, "gravity": -9.0, "life": 0.4},
	"splash": {"color": Color(0.6, 0.8, 1.0), "amount": 12, "size": 0.08, "speed": Vector2(2.0, 3.5), "spread": 25.0, "gravity": -9.0, "life": 0.6},
	"flame": {"color": Color(1.0, 0.55, 0.15), "amount": 14, "size": 0.16, "speed": Vector2(1.5, 3.0), "spread": 30.0, "gravity": 2.0, "life": 0.6},
	"shards": {"color": Color(0.75, 0.9, 1.0), "amount": 16, "size": 0.14, "speed": Vector2(2.0, 4.5), "spread": 80.0, "gravity": -9.0, "life": 0.8},
	"steam": {"color": Color(1.0, 1.0, 1.0, 0.7), "amount": 10, "size": 0.2, "speed": Vector2(0.8, 1.6), "spread": 15.0, "gravity": 0.5, "life": 0.9},
	"dust": {"color": Color(0.82, 0.77, 0.68), "amount": 8, "size": 0.15, "speed": Vector2(0.5, 1.5), "spread": 80.0, "gravity": -1.0, "life": 0.6},
}

static var instance: Fx

var _pools := {}  # kind -> Array of CPUParticles3D
var _next := {}  # kind -> int


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


## A burst of `kind` at `pos`, flying out around `dir`.
static func burst(kind: String, pos: Vector3, dir := Vector3.UP) -> void:
	if instance:
		instance._burst(kind, pos, dir)


## Throws a greybox item (from `Tools`) in an arc, then calls `landed`.
static func throw(item: String, from: Vector3, to: Vector3, seconds := 0.45, height := 1.2, landed := Callable()) -> void:
	if instance == null:
		return
	var node := Tools.make(item)
	instance.add_child(node)
	node.global_position = from
	var spin := Vector3(randf_range(-8, 8), randf_range(-4, 4), randf_range(-8, 8))
	var fly := func(u: float) -> void:
		node.global_position = from.lerp(to, u) + Vector3.UP * height * 4.0 * u * (1.0 - u)
		node.rotation = spin * u
	var land := func() -> void:
		node.queue_free()
		if landed.is_valid():
			landed.call()
	var t := instance.create_tween()
	t.tween_method(fly, 0.0, 1.0, seconds)
	t.tween_callback(land)


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
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * def.size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = m
	e.mesh = mesh
	add_child(e)
	return e
