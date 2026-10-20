class_name Sheet
extends PanelContainer
## The bottom sheet: the build list for an empty plot, a building's panel
## (level, what the next level costs, Upgrade, and −/+ for its Jans), the Stockpile's stores, or
## the Jans screen (every job with −/+, and Food fished against eaten).
## Built once when opened; texts and buttons update in place so a press is never interrupted.

var site_index := -1
## Open on the Stockpile rather than a plot.
var stockpile := false
## Open as the Jans screen.
var jans := false
## Open on a gate: the closed tile behind it (gates shift index as tiles open, tiles don't).
var gate_tile := Vector2i(9999, 9999)
var _jan_rows := {}  # job -> {label, minus, plus}
var _food_line: Label
var _auto_button: Button
var _auto_note: Label
var _auto_on_style: StyleBoxFlat

var _title: Label
var _effect: Label
var _status: Label
## What the next upgrade costs against what she has (bag and store), a shortage in red.
var _cost_line: RichTextLabel
var _upgrade: Button
## The Armory's rows (fight_v2 reviews 1 and 2): [now, next, name] labels by stat.
var _armory_cells := {}
## Whether the upgrade button is in its muted look (she's short of something).
var _upgrade_muted := false
var _job_label: Label
var _job_row: HBoxContainer
var _job := ""
var _build_button: Button  # an unbuilt plot's Build button
var _body: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 20
	offset_right = -20
	offset_bottom = -20
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	visible = false


func close() -> void:
	visible = false
	site_index = -1
	stockpile = false
	jans = false
	gate_tile = Vector2i(9999, 9999)


func open_site(index: int) -> void:
	_start(index)
	var site: Dictionary = Game.engine.state.sites[index]
	if site.building == "":
		_open_plot()
	else:
		_open_building(site.building)
	visible = true
	_refresh()


## A gate's sheet: what opening the tile behind it costs, and what it does. [agreed 2026-10-20]
func open_gate(index: int) -> void:
	_start(-1)
	gate_tile = Game.engine.state.gates[index].tile
	_title.text = "New area"
	_body.add_child(UiTheme.label("Opening it lights a small furnace here. It burns from the town's heat: +%.2f heat/s to the drain, for good. What's out there is new every winter." % Balance.STOVE_DRAIN, 34, UiTheme.INK_SOFT))
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	_upgrade = UiTheme.button("", _open_gate)
	_body.add_child(_upgrade)
	visible = true
	_refresh()


func _gate_index() -> int:
	var gates: Array = Game.engine.state.gates
	for i in gates.size():
		if gates[i].tile == gate_tile:
			return i
	return -1


func _open_gate() -> void:
	Game.engine.start_gate(_gate_index())


## The Stockpile's sheet: what's in store against the caps, and its shared upgrade.
func open_stockpile() -> void:
	_start(-1)
	stockpile = true
	_title.text = "Stockpile"
	_body.add_child(UiTheme.label("The town's store. Every stockpile is a door into it: Meagan empties her bag here and the Jans bring their work, and build pads, gates and the furnace draw from it. Its level is shared by them all and raises every cap.", 34, UiTheme.INK_SOFT))
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	_upgrade = UiTheme.button("", func() -> void: Game.engine.start_upgrade_of("stockpile"))
	_body.add_child(_upgrade)
	visible = true
	_refresh()


## The Jans screen: every job's Jans and output, −/+ to move Jans, and Food in against out.
func open_jans() -> void:
	_start(-1)
	jans = true
	_title.text = "Jans"
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	_jan_rows.clear()
	for job in Balance.JOBS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_body.add_child(row)
		var label := UiTheme.label("", 36)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var buttons := []
		for spec in [["−", Game.engine.remove_from_job], ["+", Game.engine.add_to_job]]:
			var button := UiTheme.button(spec[0], spec[1].bind(job))
			button.custom_minimum_size = Vector2(140, UiTheme.BUTTON_HEIGHT)
			button.add_theme_font_size_override("font_size", 56)
			row.add_child(button)
			buttons.append(button)
		_jan_rows[job] = {"label": label, "minus": buttons[0], "plus": buttons[1]}
	_food_line = UiTheme.label("", 34)
	_body.add_child(_food_line)
	_auto_button = UiTheme.button("", func(): Game.engine.set_auto_assign(not Game.engine.state.auto_assign))
	_body.add_child(_auto_button)
	_auto_on_style = StyleBoxFlat.new()
	_auto_on_style.bg_color = UiTheme.TEAL_DEEP
	_auto_on_style.set_corner_radius_all(20)
	_auto_note = UiTheme.label("Balances jobs every 5 s. Moving a Jan by hand turns it off.", 30, UiTheme.INK_SOFT)
	_body.add_child(_auto_note)
	visible = true
	_refresh()


