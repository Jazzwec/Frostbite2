class_name UiTheme
extends RefCounted
## One theme for every screen: big type and thumb-sized buttons on the 1080-wide layout.

const FONT_SIZE := 40
## Tap targets are at least 120 px at 1080 wide (phone UI audit, 2026-10-20).
const BUTTON_HEIGHT := 120
const PANEL := Color(0.08, 0.11, 0.2, 0.86)
const ACCENT := Color(0.98, 0.62, 0.25)
const COLD := Color(0.55, 0.78, 1.0)
## The watercolour icons (assets/ui/icons/, cut from source_art/icons/sheet.png): wood, food,
## materials, heat, jans, bag, blizzard, wolves, cold, milestone, build, stockpile, house.
const ICON_DIR := "res://assets/ui/icons/"

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_stylebox("panel", "PanelContainer", panel_style(PANEL))
	t.set_stylebox("normal", "Button", _button_style(Color(0.2, 0.42, 0.72)))
	t.set_stylebox("hover", "Button", _button_style(Color(0.26, 0.5, 0.82)))
	t.set_stylebox("pressed", "Button", _button_style(Color(0.15, 0.32, 0.58)))
	t.set_stylebox("disabled", "Button", _button_style(Color(0.25, 0.27, 0.32)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_disabled_color", "Button", Color(0.65, 0.67, 0.72))
	t.set_color("font_color", "Label", Color(0.95, 0.96, 1.0))
	t.set_constant("outline_size", "Label", 0)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.18, 0.28)
	bar_bg.set_corner_radius_all(14)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = ACCENT
	bar_fill.set_corner_radius_all(14)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	_theme = t
	return t


static func panel_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(28)
	s.set_content_margin_all(28)
	return s


static func _button_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(20)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	b.pressed.connect(func(): Audio.play("tap"))
	b.pressed.connect(on_press)
	return b


## An icon inline in a rich label's text, e.g. `UiTheme.icon("wood") + " 12"`.
static func icon(name: String, size := 44) -> String:
	return "[img width=%d height=%d]%s%s.png[/img]" % [size, size, ICON_DIR, name]


## A label that can show icons (BBCode), sized to its text, that never takes touches.
static func rich_label(size := FONT_SIZE, color := Color(0.95, 0.96, 1.0)) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_color_override("default_color", color)
	return l


static func label(text := "", size := FONT_SIZE, color := Color(0.95, 0.96, 1.0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
