class_name UiTheme
extends RefCounted
## One theme for every screen: big type and thumb-sized buttons on the 1080-wide layout.
## Paper & ink (AFK V1, 2026-10-20): the HUD is part of the picture book, cream paper cards with
## a thin deep-ink border and ink text, buttons and banners washed in the art direction's palette
## (docs/art-direction.md).

const FONT_SIZE := 40
## Tap targets are at least 120 px at 1080 wide (phone UI audit, 2026-10-20).
const BUTTON_HEIGHT := 120
## The palette (docs/art-direction.md), for the UI.
const INK := Color("2c3440")
const INK_SOFT := Color("5b6470")
const PAPER := Color("f4ecdc")
const PAPER_SHADE := Color("e4d6bd")
## Text on a washed button or banner.
const PAPER_TEXT := Color("fbf6ec")
const FALU := Color("b2412e")
const OCHRE := Color("c9973f")
const OCHRE_DEEP := Color("9a6a22")
const TEAL := Color("5e8a87")
const TEAL_DEEP := Color("35666b")
const BLUE_SHADOW := Color("7f93a6")
## The small utility buttons (Jans, Music, Sound, DEV): a light wash with ink text, so they sit
## under the main actions (Astra review, 2026-10-20), and their "off" state.
const UTILITY := Color("d5e1da")
const UTILITY_OFF := Color("c9c2b4")
const FIRELIGHT := Color("f2b266")
## A paper card, a little see-through so the world shows at its edge.
const PANEL := Color(PAPER, 0.97)
## Titles on paper.
const TITLE := FALU
## Banners: a warning, the cold and blizzards, and good news.
const WARN_WASH := Color(FALU, 0.95)
const COLD_WASH := Color("4f6a84", 0.95)
const GOOD_WASH := Color(TEAL_DEEP, 0.95)
## World text (floating words over the town) stays bright.
const ACCENT := Color(0.98, 0.62, 0.25)
const COLD := Color("4f7fa8")
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
	t.set_stylebox("normal", "Button", _button_style(TEAL))
	t.set_stylebox("hover", "Button", _button_style(TEAL.lightened(0.1)))
	var pressed := _button_style(TEAL_DEEP)
	# Pressed sinks a little: less shadow, content nudged down.
	pressed.shadow_size = 0
	pressed.content_margin_top += 3
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", _button_style(PAPER_SHADE))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", PAPER_TEXT)
	t.set_color("font_disabled_color", "Button", INK_SOFT)
	t.set_color("font_color", "Label", INK)
	t.set_constant("outline_size", "Label", 0)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("ddd3bf")
	bar_bg.set_corner_radius_all(14)
	bar_bg.set_border_width_all(3)
	bar_bg.border_color = INK
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = FIRELIGHT
	bar_fill.set_corner_radius_all(14)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	_theme = t
	return t


## A card: `color` (paper by default) with a thin deep-ink border and a soft ink shadow below,
## like a paper cut-out laid on the picture.
static func panel_style(color := PANEL) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(28)
	s.set_content_margin_all(28)
	s.set_border_width_all(3)
	s.border_color = Color(INK, 0.85)
	s.shadow_color = Color(INK, 0.15)
	s.shadow_size = 9
	s.shadow_offset = Vector2(0, 6)
	s.anti_aliasing_size = 1.5
	return s


## A utility button's look: a light `color` wash, ink border, ink text.
static func style_utility(b: Button, color := UTILITY) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var s := _button_style(color.darkened(0.08) if state == "pressed" else color)
		b.add_theme_stylebox_override(state, s)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, INK)


## A button drawn smaller than a tap target (the fight reviews' lighter look) that still takes
## touches over BUTTON_HEIGHT: its rect is the full height (and width, with `drawn_width`) and its
## looks are inset to the drawn size, centred (phone audit F5, 2026-10-21). Call it after styling.
static func pad_touch(b: Button, drawn_height: float, drawn_width := -1.0) -> void:
	var inset := Vector2(maxf(0.0, (BUTTON_HEIGHT - drawn_width) / 2.0) if drawn_width > 0.0 else 0.0,
		maxf(0.0, (BUTTON_HEIGHT - drawn_height) / 2.0))
	b.custom_minimum_size = Vector2(BUTTON_HEIGHT if drawn_width > 0.0 else b.custom_minimum_size.x, BUTTON_HEIGHT)
	for state in ["normal", "hover", "pressed", "disabled"]:
		# Its own style, or the theme's (read from the theme itself: before the button is in the
		# tree, get_theme_stylebox would give Godot's default grey).
		var own := b.get_theme_stylebox(state) if b.has_theme_stylebox_override(state) else get_theme().get_stylebox(state, "Button")
		var s := own.duplicate() as StyleBoxFlat
		if s == null:
			continue
		s.expand_margin_left = -inset.x
		s.expand_margin_right = -inset.x
		s.expand_margin_top = -inset.y
		s.expand_margin_bottom = -inset.y
		b.add_theme_stylebox_override(state, s)


## Back to the theme's own (primary) button look, undoing style_utility.
static func style_primary(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.remove_theme_stylebox_override(state)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.remove_theme_color_override(c)


static func _button_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(22)
	s.set_border_width_all(3)
	s.border_color = INK
	s.shadow_color = Color(INK, 0.3)
	s.shadow_size = 2
	s.shadow_offset = Vector2(0, 4)
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
static func rich_label(size := FONT_SIZE, color := INK) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_color_override("default_color", color)
	return l


static func label(text := "", size := FONT_SIZE, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
