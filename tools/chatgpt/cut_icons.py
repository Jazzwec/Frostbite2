"""Cuts a ChatGPT icon sheet (icons in a grid on white) into the HUD's icons: one 128 px PNG per
cell in assets/ui/icons/, its white background un-blended into transparency so the soft
watercolour edges stay soft on any panel. Needs Pillow.

    python tools/chatgpt/cut_icons.py source_art/icons/v2/sheet.png 4 4
    python tools/chatgpt/cut_icons.py source_art/icons/enemies/sheet.png 2 2 fox bear raider troll

Names after the grid size name the cells instead of the v2 sheet's NAMES.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "ui" / "icons"
## The sheet's cells, left to right and top to bottom (source_art/icons/v2/sheet.prompt.txt).
NAMES = ["wood", "food", "materials", "heat", "jans", "bag", "blizzard", "wolves",
         "cold", "milestone", "build", "stockpile", "house"]
SIZE = 128
## How far from white a pixel must be to count fully as paint (0-255); paler is see-through.
SOFT = 48
PAD = 0.0


def unblend(cell):
    """White becomes transparent; a paint colour c over white at alpha a was a*c + (1-a)*255."""
    px = cell.load()
    out = Image.new("RGBA", cell.size)
    po = out.load()
    for y in range(cell.size[1]):
        for x in range(cell.size[0]):
            r, g, b = px[x, y][:3]
            a = min(1.0, (255 - min(r, g, b)) / SOFT)
            if a <= 0.0:
                po[x, y] = (0, 0, 0, 0)
                continue
            c = [max(0, min(255, round((v - (1.0 - a) * 255) / a))) for v in (r, g, b)]
            po[x, y] = (c[0], c[1], c[2], round(a * 255))
    return out


def keep_main(cell, step=4, keep=0.25):
    """Drops specks a neighbouring icon spilled into the cell: on a coarse grid, a connected
    piece that touches the cell's edge and is under `keep` of the biggest one's size goes (an
    icon's own snowflakes and sparks don't touch the edge, so they stay)."""
    alpha = cell.getchannel("A")
    gw, gh = cell.size[0] // step, cell.size[1] // step
    small = alpha.resize((gw, gh), Image.BOX).load()
    on = {(x, y) for y in range(gh) for x in range(gw) if small[x, y] > 24}
    pieces = []
    while on:
        seed = on.pop()
        piece, todo = {seed}, [seed]
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)):
                if n in on:
                    on.remove(n)
                    piece.add(n)
                    todo.append(n)
        pieces.append(piece)
    biggest = max(len(p) for p in pieces)
    def at_edge(piece):
        return any(x == 0 or y == 0 or x == gw - 1 or y == gh - 1 for x, y in piece)
    kept = set().union(*[p for p in pieces if len(p) >= keep * biggest or not at_edge(p)])
    px = cell.load()
    for y in range(cell.size[1]):
        for x in range(cell.size[0]):
            if (min(x // step, gw - 1), min(y // step, gh - 1)) not in kept:
                px[x, y] = (0, 0, 0, 0)
    return cell


def main():
    sheet = Image.open(sys.argv[1]).convert("RGB")
    cols, rows = int(sys.argv[2]), int(sys.argv[3])
    names = sys.argv[4:] or NAMES
    w, h = sheet.size[0] / cols, sheet.size[1] / rows
    for i, name in enumerate(names):
        cx, cy = i % cols, i // cols
        cell = unblend(sheet.crop((round(cx * w), round(cy * h), round((cx + 1) * w), round((cy + 1) * h))))
        cell = keep_main(cell)
        box = cell.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
        if box is None:
            print("empty cell", name)
            continue
        icon = cell.crop(box)
        side = round(max(icon.size) * (1 + 2 * PAD))
        square = Image.new("RGBA", (side, side))
        square.paste(icon, ((side - icon.size[0]) // 2, (side - icon.size[1]) // 2))
        square.resize((SIZE, SIZE), Image.LANCZOS).save(OUT / f"{name}.png")
        print("cut", name, box)


if __name__ == "__main__":
    main()
