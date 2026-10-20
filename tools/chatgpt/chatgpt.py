"""ChatGPT for Frostbite2, through the Codex CLI (logged in with the user's ChatGPT account).

    python tools/chatgpt/chatgpt.py review shot1.png [shot2.png ...] --focus "HUD readability" [--out review.md]
    python tools/chatgpt/chatgpt.py image "a flat wood-log icon" --out assets/ui/icons/wood.png [--ref concept.png]
    python tools/chatgpt/chatgpt.py image "the village furnace" --out source_art/concept/ink/furnace.png --for-3d --ref lineup.png
    python tools/chatgpt/chatgpt.py ask "Is 6 m/s too fast for a phone screen?" [--image shot.png] [--out answer.md]

Every call runs on gpt-6-astra (Codex's frontier model) at high effort, the user's choice from
2026-10-20; --model and --effort override it. Every call is logged to tools/chatgpt/calls.log
(time, kind, model, seconds, output, prompt summary) so budgets can be checked. Standard library
only (PIL for --for-3d padding); needs `codex` on PATH.
"""

import argparse
import datetime
import json
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOG = Path(__file__).resolve().parent / "calls.log"
GENERATED = Path.home() / ".codex" / "generated_images"
## The model every call uses, and its reasoning effort (user's choice, 2026-10-20).
MODEL = "gpt-6-astra"
EFFORT = "high"

STYLE = (
    "Frostbite2 is a cosy, hypercasual mobile survival game: a small arctic town around a big furnace, "
    "seen from an angled top-down camera on a portrait phone. The player is Meagan; every villager is a "
    "Jan. Art style: an ink and watercolour picture book brought into 3D (docs/art-direction.md): soft "
    "watercolour washes with paper grain, gently simplified chunky shapes, few materials, large clean "
    "colour areas, warm firelight against cool snow blues, readable at phone size. Original work only: "
    "never copy Whiteout Survival or any other game's assets or characters."
)

# Added by `image --for-3d`: what an image-to-3D generator (Meshy, Tripo) needs from a reference.
FOR_3D = (
    "This is a reference for an image-to-3D model generator. ONE object only, whole and centred with "
    "space around it, front three-quarter view from slightly above, close to orthographic (no strong "
    "perspective), square framing, plain flat light grey background, flat even lighting with no cast "
    "shadows and no baked highlights, no ground, base, pedestal or scenery, no text. Only light, thin "
    "outlines on the object itself, because the game draws its own ink lines. Paint its surfaces as "
    "broad, flat watercolour colour areas: three or four big colour masses, few large stones, planks or "
    "folds, no fine texture, grime or dark speckle, because the 3D generator bakes every mark into the "
    "model's texture."
)

REVIEW_PROMPT = """You are an experienced art director and game designer for hypercasual mobile games.
{style}

Look at the attached screenshot(s) from the game. Focus: {focus}

Give at most 7 concrete, prioritized improvements (most impactful first). For each: what you see,
why it hurts the player experience on a phone, and the specific change (sizes, colours, placement,
timing). Be direct; skip praise. If more than one screenshot is attached, compare them
(they may be before/after). End with one line: "Verdict: ship / fix first", and why."""

ASK_PROMPT = """You are a sharp second opinion on a mobile game in development.
{style}

{question}

Answer concisely and concretely. If you'd need more information to be sure, say what."""

IMAGE_PROMPT = """Use your image generation tool to create exactly one image, then stop.
Do not write code, do not edit files, do not run shell commands.

{style}

Image to create: {prompt}"""


def log(kind, model, seconds, out, summary):
    stamp = datetime.datetime.now().isoformat(timespec="seconds")
    line = f"{stamp}\t{kind}\t{model}\t{seconds:.0f}s\t{out}\t{summary[:120].replace(chr(10), ' ')}\n"
    with LOG.open("a", encoding="utf-8") as f:
        f.write(line)


