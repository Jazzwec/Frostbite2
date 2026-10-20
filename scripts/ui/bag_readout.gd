class_name BagReadout
extends PanelContainer
## The one readout over Meagan: what's in her bag ("Bag 12/20", or a coral "BAG FULL", from the
## Astra review 2026-10-20) with
## what she carries on a short line under it. It's drawn on the screen, not in the world, so it
## stays the same small size at any zoom and sits above the buildings' labels. Hidden when the
## bag is empty; it never takes touches.

## Gap between the top of her load (or her head) and the readout, in pixels.
const GAP := 34.0
## How quickly the readout follows her (per second), so it doesn't bob with her walk.
const FOLLOW := 18.0

var _camera: Camera3D
var _meagan: Meagan
var _count: Label
var _contents: RichTextLabel
var _was_full := false
var _placed := false


func setup(camera: Camera3D, meagan: Meagan) -> void:
	_camera = camera
	_meagan = meagan


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiTheme.panel_style(Color(UiTheme.PAPER, 0.93))
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_count = UiTheme.label("", 34)
	_count.autowrap_mode = TextServer.AUTOWRAP_OFF
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_count)
	_contents = UiTheme.rich_label(28, UiTheme.INK)
	_contents.autowrap_mode = TextServer.AUTOWRAP_OFF
	_contents.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_contents)
	visible = false


func _process(delta: float) -> void:
	if _meagan == null:
		return
	var s := Game.engine.state
	var total := Economy.bag_total(s)
	visible = total > 0.01 and not s.game_over
	if not visible:
		_placed = false
		_was_full = false
		return
	var cap := Economy.bag_cap(s)
	var full := total >= cap - 0.01
	_count.text = "BAG FULL" if full else "Bag %s/%s" % [Fmt.num(floorf(total)), Fmt.num(cap)]
	_count.add_theme_color_override("font_color", UiTheme.FALU if full else UiTheme.INK)
	if full and not _was_full:
		# A little pop the moment the bag fills up.
		pivot_offset = size / 2.0
		scale = Vector2(1.25, 1.25)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_was_full = full
	var parts := []
	for res in CarryStack.ORDER:
		if s.bag[res] >= 1.0:
			parts.append("%s %s" % [UiTheme.icon(res, 30), Fmt.num(floorf(s.bag[res]))])
	_contents.text = "  ".join(parts)
	_contents.visible = not parts.is_empty()
	reset_size()
	# Above whichever is higher on screen: the top of her load or her head.
	var top := _camera.unproject_position(_meagan.bag_position())
	var head := _camera.unproject_position(_meagan.head_position())
	var anchor := Vector2(head.x, minf(top.y, head.y))
	var want := anchor - Vector2(size.x / 2.0, size.y + GAP)
	position = position.lerp(want, minf(1.0, FOLLOW * delta)) if _placed else want
	_placed = true
