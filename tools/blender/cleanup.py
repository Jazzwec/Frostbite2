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
    # From the vertices themselves: bound_box can lag behind a mesh transform.
    corners = [obj.matrix_world @ v.co for v in obj.data.vertices] if obj.type == "MESH" and obj.data.vertices \
        else [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    lo = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    hi = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    return lo, hi


def _select_only(objs, active):
    for o in bpy.context.view_layer.objects:
        if o is not None:  # a just-removed object can linger here until the view layer updates
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


# The art-direction palette (docs/art-direction.md, the house kit's PAL), in sRGB. palette_snap()
# pulls a texture towards these tones and a darker and a lighter step of each.
PALETTE = ["B2412E", "C9973F", "5E8A87", "35666B", "EEF2F2", "7F93A6", "2C3440", "F2B266",
           "8A5E3C", "5E3F2A", "B48D62", "8E8C88", "6E6C6A", "45474E", "5B6470", "B39A6E"]


def palette_snap(image, strength=0.5, blur=1):
    """One palette for every model (ink_v3): blurs the texture `blur` times (3x3) to melt fine
    speckle into washes, then moves each texel `strength` of the way to its nearest palette tone."""
    import numpy as np
    w, h = image.size
    px = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = px[:, :, :3]
    for _ in range(blur):
        pad = np.pad(rgb, ((1, 1), (1, 1), (0, 0)), mode="edge")
        rgb = sum(pad[dy:dy + h, dx:dx + w] for dy in range(3) for dx in range(3)) / 9.0
    base = np.array([[int(c[i:i + 2], 16) / 255.0 for i in (0, 2, 4)] for c in PALETTE], dtype=np.float32)
    tones = np.concatenate([base * 0.8, base, np.minimum(base * 1.15, 1.0)])
    flat = rgb.reshape(-1, 3)
    out = np.empty_like(flat)
    for start in range(0, len(flat), 65536):
        chunk = flat[start:start + 65536]
        d = ((chunk[:, None, :] - tones[None, :, :]) ** 2).sum(axis=2)
        nearest = tones[d.argmin(axis=1)]
        out[start:start + 65536] = chunk + (nearest - chunk) * strength
    px[:, :, :3] = out.reshape(h, w, 3)
    image.pixels[:] = px.ravel()
    image.update()


def pad_islands(obj, image, iterations=32):
    """Texture padding: grows every UV island's colours out over the unused texture between islands,
    so the ink shader's blurred (mip) reads never bleed the empty background into a model."""
    import numpy as np
    w, h = image.size
    me = obj.data
    me.calc_loop_triangles()
    uv = me.uv_layers.active.data
    mask = np.zeros((h, w), dtype=bool)
    for lt in me.loop_triangles:
        p = np.array([[uv[i].uv.x * w, uv[i].uv.y * h] for i in lt.loops])
        x0, y0 = np.floor(p.min(axis=0)).astype(int)
        x1, y1 = np.ceil(p.max(axis=0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, w - 1), min(y1, h - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = p
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-9:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / d
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / d
        inside = (l1 >= -0.02) & (l2 >= -0.02) & (1.0 - l1 - l2 >= -0.02)
        mask[y0:y1 + 1, x0:x1 + 1] |= inside
    px = np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rgb = px[:, :, :3] * mask[:, :, None]
    filled = mask.astype(np.float32)
    for _ in range(iterations):
        if filled.min() > 0:
            break
        pr = np.pad(rgb, ((1, 1), (1, 1), (0, 0)))
        pf = np.pad(filled, ((1, 1), (1, 1)))
        s = sum(pr[dy:dy + h, dx:dx + w] for dy in range(3) for dx in range(3))
        n = sum(pf[dy:dy + h, dx:dx + w] for dy in range(3) for dx in range(3))
        grow = (filled == 0) & (n > 0)
        rgb[grow] = s[grow] / n[grow][:, None]
        filled[grow] = 1.0
    px[:, :, :3] = rgb
    image.pixels[:] = px.ravel()
    image.update()
    return float(mask.mean())


def _split_lid(obj, at):
    """Cuts a chest at height `at` into itself (the body) and `<name>_lid`, whose origin is its
    back hinge (the top back edge of the body), with both cut faces filled."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, dist=0.0001, plane_co=(0, 0, at), plane_no=(0, 0, 1))
    lid_faces = [f for f in bm.faces if f.calc_center_median().z > at]
    lid_bm = bmesh.new()
    lid_mesh = bpy.data.meshes.new(obj.name + "_lid")
    # Copy the whole mesh to the lid, then each keeps only its own half.
    bm.to_mesh(lid_mesh)
    lid_bm.from_mesh(lid_mesh)
    bmesh.ops.delete(lid_bm, geom=[f for f in lid_bm.faces if f.calc_center_median().z <= at], context="FACES")
    bmesh.ops.delete(bm, geom=lid_faces, context="FACES")
    for part in (bm, lid_bm):
        boundary = [e for e in part.edges if e.is_boundary]
        if boundary:
            bmesh.ops.holes_fill(part, edges=boundary, sides=0)
    hinge_y = max(v.co.y for v in lid_bm.verts) if lid_bm.verts else 0.0
    bmesh.ops.translate(lid_bm, verts=lid_bm.verts, vec=(0, -hinge_y, -at))
    bm.to_mesh(obj.data)
    lid_bm.to_mesh(lid_mesh)
    bm.free()
    lid_bm.free()
    for mat in obj.data.materials:
        lid_mesh.materials.append(mat)
    lid = bpy.data.objects.new(obj.name + "_lid", lid_mesh)
    obj.users_collection[0].objects.link(lid)
    lid.parent = obj
    lid.location = (0, hinge_y, at)
    return lid


def cleanup(name, source, height=None, footprint=None, max_tris=8000, tex_size=1024,
            weld=0.0005, yaw=0.0, export=True, palette=0.0, split_lid_at=None, stretch=(1.0, 1.0, 1.0),
            strip_rig=False):
    """See the module docstring. `height` or `footprint` (the larger of width and depth) in metres.
    `palette` (0 to 1) pulls the texture towards the art-direction palette (palette_snap);
    `split_lid_at` (metres, after scaling) cuts a chest into a body and a hinged lid;
    `stretch` scales width, depth and height before sizing (a building shallower front to back
    and a little taller shows more wall under the 52° game camera)."""
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
        if not strip_rig:
            raise RuntimeError("rigged model: clean it by hand (cleanup.py is for static models), "
                               "or pass strip_rig=True if the rig is unwanted")
        # Meshy sometimes rigs a prop (a shrub came with a hand skeleton): keep the rest-pose mesh.
        # Only the skinned meshes: the importer's bone-display spheres go.
        rigs = [o for o in imported if o.type == "ARMATURE"]
        spheres = [o for o in meshes if o.name.startswith("Icosphere")]
        skinned = [o for o in meshes if o not in spheres]
        for o in skinned:
            for mod in [m for m in o.modifiers if m.type == "ARMATURE"]:
                o.modifiers.remove(mod)
            o.vertex_groups.clear()
            world = o.matrix_world.copy()
            o.parent = None
            o.matrix_world = world
        for o in spheres + rigs:
            bpy.data.objects.remove(o)
        meshes = skinned
        imported = list(skinned)
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
    obj.data.validate(clean_customdata=False)

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
        # On the mesh itself: an object rotation plus transform_apply didn't always take here.
        obj.data.transform(Matrix.Rotation(math.radians(yaw), 4, "Z"))
    if tuple(stretch) != (1.0, 1.0, 1.0):
        obj.data.transform(Matrix.Diagonal((stretch[0], stretch[1], stretch[2], 1.0)))
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
            # Padding first, so neither the snap's blur nor the game's mip reads pull in the background.
            if obj.data.uv_layers:
                pad_islands(obj, image)
            if palette > 0.0:
                palette_snap(image, palette)
            image.pack()
    parts = [obj]
    if split_lid_at is not None:
        parts.append(_split_lid(obj, split_lid_at))

    blend = PROJECT / "source_art" / "blender" / f"{name}.blend"
    glb = PROJECT / "assets" / "models" / "blender" / f"{name}.glb"
    if export:
        _select_only(parts, obj)
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
    bpy.context.view_layer.update()
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
