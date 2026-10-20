class_name Footprints
extends Node3D
## Footprints in the snow behind Meagan and walking Jans, like the trails in the agreed visual
## (AFK V6, 2026-10-20). A fixed pool of flat prints reused in turn, one shared material, each
## fading out over its life; Meagan also kicks up a small snow puff on each step.

const SHADER := preload("res://scripts/game/ink/footprint.gdshader")
## How many prints there can be at once, and how long one lasts. [proto]
const POOL := 120
const LIFE := 7.0
## A step every this many metres walked, each foot this far to the side of the line. [proto]
## Sizes and spacing from the Astra review (boot-like, a clear left/right rhythm).
const STEP := 0.48
const FOOT_SIDE := 0.09
const PRINT_SIZE := Vector2(0.14, 0.28)
## Each print turns a little, so a trail isn't ruled straight.
const TURN_JITTER := 0.09

var _prints: Array[MeshInstance3D] = []
var _ages: PackedFloat32Array = []
var _next := 0
## Per walker (any node): {pos: last step's position, left: which foot is next}.
var _walkers := {}


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var quad := PlaneMesh.new()
	quad.size = PRINT_SIZE
	quad.material = mat
	for i in POOL:
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_prints.append(mi)
	_ages.resize(POOL)
	_ages.fill(LIFE)


## Called every frame with whoever is walking; `puffs` kicks up snow on each step (Meagan).
func track(walker: Node3D, walking: bool, puffs := false) -> void:
	var p := walker.global_position
	var w: Dictionary = _walkers.get(walker, {})
	if w.is_empty() or not walking:
		_walkers[walker] = {"pos": p, "left": true}
		return
	var last: Vector3 = w.pos
	var step := Vector3(p.x - last.x, 0, p.z - last.z)
	if step.length() < STEP:
		return
	var dir := step.normalized()
	var side := Vector3(dir.z, 0, -dir.x) * (FOOT_SIDE if w.left else -FOOT_SIDE)
	_press(Vector3(p.x, 0.02, p.z) + side, dir)
	if puffs:
		Fx.burst("step", Vector3(p.x, 0.05, p.z) + side)
	_walkers[walker] = {"pos": p, "left": not w.left}


func _press(at: Vector3, dir: Vector3) -> void:
	var mi := _prints[_next]
	_ages[_next] = 0.0
	_next = (_next + 1) % POOL
	mi.position = at
	mi.rotation = Vector3(0, atan2(dir.x, dir.z) + randf_range(-TURN_JITTER, TURN_JITTER), 0)
	mi.visible = true
	mi.set_instance_shader_parameter("fade", 1.0)


func _process(delta: float) -> void:
	for i in POOL:
		if _ages[i] >= LIFE:
			continue
		_ages[i] += delta
		var mi := _prints[i]
		if _ages[i] >= LIFE:
			mi.visible = false
		else:
			# Crisp for a second, then melting away smoothly.
			mi.set_instance_shader_parameter("fade", 1.0 - smoothstep(1.0, LIFE, _ages[i]))
	# Forget walkers that have gone (a Jan who left).
	for w in _walkers.keys():
		if not is_instance_valid(w):
			_walkers.erase(w)
