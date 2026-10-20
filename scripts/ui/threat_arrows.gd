class_name ThreatArrows
extends Control
## Arrows at the screen edge for threats off screen (fight_v2 review 1), so the middle of the
## phone stays free for the fight: while a wave is announced, one rust arrow towards each side it
## will come from; during a raid, one gold arrow with a sack towards the nearest enemy running off
## with stolen goods (only that one). Nothing while a sheet is open. Nothing here takes touches.

const SIZE := 36.0
## Where an arrow may sit: this far in from each screen edge (left, top, right, bottom), clear
## of the top panel, the buttons and the fight strip under them.
const EDGE_MARGINS := Vector4(74, 460, 74, 184)
## Ochre for what's coming, terracotta for danger now (review 3), each with a cream keyline.
const COMING := Color(0.79, 0.59, 0.25)
const THIEF := Color(0.66, 0.3, 0.2)
const KEYLINE := Color(0.98, 0.94, 0.86)
const ICON_SIZE := 64.0

## The bottom sheet: while it's open the arrows keep out of the way.
var sheet: Control

var _camera: Camera3D
var _marks := []  # [screen position, direction, colour, badge amount or ""]
var _disc: Texture2D
var _bag: Texture2D
var _font: Font
var _time := 0.0


func setup(camera: Camera3D) -> void:
	_camera = camera


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc = WolfView.badge_disc()
	_bag = load(UiTheme.ICON_DIR + "bag.png")
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


## An arrow at the edge towards `ground`, if it's off screen (on screen, its own badge says it).
func _mark(ground: Vector2, color: Color, badge: String) -> void:
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
	_marks.append([centre + dir * (reach - bob), dir, color, badge])


func _draw() -> void:
	var a := SIZE
	# A chunky arrow pointing along +Y, its tip at the origin (as the hints' arrow).
	var shape := PackedVector2Array([Vector2(0, 0), Vector2(-a, -a), Vector2(-a * 0.4, -a), Vector2(-a * 0.4, -a * 1.8),
		Vector2(a * 0.4, -a * 1.8), Vector2(a * 0.4, -a), Vector2(a, -a)])
	var outline := shape.duplicate()
	outline.append(shape[0])
	for mk in _marks:
		var dir: Vector2 = mk[1]
		draw_set_transform(mk[0], dir.angle() - PI / 2.0)
		draw_polyline(outline, KEYLINE, 12.0, true)
		draw_colored_polygon(shape, mk[2])
		draw_polyline(outline, UiTheme.INK, 5.0, true)
		draw_set_transform(Vector2.ZERO)
		if mk[3] != "":
			# The thief's badge rides on its arrow: the ochre disc and what it carries.
			var c: Vector2 = mk[0] - dir * a * 2.7
			draw_texture_rect(_disc, Rect2(c - Vector2.ONE * ICON_SIZE / 2.0, Vector2.ONE * ICON_SIZE), false)
			var size := _font.get_string_size(mk[3], HORIZONTAL_ALIGNMENT_CENTER, -1, 34)
			draw_string(_font, c + Vector2(-size.x / 2.0, 12.0), mk[3], HORIZONTAL_ALIGNMENT_CENTER, -1, 34, UiTheme.INK)
			draw_texture_rect(_bag, Rect2(c + Vector2(-ICON_SIZE * 1.15, -ICON_SIZE * 0.3), Vector2.ONE * ICON_SIZE * 0.6), false)
