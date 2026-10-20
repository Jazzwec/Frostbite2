class_name MilestoneCards
extends PanelContainer
## Milestone cards: when one is reached it pops up under the top bar for a few seconds with a
## chime, one at a time, and is remembered in settings.cfg so it never shows again. The rules are
## in MilestoneRules; the writing is in data/milestones.json.

const SHOW_TIME := 3.0
const CHECK_EVERY := 0.5
## Just under the top bar's row of buttons (where warning banners also go: a card waits while
## a banner is up).
const TOP := 500.0
## A breath between one card and the next.
const GAP := 0.4

## The HUD's warning banner, so a card never covers it.
var banner: Control

var _milestones: Array = []
var _done := {}
var _queue: Array = []
var _showing := 0.0
var _gap := 0.0
var _check_in := 0.0
var _title: RichTextLabel
var _message: Label


func setup(milestones: Array) -> void:
	_milestones = milestones
	var cfg := ConfigFile.new()
	cfg.load(Game.SETTINGS_PATH)
	for id in cfg.get_value("milestones", "done", []):
		_done[id] = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UiTheme.panel_style())
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 70
	offset_right = -70
	offset_top = TOP
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_title = UiTheme.rich_label(44, UiTheme.TITLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	_message = UiTheme.label("", 34)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_message)
	visible = false


func _process(delta: float) -> void:
	_check_in -= delta
	if _check_in <= 0.0:
		_check_in = CHECK_EVERY
		_check()
	if _showing > 0.0:
		_showing -= delta
		if _showing <= 0.0:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.25)
			t.tween_callback(func(): visible = false)
			_gap = GAP + 0.25
	elif _gap > 0.0:
		_gap -= delta
	elif not _queue.is_empty() and not visible and not (banner and banner.visible):
		_show(_queue.pop_front())


func _check() -> void:
	var s := Game.engine.state
	for m in _milestones:
		if _done.has(m.id) or not MilestoneRules.reached(m, s):
			continue
		_done[m.id] = true
		_queue.append(m)
		var cfg := ConfigFile.new()
		cfg.load(Game.SETTINGS_PATH)
		cfg.set_value("milestones", "done", _done.keys())
		cfg.save(Game.SETTINGS_PATH)


func _show(m: Dictionary) -> void:
	_title.text = UiTheme.icon("milestone", 56) + "  " + m.get("title", "")
	_message.text = m.get("message", "")
	# Full width from the anchors; the height shrinks back to the text (containers only grow).
	offset_bottom = TOP
	visible = true
	modulate.a = 1.0
	pivot_offset = Vector2(size.x / 2.0, 90.0)
	scale = Vector2(0.8, 0.8)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_showing = SHOW_TIME
	Audio.play("milestone")
