"""The ink_v3 house kit: Frostbite2's buildings built from a few chunky parts, painted with the
art-direction palette (docs/art-direction.md) in vertex colours, so every building shares one
palette and needs no texture. Roofs carry thick, soft snow slabs; fronts get timber battens, a
framed door, glowing windows, a lantern and a sign with the town's motifs.

Run inside Blender through the MCP:
    exec(open(r"C:/Claude Code/Frostbite2/tools/blender/house_kit.py").read())
    build_all(export=True)
Each house is built in the FB2_HouseKit scene, centred on its footprint with its base at 0, and
exported to assets/models/blender/house_<building>.glb; the scene is saved as
source_art/blender/house_kit.blend. Blender is Z up and the front (door, pad side) faces -Y,
which is +Z (towards the camera) in Godot.
"""
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

PROJECT = r"C:/Claude Code/Frostbite2"
SCENE = "FB2_HouseKit"


def _linear(hex_colour):
    c = [int(hex_colour[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c) + (1.0,)


# The art-direction palette plus a darker and lighter step of each, in linear colour.
PAL = {k: _linear(v) for k, v in {
    "falu": "B2412E", "falu_dark": "8A3122",
    "ochre": "C9973F", "ochre_dark": "9E7330",
    "teal": "5E8A87", "teal_dark": "35666B",
    "snow": "EEF2F2", "snow_shade": "D3DDE5",
    "ink": "2C3440", "fire": "F2B266", "fire_light": "F8DCA4",
    "wood": "8A5E3C", "wood_dark": "5E3F2A", "wood_light": "B48D62",
    "stone": "8E8C88", "stone_dark": "6E6C6A",
    "iron": "45474E", "slate": "5B6470", "rope": "B39A6E",
}.items()}


class House:
    """Collects parts (each its own bmesh, painted one colour) and joins them into one mesh."""

    def __init__(self, name):
        self.name = name
        self.parts = []

    def _add(self, bm, colour, bevel=0.0, segments=1):
        if bevel > 0.0:
            bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=segments,
                            affect='EDGES', profile=0.5, clamp_overlap=True)
        me = bpy.data.meshes.new(self.name + "_part")
        bm.to_mesh(me)
        bm.free()
        attr = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
        for d in attr.data:
            d.color = PAL[colour]
        self.parts.append(me)

    def box(self, c, s, colour, rz=0.0, rx=0.0, ry=0.0, bevel=0.0, segments=1):
        bm = bmesh.new()
        m = (Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z') @ Matrix.Rotation(ry, 4, 'Y')
             @ Matrix.Rotation(rx, 4, 'X') @ Matrix.Diagonal((s[0], s[1], s[2], 1.0)))
        bmesh.ops.create_cube(bm, size=1.0, matrix=m)
        self._add(bm, colour, bevel, segments)

    def cyl(self, c, r, depth, colour, axis='Z', segments=8, r2=None, rz=0.0, rx=0.0, bevel=0.0):
        bm = bmesh.new()
        turn = {'Z': Matrix.Identity(4), 'X': Matrix.Rotation(math.pi / 2, 4, 'Y'),
                'Y': Matrix.Rotation(math.pi / 2, 4, 'X')}[axis]
        m = Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z') @ Matrix.Rotation(rx, 4, 'X') @ turn
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments, radius1=r,
                              radius2=r if r2 is None else r2, depth=depth, matrix=m)
        self._add(bm, colour, bevel, 2 if bevel > 0.0 else 1)

    def gable_wall(self, c, w, d, h, colour, front=True):
        """The triangular gable ends between the walls' top and the ridge. With `front` the ridge
        runs front to back, so a gable faces the camera (the Nordic look of the mock-up)."""
        bm = bmesh.new()
        x, y = w / 2.0, d / 2.0
        o = Vector(c)
        pts = ([(-x, -y, 0), (-x, y, 0), (x, y, 0), (x, -y, 0), (0, -y, h), (0, y, h)] if front else
               [(-x, -y, 0), (x, -y, 0), (x, y, 0), (-x, y, 0), (-x, 0, h), (x, 0, h)])
        v = [bm.verts.new(o + Vector(p)) for p in pts]
        for f in [(0, 3, 2, 1), (0, 1, 5, 4), (2, 3, 4, 5), (3, 0, 4), (1, 2, 5)]:
            bm.faces.new([v[i] for i in f])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        self._add(bm, colour)

    def roof(self, top, w, d, h, colour, snow=True, overhang=0.25, front=True):
        """A gable roof of two wood slabs over walls `w` x `d` whose top is at `top`, ridge `h`
        higher, under thick soft snow slabs and a snow roll along the ridge. With `front` the
        ridge runs front to back (the slopes face left and right)."""
        # Built with the ridge along X, then turned a quarter round Z when it runs front to back.
        span, along = (w, d) if front else (d, w)
        turn = Matrix.Rotation(math.pi / 2.0, 4, 'Z') if front else Matrix.Identity(4)
        rz = math.pi / 2.0 if front else 0.0
        half = span / 2.0 + overhang
        angle = math.atan2(h, span / 2.0)
        length = half / math.cos(angle)
        t = 0.16
        width = along + overhang * 2.0
        for side in (-1, 1):
            n = Vector((0.0, side * math.sin(angle), math.cos(angle)))
            down = Vector((0.0, side * math.cos(angle), -math.sin(angle)))  # down the slope
            mid = Vector((0.0, side * half / 2.0, top + h - (half / 2.0) * math.tan(angle)))
            # The roof boards, a little past the ridge so the two sides meet; their dark edge is
            # the fascia that shows under the snow at the eaves.
            self.box(turn @ (mid + n * (t / 2.0) - down * 0.04), (width, length + 0.08, t), colour, rz=rz, rx=-side * angle)
            if not snow:
                continue
            # The shaded side is a pale blue-grey, the lit side ivory white (ink_v3 review).
            tone = "snow_shade" if (side < 0) == front else "snow"
            st = 0.34
            # Stops short of the eave so the fascia shows, and runs past the ridge (no seam roll).
            self.box(turn @ (mid + n * (t + st / 2.0 - 0.03) - down * 0.1), (width + 0.06, length + 0.02, st), tone,
                     rz=rz, rx=-side * angle, bevel=0.13, segments=2)
            # A chunky lip of a few broad bulges along the eave, hanging just over the fascia.
            eave = mid + down * (length / 2.0 - 0.12) + n * (t + st * 0.45)
            count = 4
            for i in range(count):
                x = -width / 2.0 + width * (i + 0.5) / count
                wobble = math.sin(i * 2.3 + side) * 0.05
                self.blob(turn @ (eave + Vector((x, 0.0, wobble))), (width / count * 1.2, 0.42, 0.3 + wobble),
                          tone, rz=rz, rx=-side * angle)
        if snow:
            # A soft cap over the ridge where the two snow slabs meet, so there's no dark seam.
            ridge = Vector((0.0, 0.0, top + h + (t + 0.34) / math.cos(angle) - 0.2))
            self.box(turn @ ridge, (width + 0.04, 0.42, 0.42), "snow", rz=rz, rx=math.pi / 4.0, bevel=0.12, segments=2)

    def blob(self, c, s, colour, rz=0.0, rx=0.0):
        """A soft lump (a squashed low-poly sphere): snow lips, drifts."""
        bm = bmesh.new()
        m = (Matrix.Translation(Vector(c)) @ Matrix.Rotation(rz, 4, 'Z') @ Matrix.Rotation(rx, 4, 'X')
             @ Matrix.Diagonal((s[0] / 2.0, s[1] / 2.0, s[2] / 2.0, 1.0)))
        bmesh.ops.create_uvsphere(bm, u_segments=8, v_segments=5, radius=1.0, matrix=m)
        self._add(bm, colour)

    # ---------- Composite pieces ----------

    def body(self, w, d, wall_h, wall, dark, battens=True):
        """Stone base, timber walls, corner posts and vertical battens on the front."""
        self.box((0, 0, 0.17), (w + 0.24, d + 0.24, 0.34), "stone", bevel=0.06)
        self.box((0, 0, 0.3 + wall_h / 2.0), (w, d, wall_h), wall)
        for x in (-w / 2.0, w / 2.0):
            for y in (-d / 2.0, d / 2.0):
                self.box((x, y, 0.3 + wall_h / 2.0), (0.18, 0.18, wall_h), "wood_dark")
        if battens:
            n = max(2, int(w / 0.55))
            for i in range(1, n):
                x = -w / 2.0 + w * i / n
                self.box((x, -d / 2.0 - 0.02, 0.3 + wall_h / 2.0), (0.06, 0.04, wall_h - 0.1), dark)
        # A wood band where the wall meets the roof.
        self.box((0, -d / 2.0 - 0.03, 0.3 + wall_h - 0.06), (w + 0.1, 0.06, 0.12), "wood_dark")

    def door(self, x, d, colour, wide=False):
        w = 1.2 if wide else 0.78
        y = -d / 2.0
        self.box((x, y - 0.03, 0.3 + 0.7), (w, 0.06, 1.4), colour)
        for dx in (-w / 2.0 - 0.06, w / 2.0 + 0.06):
            self.box((x + dx, y - 0.05, 0.3 + 0.75), (0.12, 0.08, 1.5), "wood_light")
        self.box((x, y - 0.05, 0.3 + 1.5), (w + 0.24, 0.08, 0.12), "wood_light")
        self.box((x + w * 0.3, y - 0.08, 0.3 + 0.7), (0.07, 0.04, 0.07), "ink")  # the handle
        self.box((x, y - 0.32, 0.12), (w + 0.4, 0.5, 0.18), "stone_dark", bevel=0.04)  # the step

    def window(self, x, z, d):
        """A glowing window on the front, with snow on its sill."""
        # Bigger and warmer (ink_v3 review): a deep frame, an amber pane with a cream corner, a
        # cross of glazing bars.
        y = -d / 2.0
        self.box((x, y - 0.03, z), (0.84, 0.06, 0.76), "wood_dark")
        self.box((x, y - 0.05, z), (0.64, 0.06, 0.56), "fire")
        self.box((x - 0.17, y - 0.06, z + 0.15), (0.2, 0.05, 0.16), "fire_light")
        self.box((x, y - 0.07, z), (0.05, 0.04, 0.58), "wood_dark")
        self.box((x, y - 0.07, z), (0.66, 0.04, 0.05), "wood_dark")
        self.box((x, y - 0.1, z - 0.41), (0.92, 0.16, 0.07), "snow", bevel=0.025)  # snow on the sill

    def lantern(self, x, z, d):
        y = -d / 2.0 - 0.12
        self.box((x, y + 0.06, z + 0.22), (0.05, 0.16, 0.05), "iron")
        self.box((x, y - 0.04, z), (0.16, 0.16, 0.24), "fire")
        self.box((x, y - 0.04, z + 0.14), (0.22, 0.22, 0.06), "iron")

    def sign(self, x, z, d, motif):
        """A hanging board above the door with the building's motif in ink."""
        y = -d / 2.0 - 0.14
        self.box((x, y + 0.08, z + 0.34), (0.06, 0.2, 0.06), "wood_dark")
        self.box((x, y, z), (0.82, 0.06, 0.56), "wood_light", bevel=0.02)
        f = y - 0.045
        if motif == "mittens":
            for dx in (-0.15, 0.13):
                self.box((x + dx, f, z - 0.03), (0.15, 0.03, 0.22), "ink", bevel=0.03)
                self.box((x + dx + (0.1 if dx < 0 else -0.1), f, z + 0.0), (0.07, 0.03, 0.1), "ink", rz=0.0, ry=0.5 if dx < 0 else -0.5)
                self.box((x + dx, f, z - 0.17), (0.17, 0.03, 0.05), "ink")
        elif motif == "sun":
            tilt = 0.25
            self.cyl((x, f, z), 0.1, 0.03, "ink", axis='Y', segments=10)
            for i in range(8):
                a = tilt + i * math.pi / 4.0
                self.box((x + math.cos(a) * 0.17, f, z + math.sin(a) * 0.17), (0.09, 0.03, 0.03), "ink", ry=-a)
        elif motif == "furnace":
            self.cyl((x, f, z + 0.02), 0.15, 0.03, "ink", axis='Y', segments=12)
            self.box((x, f, z - 0.1), (0.3, 0.03, 0.12), "ink")
            self.cyl((x, f - 0.01, z - 0.06), 0.06, 0.03, "fire", axis='Y', segments=8)
        elif motif == "fish":
            self.box((x - 0.04, f, z), (0.22, 0.03, 0.22), "ink", ry=math.pi / 4.0)
            self.box((x + 0.17, f, z), (0.1, 0.03, 0.1), "ink", ry=math.pi / 4.0)
        elif motif == "hammer":
            self.box((x, f, z - 0.04), (0.05, 0.03, 0.3), "ink", ry=0.5)
            self.box((x - 0.06, f, z + 0.1), (0.22, 0.03, 0.09), "ink", ry=0.5)
        elif motif == "shield":
            self.cyl((x, f, z), 0.17, 0.03, "ink", axis='Y', segments=10)
            self.box((x, f - 0.01, z), (0.04, 0.03, 0.26), "wood_light")
            self.box((x, f - 0.01, z), (0.26, 0.03, 0.04), "wood_light")
        elif motif == "waves":
            for i, dz in enumerate((-0.12, 0.0, 0.12)):
                self.box((x + (0.03 if i % 2 else -0.03), f, z + dz), (0.4, 0.03, 0.05), "ink", ry=0.12 * (1 if i % 2 else -1))

    def chimney(self, x, y, z0, h):
        self.box((x, y, z0 + h / 2.0), (0.5, 0.5, h), "stone", bevel=0.04)
        self.box((x, y, z0 + h + 0.05), (0.62, 0.62, 0.12), "stone_dark")
        self.box((x, y, z0 + h + 0.17), (0.66, 0.66, 0.16), "snow", bevel=0.06, segments=2)

    def barrel(self, x, y):
        self.cyl((x, y, 0.38), 0.3, 0.76, "wood", segments=10, bevel=0.03)
        for z in (0.16, 0.6):
            self.cyl((x, y, z), 0.315, 0.06, "iron", segments=10)
        self.cyl((x, y, 0.8), 0.3, 0.1, "snow", segments=10, bevel=0.04)

    def crate(self, x, y, z=0.0, s=0.6, rz=0.0):
        self.box((x, y, z + s / 2.0), (s, s, s), "wood_light", rz=rz, bevel=0.03)
        self.box((x, y, z + s + 0.06), (s * 0.95, s * 0.95, 0.12), "snow", rz=rz, bevel=0.05, segments=2)

    def logs(self, x, y, z, count, length=1.2, r=0.15):
        for i in range(count):
            self.cyl((x + (i - (count - 1) / 2.0) * r * 2.05, y, z + r), r, length, "wood", axis='Y', segments=8)
            # The cut end, pale, facing the camera.
            self.cyl((x + (i - (count - 1) / 2.0) * r * 2.05, y - length / 2.0 - 0.005, z + r), r * 0.8, 0.02, "wood_light", axis='Y', segments=8)

    def finish(self, collection):
        """Joins the parts, centres them on the footprint (base at 0) and returns the object."""
        bm = bmesh.new()
        for me in self.parts:
            bm.from_mesh(me)
            bpy.data.meshes.remove(me)
        me = bpy.data.meshes.new(self.name)
        bm.to_mesh(me)
        bm.free()
        lo = Vector((min(v.co.x for v in me.vertices), min(v.co.y for v in me.vertices), min(v.co.z for v in me.vertices)))
        hi = Vector((max(v.co.x for v in me.vertices), max(v.co.y for v in me.vertices), max(v.co.z for v in me.vertices)))
        shift = Vector((-(lo.x + hi.x) / 2.0, -(lo.y + hi.y) / 2.0, -lo.z))
        me.transform(Matrix.Translation(shift))
        # Active and the render default: glTF's COLOR_0 is the default one.
        me.color_attributes.active_color = me.color_attributes["Col"]
        me.color_attributes.default_color_name = "Col"
        mat = bpy.data.materials.get("HousePaint") or bpy.data.materials.new("HousePaint")
        me.materials.append(mat)
        ob = bpy.data.objects.new(self.name, me)
        collection.objects.link(ob)
        print("%s: %d triangles, %.2f m tall, footprint %.2f x %.2f, shifted %.2f, %.2f" % (
            self.name, sum(len(p.vertices) - 2 for p in me.polygons), hi.z - lo.z, hi.x - lo.x, hi.y - lo.y, shift.x, shift.y))
        return ob


