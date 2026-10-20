class_name Hud
extends CanvasLayer
## The always-on UI: heat and resources up top, the blizzard forecast, warning banners,
## the bottom sheet, and (in debug builds) the dev panel.

## DEV → Ink look: switch the ink-and-watercolour art test on or off.
signal ink_toggled

## The stats line's font, and the size it steps down to when the numbers grow long.
const STATS_FONT := 36
const STATS_FONT_SMALL := 31
## The wolves countdown turns orange for its last this many seconds.
const WOLVES_URGENT := 10.0
## Gathered resources fly up into their number this big, and this fast. [agreed 2026-10-20]
const FLY_ICON_SIZE := 64.0
const FLY_ICON_TIME := 0.45

var sheet: Sheet
var joystick: Joystick
var hints: Hints
var full_readout: FullReadout
var milestone_cards: MilestoneCards

var _root: Control
var _top: PanelContainer
var _heat_bar: ProgressBar
var _heat_fill: StyleBoxFlat
var _heat_label: RichTextLabel
## The stats line: one label each, so a gathered resource can fly to its own number.
var _stats: HBoxContainer
var _stat_labels := {}
var _forecast: RichTextLabel
var _banner: PanelContainer
var _banner_label: RichTextLabel
var _banner_timer := 0.0
var _dev_button: Button
var _game_over: GameOverCard
## A chest's offer while it's waiting for her choice. [agreed 2026-10-20]
var _offer_card: OfferCard
## Whether the low-heat warning has fired; it re-arms once heat recovers.
var _low_warned := false
var _time := 0.0
var _music_button: Button
var _sound_button: Button
var _dev_panel: PanelContainer
var _jans_button: Button


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.get_theme()
	add_child(_root)
	_build_top()
	_build_banner()
	milestone_cards = MilestoneCards.new()
	_root.add_child(milestone_cards)
	milestone_cards.setup(Game.milestones)
	milestone_cards.banner = _banner
	full_readout = FullReadout.new()
	_root.add_child(full_readout)
	hints = Hints.new()
	_root.add_child(hints)
	joystick = Joystick.new()
	_root.add_child(joystick)
	sheet = Sheet.new()
	_root.add_child(sheet)
	hints.sheet = sheet
	_build_sound_toggles()
	_jans_button = _corner_button(CORNER_SLOTS.jans, _toggle_jans, "Jans")
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
	_heat_label = UiTheme.rich_label(36)
	_heat_label.fit_content = false
	_heat_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heat_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	_heat_label.add_theme_constant_override("outline_size", 10)
	heat_box.add_child(_heat_label)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 22)
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_stats)
	for key in ["jans", "wood", "food", "materials"]:
		var l := UiTheme.rich_label(STATS_FONT)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		_stats.add_child(l)
		_stat_labels[key] = l
	_forecast = UiTheme.rich_label(34, Color(0.9, 0.94, 1.0))
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
	_banner_label = UiTheme.rich_label(42)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)


## A warning across the screen; `icon` (a UiTheme icon name) leads the text.
func show_banner(text: String, seconds := 4.0, color := Color(0.55, 0.12, 0.1, 0.92), icon := "") -> void:
	_banner.add_theme_stylebox_override("panel", UiTheme.panel_style(color))
	_banner_label.text = (UiTheme.icon(icon, 60) + "  " if icon != "" else "") + text
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
	_heat_label.text = "%s Heat %s / %s   (−%.1f/s)" % [UiTheme.icon("heat", 44), Fmt.num(s.heat), Fmt.num(cap), drain]
	_warn_low_heat(s, frac)
	var caps := Economy.caps(s)
	# Each number keeps its word next to its icon, so it says what it is.
	_stat_labels.jans.text = "%s Jans %d/%d" % [UiTheme.icon("jans", 48), s.jans.size(), Economy.jan_cap(s)]
	_stat_labels.wood.text = "%s Wood %s/%s" % [UiTheme.icon("wood"), Fmt.num(s.piles.wood), Fmt.num(caps.wood)]
	_stat_labels.food.text = "%s Food %s" % [UiTheme.icon("food"), Fmt.num(s.piles.food)]
	_stat_labels.materials.text = "%s Mat %s" % [UiTheme.icon("materials", 48), Fmt.num(s.piles.materials)]
	_fit_stats()
	var note := ""
	if Economy.is_cold(s) and not s.jans.is_empty():
		note = "   %s Cold: half speed" % UiTheme.icon("cold", 36)
	elif s.hungry:
		note = "   Hungry!"
	_forecast.text = _forecast_text(s) + note
	_update_offer_card(s)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false


## The stats line steps down a size when big numbers would push it past the panel, and back up
## once there's clearly room again (the gap stops it flickering between the two).
func _fit_stats() -> void:
	var width := _stats.get_theme_constant("separation") * (_stat_labels.size() - 1.0)
	for l in _stat_labels.values():
		width += (l as RichTextLabel).get_content_width()
	var size: int = _stat_labels.wood.get_theme_font_size("normal_font_size")
	var next := size
	if size == STATS_FONT and width > _stats.size.x:
		next = STATS_FONT_SMALL
	elif size == STATS_FONT_SMALL and width < _stats.size.x * 0.85:
		next = STATS_FONT
	if next != size:
		for l in _stat_labels.values():
			(l as RichTextLabel).add_theme_font_size_override("normal_font_size", next)


