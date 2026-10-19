class_name Tools
extends RefCounted
## Greybox hand tools and carried things. A tool is built in its hand's space: the handle runs
## along -Y (carrying on from the arm), and a swing moves the far end towards -Z.

const WOOD := Color(0.5, 0.33, 0.18)
const STEEL := Color(0.8, 0.83, 0.88)
const DARK_STEEL := Color(0.35, 0.37, 0.42)


static func make(id: String) -> Node3D:
	var n := Node3D.new()
	n.name = id
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
		"materials":
			n.add_child(Shapes.box(Vector3(0.3, 0.12, 0.2), DARK_STEEL))
			n.add_child(Shapes.box(Vector3(0.12, 0.2, 0.12), Color(0.55, 0.38, 0.25), Vector3(0.05, 0.12, 0)))
	return n


## The world position of a tool's working end, for effects.
static func tip(tool: Node3D) -> Vector3:
	var marker := tool.get_node_or_null("Tip") as Node3D
	if marker:
		return marker.global_position
	return tool.global_transform * Vector3(0, -0.8, 0)