## Clears the sheet and builds its header (title and Close).
func _start(index: int) -> void:
	site_index = index
	stockpile = false
	gate_tile = Vector2i(9999, 9999)
	jans = false
	for c in get_children():
		c.queue_free()
	_build_button = null
	_job = ""
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	add_child(_body)
	var header := HBoxContainer.new()
	_body.add_child(header)
	_title = UiTheme.label("", 48, UiTheme.TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_button := UiTheme.button("Close", close)
	close_button.custom_minimum_size = Vector2(200, UiTheme.BUTTON_HEIGHT)
	header.add_child(close_button)


## An unbuilt plot: the game decides what it holds (agreed 2026-10-20), so it offers just that.
func _open_plot() -> void:
	var b: String = Game.engine.state.sites[site_index].type
	_title.text = Balance.BUILDINGS[b].name
	_body.add_child(UiTheme.label(Game.building_text(b).get("effect", ""), 34, UiTheme.INK_SOFT))
	_body.add_child(UiTheme.label("Build it, then stand on its pad: it takes what it needs from her bag, then the Stockpile.", 34, UiTheme.INK_SOFT))
	_build_button = UiTheme.button("", _build)
	_body.add_child(_build_button)


func _open_building(b: String) -> void:
	_effect = UiTheme.label(Game.building_text(b).get("effect", ""), 34, UiTheme.INK_SOFT)
	_body.add_child(_effect)
	if b == "armory":
		_body.add_child(_armory_grid())
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	_cost_line = UiTheme.rich_label(34)
	_body.add_child(_cost_line)
	_upgrade = UiTheme.button("", _start_upgrade)
	_upgrade_muted = false
	_body.add_child(_upgrade)
	for job in Balance.JOBS:
		if Balance.JOBS[job].building == b:
			_job = job
	if _job != "":
		_job_row = HBoxContainer.new()
		_job_row.add_theme_constant_override("separation", 16)
		_body.add_child(_job_row)
		_job_label = UiTheme.label("", 38)
		_job_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_job_row.add_child(_job_label)
		# A producer's own Jans (agreed 2026-10-20: 3 each); the Barracks' guards are one pool.
		var per_site := _job != "guard"
		var minus: Callable = Game.engine.remove_from_site.bind(site_index) if per_site else Game.engine.remove_from_job.bind(_job)
		var plus: Callable = Game.engine.add_to_site.bind(site_index) if per_site else Game.engine.add_to_job.bind(_job)
		for spec in [["−", minus], ["+", plus]]:
			var button := UiTheme.button(spec[0], spec[1])
			button.custom_minimum_size = Vector2(140, UiTheme.BUTTON_HEIGHT)
			button.add_theme_font_size_override("font_size", 56)
			_job_row.add_child(button)


func _build() -> void:
	Game.engine.start_construction(site_index)
	close()


## The Armory's rows, aligned: what each does now and at the next level (fight_v2 review 1).
const ARMORY_ROWS := [["snow", "Snowball damage"], ["stick", "Sweep damage"], ["guard", "Guard damage / HP"]]


func _armory_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 6)
	_armory_cells = {}
	# A fourth row says what the next level does to a wolf, when it does something (review 2).
	for row in ARMORY_ROWS + [["wolf", "Hits to beat a wolf"]]:
		var name := UiTheme.label(row[1], 36, UiTheme.INK_SOFT)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var now := UiTheme.label("", 40)
		var next := UiTheme.label("", 40, UiTheme.TEAL_DEEP)
		for l in [now, next]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			l.custom_minimum_size.x = 150
		grid.add_child(name)
		grid.add_child(now)
		grid.add_child(next)
		_armory_cells[row[0]] = [now, next, name]
	return grid


