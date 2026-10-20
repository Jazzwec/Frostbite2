"""Cleans up a generated model (Meshy or Tripo) for Frostbite2, inside Blender.

Run it through the Blender MCP (`execute_blender_code`), which needs Blender open:

    exec(open(r"C:/Claude Code/Frostbite2/tools/blender/cleanup.py", encoding="utf-8").read())
    print(cleanup("furnace", r"C:/Claude Code/Frostbite2/assets/models/meshy/furnace.glb",
                  footprint=3.6, max_tris=8000))

Static models only (buildings, props). Rigged characters are cleaned by hand, because joining
and decimating would break their skin weights.

It makes the scene FB2_<Name>, imports the GLB, joins the meshes, welds, drops loose bits,
recalculates normals, decimates to `max_tris`, scales to `height` or `footprint` metres, puts
the origin at the bottom centre at (0, 0, 0), leaves one opaque base-colour material with its
texture shrunk to `tex_size`, saves source_art/blender/<name>.blend and exports
assets/models/blender/<name>.glb. Returns a report string.

Facing: the game camera looks towards -Z, so a model's front faces +Z in Godot, which is
-Y in Blender and the front of a glTF file as Meshy and Tripo deliver it. `yaw` (degrees,
around Blender's Z) fixes a model that arrives facing elsewhere.
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

PROJECT = Path(r"C:/Claude Code/Frostbite2")


def _tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def _world_bounds(obj):
    corners = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    return lo, hi


def _select_only(objs, active):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active


def _base_colour_image(mat):
    """The image feeding the Principled BSDF's Base Color, if any."""
    if not mat or not mat.use_nodes:
        return None
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if not bsdf:
        return None
    links = bsdf.inputs["Base Color"].links
    node = links[0].from_node if links else None
    while node and node.type != "TEX_IMAGE" and node.inputs:
        # Walk back through colour nodes (mix, hue/sat) to the texture.
        linked = next((i for i in node.inputs if i.links), None)
        node = linked.links[0].from_node if linked else None
    return node.image if node and node.type == "TEX_IMAGE" else None


def _flatten_material(mat, tex_size):
    """Base colour only: no metal, no gloss, no normal or roughness maps, opaque, back faces culled."""
    image = _base_colour_image(mat)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    for name in ("Metallic", "Roughness", "Normal", "Alpha", "Emission Color", "Emission Strength"):
        sock = bsdf.inputs.get(name)
        if sock is None:
            continue
        for link in list(sock.links):
            mat.node_tree.links.remove(link)
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Alpha"].default_value = 1.0
    bsdf.inputs["Emission Strength"].default_value = 0.0
    for node in [n for n in mat.node_tree.nodes if n.type in ("NORMAL_MAP", "SEPARATE_COLOR", "SEPRGB")]:
        mat.node_tree.nodes.remove(node)
    for node in [n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE" and n.image is not image]:
        mat.node_tree.nodes.remove(node)
    try:
        mat.surface_render_method = "DITHERED"  # Blender 4.2+: opaque for the glTF exporter
    except (AttributeError, TypeError):
        pass
    mat.use_backface_culling = True
    if image and max(image.size) > tex_size:
        w, h = image.size
        k = tex_size / max(w, h)
        image.scale(max(1, round(w * k)), max(1, round(h * k)))
    return image


def cleanup(name, source, height=None, footprint=None, max_tris=8000, tex_size=1024,
            weld=0.0005, yaw=0.0, export=True):
    """See the module docstring. `height` or `footprint` (the larger of width and depth) in metres."""
    if (height is None) == (footprint is None):
        raise ValueError("give exactly one of height or footprint")
    scene_name = "FB2_" + "".join(w.capitalize() for w in name.split("_"))
    if scene_name in bpy.data.scenes:
        bpy.data.scenes.remove(bpy.data.scenes[scene_name])
    scene = bpy.data.scenes.new(scene_name)
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    bpy.context.window.scene = scene

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(source))
    imported = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in imported if o.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"no meshes in {source}")
    if any(o.type == "ARMATURE" for o in imported) or any(o.find_armature() for o in meshes):
        raise RuntimeError("rigged model: clean it by hand (cleanup.py is for static models)")
    tris_in = sum(_tris(o) for o in meshes)

    # One object, transforms applied, parents (glTF empties) gone.
    _select_only(meshes, meshes[0])
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    for o in imported:
        if o is not obj and o.name in bpy.data.objects:
            bpy.data.objects.remove(o)
    _select_only([obj], obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Weld, drop loose bits and zero-area faces, then face every normal outwards.
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=weld)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=weld)
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()

    # Decimate to the budget.
    tris = _tris(obj)
    if tris > max_tris:
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = max_tris / tris
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Smooth shading with sharp creases kept, so the ink lines read the silhouette.
    for poly in obj.data.polygons:
        poly.use_smooth = True
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(40))
    except (AttributeError, RuntimeError):
        pass

    # Face +Z in Godot, then scale to size, then origin at the bottom centre at (0, 0, 0).
    if yaw:
        obj.rotation_euler.z = math.radians(yaw)
        bpy.ops.object.transform_apply(rotation=True)
    lo, hi = _world_bounds(obj)
    size = hi - lo
    k = height / size.z if height is not None else footprint / max(size.x, size.y)
    obj.data.transform(Matrix.Scale(k, 4))
    lo, hi = _world_bounds(obj)
    obj.data.transform(Matrix.Translation(Vector(((lo.x + hi.x) / -2, (lo.y + hi.y) / -2, -lo.z))))
    obj.location = (0, 0, 0)

    # Materials: the first one carries the base colour; the game wants one opaque material.
    images = [_flatten_material(slot.material, tex_size) for slot in obj.material_slots if slot.material]
    for image in images:
        if image:
            image.pack()

    blend = PROJECT / "source_art" / "blender" / f"{name}.blend"
    glb = PROJECT / "assets" / "models" / "blender" / f"{name}.glb"
    if export:
        _select_only([obj], obj)
        bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_active_scene=True,
                                  use_active_collection=True, export_yup=True, export_apply=True,
                                  export_tangents=False, export_animations=False,
                                  export_image_format="JPEG", export_jpeg_quality=90)
        # Only this scene and what it uses, not whatever else is open in Blender.
        bpy.data.libraries.write(str(blend), {scene}, fake_user=True, compress=True)

    lo, hi = _world_bounds(obj)
    size = hi - lo
    tex = ", ".join(f"{i.name} {i.size[0]}x{i.size[1]}" for i in images if i) or "none"
    return (f"{scene_name}: {tris_in} -> {_tris(obj)} tris, size {size.x:.2f} x {size.y:.2f} x {size.z:.2f} m "
            f"(w x d x h), materials {len(obj.material_slots)}, textures {tex}"
            + (f"\nexported {glb}\nsaved {blend}" if export else ""))


