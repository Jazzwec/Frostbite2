extends TestCase
## The imported models keep to the asset pipeline's rules (.claude/skills/asset-pipeline):
## metres with the base at y = 0 and centred, within their triangle budget, few opaque
## BaseMaterial3D materials (what InkLook repaints) and textures no bigger than 1024.

const DIRS := ["res://assets/models/blender", "res://assets/models/kit", "res://assets/models/polyhaven"]
## Every model needs a row here: [max triangles, min height m, max height m].
const BUDGETS := {
	"furnace": [10000, 2.5, 4.5],
	"jan": [6000, 1.4, 1.9],  # up to 20 on screen at once
	"meagan": [10000, 1.4, 1.9],
	"wolf": [5000, 0.6, 1.2],
	"pine_a": [1100, 2.0, 4.0],
	"pine_b": [1100, 2.0, 4.0],
	"pine_c": [1100, 2.0, 4.0],
	"boulder": [2000, 0.3, 2.0],
	"crate": [2000, 0.2, 1.5],
	"log": [2000, 0.2, 1.5],
	# The ink_v3 house kit (tools/blender/house_kit.py).
	"house_lumber_yard": [6500, 2.5, 5.6],
	"house_hunting_lodge": [6500, 2.5, 5.6],
	"house_storehouse": [6500, 2.5, 5.0],
	"house_workshop": [6500, 2.5, 5.6],
	"house_barracks": [6500, 2.5, 5.6],
	"house_bunkhouse": [6500, 2.5, 5.6],
	"house_kitchen": [6500, 2.5, 5.6],
	"house_watchtower": [6500, 6.0, 9.0],
	"house_hot_springs": [6500, 2.5, 5.0],
	"prop_rock_a": [1600, 0.3, 1.2],
	"prop_rock_b": [1600, 0.3, 1.2],
	"prop_fence": [1300, 0.8, 1.5],
	"prop_shrub": [1300, 0.4, 1.2],
	"prop_lantern_post": [1300, 1.4, 2.2],
	"prop_woodpile": [1600, 0.6, 1.4],
	"prop_sled": [1300, 0.2, 0.6],
	"prop_bench": [1300, 0.4, 0.9],
	"prop_boat": [1600, 0.4, 1.0],
	"prop_jetty": [1600, 0.4, 1.0],
	"prop_stockpile": [3200, 0.8, 1.8],
	"prop_stove": [3200, 1.2, 2.4],
	"prop_den": [3200, 1.0, 2.2],
	# Chests: a body and a hinged "<name>_lid" (cleanup.py split_lid_at; the filled cut adds ~1k).
	"chest_cache": [2500, 0.3, 1.2],
	"chest_boon": [2500, 0.3, 1.2],
	"chest_gear": [2500, 0.3, 1.2],
}
## Held tools and carried things (rig/tools.gd), in their hand's space with the origin at the hand
## (cleanup.py hold=...), so no ground or centring check: [max triangles, min length m, max length m].
const HELD := {
	"tool_axe": [1600, 0.8, 1.2],
	"tool_pickaxe": [1600, 0.8, 1.2],
	"tool_hammer": [1600, 0.4, 0.7],
	"tool_rod": [1600, 1.2, 1.8],
	"tool_spear": [1600, 1.6, 2.3],
	"tool_fish": [1600, 0.3, 0.6],
}
## Rigged characters posed by ModelRig: they need its bones under Mixamo names (tools/blender/rig_names.py
## renames a Meshy rig's).
const HUMANOIDS := ["jan", "meagan"]
const MAX_MATERIALS := 2
const MAX_TEXTURE := 1024
const GROUND_TOLERANCE := 0.02
const CENTRE_TOLERANCE := 0.1


func _models() -> Array[String]:
	var paths: Array[String] = []
	for dir in DIRS:
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".glb"):
				paths.append(dir + "/" + file)
	return paths


## The node's transform relative to `root`; tests run outside the scene tree.
func _to_root(node: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != root and n != null:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func test_every_model_has_a_budget() -> void:
	for path in _models():
		var name := path.get_file().get_basename()
		check(BUDGETS.has(name) or HELD.has(name), "%s has no row in BUDGETS or HELD" % path)


func test_humanoids_have_the_rig_bones() -> void:
	for name in HUMANOIDS:
		var root := (load("res://assets/models/blender/%s.glb" % name) as PackedScene).instantiate()
		var skeletons := root.find_children("*", "Skeleton3D", true, false)
		check(skeletons.size() == 1, "%s has %d skeletons" % [name, skeletons.size()])
		if skeletons.size() == 1:
			var skeleton := skeletons[0] as Skeleton3D
			for key in ModelRig.BONES:
				var bone: String = "mixamorig_" + ModelRig.BONES[key]
				check(skeleton.find_bone(bone) >= 0, "%s has no bone %s" % [name, bone])
		root.free()


func test_models_keep_the_pipeline_rules() -> void:
	for path in _models():
		var name := path.get_file().get_basename()
		if not BUDGETS.has(name) and not HELD.has(name):
			continue
		var scene := load(path) as PackedScene
		check(scene != null, "%s doesn't load" % path)
		if scene == null:
			continue
		var root := scene.instantiate() as Node3D
		var box := AABB()
		var first := true
		var tris := 0
		var materials := {}
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var b := _to_root(m, root) * m.mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
			for s in m.mesh.get_surface_count():
				var arrays := m.mesh.surface_get_arrays(s)
				var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += (index.size() if not index.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
				materials[m.get_active_material(s)] = true
		root.free()
		if HELD.has(name):
			var held: Array = HELD[name]
			var length := maxf(box.size.x, maxf(box.size.y, box.size.z))
			check(tris > 0 and tris <= held[0], "%s has %d triangles, budget %d" % [name, tris, held[0]])
			check(length >= held[1] and length <= held[2], "%s is %.2f m long, expected %.1f-%.1f" % [name, length, held[1], held[2]])
			check(box.grow(0.05).has_point(Vector3.ZERO), "%s doesn't have its hand (origin) on it" % name)
		else:
			var budget: Array = BUDGETS[name]
			check(tris > 0 and tris <= budget[0], "%s has %d triangles, budget %d" % [name, tris, budget[0]])
			check_near(box.position.y, 0.0, GROUND_TOLERANCE, "%s base height" % name)
			check(box.size.y >= budget[1] and box.size.y <= budget[2],
					"%s is %.2f m tall, expected %.1f-%.1f" % [name, box.size.y, budget[1], budget[2]])
			var centre := box.get_center()
			check(absf(centre.x) <= CENTRE_TOLERANCE and absf(centre.z) <= CENTRE_TOLERANCE,
					"%s isn't centred on its origin (centre %.2f, %.2f)" % [name, centre.x, centre.z])
		check(materials.size() <= MAX_MATERIALS, "%s has %d materials" % [name, materials.size()])
		for mat in materials:
			check(mat is BaseMaterial3D, "%s has a material that isn't a BaseMaterial3D" % name)
			if mat is BaseMaterial3D:
				var base := mat as BaseMaterial3D
				check(base.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "%s has a transparent material" % name)
				var tex := base.albedo_texture
				if tex:
					check(maxi(tex.get_width(), tex.get_height()) <= MAX_TEXTURE,
							"%s texture is %dx%d" % [name, tex.get_width(), tex.get_height()])
