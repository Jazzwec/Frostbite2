"""ChatGPT for Frostbite2, through the Codex CLI (logged in with the user's ChatGPT account).

    python tools/chatgpt/chatgpt.py review shot1.png [shot2.png ...] --focus "HUD readability" [--out review.md]
    python tools/chatgpt/chatgpt.py image "a flat wood-log icon" --out assets/ui/icons/wood.png [--ref concept.png]
    python tools/chatgpt/chatgpt.py ask "Is 6 m/s too fast for a phone screen?" [--image shot.png] [--out answer.md]

Every call is logged to tools/chatgpt/calls.log (time, kind, seconds, output, prompt summary) so
budgets can be checked. Standard library only; needs `codex` on PATH.
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

STYLE = (
    "Frostbite2 is a cosy, hypercasual mobile survival game: a small arctic town around a big furnace, "
    "seen from an angled top-down camera on a portrait phone. The player is Meagan; every villager is a "
    "Jan. Art style: chunky, rounded, low-detail cartoon shapes, bold readable silhouettes, warm firelight "
    "against cool snow blues, readable at phone size. Original work only: never copy Whiteout Survival "
    "or any other game's assets or characters."
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


def log(kind, seconds, out, summary):
    stamp = datetime.datetime.now().isoformat(timespec="seconds")
    line = f"{stamp}\t{kind}\t{seconds:.0f}s\t{out}\t{summary[:120].replace(chr(10), ' ')}\n"
    with LOG.open("a", encoding="utf-8") as f:
        f.write(line)


def codex(prompt, images=(), out_file=None, timeout=180, sandbox="read-only"):
    """Runs one non-interactive Codex turn; returns (final message, thread id)."""
    exe = shutil.which("codex")
    if not exe:
        sys.exit("codex CLI not found on PATH")
    with tempfile.TemporaryDirectory() as work:
        last = Path(work) / "last.md"
        cmd = [exe, "exec", "-s", sandbox, "--skip-git-repo-check", "--ephemeral", "--json", "-C", work, "-o", str(last)]
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
    text, _ = codex(REVIEW_PROMPT.format(style=STYLE, focus=args.focus), args.images, args.out)
    log("review", time.time() - start, args.out or "-", args.focus)
    print(text)


def cmd_ask(args):
    start = time.time()
    text, _ = codex(ASK_PROMPT.format(style=STYLE, question=args.question), args.image or (), args.out)
    log("ask", time.time() - start, args.out or "-", args.question)
    print(text)


def _thread_images(thread):
    """The images one Codex run made, oldest first. Safe when several runs happen at once."""
    folder = GENERATED / thread
    if not thread or not folder.exists():
        return []
    return sorted(folder.glob("*.png"), key=lambda p: p.stat().st_mtime)


def cmd_image(args):
    start = time.time()
    out = Path(args.out)
    refs = [args.ref] if args.ref else []
    prompt = IMAGE_PROMPT.format(style=STYLE, prompt=args.prompt)
    if refs:
        prompt += "\nMatch the style of the attached reference image."
    reply, thread = codex(prompt, refs, timeout=args.timeout)
    made = _thread_images(thread)
    if not made:
        sys.exit(f"no image was generated. Codex said:\n{reply[-1500:]}")
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(made[-1], out)
    # Keep the prompt beside the asset so it can be regenerated.
    out.with_suffix(".prompt.txt").write_text(args.prompt + "\n", encoding="utf-8")
    log("image", time.time() - start, str(out), args.prompt)
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
    r.set_defaults(fn=cmd_review)
    a = sub.add_parser("ask", help="a second opinion")
    a.add_argument("question")
    a.add_argument("--image", nargs="*")
    a.add_argument("--out")
    a.set_defaults(fn=cmd_ask)
    i = sub.add_parser("image", help="generate one image")
    i.add_argument("prompt")
    i.add_argument("--out", required=True)
    i.add_argument("--ref")
    i.add_argument("--timeout", type=int, default=300)
    i.set_defaults(fn=cmd_image)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
