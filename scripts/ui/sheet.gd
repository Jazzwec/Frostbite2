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
var _upgrade: Button
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
	_body.add_child(UiTheme.label("Opening it lights a small furnace here. It burns from the town's heat: +%.2f heat/s to the drain, for good. What's out there is new every winter." % Balance.STOVE_DRAIN, 34, Color(0.8, 0.85, 0.95)))
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


## The Stockpile's sheet: what's in store against the caps.
func open_stockpile() -> void:
	_start(-1)
	stockpile = true
	_title.text = "Stockpile"
	_body.add_child(UiTheme.label("The town's store. Everything Meagan and the Jans gather lands here, and build pads, gates and the furnace draw from it.", 34, Color(0.8, 0.85, 0.95)))
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
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
	_auto_on_style.bg_color = Color(0.2, 0.6, 0.35)
	_auto_on_style.set_corner_radius_all(20)
	_auto_note = UiTheme.label("Balances jobs every 5 s. Moving a Jan by hand turns it off.", 30, Color(0.75, 0.8, 0.9))
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
	_title = UiTheme.label("", 48, UiTheme.ACCENT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close_button := UiTheme.button("Close", close)
	close_button.custom_minimum_size = Vector2(200, UiTheme.BUTTON_HEIGHT)
	header.add_child(close_button)


## An unbuilt plot: the game decides what it holds (agreed 2026-10-20), so it offers just that.
func _open_plot() -> void:
	var b: String = Game.engine.state.sites[site_index].type
	_title.text = Balance.BUILDINGS[b].name
	_body.add_child(UiTheme.label(Game.building_text(b).get("effect", ""), 34, Color(0.8, 0.85, 0.95)))
	_body.add_child(UiTheme.label("Build it, then stand on its pad: it takes what it needs from the Stockpile.", 34, Color(0.8, 0.85, 0.95)))
	_build_button = UiTheme.button("", _build)
	_body.add_child(_build_button)


func _open_building(b: String) -> void:
	_effect = UiTheme.label(Game.building_text(b).get("effect", ""), 34, Color(0.8, 0.85, 0.95))
	_body.add_child(_effect)
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	_upgrade = UiTheme.button("", _start_upgrade)
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
		var parts := []
		for res in need:
			parts.append("%s %s/%s" % [str(res).capitalize(), Fmt.num(site.progress.get(res, 0.0)), Fmt.num(need[res])])
		_status.text = ("Being built: " if site.level == 0 else "Upgrading: ") + ", ".join(parts) + "\nStand on the pad: it takes what it needs from the Stockpile."
		_upgrade.visible = false
	elif Economy.is_maxed(s, site_index):
		_status.text = "Fully upgraded."
		_upgrade.visible = false
	else:
		_status.text = _summary(s, b)
		_upgrade.visible = true
		_upgrade.text = "Upgrade to Lv %d  ·  %s" % [site.level + 1, Fmt.cost(Economy.site_cost(s, site_index))]
	if _job != "":
		_job_row.visible = site.level >= 1
		var def: Dictionary = Balance.JOBS[_job]
		var line := "%s: %s" % [def.name, _jans_text(Economy.job_count(s, _job))]
		if def.resource != "":
			line = "%s: %d/%d Jans  ·  %s %s/s" % [def.name, Economy.site_jans(s, site_index), Economy.site_slots(s, site_index), str(def.resource).capitalize(), "%.1f" % Economy.site_rate(s, site_index)]
		_job_label.text = line + "\nIdle Jans: %d" % Economy.idle_count(s)


func _refresh_jans(s: GameState) -> void:
	var idle := Economy.idle_count(s)
	_status.text = "%d idle  ·  %d of %d Jans" % [idle, s.jans.size(), Economy.jan_cap(s)]
	# Idle Jans are worth noticing: put them to work.
	_status.add_theme_color_override("font_color", UiTheme.ACCENT if idle > 0 else Color(0.95, 0.96, 1.0))
	for job in _jan_rows:
		var row: Dictionary = _jan_rows[job]
		var def: Dictionary = Balance.JOBS[job]
		var count := Economy.job_count(s, job)
		var open := Economy.job_open(s, job)
		if not open:
			row.label.text = "%s
build a %s first" % [def.name, Balance.BUILDINGS[def.building].name]
			row.label.add_theme_color_override("font_color", Color(0.62, 0.66, 0.74))
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
			row.label.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
		# A job without its building has nothing to press.
		row.minus.visible = open
		row.plus.visible = open
		row.minus.disabled = count == 0
		row.plus.disabled = s.jans.size() == count or not Economy.job_has_room(s, job)
	var fished := Economy.job_rate(s, "hunt")
	var eaten := Economy.food_eaten_per_second(s)
	var net := fished - eaten
	_food_line.text = "Food %s%s/s  (%s fished, %s eaten)" % ["+" if net >= 0.0 else "−", "%.2f" % absf(net), "%.2f" % fished, "%.2f" % eaten]
	_food_line.add_theme_color_override("font_color", Color(1.0, 0.55, 0.5) if net < 0.0 else Color(0.6, 0.9, 0.65))
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
