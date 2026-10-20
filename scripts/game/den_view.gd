class_name DenView
extends Node3D
## A wolf den in an opened tile (agreed 2026-10-20): wolf packs come out of it. A rocky mound
## round a dark mouth; greybox until its model is made.

const ROCK := Color(0.42, 0.4, 0.42)
const MOUTH := Color(0.12, 0.12, 0.16)


func setup(pos: Vector2) -> void:
	position = Vector3(pos.x, 0, pos.y)
	# The house kit's den: a snowy rock mound round a dark mouth (ink_v3).
	var den := Props.make("prop_den")
	if den:
		Props.use_vertex_colours(den)
		add_child(den)
		return
	var rock := Props.make("boulder", 1.6, 20.0)
	if rock:
		rock.position = Vector3(0, -0.3, -0.6)
		add_child(rock)
	else:
		add_child(Shapes.sphere(1.3, ROCK, Vector3(0, 0.2, -0.6)))
	add_child(Shapes.sphere(0.7, ROCK, Vector3(-1.1, 0.1, 0.1)))
	add_child(Shapes.sphere(0.6, ROCK, Vector3(1.0, 0.05, 0.2)))
	add_child(Shapes.cylinder(0.75, 0.04, MOUTH, Vector3(0, 0.03, 0.35)))
