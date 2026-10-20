class_name Props
extends RefCounted
## Imported models (Poly Haven props, pines modelled in Blender: source_art/blender/trees.blend, and
## generated models made game-ready by the asset pipeline, e.g. the furnace).
## Returns null when a model is missing, so callers keep their greybox shape.

const PATHS := {
	"boulder": "res://assets/models/polyhaven/boulder.glb",
	"crate": "res://assets/models/polyhaven/crate.glb",
	"log": "res://assets/models/polyhaven/log.glb",
	"pine_a": "res://assets/models/blender/pine_a.glb",
	"pine_b": "res://assets/models/blender/pine_b.glb",
	"pine_c": "res://assets/models/blender/pine_c.glb",
	"furnace": "res://assets/models/blender/furnace.glb",
}
## The pines' own height in metres (base of the trunk to the tip), to scale them to a tree's height.
const PINE_HEIGHTS := {"pine_a": 3.45, "pine_b": 3.55, "pine_c": 2.55}

static var _cache := {}
static var _vertex_paint: StandardMaterial3D


static func make(id: String, scale := 1.0, yaw_degrees := 0.0) -> Node3D:
	if not _cache.has(id):
		var path: String = PATHS.get(id, "")
		_cache[id] = load(path) if path != "" and ResourceLoader.exists(path) else null
	var scene: PackedScene = _cache[id]
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	node.scale = Vector3.ONE * scale
	node.rotation_degrees.y = yaw_degrees
	return node


## Gives every mesh under `node` one shared material that paints with its vertex colours (the
## pines carry their bark, needles and snow that way). As a material override, so trees can fade
## and the ink look can paint them.
static func use_vertex_colours(node: Node) -> void:
	if _vertex_paint == null:
		_vertex_paint = StandardMaterial3D.new()
		_vertex_paint.vertex_color_use_as_albedo = true
		_vertex_paint.roughness = 1.0
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _vertex_paint