# ---------- The buildings ----------

def _house(name, w, d, wall_h, roof_h, wall, dark, roof, door_colour, motif, windows=(), wide=False,
           door_x=0.0, front=True):
    h = House(name)
    h.body(w, d, wall_h, wall, dark)
    top = 0.3 + wall_h
    h.gable_wall((0, 0, top), w, d, roof_h, wall, front)
    h.roof(top, w, d, roof_h, roof, front=front)
    h.door(door_x, d, door_colour, wide)
    for x in windows:
        h.window(x, 0.3 + wall_h * 0.62, d)
    # The sign hangs in the gable when it faces front, else just under the eaves.
    h.sign(door_x, top + (0.35 if front else -0.38), d, motif)
    h.lantern(door_x + (0.75 if not wide else 0.95), 0.3 + 1.25, d)
    return h


def lumber_yard():
    """An open woodshed stacked with logs, under a snowy roof."""
    h = House("house_lumber_yard")
    w, d, wall_h = 3.2, 2.4, 1.9
    h.box((0, 0, 0.08), (w + 0.2, d + 0.2, 0.16), "stone_dark", bevel=0.04)
    h.box((0, d / 2.0 - 0.08, 0.16 + wall_h / 2.0), (w, 0.16, wall_h), "wood")
    for x in (-w / 2.0 + 0.1, w / 2.0 - 0.1):
        h.box((x, 0, 0.16 + wall_h / 2.0), (0.16, d, wall_h), "wood_dark")
        h.box((x, -d / 2.0 + 0.1, 0.16 + wall_h / 2.0), (0.2, 0.2, wall_h), "wood_dark")
    for row in range(4):
        h.logs(0, 0.0, 0.16 + row * 0.3, 8 - (row % 2), length=d - 0.4, r=0.15)
    top = 0.16 + wall_h
    h.gable_wall((0, 0, top), w, d, 0.8, "wood")
    h.roof(top, w, d, 0.8, "wood_dark")
    return h