def codex(prompt, images=(), out_file=None, timeout=420, sandbox="read-only", model=MODEL, effort=EFFORT):
    """Runs one non-interactive Codex turn on `model`; returns (final message, thread id)."""
    exe = shutil.which("codex")
    if not exe:
        sys.exit("codex CLI not found on PATH")
    with tempfile.TemporaryDirectory() as work:
        last = Path(work) / "last.md"
        cmd = [exe, "exec", "-m", model, "-c", f'model_reasoning_effort="{effort}"', "-s", sandbox,
               "--skip-git-repo-check", "--ephemeral", "--json", "-C", work, "-o", str(last)]
        for img in images:
            cmd += ["-i", str(Path(img).resolve())]
        cmd.append("-")
        try:
            run = subprocess.run(cmd, input=prompt, capture_output=True, text=True, encoding="utf-8",
                                 errors="replace", timeout=timeout)
        except subprocess.TimeoutExpired:
            sys.exit(f"codex timed out after {timeout}s")
        if run.returncode != 0:
            sys.exit(f"codex failed ({run.returncode}):\n{run.stderr[-2000:]}")
        text = last.read_text(encoding="utf-8") if last.exists() else ""
    # The JSON event stream names this run's thread; its generated images live in a folder of that name.
    thread = ""
    for line in run.stdout.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if event.get("type") == "thread.started":
            thread = event.get("thread_id", "")
            break
    if out_file:
        Path(out_file).parent.mkdir(parents=True, exist_ok=True)
        Path(out_file).write_text(text, encoding="utf-8")
    return text, thread


def cmd_review(args):
    start = time.time()
    for img in args.images:
        if not Path(img).exists():
            sys.exit(f"no such image: {img}")
    text, _ = codex(REVIEW_PROMPT.format(style=STYLE, focus=args.focus), args.images, args.out,
                    timeout=args.timeout, model=args.model, effort=args.effort)
    log("review", args.model, time.time() - start, args.out or "-", args.focus)
    print(text)


def cmd_ask(args):
    start = time.time()
    text, _ = codex(ASK_PROMPT.format(style=STYLE, question=args.question), args.image or (), args.out,
                    timeout=args.timeout, model=args.model, effort=args.effort)
    log("ask", args.model, time.time() - start, args.out or "-", args.question)
    print(text)


def _thread_images(thread):
    """The images one Codex run made, oldest first. Safe when several runs happen at once."""
    folder = GENERATED / thread
    if not thread or not folder.exists():
        return []
    return sorted(folder.glob("*.png"), key=lambda p: p.stat().st_mtime)


def _pad_square(path):
    """Pads an image to a square with its own corner colour; 3D generators prefer 1:1."""
    try:
        from PIL import Image
    except ImportError:
        print("PIL not installed; left the image unpadded", file=sys.stderr)
        return
    im = Image.open(path).convert("RGB")
    side = max(im.size)
    if im.width == im.height:
        return
    square = Image.new("RGB", (side, side), im.getpixel((2, 2)))
    square.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    square.save(path)


def cmd_image(args):
    start = time.time()
    out = Path(args.out)
    refs = args.ref or []
    prompt = IMAGE_PROMPT.format(style=STYLE, prompt=args.prompt)
    if args.for_3d:
        prompt += "\n" + FOR_3D
    if refs:
        prompt += "\nMatch the style of the attached reference image(s)."
    reply, thread = codex(prompt, refs, timeout=args.timeout, model=args.model, effort=args.effort)
    made = _thread_images(thread)
    if not made:
        sys.exit(f"no image was generated. Codex said:\n{reply[-1500:]}")
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(made[-1], out)
    if args.for_3d:
        _pad_square(out)
    # Keep the prompt beside the asset so it can be regenerated.
    out.with_suffix(".prompt.txt").write_text(args.prompt + "\n", encoding="utf-8")
    log("image", args.model, time.time() - start, str(out), args.prompt)
    print(out)


def main():
    # Windows consoles default to a legacy code page; ChatGPT's replies use typographic characters.
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("review", help="art-director feedback on screenshots")
    r.add_argument("images", nargs="+")
    r.add_argument("--focus", default="overall readability, clarity and juice on a phone")
    r.add_argument("--out")
    r.add_argument("--timeout", type=int, default=420)
    r.set_defaults(fn=cmd_review)
    a = sub.add_parser("ask", help="a second opinion")
    a.add_argument("question")
    a.add_argument("--image", nargs="*")
    a.add_argument("--out")
    a.add_argument("--timeout", type=int, default=420)
    a.set_defaults(fn=cmd_ask)
    i = sub.add_parser("image", help="generate one image")
    i.add_argument("prompt")
    i.add_argument("--out", required=True)
    i.add_argument("--ref", action="append", help="a style reference; repeat for several (e.g. the lineup and the front view)")
    i.add_argument("--for-3d", action="store_true", help="a reference for Meshy/Tripo: one object, plain grey, flat light, square")
    i.add_argument("--timeout", type=int, default=600)
    i.set_defaults(fn=cmd_image)
    for s in (r, a, i):
        s.add_argument("--model", default=MODEL, help="Codex model (default %(default)s)")
        s.add_argument("--effort", default=EFFORT, help="reasoning effort (default %(default)s)")
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
