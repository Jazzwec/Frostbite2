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
## Fight news (a wave announced or arriving, Meagan down, a theft) is a one-line strip for this
## long, right under the top panel beside the buttons, then lives on in the forecast line (fight_v2
## reviews 1 and 2: give the middle of the screen back to the fight). Amber for what's coming,
## red only for a theft or Meagan down.
const STRIP_TIME := 1.5
const STRIP_FONT := 32
const COMING_WASH := Color(UiTheme.OCHRE, 0.97)
const TROLL_COMING_WASH := Color(UiTheme.OCHRE_DEEP, 0.97)
## Resources fly between their number in the top bar and the world (into it as she gathers, out
## of it as a pad or gate takes them) as icons this big, along a curve this wide, in this long.
## [agreed 2026-10-20, from ChatGPT's review]
const FLY_ICON_SIZE := 56.0
const FLY_BEND := 110.0
const FLY_ICON_TIME := 0.5
## A short tapered cream trail behind each flying icon shows which way it's going.
const FLY_TRAIL_LENGTH := 90.0
const FLY_TRAIL_WIDTH := 22.0
const FLY_TRAIL_COLOR := Color(1.0, 0.93, 0.78, 0.9)

var sheet: Sheet
var joystick: Joystick
var hints: Hints
var threat_arrows: ThreatArrows
var bag_readout: BagReadout
var milestone_cards: MilestoneCards

var _root: Control
var _top: PanelContainer
var _heat_bar: ProgressBar
var _heat_fill: StyleBoxFlat
var _heat_label: RichTextLabel
## The stats line: one label each, so a gathered resource can fly to its own number.
var _stats: HBoxContainer
var _stat_labels := {}
## When even the small font doesn't fit, the stats drop their words and keep icon and number.
var _stats_compact := false
## Amounts on their way into the top bar (icons still flying), held back from its numbers until
## they land, so stolen goods won back visibly arrive before the count goes up (review 1).
var _held := {}
var _forecast: RichTextLabel
var _banner: PanelContainer
var _banner_label: RichTextLabel
var _banner_timer := 0.0
var _strip: PanelContainer
var _strip_label: RichTextLabel
var _strip_timer := 0.0
## Which look the countdown strip has (0 a wave, 1 a troll's, -1 something else), so its style is
## only made when it changes.
var _countdown_look := -1
## The next wave's make-up, on its own row in the top panel while it's announced (review 4).
var _mix_row: RichTextLabel
## A small cream card over a point in the world ("Up in 4s" over Meagan while she's down).
var _callout: PanelContainer
var _callout_label: Label
var _game_over: GameOverCard
## A chest's offer while it's waiting for her choice. [agreed 2026-10-20]
var _offer_card: OfferCard
## Whether the low-heat warning has fired; it re-arms once heat recovers.
var _low_warned := false
var _time := 0.0
var _music_button: Button
var _sound_button: Button
## Music, Sound and (in debug builds) DEV live in one Menu (fight_v2 review 1).
var _menu_button: Button
var _menu_panel: PanelContainer
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
	_build_strip()
	_build_callout()
	milestone_cards = MilestoneCards.new()
	_root.add_child(milestone_cards)
	milestone_cards.setup(Game.milestones)
	milestone_cards.banner = _banner
	bag_readout = BagReadout.new()
	_root.add_child(bag_readout)
	hints = Hints.new()
	_root.add_child(hints)
	threat_arrows = ThreatArrows.new()
	_root.add_child(threat_arrows)
	joystick = Joystick.new()
	_root.add_child(joystick)
	sheet = Sheet.new()
	_root.add_child(sheet)
	hints.sheet = sheet
	threat_arrows.sheet = sheet
	_jans_button = _corner_button(CORNER_SLOTS.jans, _toggle_jans, "Jans")
	if OS.is_debug_build():
		_build_dev()
	_build_menu()


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
	# Ink on the firelight wash, with a paper halo so it reads on the cold blue too.
	_heat_label.add_theme_color_override("font_outline_color", Color(UiTheme.PAPER, 0.85))
	_heat_label.add_theme_constant_override("outline_size", 8)
	heat_box.add_child(_heat_label)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 22)
	_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_stats)
	for key in ["jans", "wood", "food", "materials", "bag"]:
		var l := UiTheme.rich_label(STATS_FONT)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		_stats.add_child(l)
		_stat_labels[key] = l
	_forecast = UiTheme.rich_label(36, UiTheme.INK_SOFT)
	v.add_child(_forecast)
	_mix_row = UiTheme.rich_label(36, UiTheme.INK)
	_mix_row.visible = false
	v.add_child(_mix_row)