def hunting_lodge():
    h = _house("house_hunting_lodge", 3.0, 2.6, 2.4, 1.2, "teal", "teal_dark", "slate", "ochre_dark", "fish", windows=(-0.95, 0.95))
    h.barrel(1.95, -0.6)
    h.barrel(1.95, 0.2)
    return h


def storehouse():
    h = _house("house_storehouse", 3.7, 2.6, 2.4, 1.3, "ochre", "ochre_dark", "falu_dark", "falu", "sun", windows=(), wide=True)
    h.crate(-2.3, -0.5, s=0.6, rz=0.2)
    h.crate(-2.3, 0.3, s=0.55, rz=-0.1)
    h.crate(-2.25, -0.1, z=0.66, s=0.5, rz=0.4)
    return h


def workshop():
    h = _house("house_workshop", 3.0, 2.6, 2.4, 1.2, "wood", "wood_dark", "slate", "teal_dark", "hammer", windows=(-1.0,), door_x=0.45)
    h.chimney(-0.85, 0.4, 2.0, 2.5)
    h.crate(2.0, 0.4, s=0.55, rz=0.3)
    return h


def barracks():
    h = _house("house_barracks", 2.8, 2.6, 2.8, 1.35, "falu", "falu_dark", "slate", "teal_dark", "shield", windows=(-0.75,), door_x=0.45)
    # A spear rack against the side wall.
    h.box((1.75, 0.0, 0.5), (0.12, 1.4, 0.1), "wood_dark")
    for i in range(4):
        y = -0.5 + i * 0.33
        h.cyl((1.8, y, 0.95), 0.03, 1.9, "wood", segments=6, rx=0.12)
        h.cyl((1.8, y - 0.11, 1.9), 0.07, 0.18, "iron", segments=6, r2=0.0, rx=0.12)
    return h