func _refresh_armory(s: GameState) -> void:
	var lv := maxi(Economy.level(s, "armory"), 1)
	var top := lv >= Balance.ARMORY_LEVELS.size()
	var texts := func(at: int) -> Dictionary:
		var w := Economy.meagan_weapon(s, at)
		var kit: Array = Economy.armory_row(s, at).guard
		return {"snow": "%d" % w.snow_damage, "stick": "%d" % w.stick_damage, "guard": "%d / %d" % [kit[0], kit[1]]}
	var now: Dictionary = texts.call(lv)
	var next: Dictionary = {} if top else texts.call(lv + 1)
	# Sweeps to beat a wolf (its base HP), or snowballs if the sweep's count doesn't change.
	var wolf_hp: float = Balance.ENEMIES.wolf.hp
	var w_now := Economy.meagan_weapon(s, lv)
	var w_next := Economy.meagan_weapon(s, mini(lv + 1, Balance.ARMORY_LEVELS.size()))
	var sweeps := [ceili(wolf_hp / w_now.stick_damage), ceili(wolf_hp / w_next.stick_damage)]
	var balls := [ceili(wolf_hp / w_now.snow_damage), ceili(wolf_hp / w_next.snow_damage)]
	var shows_wolf: bool = not top and (sweeps[1] < sweeps[0] or balls[1] < balls[0])
	var by_sweep: bool = sweeps[1] < sweeps[0] or balls[1] >= balls[0]
	var counts: Array = sweeps if by_sweep else balls
	now["wolf"] = "%d" % counts[0]
	next["wolf"] = "%d" % counts[1]
	_armory_cells.wolf[2].text = "Sweeps to beat a wolf" if by_sweep else "Snowballs to beat a wolf"
	for key in _armory_cells:
		var cells: Array = _armory_cells[key]
		cells[0].text = now[key]
		cells[1].text = "MAX" if top else "→ " + next.get(key, "")
		if key == "wolf":
			for c in cells:
				c.visible = shows_wolf


## Each resource the upgrade needs against what she has (bag and store), owned first (fight_v2
## review 2): "Wood 299 owned / 82 needed", or "Materials 8 / 25, need 17" with only the
## shortfall in red. One per line.
func _cost_text(s: GameState, need: Dictionary) -> String:
	var lines := []
	for res in need:
		var have: float = s.piles.get(res, 0.0) + s.bag.get(res, 0.0)
		var name := str(res).capitalize()
		if have >= need[res]:
			lines.append("%s %s %s owned / %s needed" % [UiTheme.icon(res, 40), name, Fmt.num(have), Fmt.num(need[res])])
		else:
			lines.append("%s %s %s / %s, [color=#%s]need %s[/color]" % [UiTheme.icon(res, 40), name, Fmt.num(have), Fmt.num(need[res]),
					UiTheme.FALU.to_html(false), Fmt.num(ceilf(need[res] - have))])
	return "\n".join(lines)


## What's still missing for `need`, as "17 Materials" (or "" when she has it all).
func _shortfall(s: GameState, need: Dictionary) -> String:
	var parts := []
	for res in need:
		var short: float = need[res] - s.piles.get(res, 0.0) - s.bag.get(res, 0.0)
		if short > 0.0:
			parts.append("%s %s" % [Fmt.num(ceilf(short)), str(res).capitalize()])
	return ", ".join(parts)


func _start_upgrade() -> void:
	Game.engine.start_upgrade(site_index)


func _process(_delta: float) -> void:
	if visible:
		_refresh()
		# Hug the bottom edge and size to the contents (containers grow but never shrink by themselves).
		offset_top = offset_bottom - get_combined_minimum_size().y


