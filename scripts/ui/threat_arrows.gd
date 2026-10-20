class_name ThreatArrows
extends Control
## Arrows at the screen edge for threats off screen (fight_v2 review 1), so the middle of the
## phone stays free for the fight: while a wave is announced, one rust arrow towards each side it
## will come from; during a raid, one gold arrow with a sack towards the nearest enemy running off
## with stolen goods (only that one). Nothing while a sheet is open. Nothing here takes touches.

const SIZE := 34.0
## Where an arrow may sit: this far in from each screen edge (left, top, right, bottom), clear
## of the top panel and the buttons under it.
const EDGE_MARGINS := Vector4(50, 560, 50, 160)
const RUST := Color(0.62, 0.24, 0.15)
const THIEF := Color(0.95, 0.72, 0.3)
const ICON_SIZE := 56.0

## The bottom sheet: while it's open the arrows keep out of the way.
var sheet: Control

var _camera: Camera3D
var _marks := []  # [screen position, direction, colour, icon or null]
var _bag: Texture2D
var _time := 0.0


func setup(camera: Camera3D) -> void:
	_camera = camera


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag = load(UiTheme.ICON_DIR + "bag.png")


func _process(delta: float) -> void:
	_time += delta
	_marks.clear()
	var s := Game.engine.state
	if _camera != null and not s.game_over and not (sheet and sheet.visible):
		if s.attack_warned and not s.next_wave.is_empty():
			for side in s.next_wave.sides:
				_mark(side, RUST, null)
		var thief := nearest_thief(s)
		if not thief.is_empty():
			_mark(thief.pos, THIEF, _bag)
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
func _mark(ground: Vector2, color: Color, icon: Texture2D) -> void:
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
	_marks.append([centre + dir * (reach - bob), dir, color, icon])


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
		draw_colored_polygon(shape, mk[2])
		draw_polyline(outline, UiTheme.INK, 5.0, true)
		draw_set_transform(Vector2.ZERO)
		if mk[3]:
			var c: Vector2 = mk[0] - dir * a * 2.6
			draw_circle(c, ICON_SIZE * 0.62, Color(UiTheme.PAPER, 0.95))
			draw_arc(c, ICON_SIZE * 0.62, 0.0, TAU, 32, UiTheme.INK, 4.0, true)
			draw_texture_rect(mk[3], Rect2(c - Vector2.ONE * ICON_SIZE / 2.0, Vector2.ONE * ICON_SIZE), false)
