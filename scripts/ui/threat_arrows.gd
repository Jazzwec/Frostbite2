class_name ThreatArrows
extends Control
## Arrows at the screen edge for threats off screen (fight_v2 reviews 1-7), so the middle of the
## phone stays free for the fight: while a wave is announced, one ochre arrow towards each side
## it will come from; during a raid, a small marker with its distance for each of the two nearest
## attackers off screen (terracotta while one winds up, muted ink while it's coming), and one
## arrow with a sack and the amount towards the nearest enemy running off with stolen goods.
## Nothing while a sheet is open. Nothing here takes touches.

const SIZE := 36.0
## Where an arrow may sit: this far in from each screen edge (left, top, right, bottom), clear
## of the top panel, the buttons and the fight strip under them.
const EDGE_MARGINS := Vector4(62, 460, 62, 200)
## Ochre for what's coming, terracotta for danger now (review 3), each with a cream keyline.
## A warned wave's sides in slate (review 8: ochre is the counter window's alone).
const COMING := Color(0.45, 0.5, 0.6)
const THIEF := Color(0.66, 0.3, 0.2)
## The attackers' markers: smaller (about 24 px), 16 px in from the edge, with their distance.
const ATTACKER_SIZE := 26.0
## One winding up is bigger, and the wave arrows step back to half while it does (review 8).
const ATTACKER_STRIKING_SIZE := 32.0
const ATTACKER_COMING := Color(0.36, 0.39, 0.46)
const ATTACKER_STRIKING := Color(0.66, 0.3, 0.2)
const ATTACKERS_SHOWN := 2
## Markers closer than this on screen are one, with a count.
const MERGE := 120.0
const KEYLINE := Color(0.98, 0.94, 0.86)
const ICON_SIZE := 64.0

## The bottom sheet: while it's open the arrows keep out of the way.
var sheet: Control

var _camera: Camera3D
var _marks := []  # [screen position, direction, colour, badge amount or "", size, label]
var _disc: Texture2D
var _bag: Texture2D
var _card: StyleBoxFlat
var _font: Font
var _time := 0.0


func setup(camera: Camera3D) -> void:
	_camera = camera


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc = WolfView.badge_disc()
	_bag = load(UiTheme.ICON_DIR + "bag.png")
	_card = StyleBoxFlat.new()
	_card.bg_color = Color(KEYLINE, 0.95)
	_card.set_corner_radius_all(12)
	_card.set_border_width_all(2)
	_card.border_color = Color(UiTheme.INK, 0.8)
	var theme_font: Font = UiTheme.get_theme().default_font
	_font = theme_font if theme_font else ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	_marks.clear()
	var s := Game.engine.state
	if _camera != null and not s.game_over and not (sheet and sheet.visible):
		if s.attack_warned and not s.next_wave.is_empty():
			for side in s.next_wave.sides:
				_mark(side, COMING, "")
		var thief := nearest_thief(s)
		if not thief.is_empty():
			var total := 0.0
			for res in thief.carry:
				total += thief.carry[res]
			_mark(thief.pos, THIEF, Fmt.num(total))
		var shown := 0
		for e in _attackers_by_distance(s):
			if shown >= ATTACKERS_SHOWN or (not thief.is_empty() and e.id == thief.id):
				continue
			var before := _marks.size()
			var striking: bool = e.bite_t >= 0.0
			_mark(e.pos, ATTACKER_STRIKING if striking else ATTACKER_COMING, "", ATTACKER_STRIKING_SIZE if striking else ATTACKER_SIZE,
					"%dm" % roundi(e.pos.distance_to(s.meagan_pos)))
			if _marks.size() > before:
				# Two the same way share one marker: the nearer, with how many.
				var merged := false
				for k in before:
					if _marks[k][5] != "" and _marks[k][0].distance_to(_marks[before][0]) < MERGE:
						_marks[k][6] += 1
						merged = true
				if merged:
					_marks.remove_at(before)
				else:
					shown += 1
	queue_redraw()