def bunkhouse():
    return _house("house_bunkhouse", 3.3, 2.6, 2.4, 1.2, "ochre", "ochre_dark", "falu_dark", "teal_dark", "mittens", windows=(-1.15, 1.15))


def kitchen():
    h = _house("house_kitchen", 3.0, 2.6, 2.4, 1.2, "falu", "falu_dark", "slate", "ochre_dark", "furnace", windows=(-0.95,), door_x=0.35)
    h.chimney(-0.85, 0.5, 2.0, 2.6)
    # The big cooking pot over a little fire by the door.
    h.cyl((1.75, -1.9, 0.12), 0.38, 0.24, "fire", segments=8, r2=0.1)
    h.cyl((1.75, -1.9, 0.62), 0.42, 0.62, "iron", segments=10, r2=0.48, bevel=0.03)
    h.cyl((1.75, -1.9, 0.94), 0.44, 0.04, "ochre", segments=10)
    return h


def watchtower():
    """A tall lookout on four legs over a small hut, with a snowy pointed roof and a red flag."""
    h = House("house_watchtower")
    h.body(2.0, 2.0, 1.5, "teal", "teal_dark", battens=False)
    h.door(0.0, 2.0, "ochre_dark")
    top = 4.8
    for x in (-0.85, 0.85):
        for y in (-0.85, 0.85):
            h.box((x, y, top / 2.0), (0.22, 0.22, top), "wood_dark")
    for z in (2.6, 3.7):
        for y in (-0.85, 0.85):
            h.box((0, y, z), (1.9, 0.1, 0.12), "wood")
        for x in (-0.85, 0.85):
            h.box((x, 0, z), (0.1, 1.9, 0.12), "wood")
    h.box((0, 0, top), (2.3, 2.3, 0.18), "wood", bevel=0.03)
    for y in (-1.1, 1.1):
        h.box((0, y, top + 0.32), (2.3, 0.08, 0.5), "wood_light")
    for x in (-1.1, 1.1):
        h.box((x, 0, top + 0.32), (0.08, 2.3, 0.5), "wood_light")
    for x in (-1.05, 1.05):
        for y in (-1.05, 1.05):
            h.box((x, y, top + 0.8), (0.12, 0.12, 1.4), "wood_dark")
    h.cyl((0, 0, top + 1.9), 1.75, 0.9, "slate", segments=4, r2=0.0, rz=math.pi / 4.0)
    h.cyl((0, 0, top + 2.08), 1.62, 0.78, "snow", segments=4, r2=0.06, rz=math.pi / 4.0, bevel=0.06)
    h.cyl((0, 0, top + 2.75), 0.03, 0.9, "wood_dark", segments=6)
    h.box((0.25, 0, top + 3.0), (0.45, 0.03, 0.28), "falu")
    return h