func _build_banner() -> void:
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", UiTheme.panel_style(UiTheme.WARN_WASH))
	_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_left = 60
	_banner.offset_right = -60
	_banner.offset_top = 480
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_root.add_child(_banner)
	_banner_label = UiTheme.rich_label(42, UiTheme.PAPER_TEXT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)


## The strip for fight news: one short line high up, under the buttons, gone in `seconds`.
func _build_strip() -> void:
	_strip = PanelContainer.new()
	_strip.add_theme_stylebox_override("panel", _strip_style(COMING_WASH))
	_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_strip.offset_left = 20
	# Up to the buttons, on their row.
	_strip.offset_right = CORNER_SLOTS.jans[0] - 16
	_strip.offset_top = CORNER_TOP
	_strip.offset_bottom = CORNER_TOP + CORNER_HEIGHT
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.visible = false
	_root.add_child(_strip)
	_strip_label = UiTheme.rich_label(STRIP_FONT, UiTheme.PAPER_TEXT)
	_strip_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_strip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_strip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_strip_label.fit_content = false
	_strip.add_child(_strip_label)


func _build_callout() -> void:
	_callout = PanelContainer.new()
	var style := UiTheme.panel_style(Color(UiTheme.PAPER, 0.96))
	style.set_corner_radius_all(16)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 14
	style.content_margin_right = 14
	_callout.add_theme_stylebox_override("panel", style)
	_callout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callout.visible = false
	_root.add_child(_callout)
	_callout_label = UiTheme.label("", 44)
	_callout_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_callout.add_child(_callout_label)


## Shows `text` on a small card centred above screen point `at`; "" hides it.
func callout(text: String, at: Vector2) -> void:
	_callout.visible = text != ""
	if text == "":
		return
	_callout_label.text = text
	_callout.reset_size()
	_callout.position = at - Vector2(_callout.size.x / 2.0, _callout.size.y)


## The strip's panel: the usual paper card's ink border, slimmer.
func _strip_style(color: Color) -> StyleBoxFlat:
	var style := UiTheme.panel_style(color)
	style.set_corner_radius_all(20)
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


## Fight news in the strip; `icon` (a UiTheme icon name) leads it. Not while a sheet is open:
## the forecast line still has it (fight_v2 review 1).
func show_strip(text: String, icon := "", color := COMING_WASH, seconds := STRIP_TIME) -> void:
	if sheet.visible:
		return
	_strip.add_theme_stylebox_override("panel", _strip_style(color))
	_countdown_look = -1
	_strip_label.text = (UiTheme.icon(icon, 44) + "  " if icon != "" else "") + text
	_strip.visible = true
	_strip_timer = seconds
	_strip.modulate.a = 0.0
	create_tween().tween_property(_strip, "modulate:a", 1.0, 0.15)


