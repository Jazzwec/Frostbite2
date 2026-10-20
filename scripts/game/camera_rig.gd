class_name CameraRig
extends Node3D
## The fixed-angle orthographic camera, always on Meagan. A one-finger drag anywhere is a
## floating joystick that steers her; a short press is a tap; two fingers pinch to zoom. The mouse
## stands in for a finger through Godot's touch emulation, and its wheel zooms. Apart from the
## wheel only touch events are handled, so the same code runs on a phone.

signal tapped(screen_pos: Vector2)
## The joystick: 0..1 in screen directions (x right, y down). Zero when the finger lifts.
signal steered(dir: Vector2)

const PITCH_DEGREES := 52.0
const DISTANCE := 40.0
## Vertical size of the view in metres: close, so Meagan reads at phone size.
const VIEW_HEIGHT := 22.0
## How far the player can zoom in and out (view height in metres).
const VIEW_HEIGHT_MIN := 16.0
const VIEW_HEIGHT_MAX := 34.0
## One mouse-wheel notch zooms by this factor.
const WHEEL_STEP := 1.1
## How quickly the view eases to the zoom asked for (per second).
const ZOOM_EASE := 12.0
## A press that moves less than this many pixels is a tap, not a drag.
const TAP_SLOP := 14.0
## Joystick: full speed this many pixels from where the finger went down; no movement inside DEAD.
const JOY_RADIUS := 110.0
const JOY_DEAD := 12.0
## How far the view may go past the snowfield's edge, in metres (x, top, bottom).
const EDGE_MARGIN := Vector3(6.0, 8.0, 10.0)

var camera: Camera3D
var follow_target: Node3D
## Extra screen rects (UI) where touches don't reach the world.
var ui_blocker: Callable
## The on-screen joystick to draw, if any.
var joystick: Joystick

var _touch_index := -1
var _press_pos := Vector2.ZERO
var _dragging := false
## Where every finger on the world is: touch index -> position.
var _fingers := {}
## A pinch in progress: the view height and finger spread when it started (spread 0 = none).
var _pinch_from_size := 0.0
var _pinch_from_spread := 0.0
## The view height the camera eases to.
var _zoom := VIEW_HEIGHT


func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = VIEW_HEIGHT
	camera.near = 1.0
	camera.far = 120.0
	var pitch := deg_to_rad(PITCH_DEGREES)
	camera.position = Vector3(0, sin(pitch) * DISTANCE, cos(pitch) * DISTANCE)
	camera.rotation = Vector3(-pitch, 0, 0)
	add_child(camera)
	camera.current = true


func _process(delta: float) -> void:
	camera.size = lerpf(camera.size, _zoom, minf(1.0, ZOOM_EASE * delta))
	if follow_target:
		var t := follow_target.global_position
		global_position = global_position.lerp(Vector3(t.x, 0, t.z), minf(1.0, 9.0 * delta))
	_clamp()


## The view height a pinch gives: fingers spreading apart zoom in.
static func pinch_size(from_size: float, from_spread: float, spread: float) -> float:
	if from_spread <= 0.0 or spread <= 0.0:
		return from_size
	return clampf(from_size * from_spread / spread, VIEW_HEIGHT_MIN, VIEW_HEIGHT_MAX)


## The view height after `notches` mouse-wheel notches (up, negative, zooms in).
static func wheel_size(size: float, notches: int) -> float:
	return clampf(size * pow(WHEEL_STEP, notches), VIEW_HEIGHT_MIN, VIEW_HEIGHT_MAX)


## The view height the camera is easing to.
func zoom() -> float:
	return _zoom


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var wheel := event as InputEventMouseButton
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = wheel_size(_zoom, -1)
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = wheel_size(_zoom, 1)
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not _blocked(touch.position):
			_fingers[touch.index] = touch.position
			if _fingers.size() == 2:
				_start_pinch()
				return
		elif not touch.pressed:
			_fingers.erase(touch.index)
			if _fingers.size() < 2:
				_pinch_from_spread = 0.0
		if touch.pressed:
			if _touch_index != -1 or _blocked(touch.position) or _pinch_from_spread > 0.0:
				return
			_touch_index = touch.index
			_press_pos = touch.position
			_dragging = false
		elif touch.index == _touch_index:
			_touch_index = -1
			if _dragging:
				steered.emit(Vector2.ZERO)
				if joystick:
					joystick.hide()
			else:
				tapped.emit(touch.position)
			_dragging = false
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _fingers.has(drag.index):
			_fingers[drag.index] = drag.position
		if _pinch_from_spread > 0.0 and _fingers.size() >= 2:
			_zoom = pinch_size(_pinch_from_size, _pinch_from_spread, _spread())
			return
		if drag.index != _touch_index:
			return
		if not _dragging and drag.position.distance_to(_press_pos) > TAP_SLOP:
			_dragging = true
			if joystick:
				joystick.radius = JOY_RADIUS
				joystick.show_at(_press_pos)
		if _dragging:
			var offset := drag.position - _press_pos
			if joystick:
				joystick.move_knob(offset)
			var strength := clampf((offset.length() - JOY_DEAD) / (JOY_RADIUS - JOY_DEAD), 0.0, 1.0)
			steered.emit(offset.normalized() * strength)


## A second finger turns the one-finger joystick into a pinch.
func _start_pinch() -> void:
	if _dragging:
		steered.emit(Vector2.ZERO)
		if joystick:
			joystick.hide()
	_touch_index = -1
	_dragging = false
	_pinch_from_size = _zoom
	_pinch_from_spread = _spread()


## How far apart the first two fingers are, in pixels.
func _spread() -> float:
	var points := _fingers.values()
	return (points[0] as Vector2).distance_to(points[1])


func _clamp() -> void:
	var b := MapData.BOUNDS
	# Keep the view mostly over the snowfield rather than the empty land around it.
	global_position.x = clampf(global_position.x, b.position.x + EDGE_MARGIN.x, b.end.x - EDGE_MARGIN.x)
	global_position.z = clampf(global_position.z, b.position.y + EDGE_MARGIN.y, b.end.y - EDGE_MARGIN.z)


func _blocked(pos: Vector2) -> bool:
	return ui_blocker.is_valid() and ui_blocker.call(pos)


## What's under a screen point: {kind, index} for a tappable thing, else {kind: "ground", pos: Vector3}.
func pick(screen_pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0, Layers.TAPPABLE)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("kind"):
		return {"kind": hit.collider.get_meta("kind"), "index": hit.collider.get_meta("index")}
	var ground: Variant = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if ground == null:
		return {}
	var p: Vector3 = ground
	var b := MapData.BOUNDS
	p.x = clampf(p.x, b.position.x + 0.5, b.end.x - 0.5)
	p.z = clampf(p.z, b.position.y + 0.5, b.end.y - 0.5)
	return {"kind": "ground", "pos": p}
