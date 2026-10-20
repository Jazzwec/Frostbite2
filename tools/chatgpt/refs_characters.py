"""Makes the character references for Meshy multi-image-to-3D (model pipeline, phase E): a front,
side and back T-pose view of each character, through chatgpt.py on gpt-6-astra. The front is made
first with the round-3 lineup as its style reference; the side and back then use the front, so all
three show the same character. Skips any that already exist.

    python tools/chatgpt/refs_characters.py [meagan|jan|wolf ...]
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INK = ROOT / "source_art" / "concept" / "ink"
LINEUP = ROOT / "source_art" / "direction" / "round3" / "inked" / "lineup.png"
STYLE = (
    "Rendered in INK AND WATERCOLOUR PICTURE-BOOK style: hand-inked slightly wobbly dark outlines, soft "
    "watercolour colour washes with visible paper grain, gently simplified shapes, like a Nordic children's "
    "picture book brought into a 3D game with toon shading and outlines. Palette: Falu red #B2412E, ochre "
    "#C9973F, faded teal #5E8A87, deep teal #35666B, snow #EEF2F2, deep ink #2C3440. Deliberate "
    "simplification: three or four big clear colour masses (head and hair, coat, trousers, boots), no fine "
    "texture, no stitching detail, no patterns, no dirt, small dot eyes and minimal features, mitten hands, "
    "moderately stylised proportions with the head about a fifth of the height (a little larger than "
    "realistic so it reads on a phone), no chibi, no big shiny eyes, no glossy 3D movie look, no text."
)
POSE = (
    " Full body, standing in a T-POSE: arms held straight out to the sides at shoulder height, palms down, "
    "legs straight and slightly apart, nothing in the hands, neutral face, centred, the whole figure visible "
    "with space around it, orthographic, plain light grey background, flat even lighting, no shadows."
)
CHARACTERS = {
    "meagan": "MEAGAN, the heroine, a young woman: a deep Falu-red (#B2412E) hooded winter parka with a cream "
              "fur trim round the hood (hood down), one thick dark-brown braid over her shoulder, a long mustard "
              "(#C9973F) scarf, dark navy trousers, tan winter boots, red mittens. She is the only red figure.",
    "jan": "A JAN, a villager: a stocky friendly man with a full round brown beard, a small round red nose, a "
           "navy knitted beanie, a deep-teal (#35666B) padded work parka, dark grey trousers, chunky brown "
           "boots and big grey mittens.",
}
VIEWS = {
    "front": "FRONT VIEW, facing the viewer.",
    "side": "SIDE VIEW from the character's left, in exact profile, the same character and outfit as the "
            "attached front view, same T-pose, same proportions.",
    "back": "BACK VIEW, seen from directly behind, the same character and outfit as the attached front view, "
            "same T-pose, same proportions.",
}


def make(name, view):
    out = INK / f"{name}_v2_{view}.png"
    if out.exists():
        print("exists", out.name, flush=True)
        return out
    refs = [LINEUP] if view == "front" else [INK / f"{name}_v2_front.png"]
    cmd = [sys.executable, str(ROOT / "tools" / "chatgpt" / "chatgpt.py"), "image",
           STYLE + " SUBJECT: " + CHARACTERS[name] + POSE + " " + VIEWS[view]]
    for r in refs:
        cmd += ["--ref", str(r)]
    cmd += ["--out", str(out)]
    run = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    print(name, view, "ok" if run.returncode == 0 else "FAILED " + run.stderr[-300:], flush=True)
    return out


def main():
    for name in sys.argv[1:] or list(CHARACTERS):
        for view in VIEWS:
            make(name, view)


if __name__ == "__main__":
    main()
