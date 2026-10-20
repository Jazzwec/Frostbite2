class_name FullReadout
extends PanelContainer
## Over Meagan while the Stockpile is full of what she's gathering: a red "Stockpile full" with
## that resource's icon, so the shrug reads. It's drawn on the screen, not in the world, so it
## stays the same small size at any zoom and sits above the buildings' labels; it never takes
## touches. [agreed 2026-10-20]

## Gap between the top of her head and the readout, in pixels.
const GAP := 28.0
## How quickly the readout follows her (per second), so it doesn't bob with her walk.
const FOLLOW := 18.0

var _camera: Camera3D
var _meagan: Meagan
var _label: RichTextLabel
var _placed := false


func setup(camera: Camera3D, meagan: Meagan) -> void:
	_camera = camera
	_meagan = meagan


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiTheme.panel_style(Color(0.08, 0.1, 0.16, 0.72))
	style.set_corner_radius_all(18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	_label = UiTheme.rich_label(40, Color(1.0, 0.45, 0.4))
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	visible = false


func _process(delta: float) -> void:
	if _meagan == null:
		return
	var s := Game.engine.state
	var full := s.meagan_activity == "full" and s.meagan_target >= 0 and not s.game_over
	if not full:
		visible = false
		_placed = false
		return
	var res: String = Balance.NODES[MapData.node_kind(s, s.meagan_target)].resource
	_label.text = "%s Stockpile full" % UiTheme.icon(res, 40)
	if not visible:
		visible = true
		# A little pop the moment it shows.
		reset_size()
		pivot_offset = size / 2.0
		scale = Vector2(1.25, 1.25)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reset_size()
	var head := _camera.unproject_position(_meagan.head_position())
	var want := head - Vector2(size.x / 2.0, size.y + GAP)
	position = position.lerp(want, minf(1.0, FOLLOW * delta)) if _placed else want
	_placed = true