## A warning across the screen; `icon` (a UiTheme icon name) leads the text.
func show_banner(text: String, seconds := 4.0, color := UiTheme.WARN_WASH, icon := "") -> void:
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
	_heat_fill.bg_color = UiTheme.BLUE_SHADOW.lerp(UiTheme.FIRELIGHT, clampf(frac / Balance.COLD_THRESHOLD, 0.0, 1.0))
	var drain := Economy.heat_drain(s)
	_heat_label.text = "%s Heat %s / %s   (−%.1f/s)" % [UiTheme.icon("heat", 44), Fmt.num(s.heat), Fmt.num(cap), drain]
	_warn_low_heat(s, frac)
	var caps := Economy.caps(s)
	# Each number keeps its word next to its icon, so it says what it is, while there's room.
	var w := func(word: String) -> String: return "" if _stats_compact else word + " "
	_stat_labels.jans.text = "%s %s%d/%d" % [UiTheme.icon("jans", 52), w.call("Jans"), s.jans.size(), Economy.jan_cap(s)]
	_stat_labels.wood.text = "%s %s%s/%s" % [UiTheme.icon("wood", 52), w.call("Wood"), Fmt.num(_shown(s, "wood")), Fmt.num(caps.wood)]
	_stat_labels.food.text = "%s %s%s" % [UiTheme.icon("food", 52), w.call("Food"), Fmt.num(_shown(s, "food"))]
	_stat_labels.materials.text = "%s %s%s" % [UiTheme.icon("materials", 52), w.call("Mat"), Fmt.num(_shown(s, "materials"))]
	# Her bag beside the store, coral when it's full (fight_v2 review 1: instead of a toast).
	var bag := "%s %d/%d" % [UiTheme.icon("bag", 52), roundi(Economy.bag_total(s)), roundi(Economy.bag_cap(s))]
	var full := Economy.bag_total(s) >= Economy.bag_cap(s) - 0.01
	_stat_labels.bag.text = "[color=#%s]%s[/color]" % [UiTheme.FALU.to_html(false), bag] if full else bag
	_fit_stats()
	var note := ""
	if Economy.is_cold(s) and not s.jans.is_empty():
		note = "   %s Cold: half speed" % UiTheme.icon("cold", 44)
	elif s.hungry:
		note = "   Hungry!"
	_forecast.text = _forecast_text(s) + note
	_update_offer_card(s)
	_place_row()
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false
	if _strip_timer > 0.0:
		_strip_timer -= delta
		if _strip_timer <= 0.0 or sheet.visible:
			_strip_timer = 0.0
			_strip.visible = false
	# Between news, a warned wave's countdown owns the strip (review 4).
	if _strip_timer <= 0.0:
		_strip.visible = s.attack_warned and not sheet.visible and not s.game_over
		if _strip.visible:
			var troll: bool = s.next_wave.get("mix", {}).get("troll", 0) > 0
			var left := ceili(maxf(s.attack_at - s.time, 0.0))
			if int(troll) != _countdown_look:
				_countdown_look = int(troll)
				_strip.add_theme_stylebox_override("panel", _strip_style(TROLL_COMING_WASH if troll else COMING_WASH))
			_strip_label.text = "%s  %s  ·  %ds" % [UiTheme.icon("troll" if troll else "wolves", 44), "Troll raid" if troll else "Next raid", left]
			_strip.modulate.a = 1.0


## The stats line steps down a size when big numbers would push it past the panel, and back up
## once there's clearly room again (the gap stops it flickering between the two).
func _fit_stats() -> void:
	var width := _stats.get_theme_constant("separation") * (_stat_labels.size() - 1.0)
	for l in _stat_labels.values():
		width += (l as RichTextLabel).get_content_width()
	var size: int = _stat_labels.wood.get_theme_font_size("normal_font_size")
	var next := size
	if _stats_compact:
		# The words take about a third of the line: put them back once there's clearly room.
		if width < _stats.size.x * 0.6:
			_stats_compact = false
	elif size == STATS_FONT and width > _stats.size.x:
		next = STATS_FONT_SMALL
	elif size == STATS_FONT_SMALL and width > _stats.size.x:
		_stats_compact = true
	elif size == STATS_FONT_SMALL and width < _stats.size.x * 0.85:
		next = STATS_FONT
	if next != size:
		for l in _stat_labels.values():
			(l as RichTextLabel).add_theme_font_size_override("normal_font_size", next)


## A store amount as the top bar shows it: less whatever is still flying in.
func _shown(s: GameState, res: String) -> float:
	return maxf(0.0, s.piles[res] - _held.get(res, 0.0))


## Holds `amount` of `res` (already in the store) back from the top bar's number until an icon
## flying in with it lands (fly_to_counter's `release`).
func hold(res: String, amount: float) -> void:
	_held[res] = _held.get(res, 0.0) + amount


## A gathered resource's icon flies from the world into its number in the top bar, which pulses
## as it lands. `from` returns the screen point it starts at; `release` is what it lets through
## of an amount held back (hold()).
func fly_to_counter(res: String, from: Callable, release := 0.0) -> void:
	if not _stat_labels.has(res):
		return
	_fly(res, from, _counter_point.bind(res), func() -> void:
		_held[res] = maxf(0.0, _held.get(res, 0.0) - release)
		_pulse(_stat_labels[res]))


## A resource a pad or gate takes from the Stockpile flies out of its number in the top bar (which
## pulses as it leaves) to the screen point `to` returns; `landed` runs when it gets there.
func fly_from_counter(res: String, to: Callable, landed: Callable) -> void:
	if _stat_labels.has(res):
		_pulse(_stat_labels[res])
		_fly(res, _counter_point.bind(res), to, landed)


## Where a resource's number sits in the top bar: on its icon, at the label's left end.
func _counter_point(res: String) -> Vector2:
	var r: Rect2 = (_stat_labels[res] as RichTextLabel).get_global_rect()
	return Vector2(r.position.x + r.size.y / 2.0, r.get_center().y)


