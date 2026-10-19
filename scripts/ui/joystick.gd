class_name Joystick
extends Control
## The floating joystick: a ring where the finger went down and a knob that follows it.
## Drawing only; CameraRig reads the touches and drives it.

const RING_COLOR := Color(1, 1, 1, 0.22)
const RIM_COLOR := Color(1, 1, 1, 0.55)
const KNOB_COLOR := Color(1, 1, 1, 0.8)

var radius := 110.0
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_at(pos: Vector2) -> void:
	_center = pos
	_knob = Vector2.ZERO
	visible = true
	queue_redraw()


## `offset` is the finger's offset from the centre, in pixels; the knob stays inside the ring.
func move_knob(offset: Vector2) -> void:
	_knob = offset.limit_length(radius)
	queue_redraw()


func _draw() -> void:
	draw_circle(_center, radius, RING_COLOR)
	draw_arc(_center, radius, 0.0, TAU, 48, RIM_COLOR, 4.0, true)
	draw_circle(_center + _knob, radius * 0.42, KNOB_COLOR)