def cleanup_character(name, source, height, max_tris=9000, tex_size=1024, export=True):
    """A rigged humanoid (Meshy or Tripo): bones renamed to Mixamo's (rig_names.py), the skinned
    meshes decimated to `max_tris` in total with their weights kept, `height` metres tall, feet
    at the origin, one opaque base-colour material, then exported like cleanup(). The armature,
    its rest pose and the skin weights are otherwise left alone."""
    names = {}
    exec(open(PROJECT / "tools" / "blender" / "rig_names.py", encoding="utf-8").read(), names)
    scene_name = "FB2_" + "".join(w.capitalize() for w in name.split("_"))
    if scene_name in bpy.data.scenes:
        bpy.data.scenes.remove(bpy.data.scenes[scene_name])
    scene = bpy.data.scenes.new(scene_name)
    bpy.context.window.scene = scene

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(source))
    imported = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in imported if o.type == "ARMATURE"), None)
    if arm is None:
        raise RuntimeError(f"no armature in {source}: use cleanup() for static models")
    skinned = [o for o in imported if o.type == "MESH" and o.find_armature() is arm]
    # The glTF importer's bone-display spheres and any other loose meshes go.
    for o in imported:
        if o.type == "MESH" and o not in skinned:
            bpy.data.objects.remove(o)
    renamed = names["to_mixamo"](arm)
    tris_in = sum(_tris(o) for o in skinned)

    # Decimate first in each stack (before the Armature modifier), so the rest mesh is what's reduced.
    ratio = min(1.0, max_tris / tris_in)
    for o in skinned:
        if ratio < 1.0:
            _select_only([o], o)
            mod = o.modifiers.new("decimate", "DECIMATE")
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            bpy.ops.object.modifier_move_to_index(modifier=mod.name, index=0)
            bpy.ops.object.modifier_apply(modifier=mod.name)
        for poly in o.data.polygons:
            poly.use_smooth = True

    # Scale the whole rig to height, then stand it on the origin.
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for o in skinned:
        a, b = _world_bounds(o)
        lo = Vector(map(min, lo, a))
        hi = Vector(map(max, hi, b))
    k = height / (hi.z - lo.z)
    arm.scale = arm.scale * k
    arm.location = Vector((arm.location.x - (lo.x + hi.x) / 2 * k, arm.location.y - (lo.y + hi.y) / 2 * k,
                           arm.location.z - lo.z * k))
    _select_only([arm] + skinned, arm)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    images = []
    for o in skinned:
        images += [_flatten_material(s.material, tex_size) for s in o.material_slots if s.material]
    for image in images:
        if image:
            image.pack()

    blend = PROJECT / "source_art" / "blender" / f"{name}.blend"
    glb = PROJECT / "assets" / "models" / "blender" / f"{name}.glb"
    if export:
        _select_only([arm] + skinned, arm)
        bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", use_active_scene=True,
                                  use_active_collection=True, export_yup=True, export_apply=False,
                                  export_skins=True, export_tangents=False, export_animations=False,
                                  export_image_format="JPEG", export_jpeg_quality=90)
        bpy.data.libraries.write(str(blend), {scene}, fake_user=True, compress=True)

    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for o in skinned:
        a, b = _world_bounds(o)
        lo = Vector(map(min, lo, a))
        hi = Vector(map(max, hi, b))
    size = hi - lo
    tex = ", ".join(f"{i.name} {i.size[0]}x{i.size[1]}" for i in images if i) or "none"
    return (f"{scene_name}: {renamed}; {tris_in} -> {sum(_tris(o) for o in skinned)} tris, "
            f"size {size.x:.2f} x {size.y:.2f} x {size.z:.2f} m, bottom {lo.z:.3f}, {len(arm.data.bones)} bones, "
            f"textures {tex}" + (f"\nexported {glb}\nsaved {blend}" if export else ""))
