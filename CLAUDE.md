# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Frostbite2

A personalised incremental survival game for Meagan. The player character is Meagan; every NPC is a Jan. Inspired by the Whiteout Survival ads, but all art, names and text are original.

Frostbite2 is a fresh rebuild in Godot of Frostbite 1 (a finished Vite + Phaser web game at `C:\Projects\Frostbite\Frostbite`, repo `Jazzwec/Frostbite1`). It takes over the design, not the code: Frostbite 1 is a reference for what worked, never something to port line by line.

## Current state
- First playable prototype (2026-10-19), greybox 3D. It covers the core loop, blizzards and wolves:
  - **Objective:** the furnace starts full; when heat reaches 0 the game is over (engine `game_over`, a `GameOverCard` with time survived and best time, `Game.new_game()` to play again). Low-heat warnings below 25%, a countdown below 10%.
  - **Hypercasual feel:** a drag-anywhere joystick steers Meagan (6 m/s) and a close camera stays on her. What she carries stacks on her back with a "12/20" counter ("MAX" when full), and pieces fly in and out one at a time with "+N" pops. Each plot has a build pad: stop on it to open its sheet, stand on it to pay. A Stockpile by the furnace is the town bank: drop everything off on its pad; build pads pay from her bag and then the Stockpile; the furnace feeds itself from its Wood; Jans' output goes into it.
  - **Core loop:** hand-gathering into Meagan's bag, fuelling the furnace, rescuing frozen Jans, jobs that fill the Stockpile, building and upgrading on plots.
  - **Pressure:** blizzards with forecast and banners; wolf packs from Furnace Lv 2, fought by guards and Meagan.
  - **Buildings:** Furnace, Lumber Yard, Hunting Lodge, Sled Shed, Storehouse, Workshop, Barracks, Bunkhouse. **Jobs:** chop, hunt, build, guard.
- Not built yet: Research, Kitchen, Watchtower, Hot Springs, Expedition Post, Signal Beacon, caravans, gear and guard kits, bears, Jan variants, the Build/Jans/Collection screens, milestones, prestige, saving, sound and music.
- Characters animate: Meagan chops, ice-fishes (the hunting grounds are frozen ponds), scavenges, fuels the furnace, hammers, carries, warms frozen Jans and fights wolves; Jans chop, fish and hammer at their stations, and guards thrust spears. All greybox, in code.
- Art: the Poly Haven props (boulder, crate, log) are in `assets/models/polyhaven/`, decimated in Blender; their source is `source_art/blender/polyhaven_props.blend`. Poly Haven trees are ~7M triangles and unusable on mobile, so trees, buildings and characters are greybox shapes in code (`scripts/game/shapes.gd`). `Props.make()` falls back to greybox when a model is missing.
- `NOTES.md` has the play checklist and the open design questions.

## Source of truth
- `docs/design-brief.md` is the design (copied from Frostbite 1). Its game rules, economy tables, characters and content still apply. Its **Tech & build plan** and **Art & assets** sections describe the old web/Phaser/2D build and are superseded by this file until the brief is rewritten for Godot.
- Frostbite2 may change the design freely, but every change is agreed with the user first and written into the brief, so the brief stays authoritative. If something is unclear, ask before guessing; where the brief gives no number, ask.
- `docs/frostbite1/` holds reference copies from Frostbite 1: its `CLAUDE.md` (architecture and what got built), `NOTES.md` (open items and the untested phone checklist), `balance.ts` (its tuned constants, which differ from the brief in places) and `content/*.json` (all player-facing writing, still placeholder drafts awaiting the real in-jokes). `docs/` has a `.gdignore`, so Godot does not import it.

## Stack
- Godot 4.7.2 (`C:\Godot`, `godot` on PATH), GDScript. No C# (no .NET SDK installed).
- 3D town seen from an angled top-down/isometric camera. Mobile renderer, portrait 1080×1920 (`canvas_items` stretch, `expand` aspect; the desktop window opens at 540×960).
- It's a mobile game, built and played on Windows for now and ported to Android and iOS later. Design for a phone throughout: portrait, touch-first controls (taps and drags, no keyboard or hover reliance), thumb-sized tap targets and the mobile renderer's limits. The game must also be playable with a mouse on Windows, since that is where it is tested. Android and iOS export setup is out of scope until the port; iOS will need a Mac at that point.
- No backend, no accounts, no ads, no analytics. Saves are local, with an export/import code like Frostbite 1.
- No offline progress: the game pauses when the app is backgrounded or the window loses focus.

