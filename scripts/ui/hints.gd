class_name Hints
extends Control
## The first-minute hints: one short line at a time, each shown until the player has done it,
## with an arrow to where it happens (over the target, or at the screen edge when it's off screen).
## Hints that are done are remembered in settings.cfg, so they never repeat, even after Play again.
## Nothing here takes touches. The rules (order, when each is done, where) are in HintRules.

const ARROW_SIZE := 46.0
## Where an off-screen arrow may sit: this far in from each screen edge (left, top, right,
## bottom), clear of the top panel and the buttons under it.
const EDGE_MARGINS := Vector4(60, 560, 60, 120)
## The hint line sits this far above the bottom of the screen, or this gap above the sheet when
## it's open.
const PILL_BOTTOM := 520.0
const SHEET_GAP := 24.0

## The bottom sheet, so the hint can move up out of its way.
var sheet: Control

var _camera: Camera3D
var _meagan: Node3D
var _texts := {}
var _done := {}
var _current := ""
var _start := Vector2.INF
var _pill: PanelContainer
var _label: Label
var _arrow: Control
var _time := 0.0


func setup(camera: Camera3D, meagan: Node3D, texts: Dictionary) -> void:
	_camera = camera
	_meagan = meagan
	_texts = texts
	var cfg := ConfigFile.new()
	cfg.load(Game.SETTINGS_PATH)
	for id in cfg.get_value("hints", "done", []):
		_done[id] = true


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill = PanelContainer.new()
	_pill.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(UiTheme.PAPER, 0.94)))
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.visible = false
	add_child(_pill)
	_label = UiTheme.label("", 40)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_child(_label)
	_arrow = Control.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_arrow)
	_arrow.visible = false
	add_child(_arrow)


func _process(delta: float) -> void:
	var s := Game.engine.state
	if s.game_over or _meagan == null:
		_show("")
		return
	_time += delta
	if _start == Vector2.INF:
		_start = s.meagan_pos
	# Skip past anything already done, in this winter or a past one.
	var next := ""
	for id in HintRules.ORDER:
		if _done.has(id):
			continue
		if HintRules.is_done(id, s, _start):
			_finish(id)
			continue
		next = id
		break
	_show(next)
	if next != "":
		var screen := get_viewport_rect().size
		var bottom := screen.y - PILL_BOTTOM
		if sheet and sheet.visible:
			bottom = minf(bottom, sheet.get_global_rect().position.y - SHEET_GAP)
		_pill.position = Vector2((screen.x - _pill.size.x) / 2.0, bottom - _pill.size.y)
		_place_arrow(HintRules.target(next, s))


func _finish(id: String) -> void:
	_done[id] = true
	var cfg := ConfigFile.new()
	cfg.load(Game.SETTINGS_PATH)
	cfg.set_value("hints", "done", _done.keys())
	cfg.save(Game.SETTINGS_PATH)
	if id == _current:
		Audio.play("tap")


func _show(id: String) -> void:
	if id == _current:
		if _pill.visible:
			_pill.scale = Vector2.ONE * (1.0 + 0.03 * sin(_time * 4.0))
		return
	_current = id
	_pill.visible = id != ""
	_arrow.visible = false
	if id == "":
		return
	_label.text = str(_texts.get(id, id))
	_pill.reset_size()
	_pill.pivot_offset = _pill.size / 2.0
	_pill.scale = Vector2(0.85, 0.85)
	_pill.modulate.a = 0.0
	# Each new hint fades in and its arrow starts bobbing afresh.
	_time = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_pill, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pill, "modulate:a", 1.0, 0.25)


## Puts the arrow over the target, bobbing, or at the screen edge pointing towards it.
func _place_arrow(ground: Vector2) -> void:
	if ground == Vector2.INF:
		_arrow.visible = false
		return
	var world := Vector3(ground.x, 0.0, ground.y)
	var screen := get_viewport_rect().size
	var at := _camera.unproject_position(world + Vector3(0, 3.0, 0))
	var m := EDGE_MARGINS
	var inside := Rect2(m.x, m.y, screen.x - m.x - m.z, screen.y - m.y - m.w)
	var bob := absf(sin(_time * 5.0))
	if inside.has_point(at):
		_arrow.position = at + Vector2(0, -18.0 * bob)
		_arrow.rotation = 0.0
	else:
		# Walk out from the middle of the free area to its edge, and point that way.
		var centre := inside.get_center()
		var dir := (at - centre).normalized()
		var half := inside.size / 2.0
		var reach := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		_arrow.position = centre + dir * (reach - 12.0 * bob)
		_arrow.rotation = dir.angle() - PI / 2.0
	_arrow.visible = true
	_arrow.queue_redraw()


## A chunky arrow pointing down (+Y), its tip at the control's origin.
func _draw_arrow() -> void:
	var a := ARROW_SIZE
	var shape := PackedVector2Array([Vector2(0, 0), Vector2(-a, -a), Vector2(-a * 0.4, -a), Vector2(-a * 0.4, -a * 2.0),
		Vector2(a * 0.4, -a * 2.0), Vector2(a * 0.4, -a), Vector2(a, -a)])
	var outline := shape.duplicate()
	outline.append(shape[0])
	_arrow.draw_colored_polygon(shape, UiTheme.FIRELIGHT)
	_arrow.draw_polyline(outline, UiTheme.INK, 6.0, true)
