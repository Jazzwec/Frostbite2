class_name Tools
extends RefCounted
## Greybox hand tools and carried things. A tool is built in its hand's space: the handle runs
## along -Y (carrying on from the arm), and a swing moves the far end towards -Z.

const WOOD := Color(0.5, 0.33, 0.18)
const STEEL := Color(0.8, 0.83, 0.88)
const DARK_STEEL := Color(0.35, 0.37, 0.42)
## Load colours, from the palette (docs/art-direction.md).
const LOG_BARK := Color("8a5e3c")
const LOG_END := Color("e6c58a")
const ROPE := Color("5e3f2a")
const WICKER := Color("c9973f")
const CRATE_WOOD := Color("b48d62")


## The ones with a pipeline model (assets/models/blender/tool_<id>.glb, cleanup.py hold=...), each
## built in the same hand space as its greybox below, and which way its working end points.
const MODELS := {"axe": Vector3.DOWN, "pickaxe": Vector3.DOWN, "hammer": Vector3.DOWN, "spear": Vector3.DOWN,
		"rod": Vector3.BACK, "fish": Vector3.ZERO}


static func make(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
	var model := Props.make("tool_" + id) if MODELS.has(id) else null
	if model:
		n.add_child(model)
		if MODELS[id] != Vector3.ZERO:
			var tip := Marker3D.new()
			tip.name = "Tip"
			tip.position = _far_end(model, MODELS[id])
			n.add_child(tip)
		return n
	match id:
		"axe":
			# Chunky, so it reads at phone size.
			n.add_child(Shapes.cylinder(0.05, 0.95, WOOD, Vector3(0, -0.38, 0)))
			n.add_child(Shapes.box(Vector3(0.08, 0.3, 0.36), STEEL, Vector3(0, -0.76, -0.12)))
			n.add_child(Shapes.box(Vector3(0.1, 0.12, 0.1), DARK_STEEL, Vector3(0, -0.8, 0.08)))
		"pickaxe":
			n.add_child(Shapes.cylinder(0.05, 0.95, WOOD, Vector3(0, -0.38, 0)))
			var head := Shapes.cylinder(0.06, 0.8, DARK_STEEL, Vector3(0, -0.82, 0), 0.02)
			head.rotation_degrees.x = 90.0
			n.add_child(head)
		"hammer":
			n.add_child(Shapes.cylinder(0.04, 0.5, WOOD, Vector3(0, -0.18, 0)))
			n.add_child(Shapes.box(Vector3(0.16, 0.16, 0.3), DARK_STEEL, Vector3(0, -0.42, -0.03)))
		"rod":
			# Held in the fist and pointing forward along +Z; the line is drawn by the rig.
			var rod := Shapes.cylinder(0.025, 1.5, WOOD, Vector3(0, -0.05, 0.7), 0.012)
			rod.rotation_degrees.x = 90.0
			n.add_child(rod)
			n.add_child(Shapes.cylinder(0.06, 0.08, DARK_STEEL, Vector3(0.06, -0.05, 0.12)))
			var tip := Marker3D.new()
			tip.name = "Tip"
			tip.position = Vector3(0, -0.05, 1.45)
			n.add_child(tip)
		"spear":
			# Held mid-shaft; the point is at the -Y end.
			n.add_child(Shapes.cylinder(0.035, 1.9, WOOD, Vector3(0, -0.35, 0)))
			n.add_child(Shapes.cone(0.07, 0.25, STEEL, Vector3(0, -1.4, 0)))
			n.get_child(-1).rotation_degrees.x = 180.0
		"log":
			var log := Shapes.cylinder(0.11, 0.55, WOOD, Vector3(0, -0.08, 0))
			log.rotation_degrees.z = 90.0
			n.add_child(log)
		"crate":
			n.add_child(Shapes.box(Vector3(0.45, 0.35, 0.35), Color(0.62, 0.45, 0.25)))
		"fish":
			n.add_child(Shapes.capsule(0.07, 0.36, Color(0.55, 0.7, 0.8)))
			n.get_child(-1).rotation_degrees.z = 90.0
			n.add_child(Shapes.cone(0.08, 0.12, Color(0.45, 0.6, 0.72), Vector3(-0.22, 0, 0)))
			n.get_child(-1).rotation_degrees.z = -90.0
		# Meagan's walking stick, for her melee sweep (agreed 2026-10-20).
		"stick":
			n.add_child(Shapes.cylinder(0.035, 1.1, Color(0.42, 0.27, 0.15), Vector3(0, -0.45, 0), 0.03))
			n.add_child(Shapes.sphere(0.06, Color(0.36, 0.22, 0.12), Vector3(0, 0.08, 0)))
		# A raider's thrown ice shard.
		# A raider's ice shard in flight: pale ice in a darker sleeve, so it reads against snow
		# (fight_v2 review 1: 10-14 px long on the phone, dark-edged).
		# Pointing along -Z (Fx.throw aims it down its flight): a dark blue-grey sleeve, pale ice
		# inside, and a tapered terracotta trail behind (fight_v2 review 5: a hostile silhouette,
		# about 11 px plus a 20 px trail).
		"shard":
			var edge := Shapes.cone(0.12, 0.3, Color(0.22, 0.3, 0.42))
			edge.rotation_degrees.x = -90.0
			n.add_child(edge)
			var ice := Shapes.cone(0.085, 0.34, Color(0.82, 0.93, 1.0), Vector3(0, 0, -0.02))
			ice.rotation_degrees.x = -90.0
			n.add_child(ice)
			var trail := Shapes.cone(0.09, 0.5, Color(0.66, 0.3, 0.2, 0.75), Vector3(0, 0, 0.38))
			trail.rotation_degrees.x = 90.0
			n.add_child(trail)
		# A snowball in her mitten, for her throw.
		# Hers: cream (review 5: cream and blue, apart from the raiders' terracotta).
		"snowball":
			n.add_child(Shapes.sphere(0.16, Color(1.0, 0.96, 0.86), Vector3(0, -0.1, 0)))
		# A Jan's load on the way to a stockpile (AFK V4, 2026-10-20): big, distinct shapes held
		# clear of his chest, about a third of his height, so a hauler reads at a glance.
		"bundle":
			for p in [Vector3(-0.1, 0.0, 0), Vector3(0.1, 0.0, 0), Vector3(0.0, 0.17, 0)]:
				var piece := Shapes.cylinder(0.1, 0.62, LOG_BARK, p)
				piece.rotation_degrees.z = 90.0
				n.add_child(piece)
				var end := Shapes.cylinder(0.085, 0.02, LOG_END, p + Vector3(0.31, 0, 0))
				end.rotation_degrees.z = 90.0
				n.add_child(end)
			for x in [-0.17, 0.17]:
				var rope := Shapes.cylinder(0.2, 0.05, ROPE, Vector3(x, 0.06, 0))
				rope.rotation_degrees.z = 90.0
				n.add_child(rope)
		"basket":
			n.add_child(Shapes.cylinder(0.19, 0.26, WICKER, Vector3(0, 0, 0), 0.24))
			n.add_child(Shapes.cylinder(0.25, 0.04, ROPE, Vector3(0, 0.13, 0)))
			for k in 2:
				var fish := make("fish")
				fish.scale = Vector3.ONE * 0.8
				fish.position = Vector3(-0.06 + k * 0.12, 0.18 + k * 0.03, 0.0)
				fish.rotation_degrees = Vector3(0, 20 - k * 40, 35 - k * 70)
				n.add_child(fish)
		"load_crate":
			n.add_child(Shapes.box(Vector3(0.5, 0.36, 0.38), CRATE_WOOD))
			n.add_child(Shapes.box(Vector3(0.52, 0.07, 0.4), DARK_STEEL, Vector3(0, 0.1, 0)))
			n.add_child(Shapes.box(Vector3(0.52, 0.07, 0.4), DARK_STEEL, Vector3(0, -0.1, 0)))
		"materials":
			n.add_child(Shapes.box(Vector3(0.3, 0.12, 0.2), DARK_STEEL))
			n.add_child(Shapes.box(Vector3(0.12, 0.2, 0.12), Color(0.55, 0.38, 0.25), Vector3(0.05, 0.12, 0)))
	# Held and carried things never wear the ink look's snow caps (a basket's rim went white).
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		mi.set_meta("no_snow", true)
	return n


## The world position of a tool's working end, for effects.
static func tip(tool: Node3D) -> Vector3:
	var marker := tool.get_node_or_null("Tip") as Node3D
	if marker:
		return marker.global_position
	return tool.global_transform * Vector3(0, -0.8, 0)


## The middle of a model's end furthest along `dir` (its head or tip), in the model's parent's space.
static func _far_end(model: Node3D, dir: Vector3) -> Vector3:
	var box := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var t := model.transform
		var n: Node = m
		var local := Transform3D.IDENTITY
		while n != model:
			local = (n as Node3D).transform * local
			n = n.get_parent()
		var b := t * local * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var c := box.get_center()
	var half := box.size / 2.0
	return c + dir * Vector3(half.x, half.y, half.z).dot(dir.abs())