def hot_springs():
    h = _house("house_hot_springs", 2.4, 2.2, 2.0, 1.0, "teal", "teal_dark", "slate", "ochre_dark", "waves")
    return h


BUILDINGS = {
    "lumber_yard": lumber_yard, "hunting_lodge": hunting_lodge, "storehouse": storehouse,
    "workshop": workshop, "barracks": barracks, "bunkhouse": bunkhouse, "kitchen": kitchen,
    "watchtower": watchtower, "hot_springs": hot_springs,
}


# ---------- Set dressing (ink_v3 phase 3): the small things that make it a place ----------

def _rock(name, lumps):
    h = House(name)
    for (x, y, sx, sy, sz) in lumps:
        h.blob((x, y, sz * 0.32), (sx, sy, sz), "stone")
    # Snow settled on top, a little smaller than the stone, the shaded side bluer.
    for (x, y, sx, sy, sz) in lumps:
        h.blob((x, y, sz * 0.62), (sx * 0.8, sy * 0.8, sz * 0.4), "snow")
    h.blob((0.0, 0.0, 0.02), (1.6, 1.4, 0.18), "snow_shade")  # a drift round its foot
    return h


def rock_a():
    return _rock("prop_rock_a", [(0.0, 0.0, 1.2, 1.0, 0.8), (0.45, 0.2, 0.7, 0.6, 0.5)])


