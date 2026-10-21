"""Draws the fight's effect textures into assets/textures/fx/ (fight_v2 review 6). Needs Pillow.

    python tools/fx/make_fx_textures.py

- impact.png / impact_counter.png: a blow's burst (review 9: concentrated), an opaque cream core
  about 9 px across on the phone, three thick rays fanned along +X (Fx turns them out of the body,
  towards the blow) and three short accents, terracotta (ochre for a counter), with a 2 px
  warm-ink outline round the whole shape so it reads over bodies and snow.

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
RAY_SET = [(-34, 0.86, 0.27), (0, 1.0, 0.3), (36, 0.8, 0.27), (-78, 0.5, 0.17), (74, 0.46, 0.17), (180, 0.42, 0.15)]
CENTRE = 0.34


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


if __name__ == "__main__":
    for name, rays in RAYS.items():
        make(name, rays)
