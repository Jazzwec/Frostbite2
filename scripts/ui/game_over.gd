class_name GameOverCard
extends Control
## Shown when the fire goes out: how long the village was kept warm, the best time, a few
## numbers from the winter, and Play again.

var time_survived := 0.0
var best := 0.0
var new_best := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.1, 0.0)
	add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.65, 0.6)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.1, 0.13, 0.22, 0.97)))
	panel.custom_minimum_size = Vector2(860, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)

	var s := Game.engine.state
	_add_line(v, "The fire went out", 64, UiTheme.ACCENT)
	_add_line(v, "You kept the village warm for", 38, Color(0.85, 0.88, 0.95))
	_add_line(v, Fmt.clock(time_survived), 110, Color.WHITE)
	_add_line(v, "New best!" if new_best else "Best: %s" % Fmt.clock(best), 44, UiTheme.ACCENT if new_best else UiTheme.COLD)
	var built := s.sites.filter(func(site): return site.building != "" and site.level >= 1).size()
	# The winter's numbers as four big tiles, each with its icon and what it counts.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	v.add_child(grid)
	_add_stat(grid, "jans", s.rescued_total, "Jans rescued")
	_add_stat(grid, "build", built, "Buildings")
	_add_stat(grid, "heat", Economy.furnace_level(s), "Furnace level")
	_add_stat(grid, "wolves", s.attacks_repelled, "Wolf attacks\nfought off")
	var again := UiTheme.button("Play again", Game.new_game)
	again.custom_minimum_size = Vector2(0, 150)
	again.add_theme_font_size_override("font_size", 52)
	v.add_child(again)

	# Pop in once the panel has its size.
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.25)


func _add_stat(grid: GridContainer, icon: String, value: int, caption: String) -> void:
	var tile := PanelContainer.new()
	tile.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(1, 1, 1, 0.06)))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(tile)
	var t := VBoxContainer.new()
	t.add_theme_constant_override("separation", 0)
	tile.add_child(t)
	var number := UiTheme.rich_label(72, Color.WHITE)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.text = "%s %s" % [UiTheme.icon(icon, 72), Fmt.num(value)]
	t.add_child(number)
	var label := UiTheme.label(caption, 32, Color(0.8, 0.84, 0.95))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_child(label)


func _add_line(parent: Control, text: String, size: int, color: Color) -> void:
	var l := UiTheme.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