def rock_b():
    return _rock("prop_rock_b", [(0.0, 0.0, 0.8, 0.7, 0.55), (-0.4, -0.2, 0.5, 0.45, 0.35), (0.35, -0.25, 0.45, 0.4, 0.3)])


def fence():
    """One 2 m run of fence: two posts, two rails, snow along the top."""
    h = House("prop_fence")
    for x in (-0.95, 0.95):
        h.cyl((x, 0, 0.5), 0.07, 1.0, "wood_dark", segments=6)
        h.blob((x, 0, 1.02), (0.2, 0.2, 0.14), "snow")
    for z in (0.4, 0.8):
        h.box((0, 0, z), (2.0, 0.07, 0.11), "wood", rz=0.0, rx=0.0, ry=0.02 if z > 0.5 else -0.02)
    h.box((0, 0, 0.88), (1.95, 0.12, 0.07), "snow", bevel=0.03)
    h.blob((0.0, 0.0, 0.02), (2.3, 0.5, 0.16), "snow_shade")
    return h


def shrub():
    """A bare winter shrub: a few dark twigs fanning out, snow caught at the base."""
    h = House("prop_shrub")
    for i in range(6):
        a = i * math.tau / 6.0 + 0.3
        lean = 0.35 + 0.1 * (i % 2)
        h.cyl((math.cos(a) * 0.12, math.sin(a) * 0.12, 0.35), 0.025, 0.75, "wood_dark", segments=4, rz=a, rx=lean)
    h.blob((0.0, 0.0, 0.05), (0.6, 0.55, 0.2), "snow")
    return h