func _refresh() -> void:
	var s := Game.engine.state
	if jans:
		_refresh_jans(s)
		return
	if gate_tile != Vector2i(9999, 9999):
		var g := _gate_index()
		if g < 0:
			close()
			return
		var gate: Dictionary = s.gates[g]
		if gate.paying:
			var parts := []
			for res in gate.cost:
				parts.append("%s %s/%s" % [str(res).capitalize(), Fmt.num(gate.progress.get(res, 0.0)), Fmt.num(gate.cost[res])])
			_status.text = "Stand on the pad to pay: " + ", ".join(parts)
			_upgrade.visible = false
		else:
			_status.text = "The drain is %.2f heat/s now, %.2f after." % [Economy.heat_drain(s), Economy.heat_drain(s, 1)]
			_upgrade.text = "Open  ·  %s" % Fmt.cost(gate.cost)
			_upgrade.visible = true
		return
	if stockpile:
		var caps := Economy.caps(s)
		var lines := []
		for res in ["wood", "food", "materials"]:
			lines.append("%s  %s / %s" % [str(res).capitalize(), Fmt.num(s.piles[res]), Fmt.num(caps[res])])
		_title.text = "Stockpile  Lv %d" % s.stockpile_level
		var need := Economy.cost("stockpile", s.stockpile_level)
		if s.upgrades.has("stockpile"):
			var parts := []
			for res in need:
				parts.append("%s %s/%s" % [str(res).capitalize(), Fmt.num(s.upgrades.stockpile.get(res, 0.0)), Fmt.num(need[res])])
			lines.append("Upgrading: " + ", ".join(parts) + "\nStand on any stockpile's pad.")
			_upgrade.visible = false
		elif s.stockpile_level >= Balance.BUILDINGS.stockpile.max:
			lines.append("Fully upgraded.")
			_upgrade.visible = false
		else:
			_upgrade.visible = true
			_upgrade.text = "Upgrade to Lv %d  ·  %s" % [s.stockpile_level + 1, Fmt.cost(need)]
		_status.text = "\n".join(lines)
		return
	if site_index < 0:
		return
	var site: Dictionary = s.sites[site_index]
	if _build_button != null:
		if site.building != "":
			close()
			return
		var plot: String = site.type
		if Economy.is_unlocked(s, plot):
			_build_button.text = "Build  ·  %s" % Fmt.cost(Economy.cost(plot, 0))
			_build_button.disabled = false
		else:
			_build_button.text = "Needs Furnace Lv %d" % Balance.BUILDINGS[plot].unlock
			_build_button.disabled = true
		return
	var b: String = site.building
	var name: String = Balance.BUILDINGS[b].name
	_title.text = name if site.level == 0 else "%s  Lv %d" % [name, site.level]
	if site.upgrading:
		var need := Economy.site_cost(s, site_index)
		var progress := Economy.site_progress(s, site_index)
		var parts := []
		for res in need:
			parts.append("%s %s/%s" % [str(res).capitalize(), Fmt.num(progress.get(res, 0.0)), Fmt.num(need[res])])
		var where := "Stand on the pad" if site.level == 0 else _upgrade_where(s, b)
		_status.text = ("Being built: " if site.level == 0 else "Upgrading: ") + ", ".join(parts) + "\n%s: it takes what it needs from her bag, then the Stockpile." % where
		_upgrade.visible = false
	elif Economy.is_maxed(s, site_index):
		_status.text = "Fully upgraded."
		_upgrade.visible = false
	else:
		_status.text = _summary(s, b) + _shared_note(s, b)
		_upgrade.visible = true
		# Short of something, the button says so and looks muted; it still starts the upgrade, which
		# she pays on the pad as she brings it (review 2).
		var short := _shortfall(s, Economy.site_cost(s, site_index))
		_upgrade.text = "Upgrade to Lv %d" % (site.level + 1) if short == "" else "Start Lv %d: need %s" % [site.level + 1, short]
		if (short != "") != _upgrade_muted:
			_upgrade_muted = short != ""
			if _upgrade_muted:
				UiTheme.style_utility(_upgrade, UiTheme.UTILITY_OFF)
			else:
				UiTheme.style_primary(_upgrade)
	_cost_line.visible = _upgrade.visible
	if _upgrade.visible:
		_cost_line.text = _cost_text(s, Economy.site_cost(s, site_index))
	if b == "armory":
		_refresh_armory(s)
	if _job != "":
		_job_row.visible = site.level >= 1
		var def: Dictionary = Balance.JOBS[_job]
		var line := "%s: %s" % [def.name, _jans_text(Economy.job_count(s, _job))]
		if def.resource != "":
			line = "%s: %d/%d Jans  ·  %s %s/s" % [def.name, Economy.site_jans(s, site_index), Economy.site_slots(s, site_index), str(def.resource).capitalize(), "%.1f" % Economy.site_rate(s, site_index)]
		_job_label.text = line + "\nIdle Jans: %d" % Economy.idle_count(s)


## Upgrades are shared by every plot of a building (agreed 2026-10-20), so the sheet says so.
func _shared_note(s: GameState, b: String) -> String:
	if b == "furnace":
		return "\nUpgrading raises every small furnace too." if not s.stoves.is_empty() else ""
	var plots := Economy.upgrade_pads(s, b).size()
	return "\nUpgrading raises all %d of them." % plots if plots > 1 else ""


