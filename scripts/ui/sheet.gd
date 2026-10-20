class_name Sheet
extends PanelContainer
## The bottom sheet: the build list for an empty plot, a building's panel
## (level, what the next level costs, Upgrade, and −/+ for its Jans), or the Stockpile's stores.
## Built once when opened; texts and buttons update in place so a press is never interrupted.

var site_index := -1
## Open on the Stockpile rather than a plot.
var stockpile := false

var _title: Label
var _effect: Label
var _status: Label
var _upgrade: Button
var _job_label: Label
var _job_row: HBoxContainer
var _job := ""
var _build_buttons := {}  # building id -> Button
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


func open_site(index: int) -> void:
	_start(index)
	var site: Dictionary = Game.engine.state.sites[index]
	if site.building == "":
		_open_plot()
	else:
		_open_building(site.building)
	visible = true
	_refresh()


## The Stockpile's sheet: what's in store against the caps.
func open_stockpile() -> void:
	_start(-1)
	stockpile = true
	_title.text = "Stockpile"
	_body.add_child(UiTheme.label("The town's store. Jans' work lands here, build pads and the furnace draw from it, and she can drop off her bag on the pad.", 34, Color(0.8, 0.85, 0.95)))
	_status = UiTheme.label("", 38)
	_body.add_child(_status)
	visible = true
	_refresh()


## Clears the sheet and builds its header (title and Close).
func _start(index: int) -> void:
	site_index = index
	stockpile = false
	for c in get_children():
		c.queue_free()
	_build_buttons.clear()
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


func _open_plot() -> void:
	_title.text = "Empty plot"
	_body.add_child(UiTheme.label("Pick a building, then stand on its pad: her bag pays first, then the Stockpile.", 34, Color(0.8, 0.85, 0.95)))
	for b in Balance.BUILDINGS:
		if Balance.BUILDINGS[b].start > 0:
			continue
		var button := UiTheme.button("", _choose.bind(b))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_body.add_child(button)
		_build_buttons[b] = button


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
		for spec in [["−", Game.engine.remove_from_job], ["+", Game.engine.add_to_job]]:
			var button := UiTheme.button(spec[0], spec[1].bind(_job))
			button.custom_minimum_size = Vector2(140, UiTheme.BUTTON_HEIGHT)
			button.add_theme_font_size_override("font_size", 56)
			_job_row.add_child(button)


func _choose(b: String) -> void:
	Game.engine.choose_building(site_index, b)
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
	if not _build_buttons.is_empty():
		if site.building != "":
			close()
			return
		var open := Economy.buildable(s)
		for b in _build_buttons:
			var button: Button = _build_buttons[b]
			var name: String = Balance.BUILDINGS[b].name
			button.visible = open.has(b)
			if Economy.is_unlocked(s, b):
				button.text = "%s  ·  %s" % [name, Fmt.cost(Economy.cost(b, 0))]
				button.disabled = false
			else:
				button.text = "%s  ·  needs Furnace Lv %d" % [name, Balance.BUILDINGS[b].unlock]
				button.disabled = true
		return
	var b: String = site.building
	var name: String = Balance.BUILDINGS[b].name
	_title.text = name if site.level == 0 else "%s  Lv %d" % [name, site.level]
	if site.upgrading:
		var need := Economy.site_cost(s, site_index)
		var parts := []
		for res in need:
			parts.append("%s %s/%s" % [str(res).capitalize(), Fmt.num(site.progress.get(res, 0.0)), Fmt.num(need[res])])
		_status.text = ("Being built: " if site.level == 0 else "Upgrading: ") + ", ".join(parts) + "\nStand on the pad: her bag pays first, then the Stockpile."
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
		var line := "%s: %d Jans" % [def.name, Economy.job_count(s, _job)]
		if def.resource != "":
			line += "  ·  %s %s/s" % [str(def.resource).capitalize(), "%.1f" % Economy.job_rate(s, _job)]
		_job_label.text = line + "\nIdle Jans: %d" % Economy.idle_count(s)


func _summary(s: GameState, b: String) -> String:
	match b:
		"furnace":
			return "Jans %d/%d  ·  Fuel %s/%s  ·  Idle Jans %d" % [s.jans.size(), Economy.jan_cap(s), Fmt.num(s.fuel), Fmt.num(Economy.fuel_cap(s)), Economy.idle_count(s)]
		"sled_shed":
			return "Meagan's bag holds %s." % Fmt.num(Economy.bag_cap(s))
		"storehouse":
			var caps := Economy.caps(s)
			return "Storage: Wood %s, Food %s, Materials %s." % [Fmt.num(caps.wood), Fmt.num(caps.food), Fmt.num(caps.materials)]
		"bunkhouse":
			return "Room for %d Jans in the city." % Economy.jan_cap(s)
		"watchtower":
			return "Blizzards warned %s ahead, wolves %s ahead." % [Fmt.clock(Economy.blizzard_warning(s)), Fmt.clock(Economy.attack_warning(s))]
		"kitchen":
			return "Each Jan eats %s Food a minute." % ("%.2f" % (Economy.food_per_jan_per_second(s) * 60.0))
	return ""