def lantern_post():
    h = House("prop_lantern_post")
    h.cyl((0, 0, 0.9), 0.06, 1.8, "wood_dark", segments=6)
    h.box((0.18, 0, 1.75), (0.4, 0.06, 0.06), "wood_dark")
    h.box((0.34, 0, 1.55), (0.18, 0.18, 0.26), "fire")
    h.box((0.34, 0, 1.71), (0.24, 0.24, 0.06), "iron")
    h.blob((0.34, 0, 1.76), (0.24, 0.24, 0.08), "snow")
    h.blob((0.0, 0.0, 0.02), (0.6, 0.6, 0.16), "snow_shade")
    return h


def woodpile():
    h = House("prop_woodpile")
    for row, count in enumerate((4, 3, 2)):
        h.logs(0, 0, row * 0.26, count, length=1.0, r=0.13)
    h.blob((0, 0.1, 0.8), (0.5, 0.7, 0.1), "snow")
    h.blob((0.0, 0.0, 0.02), (1.4, 1.3, 0.16), "snow_shade")
    return h


def sled():
    h = House("prop_sled")
    for x in (-0.32, 0.32):
        h.box((x, 0, 0.06), (0.06, 1.5, 0.06), "iron")
        h.box((x, -0.78, 0.16), (0.06, 0.2, 0.06), "iron", rx=-0.9)
        for y in (-0.45, 0.45):
            h.box((x, y, 0.16), (0.05, 0.05, 0.2), "wood_dark")
    for i in range(5):
        h.box((0, -0.5 + i * 0.25, 0.27), (0.78, 0.18, 0.04), "wood_light")
    h.box((0, -0.82, 0.32), (0.7, 0.04, 0.04), "rope")
    return h