func _upgrade_where(s: GameState, b: String) -> String:
	if b == "furnace":
		return "Stand on the furnace's pad or a small furnace's" if not s.stoves.is_empty() else "Stand on the pad"
	return "Stand on any of their pads" if Economy.upgrade_pads(s, b).size() > 1 else "Stand on the pad"


func _refresh_jans(s: GameState) -> void:
	var idle := Economy.idle_count(s)
	_status.text = "%d idle  ·  %d of %d Jans" % [idle, s.jans.size(), Economy.jan_cap(s)]
	# Idle Jans are worth noticing: put them to work.
	_status.add_theme_color_override("font_color", UiTheme.FALU if idle > 0 else UiTheme.INK)
	for job in _jan_rows:
		var row: Dictionary = _jan_rows[job]
		var def: Dictionary = Balance.JOBS[job]
		var count := Economy.job_count(s, job)
		var open := Economy.job_open(s, job)
		if not open:
			row.label.text = "%s
build a %s first" % [def.name, Balance.BUILDINGS[def.building].name]
			row.label.add_theme_color_override("font_color", Color(UiTheme.INK_SOFT, 0.7))
		else:
			var line := "%s  ·  %s" % [def.name, _jans_text(count)]
			if def.resource != "":
				# Room across all its producers: more of them means more room. [agreed 2026-10-20]
				line = "%s  ·  %d/%d Jans in %d" % [def.name, count, Economy.job_slots(s, job), Economy.job_sites(s, job).size()]
				line += "
%s %s/s" % [str(def.resource).capitalize(), "%.1f" % Economy.job_rate(s, job)]
			else:
				line += "
guarding the furnace"
			row.label.text = line
			row.label.add_theme_color_override("font_color", UiTheme.INK)
		# A job without its building has nothing to press.
		row.minus.visible = open
		row.plus.visible = open
		row.minus.disabled = count == 0
		row.plus.disabled = s.jans.size() == count or not Economy.job_has_room(s, job)
	var fished := Economy.job_rate(s, "hunt")
	var eaten := Economy.food_eaten_per_second(s)
	var net := fished - eaten
	_food_line.text = "Food %s%s/s  (%s fished, %s eaten)" % ["+" if net >= 0.0 else "−", "%.2f" % absf(net), "%.2f" % fished, "%.2f" % eaten]
	_food_line.add_theme_color_override("font_color", UiTheme.FALU if net < 0.0 else UiTheme.TEAL_DEEP)
	if Game.engine.can_auto_assign():
		_auto_button.disabled = false
		_auto_button.text = "Auto-assign: ON" if s.auto_assign else "Auto-assign: off"
		_auto_note.visible = true
	else:
		_auto_button.disabled = true
		_auto_button.text = "Auto-assign unlocks at Furnace Lv %d" % Balance.AUTO_ASSIGN_FURNACE_LEVEL
		_auto_note.visible = false
	# Green while it's on, so the state reads at a glance.
	for state in ["normal", "hover", "pressed"]:
		if s.auto_assign:
			_auto_button.add_theme_stylebox_override(state, _auto_on_style)
		else:
			_auto_button.remove_theme_stylebox_override(state)


## "1 Jan", "3 Jans".
static func _jans_text(n: int) -> String:
	return "%d Jan%s" % [n, "" if n == 1 else "s"]


func _summary(s: GameState, b: String) -> String:
	match b:
		"furnace":
			return "Jans %d/%d  ·  Fuel %s/%s  ·  Idle Jans %d" % [s.jans.size(), Economy.jan_cap(s), Fmt.num(s.fuel), Fmt.num(Economy.fuel_cap(s)), Economy.idle_count(s)]
		"storehouse":
			var caps := Economy.caps(s)
			return "Storage: Wood %s, Food %s, Materials %s." % [Fmt.num(caps.wood), Fmt.num(caps.food), Fmt.num(caps.materials)]
		"bunkhouse":
			return "Room for %d Jans in the city." % Economy.jan_cap(s)
		"hot_springs":
			return "Heat drain %d%% lower: %s heat a second now." % [roundi(Economy.hot_springs_cut(s) * 100.0), "%.2f" % Economy.heat_drain(s)]
		"watchtower":
			return "Blizzards warned %s ahead, wolves %s ahead." % [Fmt.clock(Economy.blizzard_warning(s)), Fmt.clock(Economy.attack_warning(s))]
		"kitchen":
			return "Each Jan eats %s Food a minute." % ("%.2f" % (Economy.food_per_jan_per_second(s) * 60.0))
	return ""
