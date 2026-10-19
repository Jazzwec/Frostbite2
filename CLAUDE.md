# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Frostbite2

A personalised incremental survival game for Meagan. The player character is Meagan; every NPC is a Jan. Inspired by the Whiteout Survival ads, but all art, names and text are original.

Frostbite2 is a fresh rebuild in Godot of Frostbite 1 (a finished Vite + Phaser web game at `C:\Projects\Frostbite\Frostbite`, repo `Jazzwec/Frostbite1`). It takes over the design, not the code: Frostbite 1 is a reference for what worked, never something to port line by line.

## Current state
- First playable prototype (2026-10-19), greybox 3D. It covers the core loop, blizzards and wolves:
  - **Core loop:** tap to walk, hand-gathering into Meagan's bag, fuelling the furnace, rescuing frozen Jans, jobs that pile up output, building and upgrading on plots by carrying.
  - **Pressure:** blizzards with forecast and banners; wolf packs from Furnace Lv 2, fought by guards and Meagan.
  - **Buildings:** Furnace, Lumber Yard, Hunting Lodge, Sled Shed, Storehouse, Workshop, Barracks, Bunkhouse. **Jobs:** chop, hunt, build, guard.
- Not built yet: Research, Kitchen, Watchtower, Hot Springs, Expedition Post, Signal Beacon, caravans, gear and guard kits, bears, Jan variants, the Build/Jans/Collection screens, milestones, prestige, saving, sound and music.
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
  - **Camera and UI:** `CameraRig` (orthographic camera; touch-only input, so drag pans and a short press taps), and `Hud`/`Sheet` in `scripts/ui/`.
- **Text:** player-facing writing lives in `data/` (JSON copied from Frostbite 1, still placeholder drafts), not in code.
- **Randomness:** an injected, seeded RNG, so tests are deterministic.
- **Physics layers** are in `scripts/game/layers.gd`: ground, obstacle, tappable.
- **Tests:** no framework yet; picking GUT or gdUnit4 is still open, so ask before adding one. Meanwhile `tests/run_tests.gd` runs every `test_*` method in `tests/test_*.gd`; tests extend `TestCase` (`tests/test_case.gd`).

## Assets
- `assets/models/tripo/`: GLB files the user generates by hand in Tripo Studio (the web app) and drops in. The Tripo API has no credits, so do not call `tripo_make` unless the user says they bought API credits.
- `assets/models/blender/`: GLBs exported after cleanup in Blender (scale, pivot, decimation, rigging), via the `blender` MCP server, which needs Blender open. Keep the `.blend` working files in `source_art/blender/` (`.gdignore`d so Godot doesn't import them).
- Free models, textures and HDRIs: Poly Haven via the Blender MCP (`search_assets`/`import_asset`), CC0.
- Art style: chunky, readable at phone size, never copying Whiteout Survival's assets. Meagan and the Jans are the assets that genuinely have to be good.
- `assets/audio/music/`: music, planned from ElevenLabs (no integration yet). `assets/audio/sfx/`: effects.
- Models arrive at arbitrary scale: normalise to 1 unit = 1 metre with the ground at y = 0.

## Commands
- `godot --path . --editor` or `swallowtail launch` opens the editor. Swallowtail's typed tools only appear once the editor is running, and `swallowtail doctor` diagnoses the MCP connection.
- `godot --path .` runs the game. Add `-- --keep-running` to stop it pausing when the window loses focus.
- `godot --headless --path . -s res://tests/run_tests.gd` runs the engine tests.
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
