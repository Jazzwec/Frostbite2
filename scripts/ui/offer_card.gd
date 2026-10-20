class_name OfferCard
extends Control
## What a chest offers (agreed 2026-10-20), over everything while the world waits: a boon chest's
## 2 or 3 run-long boons to pick from, or a gear chest's item to equip or leave.

const TIER_NAMES := {"common": "Common", "rare": "Rare", "epic": "Epic"}
const TIER_COLORS := {"common": Color(0.85, 0.88, 0.95), "rare": Color(0.55, 0.85, 0.82), "epic": Color(0.95, 0.75, 0.35)}

var offer := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.1, 0.55)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.1, 0.13, 0.22, 0.97)))
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	panel.add_child(v)
	if offer.kind == "boon":
		_boons(v)
	else:
		_gear(v)

	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	await get_tree().process_frame
	panel.pivot_offset = panel.size / 2.0
	var t := create_tween().set_parallel(true)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(panel, "modulate:a", 1.0, 0.2)


func _boons(v: VBoxContainer) -> void:
	var rarity: String = Game.engine.state.chests[offer.chest].rarity
	_line(v, "%s chest" % TIER_NAMES[rarity], 60, TIER_COLORS[rarity])
	_line(v, "Pick one. It lasts all winter.", 36, Color(0.82, 0.86, 0.95))
	for i in offer.options.size():
		var boon: Dictionary = Balance.BOONS[offer.options[i]]
		var button := UiTheme.button("%s\n%s" % [boon.name, boon.text], func(): Game.engine.choose_boon(i))
		button.custom_minimum_size = Vector2(0, 170)
		button.add_theme_font_size_override("font_size", 40)
		v.add_child(button)


func _gear(v: VBoxContainer) -> void:
	var slot: String = offer.slot
	var tier: String = offer.tier
	var def: Dictionary = Balance.GEAR[slot]
	var have: String = Game.engine.state.gear[slot]
	_line(v, "%s %s" % [TIER_NAMES[tier], def.name.to_lower()], 60, TIER_COLORS[tier])
	_line(v, _gear_effect(slot, tier), 40, Color.WHITE)
	_line(v, "Now: %s" % (("%s %s, %s" % [TIER_NAMES[have].to_lower(), def.name.to_lower(), _gear_effect(slot, have)]) if have != "" else "no %s" % def.name.to_lower()), 34, Color(0.75, 0.8, 0.9))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	for spec in [["Equip", true], ["Keep mine" if have != "" else "Leave it", false]]:
		var equip: bool = spec[1]
		var button := UiTheme.button(spec[0], func(): Game.engine.choose_gear(equip))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 150)
		button.add_theme_font_size_override("font_size", 48)
		row.add_child(button)


## "+20% walking".
static func _gear_effect(slot: String, tier: String) -> String:
	var def: Dictionary = Balance.GEAR[slot]
	var value: float = def.tiers[tier]
	return "+%d%% %s" % [roundi(value * 100.0), def.text]


func _line(parent: Control, text: String, size: int, color: Color) -> void:
	var l := UiTheme.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
