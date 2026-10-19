class_name Props
extends RefCounted
## Imported models (Poly Haven for now, Tripo/Blender later). Returns null when a model is missing,
## so callers keep their greybox shape.

const PATHS := {
	"boulder": "res://assets/models/polyhaven/boulder.glb",
	"crate": "res://assets/models/polyhaven/crate.glb",
	"log": "res://assets/models/polyhaven/log.glb",
}

static var _cache := {}


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