## A gathered resource's icon flies from `from` (a screen point) into its number in the top bar,
## which gives a little pulse as it lands. [agreed 2026-10-20]
func fly_icon(res: String, from: Vector2) -> void:
	var label: RichTextLabel = _stat_labels.get(res)
	if label == null:
		return
	var icon := TextureRect.new()
	icon.texture = load(UiTheme.ICON_DIR + res + ".png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2.ONE * FLY_ICON_SIZE
	icon.pivot_offset = icon.size / 2.0
	_root.add_child(icon)
	icon.position = from - icon.pivot_offset
	var to := label.get_global_rect().get_center() - icon.pivot_offset
	var t := create_tween()
	t.tween_property(icon, "position", to, FLY_ICON_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(icon, "scale", Vector2.ONE * 0.6, FLY_ICON_TIME)
	t.tween_callback(func() -> void:
		icon.queue_free()
		label.pivot_offset = label.size / 2.0
		label.scale = Vector2.ONE * 1.2
		create_tween().tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## Keeping the fire alive is the goal, so a dying fire is loud: the bar pulses red, a banner
## and horn fire once (again after it recovers), and near the end the bar counts down.
func _warn_low_heat(s: GameState, frac: float) -> void:
	if s.game_over:
		return
	if frac < Balance.LOW_HEAT_WARNING:
		_heat_fill.bg_color = Color(0.85, 0.15, 0.12).lerp(Color(1.0, 0.55, 0.3), 0.5 + 0.5 * sin(_time * 9.0))
		if not _low_warned:
			_low_warned = true
			show_banner("The fire is dying! Chop Wood for the Stockpile.", 4.0, Color(0.55, 0.12, 0.1, 0.92), "heat")
			Audio.play("warning")
	elif frac > Balance.LOW_HEAT_CLEAR:
		_low_warned = false
	var left := Economy.seconds_until_cold(s)
	if frac < Balance.FIRE_OUT_COUNTDOWN and left < INF:
		_heat_label.text = "Fire out in %s!" % Fmt.clock(left)


## Shows a chest's offer while one is waiting, and takes it away once she's chosen.
func _update_offer_card(s: GameState) -> void:
	hints.visible = s.offer.is_empty()
	if s.offer.is_empty():
		if _offer_card:
			_offer_card.queue_free()
			_offer_card = null
		return
	if _offer_card == null:
		sheet.close()
		_offer_card = OfferCard.new()
		_offer_card.offer = s.offer
		_root.add_child(_offer_card)


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
		parts.append("%s BLIZZARD! %s left" % [UiTheme.icon("blizzard", 40), Fmt.clock(s.blizzard_ends_at - s.time)])
	elif s.blizzard_warned:
		parts.append("%s Blizzard in %s" % [UiTheme.icon("blizzard", 40), Fmt.clock(s.blizzard_at - s.time)])
	else:
		parts.append("Clear skies")
	if not s.wolves.is_empty():
		parts.append("%s Wolves: %d" % [UiTheme.icon("wolves", 40), s.wolves.size()])
	elif s.attack_warned:
		var left := maxf(s.attack_at - s.time, 0.0)
		var line := "%s Wolves in %s" % [UiTheme.icon("wolves", 40), Fmt.clock(left)]
		# Orange only for the last seconds, so it reads as urgent rather than routine.
		parts.append("[color=#%s]%s[/color]" % [UiTheme.ACCENT.to_html(false), line] if left <= WOLVES_URGENT else line)
	if Game.engine.paused:
		parts.append("PAUSED")
	return "  ·  ".join(parts)


## True when a screen point is over UI, so the world shouldn't get the touch.
func blocks(pos: Vector2) -> bool:
	for c in [_top, sheet, _dev_button, _dev_panel, _music_button, _sound_button, _jans_button, _game_over, _offer_card]:
		if c and c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


# ---------- Sound ----------

## The row of small buttons under the top bar, from the right: DEV, Sound, Music. Each has its
## own slot (in pixels from the right edge) so longer labels like "Music off" never overlap.
const CORNER_TOP := 360
const CORNER_SLOTS := {"dev": [-174, -24], "sound": [-380, -190], "music": [-586, -396], "jans": [-772, -602]}


func _build_sound_toggles() -> void:
	_music_button = _corner_button(CORNER_SLOTS.music, _toggle_music)
	_sound_button = _corner_button(CORNER_SLOTS.sound, _toggle_sound)
	_label_sound_toggles()


## The Jans button opens the Jans screen, or closes it again.
func _toggle_jans() -> void:
	if sheet.visible and sheet.jans:
		sheet.close()
	else:
		sheet.open_jans()


func _toggle_music() -> void:
	Audio.toggle_music()
	_label_sound_toggles()


func _toggle_sound() -> void:
	Audio.toggle_sfx()
	_label_sound_toggles()


## A small button in the row under the top bar, in `slot` ([left, right] from the right edge).
func _corner_button(slot: Array, on_press: Callable, text := "") -> Button:
	var b := UiTheme.button(text, on_press)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = slot[0]
	b.offset_right = slot[1]
	b.offset_top = CORNER_TOP
	b.offset_bottom = CORNER_TOP + UiTheme.BUTTON_HEIGHT
	b.clip_text = true
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
	_dev_button = _corner_button(CORNER_SLOTS.dev, _toggle_dev, "DEV")
	_dev_panel = PanelContainer.new()
	_dev_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_panel.offset_left = -520
	_dev_panel.offset_right = -24
	_dev_panel.offset_top = CORNER_TOP + UiTheme.BUTTON_HEIGHT + 20
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
