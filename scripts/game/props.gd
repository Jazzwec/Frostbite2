class_name Props
extends RefCounted
## Imported models (Poly Haven props, pines modelled in Blender: source_art/blender/trees.blend, and
## generated models made game-ready by the asset pipeline, e.g. the furnace).
## Returns null when a model is missing, so callers keep their greybox shape.

const PATHS := {
	# The pipeline's models; Props.make falls back to the kit's, then Poly Haven's, of the same name.
	"boulder": "res://assets/models/blender/boulder.glb",
	"crate": "res://assets/models/blender/crate.glb",
	"log": "res://assets/models/blender/log.glb",
	"pine_a": "res://assets/models/blender/pine_a.glb",
	"pine_b": "res://assets/models/blender/pine_b.glb",
	"pine_c": "res://assets/models/blender/pine_c.glb",
	"furnace": "res://assets/models/blender/furnace.glb",
	# The ink_v3 house kit (tools/blender/house_kit.py): one model per building, painted in the
	# palette's vertex colours.
	"house_lumber_yard": "res://assets/models/blender/house_lumber_yard.glb",
	"house_hunting_lodge": "res://assets/models/blender/house_hunting_lodge.glb",
	"house_storehouse": "res://assets/models/blender/house_storehouse.glb",
	"house_workshop": "res://assets/models/blender/house_workshop.glb",
	"house_barracks": "res://assets/models/blender/house_barracks.glb",
	"house_bunkhouse": "res://assets/models/blender/house_bunkhouse.glb",
	"house_kitchen": "res://assets/models/blender/house_kitchen.glb",
	"house_watchtower": "res://assets/models/blender/house_watchtower.glb",
	"house_hot_springs": "res://assets/models/blender/house_hot_springs.glb",
	# Its set dressing (SetDressing places them).
	"prop_rock_a": "res://assets/models/blender/prop_rock_a.glb",
	"prop_rock_b": "res://assets/models/blender/prop_rock_b.glb",
	"prop_fence": "res://assets/models/blender/prop_fence.glb",
	"prop_shrub": "res://assets/models/blender/prop_shrub.glb",
	"prop_lantern_post": "res://assets/models/blender/prop_lantern_post.glb",
	"prop_woodpile": "res://assets/models/blender/prop_woodpile.glb",
	"prop_sled": "res://assets/models/blender/prop_sled.glb",
	"prop_bench": "res://assets/models/blender/prop_bench.glb",
	"prop_boat": "res://assets/models/blender/prop_boat.glb",
	"prop_jetty": "res://assets/models/blender/prop_jetty.glb",
	"prop_stockpile": "res://assets/models/blender/prop_stockpile.glb",
	"prop_stove": "res://assets/models/blender/prop_stove.glb",
	"prop_den": "res://assets/models/blender/prop_den.glb",
	# Chests by kind, each with its lid as a "<name>_lid" child (cleanup.py split_lid_at).
	"chest_cache": "res://assets/models/blender/chest_cache.glb",
	"chest_boon": "res://assets/models/blender/chest_boon.glb",
	"chest_gear": "res://assets/models/blender/chest_gear.glb",
	# Held tools and carried things (Tools.make), in their hand's space.
	"tool_axe": "res://assets/models/blender/tool_axe.glb",
	"tool_pickaxe": "res://assets/models/blender/tool_pickaxe.glb",
	"tool_hammer": "res://assets/models/blender/tool_hammer.glb",
	"tool_rod": "res://assets/models/blender/tool_rod.glb",
	"tool_spear": "res://assets/models/blender/tool_spear.glb",
	"tool_fish": "res://assets/models/blender/tool_fish.glb",
}
## The pines' own height in metres (base of the trunk to the tip), to scale them to a tree's height.
const PINE_HEIGHTS := {"pine_a": 3.45, "pine_b": 3.55, "pine_c": 2.55}

static var _cache := {}
static var _vertex_paint: StandardMaterial3D


static func make(id: String, scale := 1.0, yaw_degrees := 0.0) -> Node3D:
	if not _cache.has(id):
		var path: String = PATHS.get(id, "")
		# The pipeline's model (assets/models/blender) when there is one, else the hand-built kit's
		# (assets/models/kit: tools/blender/house_kit.py, trees.blend), else Poly Haven's.
		for fallback in ["/models/kit/", "/models/polyhaven/"]:
			if path != "" and not ResourceLoader.exists(path):
				path = PATHS.get(id, "").replace("/models/blender/", fallback)
		_cache[id] = load(path) if path != "" and ResourceLoader.exists(path) else null
	var scene: PackedScene = _cache[id]
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	# The pipeline's models carry their own painted snow, so the ink look's snow caps skip them.
	if scene.resource_path.contains("/models/blender/"):
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			mi.set_meta("no_snow", true)
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
		# Only meshes that carry vertex colours (the hand-built kit, the pines); a textured model from
		# the pipeline keeps its own material.
		var mesh := (mi as MeshInstance3D).mesh
		if mesh and mesh.get_surface_count() > 0 and mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR:
			(mi as MeshInstance3D).material_override = _vertex_paint