## Architecture
- **`scripts/engine/`: the rules.** Plain GDScript `RefCounted` classes with no nodes, so they test headless. Positions are `Vector2` metres: x is world X, y is world Z.
  - `GameEngine` owns the `GameState`. It runs fixed 0.1 s ticks through `advance(delta)`, capped at 1 s per call with no catch-up, and handles `pause()`/`resume()`.
  - **Actions:** `set_meagan_position`, `choose_building`, `start_upgrade`, `target_arrival`, `add_to_job`, `remove_from_job`.
  - **Dev shortcuts:** `skip`, `fill`, `force_blizzard`, `spawn_wolves`, `dev_level_up`, `dev_add_jan`.
  - **Events:** queued dictionaries, read with `drain_events()`.
- **Rules by file** (each called from the tick):
  - `economy.gd`: pure derived values (costs, caps, drain, rates, `neediest_job`)
  - `meagan_rules.gd`: gathering, node regrowth, the bag ↔ building magnet, rescues
  - `world_events.gd`: arrivals, eating, Jans leaving at zero heat, blizzards
  - `combat.gd`: wolves, guards, Meagan fighting
  - `map_data.gd`: the layout (plots, resource nodes, arrival spots, wolf spawns)
- **Every tunable number lives in `balance.gd`** as a named, commented constant, with its source noted. Engine logic never hard-codes a number. Where the brief has no number, the value is marked `[proto]` and still needs your sign-off.
- **The rest reads engine state and calls engine actions; it never changes state directly.**
  - **`Game` autoload** (`scripts/game/game.gd`): ticks the engine, pauses when the window loses focus, emits `engine_event`, and loads the text from `data/`.
  - **`scripts/game/main.gd`:** builds the world in code from `MapData` (the scene file is just a root node), turns taps into walks and sheets, and engine events into banners and floating text.
  - **Views:** `SiteView` (plots and buildings, including the furnace), `NodeView` (resource spots), `PeopleLayer` with `JanView`/`WolfView`, and `Meagan` (a `CharacterBody3D` with a `NavigationAgent3D`; the navmesh is re-baked when a plot gets a building).
  - **Animation:** every character is a `CharacterRig` (`scripts/game/rig/`) playing keyframed clips from `Clips`, holding tools from `Tools`. `GreyboxRig` poses greybox shapes (the Jans, and Meagan's fallback). `ModelRig` poses a rigged Mixamo-style model bone by bone: each joint is a rotation in character space on top of the bone's rest, so the bones' own axes don't matter. Meagan (`meagan.glb`, drawn ×1.2) and the Jans (`jan.glb`, 5k tris, ×1.15) use `ModelRig` with their models in `assets/models/blender/`; both fall back to `GreyboxRig` if the file is missing. The engine records what Meagan did each tick (`meagan_activity`: gather, full, store, fuel, build, fight, plus a target); `main.gd` maps that to a clip (`chop`/`fish`/`scavenge` by node kind, `carry`, `fuel`, `build`, `fight`, `full`) and reacts to the rig's `impact` signal with `Fx` bursts, thrown items, tree shakes and furnace flares. Jans work at a station in front of their building (stump, ice hole, anvil), slower when cold or hungry, and rest when the Stockpile is full of what they make.
  - **Rig contract** (both rigs keep it): `play(clip, speed)`, `play_once(clip)`, `cancel_once()`, the `impact(clip)` signal (a method track on a real AnimationPlayer), `tip_position()`, `line_target`, and the clip names in `Clips`.
  - **Camera and UI:** `CameraRig` (orthographic camera, always on Meagan; touch-only input: a drag is a floating joystick, emitted as `steered`, and drawn by `Joystick`; a short press is a tap), and `Hud`/`Sheet` in `scripts/ui/`.
  - **Carrying and pads:** `CarryStack` on Meagan's back mirrors the engine's bag, given where pieces come from and go to by `main.gd` from her activity. `Fx.pop` shows the "+N" numbers. `SiteView` draws each plot's pad (`MapData.pad_pos`); construction and upgrades are paid only on the pad (`PAD_RADIUS`), and `main.gd` opens a pad's sheet when she stops on it. `StockpileView` draws the Stockpile (`MapData.STOCKPILE_POS`, pad at `stockpile_pad()`); the engine's `piles` are its stores.
- **Text:** player-facing writing lives in `data/` (JSON copied from Frostbite 1, still placeholder drafts), not in code.
- **Randomness:** an injected, seeded RNG, so tests are deterministic.
- **Physics layers** are in `scripts/game/layers.gd`: ground, obstacle, tappable.
- **Tests:** no framework yet; picking GUT or gdUnit4 is still open, so ask before adding one. Meanwhile `tests/run_tests.gd` runs every `test_*` method in `tests/test_*.gd`; tests extend `TestCase` (`tests/test_case.gd`).

## Assets
- `assets/models/tripo/`: GLB files the user generates by hand in Tripo Studio (the web app) and drops in, kept as delivered. The folder is `.gdignore`d; the game uses the cleaned-up exports in `assets/models/blender/`. Tripo characters come rigged with Mixamo bone names (`mixamorig_*` in Godot). The pipeline:
  1. Import into its own Blender scene (`FB2_<Name>`).
  2. Decimate to about 9k triangles and shrink the texture to 1024.
  3. Scale to metres, with the feet at the origin.
  4. Export with `use_active_scene` and `use_active_collection`, otherwise the glTF exporter takes every scene in the open file. The Tripo API has no credits, so do not call `tripo_make` unless the user says they bought API credits.
- `assets/models/blender/`: GLBs exported after cleanup in Blender (scale, pivot, decimation, rigging), via the `blender` MCP server, which needs Blender open. Keep the `.blend` working files in `source_art/blender/` (`.gdignore`d so Godot doesn't import them).
- **ChatGPT, through the user's Codex CLI** (ChatGPT plan, not API credits): `tools/chatgpt/chatgpt.py` does `review` (art-director feedback on screenshots), `ask` (a second opinion) and `image` (2D assets). The `chatgpt` skill (`.claude/skills/chatgpt/`) says when to use it, and it's used after every visible change, including in workflows and AFK runs. Generated assets go in `assets/ui/icons/`, `assets/textures/` and `source_art/concept/` (Tripo references), each with a `.prompt.txt`.
- Free models, textures and HDRIs: Poly Haven via the Blender MCP (`search_assets`/`import_asset`), CC0.
- Art style: chunky, readable at phone size, never copying Whiteout Survival's assets. Meagan and the Jans are the assets that genuinely have to be good.
- `assets/audio/music/` and `assets/audio/sfx/`: synthesized placeholders made by `tools/audio/make_audio.py` (numpy + scipy, fixed seeds), until the planned ElevenLabs audio. Change a sound in the script and re-run it rather than editing the .wav files. `winter_town.wav` and `wind_loop.wav` are imported with looping on.
- **`Audio` autoload** (`scripts/game/audio.gd`): Music and SFX buses, the music loop, blizzard muffling plus wind, and `Audio.play(name, at, pitch, volume_db)` for effects named after their files; the `SOUNDS` table sets each one's volume, pitch spread and minimum gap. Effects with a position fade with distance from Meagan. The Music/Sound toggles are saved in `user://settings.cfg`.
- Models arrive at arbitrary scale: normalise to 1 unit = 1 metre with the ground at y = 0.

## Commands
- `godot --path . --editor` or `swallowtail launch` opens the editor. Swallowtail's typed tools only appear once the editor is running, and `swallowtail doctor` diagnoses the MCP connection.
- `godot --path .` runs the game. Add `-- --keep-running` to stop it pausing when the window loses focus.
- `godot --headless --path . -s res://tests/run_tests.gd` runs the engine tests.
- `python tools/audio/make_audio.py` regenerates the music and sound effects (needs numpy and scipy).
- `python tools/chatgpt/chatgpt.py review|ask|image ...`: ChatGPT via the Codex CLI (see the `chatgpt` skill). A review or ask takes about 30 s, an image about 40 s.
- **In the game (debug builds):** the DEV button or F1 opens the dev panel: skip 60 s, fill resources, add a Jan, Furnace +1, blizzard, wolves.
- **Driving the running game from Swallowtail:**
  - Use the Bash tool: PowerShell 5.1 strips the double quotes inside `--code` strings.
  - `swallowtail input click` takes viewport coordinates (1080×1920), not window pixels.
  - After adding a new `class_name` file, run `swallowtail editor reload` before `scene play`.

## How to work
- Plan before coding anything larger than a one-file change, and show the plan first.
- One feature at a time; keep the game runnable after every change.
- After each change, say what to check in the running game.
- Big numbers formatted as 1.2K, 3.4M, 5.6B.
- Ask before adding any dependency or addon.
- Log what felt wrong while playing in `NOTES.md`; it becomes the prompt for the next session.
- Unattended runs (`/loop ... Follow AFK.md.`) follow `AFK.md`, work only on **safe** items in `BACKLOG.md` and log to `AFK_REPORT.md`.
- Commit and push after every change, so everything is trackable:
  - Commit once the tests pass and the game runs, then push to `origin main`.
  - Make one commit per feature or fix, with a clear message and nothing unrelated mixed in.
  - Never force-push or rewrite history.