## An icon of `res` flying along a short curve between two screen points. Both ends are read every
## frame, so a point in the world stays put while the camera moves.
func _fly(res: String, from: Callable, to: Callable, landed: Callable) -> void:
	var icon := TextureRect.new()
	icon.texture = load(UiTheme.ICON_DIR + res + ".png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = Vector2.ONE * FLY_ICON_SIZE
	icon.pivot_offset = icon.size / 2.0
	var trail := _fly_trail()
	_root.add_child(trail)
	_root.add_child(icon)
	var bend := FLY_BEND if randf() < 0.5 else -FLY_BEND
	var step := func(u: float) -> void:
		var a: Vector2 = from.call()
		var b: Vector2 = to.call()
		var mid := (a + b) / 2.0 + (b - a).orthogonal().normalized() * bend
		var at := a.lerp(mid, u).lerp(mid.lerp(b, u), u)
		icon.position = at - icon.pivot_offset
		trail.add_point(at)
		# Only the last stretch of the path: the tail end drops off as the icon moves on.
		var length := 0.0
		for i in range(trail.get_point_count() - 1, 0, -1):
			length += trail.get_point_position(i).distance_to(trail.get_point_position(i - 1))
			if length > FLY_TRAIL_LENGTH:
				for j in i:
					trail.remove_point(0)
				break
	step.call(0.0)
	var t := create_tween()
	t.tween_method(step, 0.0, 1.0, FLY_ICON_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func() -> void:
		icon.queue_free()
		trail.queue_free()
		landed.call())


## The trail: thin and clear at its tail, full width at the icon.
func _fly_trail() -> Line2D:
	var trail := Line2D.new()
	trail.width = FLY_TRAIL_WIDTH
	var taper := Curve.new()
	taper.add_point(Vector2(0, 0))
	taper.add_point(Vector2(1, 1))
	trail.width_curve = taper
	var fade := Gradient.new()
	fade.set_color(0, Color(FLY_TRAIL_COLOR, 0.0))
	fade.set_color(1, FLY_TRAIL_COLOR)
	trail.gradient = fade
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	return trail


## A quick bounce on a stats label.
func _pulse(label: RichTextLabel) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE * 1.2
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Keeping the fire alive is the goal, so a dying fire is loud: the bar pulses red, a banner
## and horn fire once (again after it recovers), and near the end the bar counts down.
func _warn_low_heat(s: GameState, frac: float) -> void:
	if s.game_over:
		return
	if frac < Balance.LOW_HEAT_WARNING:
		_heat_fill.bg_color = UiTheme.FALU.lerp(UiTheme.FIRELIGHT, 0.5 + 0.5 * sin(_time * 9.0))
		if not _low_warned:
			_low_warned = true
			show_banner("The fire is dying! Bring Wood to a Stockpile.", 4.0, UiTheme.WARN_WASH, "heat")
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
	var raiders := s.wolves.filter(func(w): return w.outpost < 0).size() + s.wave_queue.size()
	var wave_line := ""
	if s.raid_on and raiders > 0:
		wave_line = "%s Wave %d  ·  %d left" % [UiTheme.icon("wolves", 44), s.wave, raiders]
	# What's coming, by kind, on its own row (review 4); the strip has the countdown.
	_mix_row.visible = s.attack_warned and not s.next_wave.is_empty()
	if _mix_row.visible:
		_mix_row.text = "Wave %d:  %s" % [s.wave + 1, mix_icons(s.next_wave.get("mix", {}), 48)]
	if s.blizzard_active:
		parts.append("%s BLIZZARD! %s left" % [UiTheme.icon("blizzard", 44), Fmt.clock(s.blizzard_ends_at - s.time)])
	elif s.blizzard_warned:
		parts.append("%s Blizzard in %s" % [UiTheme.icon("blizzard", 44), Fmt.clock(s.blizzard_at - s.time)])
	elif wave_line == "":
		parts.append("Clear skies")
	if wave_line != "":
		parts.append(wave_line)
	if Game.engine.paused:
		parts.append("PAUSED")
	return "  ·  ".join(parts)


## What a wave brings, as each kind's icon and count ("<wolf> 6  <fox> 4  <troll> 1"), a troll in
## red. Kinds without an icon yet are named.
static func mix_icons(mix: Dictionary, size := 40) -> String:
	var parts := []
	for kind in ["troll", "bear", "raider", "wolf", "fox"]:
		var n: int = mix.get(kind, 0)
		if n <= 0:
			continue
		var name: String = "wolves" if kind == "wolf" else kind
		var part := ("%s%d" % [UiTheme.icon(name, size), n]) if ResourceLoader.exists(UiTheme.ICON_DIR + name + ".png") \
				else "%d %s" % [n, Balance.ENEMIES[kind].name.to_lower()]
		if kind == "troll":
			part = "[color=#%s]%s[/color]" % [UiTheme.FALU.to_html(false), part]
		parts.append(part)
	return "  ".join(parts)


## True when a screen point is over UI, so the world shouldn't get the touch.
func blocks(pos: Vector2) -> bool:
	for c in [_top, sheet, _menu_button, _menu_panel, _dev_panel, _jans_button, _game_over, _offer_card]:
		if c and c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


# ---------- The button row: Jans and Menu ----------

## The row under the top bar: Menu and Jans side by side at the right, 48 px high on the phone
## (review 2), the fight strip to their left. Each button has its own slot (in pixels from the
## right edge).
const CORNER_TOP := 268
const CORNER_HEIGHT := 96
const CORNER_SLOTS := {"menu": [-194, -24], "jans": [-380, -210]}


## The row follows the top panel's bottom edge, which grows if the forecast wraps.
func _place_row() -> void:
	var top := maxf(CORNER_TOP, _top.get_rect().end.y + 12.0)
	for c in [_jans_button, _menu_button, _strip]:
		c.offset_top = top
		c.offset_bottom = top + CORNER_HEIGHT
	for c in [_menu_panel, _dev_panel]:
		if c:
			c.offset_top = top + CORNER_HEIGHT + 14


## Menu opens a small panel of Music, Sound and (debug builds) DEV.
func _build_menu() -> void:
	_menu_button = _corner_button(CORNER_SLOTS.menu, _toggle_menu, "Menu")
	_menu_panel = PanelContainer.new()
	_menu_panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(UiTheme.PAPER, 0.96)))
	_menu_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_menu_panel.offset_left = -380
	_menu_panel.offset_right = -24
	_menu_panel.offset_top = CORNER_TOP + CORNER_HEIGHT + 14
	_menu_panel.visible = false
	_root.add_child(_menu_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_menu_panel.add_child(v)
	_music_button = UiTheme.button("", _toggle_music)
	_sound_button = UiTheme.button("", _toggle_sound)
	v.add_child(_music_button)
	v.add_child(_sound_button)
	if OS.is_debug_build():
		var dev := UiTheme.button("DEV", func() -> void:
			_menu_panel.visible = false
			_toggle_dev())
		UiTheme.style_utility(dev)
		v.add_child(dev)
	_label_sound_toggles()


func _toggle_menu() -> void:
	_menu_panel.visible = not _menu_panel.visible
	if _dev_panel:
		_dev_panel.visible = false


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
	b.offset_bottom = CORNER_TOP + CORNER_HEIGHT
	b.custom_minimum_size.y = CORNER_HEIGHT
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 30)
	UiTheme.style_utility(b)
	_root.add_child(b)
	return b


