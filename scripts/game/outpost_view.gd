class_name OutpostView
extends Node3D
## An enemy outpost in an opened tile (agreed 2026-10-20): a lair or camp whose defenders sleep
## until Meagan comes near. Greybox until its models are made: a fox den's snowy burrow, a wolf
## hollow's ring of stones, a raider camp's stakes and tent, a bear's cave. A rust pennant flies
## over it until it's cleared, then it drops and the place goes quiet. While its defenders sleep,
## one "z z" floats over the camp; woken, a "!" for the moment they take to get up (fight_v2
## review 1). The camp's stakes stand only behind it, so none hide the fight from the camera.

const ROCK := Color(0.45, 0.44, 0.47)
const DARK := Color(0.12, 0.12, 0.16)
const WOOD := Color(0.45, 0.32, 0.2)
const PENNANT := Color(0.66, 0.3, 0.2)

var index := -1
var _flag: Node3D
var _cleared := false
var _sleep: Label3D
var _was_awake := false


func setup(i: int, post: Dictionary) -> void:
	index = i
	position = Vector3(post.pos.x, 0, post.pos.y)
	match post.kind:
		"fox_den":
			add_child(Shapes.sphere(0.9, Color(0.93, 0.95, 0.98), Vector3(0, -0.35, -0.3)))
			add_child(Shapes.cylinder(0.42, 0.04, DARK, Vector3(0, 0.03, 0.45)))
			add_child(Shapes.sphere(0.35, ROCK, Vector3(0.9, 0.05, 0.1)))
		"wolf_hollow":
			for k in 7:
				var a := TAU * k / 7.0
				var rock := Shapes.sphere(0.32 + 0.1 * (k % 3), ROCK, Vector3(cos(a) * 1.9, 0.1, sin(a) * 1.9))
				add_child(rock)
			add_child(Shapes.cylinder(1.4, 0.03, Color(0.78, 0.8, 0.85), Vector3(0, 0.02, 0)))
		"raider_camp":
			# Only along the back (away from the camera, which looks north).
			for k in 9:
				var a := PI + 0.25 + (PI - 0.5) * k / 8.0
				var stake := Shapes.cylinder(0.08, 1.1 + 0.15 * (k % 2), WOOD, Vector3(cos(a) * 2.2, 0.55, sin(a) * 2.2))
				add_child(stake)
			add_child(Shapes.cone(0.95, 1.4, Color(0.42, 0.36, 0.3), Vector3(-0.5, 0.7, -0.5)))
			add_child(Shapes.cylinder(0.28, 0.12, Color(0.3, 0.22, 0.16), Vector3(0.7, 0.06, 0.5)))
			add_child(Shapes.sphere(0.16, Color(1.0, 0.55, 0.2), Vector3(0.7, 0.2, 0.5), 2.0))
		"bear_cave":
			var den := Props.make("prop_den")
			if den:
				Props.use_vertex_colours(den)
				den.scale = Vector3.ONE * 1.4
				add_child(den)
			else:
				add_child(Shapes.sphere(1.6, ROCK, Vector3(0, 0.1, -0.7)))
				add_child(Shapes.cylinder(0.9, 0.04, DARK, Vector3(0, 0.03, 0.5)))
	_flag = Node3D.new()
	_flag.position = Vector3(1.5, 0, -1.2)
	add_child(_flag)
	_flag.add_child(Shapes.cylinder(0.04, 2.2, WOOD, Vector3(0, 1.1, 0)))
	_flag.add_child(Shapes.box(Vector3(0.6, 0.38, 0.03), PENNANT, Vector3(0.3, 1.95, 0)))
	_sleep = Shapes.label("z z", Vector3(0, 2.6, 0), 64, Color(0.86, 0.9, 1.0))
	add_child(_sleep)
	refresh(post)


func refresh(post: Dictionary) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_sleep.visible = not post.cleared and not post.awake
	_sleep.position.y = 2.6 + 0.12 * sin(now * 2.0)
	if post.awake and not _was_awake and not post.cleared:
		_wake_mark()
	_was_awake = post.awake
	if post.cleared and not _cleared:
		_cleared = true
		# The pennant comes down.
		var t := create_tween()
		t.tween_property(_flag, "rotation:z", -1.5, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		t.tween_property(_flag, "scale", Vector3.ONE * 0.01, 0.3)
		t.tween_callback(_flag.hide)
	elif not post.cleared and _flag:
		_flag.rotation.y = 0.15 * sin(Time.get_ticks_msec() / 400.0 + index)


## Woken: a "!" pops over the camp while they get up.
func _wake_mark() -> void:
	var mark := Shapes.label("!", Vector3(0, 2.4, 0), 96, Color(0.95, 0.72, 0.3))
	add_child(mark)
	mark.scale = Vector3.ONE * 0.4
	var t := create_tween()
	t.tween_property(mark, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(Balance.OUTPOST_WAKE - 0.18)
	t.tween_property(mark, "modulate:a", 0.0, 0.25)
	t.tween_callback(mark.queue_free)
