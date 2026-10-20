---
name: chatgpt
description: Use ChatGPT (through the Codex CLI bridge) in Frostbite2 for art-director feedback on game screenshots, second opinions on design questions, and generating 2D assets (UI icons, textures, concept sheets for Tripo). Use it after any visible change, before guessing on a design call, and whenever an asset is needed. Works in normal sessions, workflow agents and AFK runs.
---

# ChatGPT for Frostbite2

ChatGPT is reached through the user's Codex CLI, which is logged in with their ChatGPT account, so it uses their ChatGPT plan and not API credits. Everything goes through one script, run from the project root:

```
python tools/chatgpt/chatgpt.py review <shot.png> [<shot2.png> ...] --focus "<what to judge>" [--out <file.md>]
python tools/chatgpt/chatgpt.py ask "<question>" [--image <shot.png>] [--out <file.md>]
python tools/chatgpt/chatgpt.py image "<what to draw>" --out <path.png> [--ref <style reference.png>] [--for-3d]
```

- A review or ask takes about 30 s; an image about 40 s. The script prints the result. Images are written to `--out`, with the prompt saved beside them as `<name>.prompt.txt`.
- **Every call runs on `gpt-6-astra` at high effort** (Codex's frontier model; the user's choice, 2026-10-20). It's the script's default, so pass nothing; `--model`/`--effort` exist only for a one-off. An Astra image takes about 1–3 minutes and a review about a minute (timeouts 600 s and 420 s).
- `--ref` can be given more than once (say the round-3 lineup and the last approved reference of the same kind), so a set of assets stays consistent.
- Every call is logged in `tools/chatgpt/calls.log` (with its model), which is gitignored. Check it to stay within a budget.
- The script adds the game's style brief to every prompt by itself (cosy arctic town, ink & watercolour picture book, original work only), so prompts only need to say what's specific.
- `--for-3d` makes a reference for a 3D generator (Meshy or Tripo): it adds the generator's needs (one object, plain grey, flat light, no shadows) and pads the image to a square. The `asset-pipeline` skill has the whole route to a game model.
- Use the Bash tool. Screenshots come from `swallowtail runtime screenshot --save_path <file>`.

## When to use it

**Feedback, after every visible change** (UI, effects, animation, new building or asset):
1. Screenshot before and after the change, at the normal camera zoom, plus a close-up if it helps.
2. Run `review before.png after.png --focus "<the change, what it should achieve>"`.
3. Apply the points that are in scope for the current task. Note the others where the work is reported (the AFK report or the answer to the user). Don't chase every point: ChatGPT can't play the game, and the brief and the user overrule it.

**Second opinions:** before guessing on balance or design, run `ask`, giving the numbers and the brief's rules. It's advice, not a decision. Anything the brief or the user hasn't settled still goes to the user.

**Asset creation**, where 2D images are needed:
- **UI icons** go in `assets/ui/icons/<name>.png`.
  - Prompt: "game UI icon of …, bold dark outline, flat colours, centred, plain pure white background, square, no text".
  - Then key the white background out to transparency, using PIL, which comes with the installed Python.
  - Check the icon at 64 px.
- **Textures** go in `assets/textures/`. Ask for "seamless tileable", then check the tiling by placing two copies side by side.
- **Concept and model references for Tripo or Meshy** go in `source_art/concept/ink/`, made with `--for-3d`. Ask for "character model sheet, front, side and back views, T-pose, plain light grey background", and keep one sheet as `--ref` for the others so the style stays consistent. These are references for the user to upload to Tripo Studio (image to 3D). They're never used in the game directly.

## Rules
- **Look at every generated image with the Read tool before using or committing it.** Regenerate (at most twice) if it's off-style, has text or watermarks, or isn't what was asked.
- **Only the Codex bridge.** Never use `OPENAI_API_KEY` or any paid API from here.
- **AFK budget:** at most 8 images and 25 reviews or asks per run. Count them from `calls.log` since the run started.
- **Commit the prompt with the asset** (`<name>.prompt.txt`), so it can be regenerated.
- **If `codex` fails** (not logged in, rate-limited or timed out), carry on without it and say so in the report. Don't retry in a loop.