func _label_sound_toggles() -> void:
	_music_button.text = "Music" if Audio.music_on else "Music off"
	_sound_button.text = "Sound" if Audio.sfx_on else "Sound off"
	# "Off" is an opaque muted fill, not faded, so it doesn't look unavailable (Astra review).
	UiTheme.style_utility(_music_button, UiTheme.UTILITY if Audio.music_on else UiTheme.UTILITY_OFF)
	UiTheme.style_utility(_sound_button, UiTheme.UTILITY if Audio.sfx_on else UiTheme.UTILITY_OFF)


# ---------- Dev panel (debug builds) ----------

func _build_dev() -> void:
	_dev_panel = PanelContainer.new()
	_dev_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dev_panel.offset_left = -520
	_dev_panel.offset_right = -24
	_dev_panel.offset_top = CORNER_TOP + CORNER_HEIGHT + 14
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
	v.add_child(UiTheme.button("Next wave", e.dev_wave))
	v.add_child(UiTheme.button("Armory +1", func(): _dev_armory(e)))
	v.add_child(UiTheme.button("Ink look", ink_toggled.emit))


## Builds the Armory, or raises it a level.
func _dev_armory(e: GameEngine) -> void:
	var i := MapData.site_of_building(e.state.sites, "armory")
	if i < 0:
		for k in e.state.sites.size():
			if e.state.sites[k].type == "armory":
				e.start_construction(k)
				i = k
	if i >= 0:
		e.dev_level_up(i)


func _toggle_dev() -> void:
	_dev_panel.visible = not _dev_panel.visible


func _unhandled_key_input(event: InputEvent) -> void:
	if _dev_panel and event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle_dev()