## The raid's enemy nearest Meagan that's running off with something, or {}.
static func nearest_thief(s: GameState) -> Dictionary:
	var best := {}
	for e in s.wolves:
		if e.outpost >= 0 or e.carry.is_empty() or e.hp <= 0.0:
			continue
		if best.is_empty() or e.pos.distance_to(s.meagan_pos) < best.pos.distance_to(s.meagan_pos):
			best = e
	return best


## The raid's enemies still after the town (not the leaving or the dead), nearest Meagan first.
static func _attackers_by_distance(s: GameState) -> Array:
	var out := s.wolves.filter(func(e): return e.outpost < 0 and e.hp > 0.0 and e.mode != "leave")
	out.sort_custom(func(a, b): return a.pos.distance_to(s.meagan_pos) < b.pos.distance_to(s.meagan_pos))
	return out


## An arrow at the edge towards `ground`, if it's off screen (on screen, its own badge says it).
func _mark(ground: Vector2, color: Color, badge: String, size := SIZE, label := "") -> void:
	var at := _camera.unproject_position(Vector3(ground.x, 1.0, ground.y))
	var screen := get_viewport_rect().size
	var m := EDGE_MARGINS
	var inside := Rect2(m.x, m.y, screen.x - m.x - m.z, screen.y - m.y - m.w)
	if inside.has_point(at):
		return
	var centre := inside.get_center()
	var dir := (at - centre).normalized()
	var half := inside.size / 2.0
	var reach := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
	var bob := 8.0 * absf(sin(_time * 5.0))
	_marks.append([centre + dir * (reach - bob), dir, color, badge, size, label, 1])


func _draw() -> void:
	var striking := _marks.any(func(mk): return mk[4] == ATTACKER_STRIKING_SIZE)
	for mk in _marks:
		var a: float = mk[4]
		var faded: bool = striking and mk[2] == COMING
		# A chunky arrow pointing along +Y, its tip at the origin (as the hints' arrow).
		var shape := PackedVector2Array([Vector2(0, 0), Vector2(-a, -a), Vector2(-a * 0.4, -a), Vector2(-a * 0.4, -a * 1.8),
			Vector2(a * 0.4, -a * 1.8), Vector2(a * 0.4, -a), Vector2(a, -a)])
		var outline := shape.duplicate()
		outline.append(shape[0])
		var dir: Vector2 = mk[1]
		draw_set_transform(mk[0], dir.angle() - PI / 2.0)
		var alpha := 0.5 if faded else 1.0
		draw_polyline(outline, Color(KEYLINE, alpha), 12.0, true)
		draw_colored_polygon(shape, Color(mk[2], alpha))
		draw_polyline(outline, Color(UiTheme.INK, alpha), 5.0, true)
		draw_set_transform(Vector2.ZERO)
		if mk[5] != "":
			# How far it is (and how many, if several), just behind the arrow, ink on a cream halo.
			var text: String = mk[5] if mk[6] < 2 else "%s ×%d" % [mk[5], mk[6]]
			var at: Vector2 = mk[0] - dir * a * 3.4
			# 16 px semibold on a compact cream card (review 8).
			var label_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 32)
			var card := Rect2(at - Vector2(label_size.x / 2.0 + 10.0, 22.0), Vector2(label_size.x + 20.0, 42.0))
			draw_style_box(_card, card)
			draw_string(_font, at + Vector2(-label_size.x / 2.0, 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UiTheme.INK)
			draw_string(_font, at + Vector2(-label_size.x / 2.0 + 1.0, 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UiTheme.INK)
		if mk[3] != "":
			# The thief's badge rides on its arrow: the ochre disc and what it carries.
			# The thief's capsule rides on its arrow, the same as over its head: a sack and the amount.
			var c: Vector2 = mk[0] - dir * a * 2.9
			var capsule := Vector2(ICON_SIZE * 2.0, ICON_SIZE)
			draw_texture_rect(_disc, Rect2(c - capsule / 2.0, capsule), false)
			draw_texture_rect(_bag, Rect2(c + Vector2(-ICON_SIZE * 0.8, -ICON_SIZE * 0.3), Vector2.ONE * ICON_SIZE * 0.6), false)
			draw_string(_font, c + Vector2(-2.0, 12.0), mk[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 34, UiTheme.INK)
