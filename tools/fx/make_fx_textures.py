"""Draws the fight's effect textures into assets/textures/fx/ (fight_v2 review 6). Needs Pillow.

    python tools/fx/make_fx_textures.py

- impact.png / impact_counter.png: a blow's burst (reviews 9, 10: concentrated), an opaque cream
  core about 13 px across on the phone, three thick rays reaching about 9 px past it fanned along +X (Fx turns them out of the body,
  towards the blow) and three short accents, terracotta (ochre for a counter), with a 2 px
  warm-ink outline round the whole shape so it reads over bodies and snow.

- impact_rim.png: a dark ochre ring round the burst's core, shown for its first 40 ms so the
  moment of contact snaps (review 11).
- impact_splash.png / impact_splash_counter.png (review 16, what the game uses now): an irregular,
  directional cream burst with a 2 px burnt-orange edge, no round core (the round bead is the
  counter window's), flung along +X; the counter's edge is gold.

Change a texture here and re-run rather than editing the PNGs.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "textures" / "fx"
SIZE = 256
SCALE = 4  # drawn big, then shrunk, for soft edges
CREAM = (255, 245, 220, 255)
INK = (52, 40, 34, 255)
RAYS = {"impact": (168, 69, 41, 255), "impact_counter": (219, 158, 56, 255)}
# Each ray: its angle in degrees from +X and its length as a share of the half-size.
RAY_SET = [(-36, 0.92, 0.24), (0, 1.0, 0.26), (38, 0.88, 0.24), (-80, 0.6, 0.15), (78, 0.58, 0.15), (180, 0.52, 0.13)]
CENTRE = 0.42


def shape(draw, colour, grow):
    big = SIZE * SCALE
    c = big / 2.0
    half = big / 2.0 * 0.86
    for angle, length, width in RAY_SET:
        a = math.radians(angle)
        tip = (c + math.cos(a) * (half * length + grow), c + math.sin(a) * (half * length + grow))
        side = a + math.pi / 2.0
        w = half * width + grow
        base1 = (c + math.cos(side) * w, c + math.sin(side) * w)
        base2 = (c - math.cos(side) * w, c - math.sin(side) * w)
        draw.polygon([base1, tip, base2], fill=colour)
    r = half * CENTRE + grow
    draw.ellipse([c - r, c - r, c + r, c + r], fill=colour)


def make(name, rays):
    big = SIZE * SCALE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # The outline: the same shape grown by 2 px (at the game's size), in ink, underneath.
    shape(draw, INK, grow=2.2 * SCALE * 2)
    shape(draw, rays, grow=0)
    half = big / 2.0 * 0.86
    r = half * CENTRE
    c = big / 2.0
    draw.ellipse([c - r, c - r, c + r, c + r], fill=CREAM)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.png")
    print("wrote", OUT / f"{name}.png")


def make_rim():
    big = SIZE * SCALE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = big / 2.0
    r = big / 2.0 * 0.86 * CENTRE
    width = 14 * SCALE  # about 2 px on the phone
    draw.ellipse([c - r - width / 2, c - r - width / 2, c + r + width / 2, c + r + width / 2], fill=(122, 78, 26, 255))
    draw.ellipse([c - r + width / 2, c - r + width / 2, c + r - width / 2, c + r - width / 2], fill=(0, 0, 0, 0))
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    img.save(OUT / "impact_rim.png")
    print("wrote", OUT / "impact_rim.png")


# The splash's outline, as (angle in degrees from +X, radius as a share of the half-size): long
# points thrown along +X, ragged and short behind.
SPLASH = [(0, 1.0), (16, 0.5), (30, 0.86), (46, 0.42), (64, 0.62), (90, 0.34), (125, 0.4), (160, 0.3),
          (200, 0.34), (236, 0.42), (270, 0.36), (296, 0.6), (314, 0.44), (330, 0.92), (346, 0.48)]
EDGES = {"impact_splash": (190, 86, 34, 255), "impact_splash_counter": (226, 166, 58, 255)}


def make_splash(name, edge):
    big = SIZE * SCALE
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    c = big / 2.0
    half = big / 2.0 * 0.9

    def outline(grow):
        pts = []
        for angle, r in SPLASH:
            a = math.radians(angle)
            pts.append((c + math.cos(a) * (half * r + grow), c + math.sin(a) * (half * r + grow)))
        return pts

    draw.polygon(outline(2.0 * SCALE * 7), fill=edge)
    draw.polygon(outline(0), fill=CREAM)
    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    img.save(OUT / f"{name}.png")
    print("wrote", OUT / f"{name}.png")


if __name__ == "__main__":
    for name, rays in RAYS.items():
        make(name, rays)
    make_rim()
    for name, edge in EDGES.items():
        make_splash(name, edge)
