class_name Hud
extends CanvasLayer
## The always-on UI: heat and resources up top, the blizzard forecast, warning banners,
## the bottom sheet, and (in debug builds) the dev panel.

## DEV → Ink look: switch the ink-and-watercolour art test on or off.
signal ink_toggled

var sheet: Sheet
var joystick: Joystick
var hints: Hints

var _root: Control
var _top: PanelContainer
var _heat_bar: ProgressBar
var _heat_fill: StyleBoxFlat
var _heat_label: Label
var _stats: Label
var _bag: Label
var _forecast: Label
var _banner: PanelContainer
var _banner_label: Label
var _banner_timer := 0.0
var _dev_button: Button
var _game_over: GameOverCard
## Whether the low-heat warning has fired; it re-arms once heat recovers.
var _low_warned := false
var _time := 0.0
var _music_button: Button
var _sound_button: Button
var _dev_panel: PanelContainer


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	_build_top()
	_build_banner()
	hints = Hints.new()
	_root.add_child(hints)
	joystick = Joystick.new()
	_root.add_child(joystick)
	sheet = Sheet.new()
	_root.add_child(sheet)
	hints.sheet = sheet
	_build_sound_toggles()
	if OS.is_debug_build():
		_build_dev()


func _build_top() -> void:
	_top = PanelContainer.new()
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_left = 20
	_top.offset_right = -20
	_top.offset_top = 20
	_root.add_child(_top)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_top.add_child(v)
	var heat_box := Control.new()
	heat_box.custom_minimum_size = Vector2(0, 64)
	v.add_child(heat_box)
	_heat_bar = ProgressBar.new()
	_heat_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heat_bar.show_percentage = false
	_heat_fill = StyleBoxFlat.new()
	_heat_fill.set_corner_radius_all(14)
	_heat_bar.add_theme_stylebox_override("fill", _heat_fill)
	heat_box.add_child(_heat_bar)
	_heat_label = UiTheme.label("", 36)
	_heat_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heat_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	_heat_label.add_theme_constant_override("outline_size", 10)
	heat_box.add_child(_heat_label)
	_stats = UiTheme.label("", 38)
	v.add_child(_stats)
	_bag = UiTheme.label("", 34, Color(0.9, 0.85, 0.7))
	v.add_child(_bag)
	_forecast = UiTheme.label("", 34, UiTheme.COLD)
	v.add_child(_forecast)


func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.55, 0.12, 0.1, 0.92)))
	_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_left = 60
	_banner.offset_right = -60
	_banner.offset_top = 480
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_root.add_child(_banner)
	_banner_label = UiTheme.label("", 42)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)


func show_banner(text: String, seconds := 4.0, color := Color(0.55, 0.12, 0.1, 0.92)) -> void:
	_banner.add_theme_stylebox_override("panel", UiTheme.panel_style(color))
	_banner_label.text = text
	_banner.visible = true
	_banner_timer = seconds
	_banner.scale = Vector2(0.9, 0.9)
	_banner.pivot_offset = _banner.size / 2.0
	create_tween().tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	var s := Game.engine.state
	_time += delta
	var cap := Economy.heat_cap(s)
	var frac := s.heat / maxf(cap, 1.0)
	_heat_bar.max_value = cap
	_heat_bar.value = s.heat
	_heat_fill.bg_color = UiTheme.COLD.lerp(UiTheme.ACCENT, clampf(frac / Balance.COLD_THRESHOLD, 0.0, 1.0))
	var drain := Economy.heat_drain(s)
	_heat_label.text = "Heat %s / %s   (−%.1f/s)" % [Fmt.num(s.heat), Fmt.num(cap), drain]
	_warn_low_heat(s, frac)
	var caps := Economy.caps(s)
	_stats.text = "Jans %d/%d    Wood %s/%s    Food %s    Mat %s" % [
		s.jans.size(), Economy.jan_cap(s), Fmt.num(s.piles.wood), Fmt.num(caps.wood), Fmt.num(s.piles.food), Fmt.num(s.piles.materials)]
	_bag.text = "Bag %s/%s   (Wood %s, Food %s, Mat %s)%s" % [
		Fmt.num(Economy.bag_total(s)), Fmt.num(Economy.bag_cap(s)), Fmt.num(s.bag.wood), Fmt.num(s.bag.food), Fmt.num(s.bag.materials),
		"   Cold: half speed" if Economy.is_cold(s) and not s.jans.is_empty() else ("   Hungry!" if s.hungry else "")]
	_forecast.text = _forecast_text(s)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false


