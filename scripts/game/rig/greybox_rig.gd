class_name GreyboxRig
extends Node3D
## A greybox character with jointed arms, playing the keyframed clips in `Clips`.
##
## This is the contract a rigged model will keep, so the views never need to change:
## - `play(clip, speed)` loops a clip. Calling it every frame with the same clip is fine.
## - `play_once(clip)` plays a clip once, then goes back to what was asked for meanwhile.
## - `impact(clip)` fires at each clip's hit moment (a method track, on a real model).
## - `tip_position()` is where the held tool's working end is, for effects.
## - `line_target` is where a fishing line goes.
##
## Facing is the owner's job: it rotates the rig about Y. The rig faces +Z.

signal impact(clip: String)

## The body pivot, at the feet. Owners add their character's extras (hat, scarf, bag) to it.
var body: Node3D
## The head pivot, at the neck.
var head: Node3D
var clip := ""
var speed := 1.0
## 0..1: how much the character trembles with cold.
var shiver := 0.0
var line_target := Vector3.INF

var _arm_r: Node3D
var _arm_l: Node3D
var _hand_r: Node3D
var _chest: Node3D
var _tools := {}  # id -> Node3D
var _tool: Node3D
var _line: MeshInstance3D
var _bobber: MeshInstance3D
var _phase := 0.0
var _thrown := false
var _pose := Clips.REST.duplicate()
var _from_pose := Clips.REST.duplicate()
var _blend := 1.0
var _once := ""
var _after_once := "idle"
var _after_once_speed := 1.0
var _time := 0.0

static var _full_keys := {}  # clip -> Array of complete poses


## `spec`: coat (Color), radius and height (of the coat), skin (Color), head_radius, mitten (Color).
func _init(spec: Dictionary) -> void:
	var radius: float = spec.radius
	var height: float = spec.height
	body = Node3D.new()
	add_child(body)
	body.add_child(Shapes.capsule(radius, height, spec.coat, Vector3(0, height / 2.0 + 0.02, 0)))
	head = Node3D.new()
	head.position = Vector3(0, height + 0.01, 0)
	body.add_child(head)
	head.add_child(Shapes.sphere(spec.head_radius, spec.skin, Vector3(0, spec.head_radius * 0.62, 0)))

	var arm_len := height * 0.44
	for side in [-1.0, 1.0]:
		# The character faces +Z, so its right side is -X.
		var arm := Node3D.new()
		arm.position = Vector3(side * (radius + 0.07), height * 0.84, 0)
		body.add_child(arm)
		arm.add_child(Shapes.capsule(0.09, arm_len, spec.coat.darkened(0.08), Vector3(0, -arm_len / 2.0 + 0.06, 0)))
		arm.add_child(Shapes.sphere(0.1, spec.mitten, Vector3(0, -arm_len + 0.04, 0)))
		var hand := Node3D.new()
		hand.position = Vector3(0, -arm_len + 0.04, 0)
		arm.add_child(hand)
		if side < 0.0:
			_arm_r = arm
			_hand_r = hand
		else:
			_arm_l = arm
	_chest = Node3D.new()
	_chest.position = Vector3(0, height * 0.62, radius + 0.3)
	body.add_child(_chest)

	_line = Shapes.cylinder(0.008, 1.0, Color(0.15, 0.15, 0.18))
	_line.top_level = true
	_line.visible = false
	add_child(_line)
	_bobber = Shapes.sphere(0.07, Color(0.9, 0.2, 0.2))
	_bobber.top_level = true
	_bobber.visible = false
	add_child(_bobber)
	play("idle")


func play(next: String, next_speed := 1.0) -> void:
	if _once != "":
		_after_once = next
		_after_once_speed = next_speed
		return
	_switch(next, next_speed)


func play_once(next: String) -> void:
	if _once == "":
		_after_once = clip
		_after_once_speed = speed
	_once = next
	_switch(next, 1.0, true)


## Stops a play_once clip early, e.g. when the character walks off.
func cancel_once() -> void:
	if _once != "":
		_once = ""
		_switch(_after_once, _after_once_speed)


func tip_position() -> Vector3:
	if _tool and _tool.visible:
		return Tools.tip(_tool)
	return _hand_r.global_position


func _switch(next: String, next_speed: float, restart := false) -> void:
	speed = next_speed
	if next == clip and not restart:
		return
	clip = next
	_phase = 0.0
	_thrown = false
	_from_pose = _pose.duplicate()
	_blend = 0.0
	var c: Dictionary = Clips.CLIPS[clip]
	_show_tool(c.tool, c.get("socket", "hand"))


