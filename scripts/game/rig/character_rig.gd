class_name CharacterRig
extends Node3D
## Plays the keyframed clips in `Clips` on a character. Subclasses pose a body from the sampled
## joints: `GreyboxRig` moves greybox shapes, `ModelRig` moves a rigged model's bones.
##
## The contract the views rely on:
## - `play(clip, speed)` loops a clip. Calling it every frame with the same clip is fine.
## - `play_once(clip)` plays a clip once, then goes back to what was asked for meanwhile.
## - `impact(clip)` fires at each clip's hit moment.
## - `tip_position()` is where the held tool's working end is, for effects.
## - `line_target` is where a fishing line goes.
## - `body` follows the torso (owners hang things off it, like her carry stack); `head` the head.
##
## Facing is the owner's job: it rotates the rig about Y. The rig faces +Z.

signal impact(clip: String)

## Follows the torso, pivoting at the feet like the greybox body did.
var body: Node3D
## Follows the head, at the neck.
var head: Node3D
var clip := ""
var speed := 1.0
## 0..1: how much the character trembles with cold.
var shiver := 0.0
var line_target := Vector3.INF

## Where held tools and carried things hang; subclasses create these.
var _hand_r: Node3D
var _chest: Node3D
var _tools := {}  # id@socket -> Node3D
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
## Impacts with weight (AFK N3, from Astra's animation review and the usual game-feel practice):
## on a blow's hit moment the clip holds still a few frames (hit-stop) and the body squashes a
## little and springs back, keeping its volume.
const HIT_STOP := 0.05
const SQUASH_TIME := 0.09
const SQUASH := 0.05
const HEAVY_CLIPS := ["chop", "split", "scavenge", "build", "fight", "guard_attack"]
var _hold := 0.0
var _squash := 0.0
var _base_scale := Vector3.ZERO
## The float dips when a fish bites (1 at the bite, easing back to 0).
var _dip := 0.0
## A quick forward dip of the whole body, in degrees, easing out (dip()).
var _nod := 0.0
## Whether the character is on screen: off it, the clip keeps time (and its impacts still fire)
## but the body isn't posed, which is most of a rig's cost.
var _screen: VisibleOnScreenNotifier3D

static var _full_keys := {}  # clip -> Array of complete poses


## Subclasses call this once their body, sockets and `body`/`head` exist.
func _finish_setup() -> void:
	_screen = VisibleOnScreenNotifier3D.new()
	_screen.aabb = AABB(Vector3(-1.2, 0, -1.2), Vector3(2.4, 2.8, 2.4))
	add_child(_screen)
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


## Poses the body from the sampled joints (see `Clips`). `tremble` is degrees of cold shiver.
func _apply_pose(_p: Dictionary, _tremble: float) -> void:
	pass


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
	_update_squash(delta)
	_dip = move_toward(_dip, 0.0, delta * 3.0)
	_nod = move_toward(_nod, 0.0, delta * 40.0)
	if _hold > 0.0:
		_hold -= delta
		return
	var c: Dictionary = Clips.CLIPS[clip]
	var before := _phase
	_phase += delta * speed / c.length
	var hit: float = c.impact
	if hit >= 0.0 and ((before < hit and _phase >= hit) or (_phase >= 1.0 and _phase - 1.0 >= hit)):
		if c.get("throws", false):
			_thrown = true
		if clip in HEAVY_CLIPS and _screen.is_on_screen():
			_hold = HIT_STOP
			_squash = SQUASH_TIME
		if clip == "fish" or clip == "fish_sit":
			_dip = 1.0
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
	if not _screen.is_on_screen():
		return
	var target := _sample(clip, _phase)
	var w := smoothstep(0.0, 1.0, _blend)
	for joint in target:
		_pose[joint] = lerp(_from_pose[joint], target[joint], w)
	if _nod > 0.0:
		var posed := _pose.duplicate()
		posed.lean += _nod
		_apply_pose(posed, sin(_time * 55.0) * 2.0 * shiver)
	else:
		_apply_pose(_pose, sin(_time * 55.0) * 2.0 * shiver)
	if _tool:
		_tool.rotation_degrees = _pose.tool
		_tool.visible = not _thrown
	_update_line()


## A quick dip of `degrees` forward that eases out over about 0.12 s (a piece set down).
func dip(degrees: float) -> void:
	_nod = maxf(_nod, degrees)


## The squash after a blow: down and out, springing back, volume kept.
func _update_squash(delta: float) -> void:
	if _squash <= 0.0:
		return
	if _base_scale == Vector3.ZERO:
		_base_scale = scale
	_squash = maxf(0.0, _squash - delta)
	var k := sin(PI * (1.0 - _squash / SQUASH_TIME)) * SQUASH
	scale = _base_scale * Vector3(1.0 + k * 0.5, 1.0 - k, 1.0 + k * 0.5)
	if _squash <= 0.0:
		scale = _base_scale


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
	# A gentle bob while waiting (about a second a cycle), a quick dip at the bite (AFK N5).
	_bobber.global_position = to + Vector3(0, 0.04 + sin(_time * 6.0) * 0.02 - 0.06 * _dip, 0)


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