## Keeping the fire alive is the goal, so a dying fire is loud: the bar pulses red, a banner
## and horn fire once (again after it recovers), and near the end the bar counts down.
func _warn_low_heat(s: GameState, frac: float) -> void:
	if s.game_over:
		return
	if frac < Balance.LOW_HEAT_WARNING:
		_heat_fill.bg_color = Color(0.85, 0.15, 0.12).lerp(Color(1.0, 0.55, 0.3), 0.5 + 0.5 * sin(_time * 9.0))
		if not _low_warned:
			_low_warned = true
			show_banner("The fire is dying! Bring Wood to the furnace.", 4.0)
			Audio.play("warning")
	elif frac > Balance.LOW_HEAT_CLEAR:
		_low_warned = false
	var left := Economy.seconds_until_cold(s)
	if frac < Balance.FIRE_OUT_COUNTDOWN and left < INF:
		_heat_label.text = "Fire out in %s!" % Fmt.clock(left)


## The fire went out: the end-of-winter card over everything.
func show_game_over(time_survived: float, best: float, new_best: bool) -> void:
	sheet.close()
	_banner.visible = false
	_game_over = GameOverCard.new()
	_game_over.time_survived = time_survived
	_game_over.best = best
	_game_over.new_best = new_best
	_root.add_child(_game_over)


func _forecast_text(s: GameState) -> String:
	var parts := []
	if s.blizzard_active:
		parts.append("BLIZZARD! %s left" % Fmt.clock(s.blizzard_ends_at - s.time))
	elif s.blizzard_warned:
		parts.append("Blizzard in %s" % Fmt.clock(s.blizzard_at - s.time))
	else:
		parts.append("Clear skies")
	if not s.wolves.is_empty():
		parts.append("Wolves: %d" % s.wolves.size())
	if Game.engine.paused:
		parts.append("PAUSED")
	return "    ".join(parts)


## True when a screen point is over UI, so the world shouldn't get the touch.
func blocks(pos: Vector2) -> bool:
	for c in [_top, sheet, _dev_button, _dev_panel, _music_button, _sound_button, _game_over]:
		if c and c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


# ---------- Sound ----------

func _build_sound_toggles() -> void:
	_music_button = _corner_button(-520, _toggle_music)
	_sound_button = _corner_button(-345, _toggle_sound)
	_label_sound_toggles()


func _toggle_music() -> void:
	Audio.toggle_music()
	_label_sound_toggles()


func _toggle_sound() -> void:
	Audio.toggle_sfx()
	_label_sound_toggles()


## A small button in the row under the top bar, `left` pixels in from the right edge.
func _corner_button(left: int, on_press: Callable) -> Button:
	var b := UiTheme.button("", on_press)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = left
	b.offset_right = left + 160
	b.offset_top = 360
	b.offset_bottom = 360 + 90
	b.add_theme_font_size_override("font_size", 30)
	_root.add_child(b)
	return b


func _label_sound_toggles() -> void:
	_music_button.text = "Music" if Audio.music_on else "Music off"
	_sound_button.text = "Sound" if Audio.sfx_on else "Sound off"
	_music_button.modulate = Color.WHITE if Audio.music_on else Color(1, 1, 1, 0.55)
	_sound_button.modulate = Color.WHITE if Audio.sfx_on else Color(1, 1, 1, 0.55)


# ---------- Dev panel (debug builds) ----------

func _build_dev() -> void:
	_dev_button = UiTheme.button("DEV", _toggle_dev)
	_dev_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_button.offset_left = -170
	_dev_button.offset_right = -24
	_dev_button.offset_top = 360
	_dev_button.offset_bottom = 360 + 90
	_dev_button.add_theme_font_size_override("font_size", 30)
	_root.add_child(_dev_button)
	_dev_panel = PanelContainer.new()
	_dev_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_panel.offset_left = -520
	_dev_panel.offset_right = -24
	_dev_panel.offset_top = 470
	_dev_panel.visible = false
	_root.add_child(_dev_panel)
	var v := VBoxContainer.new()
	_dev_panel.add_child(v)
	var e := Game.engine
	v.add_child(UiTheme.button("Skip 60 s", func(): e.skip(60.0)))
	v.add_child(UiTheme.button("Fill resources", e.fill))
	v.add_child(UiTheme.button("Add a Jan", e.dev_add_jan))
	v.add_child(UiTheme.button("Furnace +1", func(): e.dev_level_up(0)))
	v.add_child(UiTheme.button("Blizzard", e.force_blizzard))
	v.add_child(UiTheme.button("Wolves", func(): e.spawn_wolves()))
	v.add_child(UiTheme.button("Ink look", ink_toggled.emit))


func _toggle_dev() -> void:
	_dev_panel.visible = not _dev_panel.visible


func _unhandled_key_input(event: InputEvent) -> void:
	if _dev_panel and event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle_dev()