func _show_tool(id: String, socket: String) -> void:
	if _tool:
		_tool.visible = false
	_tool = null
	if id == "":
		return
	var key := "%s@%s" % [id, socket]
	if not _tools.has(key):
		var t := Tools.make(id)
		(_chest if socket == "chest" else _hand_r).add_child(t)
		_tools[key] = t
	_tool = _tools[key]
	_tool.visible = true


func _process(delta: float) -> void:
	_time += delta
	var c: Dictionary = Clips.CLIPS[clip]
	var before := _phase
	_phase += delta * speed / c.length
	var hit: float = c.impact
	if hit >= 0.0 and ((before < hit and _phase >= hit) or (_phase >= 1.0 and _phase - 1.0 >= hit)):
		if c.get("throws", false):
			_thrown = true
		impact.emit(clip)
	if _phase >= 1.0:
		if c.loop:
			_phase = fmod(_phase, 1.0)
			_thrown = false
		elif _once == clip:
			_once = ""
			_switch(_after_once, _after_once_speed)
			return
		else:
			_phase = 1.0

	_blend = minf(1.0, _blend + delta / Clips.BLEND)
	var target := _sample(clip, _phase)
	var w := smoothstep(0.0, 1.0, _blend)
	for joint in target:
		_pose[joint] = lerp(_from_pose[joint], target[joint], w)
	_apply()


func _apply() -> void:
	var tremble := sin(_time * 55.0) * 2.0 * shiver
	body.position.y = _pose.rise
	body.rotation_degrees = Vector3(_pose.lean, _pose.turn, _pose.roll + tremble)
	head.rotation_degrees.x = _pose.head
	_arm_l.rotation_degrees = _pose.arm_l + Vector3(tremble, 0, 0)
	var r: Vector3 = _pose.arm_r
	_arm_r.rotation_degrees = Vector3(r.x - tremble, -r.y, -r.z)
	if _tool:
		_tool.rotation_degrees = _pose.tool
		_tool.visible = not _thrown
	_update_line()


## The fishing line runs from the rod's tip to the hole.
func _update_line() -> void:
	var fishing := _tool != null and _tool.name == "rod" and _tool.visible
	_line.visible = fishing
	_bobber.visible = fishing
	if not fishing:
		return
	var from := Tools.tip(_tool)
	var to := line_target if line_target != Vector3.INF else Vector3(from.x, 0.05, from.z)
	var d := to - from
	if d.length() < 0.01:
		return
	var y := d.normalized()
	var x := y.cross(Vector3.RIGHT if absf(y.x) < 0.9 else Vector3.FORWARD).normalized()
	_line.global_transform = Transform3D(Basis(x, d, x.cross(y)), (from + to) / 2.0)
	_bobber.global_position = to + Vector3(0, 0.04 + sin(_time * 5.0) * 0.03, 0)


## The pose at `phase` (0..1) of a clip, eased between its keys.
static func _sample(name: String, phase: float) -> Dictionary:
	var c: Dictionary = Clips.CLIPS[name]
	var keys: Array = c.keys
	var poses := _poses(name)
	var n := keys.size()
	var i := n - 1
	for k in n:
		if keys[k].t > phase:
			i = k - 1
			break
	var a_t: float
	var b_t: float
	var a: int
	var b: int
	if i < 0:
		# Before the first key: coming round from the last key of a loop.
		a = n - 1
		b = 0
		a_t = keys[a].t - 1.0
		b_t = keys[0].t
	else:
		a = i
		b = i + 1
		a_t = keys[a].t
		if b < n:
			b_t = keys[b].t
		elif c.loop:
			b = 0
			b_t = keys[0].t + 1.0
		else:
			return poses[a]
	var u := clampf((phase - a_t) / maxf(b_t - a_t, 0.0001), 0.0, 1.0)
	match keys[b].get("ease", "smooth"):
		"in":
			u = u * u * u
		"out":
			u = 1.0 - pow(1.0 - u, 3.0)
		_:
			u = smoothstep(0.0, 1.0, u)
	var out := {}
	for joint in poses[a]:
		out[joint] = lerp(poses[a][joint], poses[b][joint], u)
	return out


## A clip's keys as complete poses (REST filled in), built once.
static func _poses(name: String) -> Array:
	if _full_keys.has(name):
		return _full_keys[name]
	var out := []
	for key in Clips.CLIPS[name].keys:
		var pose := Clips.REST.duplicate()
		for joint in key:
			if pose.has(joint):
				pose[joint] = key[joint]
		out.append(pose)
	_full_keys[name] = out
	return out