def bench():
    h = House("prop_bench")
    for x in (-0.55, 0.55):
        h.cyl((x, 0, 0.18), 0.17, 0.36, "wood", segments=8)
        h.cyl((x, 0, 0.37), 0.15, 0.03, "wood_light", segments=8)
    h.cyl((0, 0, 0.47), 0.15, 1.5, "wood", axis='X', segments=8)
    h.box((0, 0, 0.6), (1.4, 0.22, 0.06), "snow", bevel=0.03)
    return h


def boat():
    """A little rowing boat frozen in at the edge of the ice, snow in its bottom."""
    h = House("prop_boat")
    h.blob((0, 0, 0.22), (1.0, 2.2, 0.55), "wood")
    h.blob((0, 0, 0.36), (0.8, 1.9, 0.36), "wood_dark")
    h.blob((0, 0, 0.3), (0.66, 1.6, 0.2), "snow")
    h.box((0, 0.2, 0.42), (0.86, 0.16, 0.06), "wood_light")
    h.box((0, -0.5, 0.42), (0.82, 0.16, 0.06), "wood_light")
    h.cyl((0.42, 0.1, 0.5), 0.03, 1.6, "wood_light", axis='Y', segments=5, rx=0.2)
    return h


def jetty():
    """A short plank jetty out over the ice, on four posts, snow along its boards."""
    h = House("prop_jetty")
    for x in (-0.45, 0.45):
        for y in (-1.0, 1.0):
            h.cyl((x, y, 0.3), 0.08, 0.6, "wood_dark", segments=6)
            h.blob((x, y, 0.62), (0.2, 0.2, 0.12), "snow")
    for i in range(9):
        h.box((0, -1.1 + i * 0.275, 0.5), (1.1, 0.24, 0.06), "wood", rz=0.03 * ((i % 3) - 1))
    h.box((0.3, 0.0, 0.56), (0.35, 2.2, 0.06), "snow", bevel=0.025)
    return h


PROPS = {
    "rock_a": rock_a, "rock_b": rock_b, "fence": fence, "shrub": shrub, "lantern_post": lantern_post,
    "woodpile": woodpile, "sled": sled, "bench": bench, "boat": boat, "jetty": jetty,
}


def _scene():
    scene = bpy.data.scenes.get(SCENE) or bpy.data.scenes.new(SCENE)
    bpy.context.window.scene = scene
    for ob in list(scene.collection.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0 and me.name.startswith(("house_", "prop_")):
            bpy.data.meshes.remove(me)
    return scene


def build_all(export=False, only=None, spacing=6.0):
    """Builds every house and prop (or those in `only`) side by side; exports each GLB when
    `export` (house_<building>.glb, prop_<name>.glb)."""
    scene = _scene()
    built = []
    makers = [("house_" + k, f) for k, f in BUILDINGS.items()] + [("prop_" + k, f) for k, f in PROPS.items()]
    for i, (key, make) in enumerate(makers):
        if only and key not in only:
            continue
        ob = make().finish(scene.collection)
        ob.location.x = i * spacing
        built.append((key, ob))
    if export:
        out_dir = os.path.join(PROJECT, "assets", "models", "blender")
        layer = scene.view_layers[0]
        for key, ob in built:
            x = ob.location.x
            ob.location.x = 0.0
            # Only this house: other scenes in the file (the trees, the furnace) stay out.
            with bpy.context.temp_override(scene=scene, view_layer=layer):
                for other in scene.objects:
                    other.select_set(other == ob, view_layer=layer)
                layer.objects.active = ob
                bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, "%s.glb" % key), export_format='GLB',
                                          use_selection=True, use_active_scene=True, export_yup=True, export_apply=True,
                                          export_vertex_color='ACTIVE', export_materials='EXPORT')
            ob.location.x = x
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(PROJECT, "source_art", "blender", "house_kit.blend"), copy=True)
    return [ob.name for _, ob in built]
