# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Frostbite2

A personalised incremental survival game for Meagan. The player character is Meagan; every NPC is a Jan. Inspired by the Whiteout Survival ads, but all art, names and text are original.

Frostbite2 is a fresh rebuild in Godot of Frostbite 1 (a finished Vite + Phaser web game at `C:\Projects\Frostbite\Frostbite`, repo `Jazzwec/Frostbite1`). It takes over the design, not the code: Frostbite 1 is a reference for what worked, never something to port line by line.

## Current state
- Project skeleton only (2026-10-19): Godot 4.7 project, Swallowtail addon and MCP, portrait mobile settings, folder layout, git initialised. No game code yet.
- Next: the design pass in `NOTES.md` ("Next session"), then the 3D scaffold.

## Source of truth
- `docs/design-brief.md` is the design (copied from Frostbite 1). Its game rules, economy tables, characters and content still apply. Its **Tech & build plan** and **Art & assets** sections describe the old web/Phaser/2D build and are superseded by this file until the brief is rewritten for Godot.
- Frostbite2 may change the design freely, but every change is agreed with the user first and written into the brief, so the brief stays authoritative. If something is unclear, ask before guessing; where the brief gives no number, ask.
- `docs/frostbite1/` holds reference copies from Frostbite 1: its `CLAUDE.md` (architecture and what got built), `NOTES.md` (open items and the untested phone checklist), `balance.ts` (its tuned constants, which differ from the brief in places) and `content/*.json` (all player-facing writing, still placeholder drafts awaiting the real in-jokes). `docs/` has a `.gdignore`, so Godot does not import it.

## Stack
- Godot 4.7.2 (`C:\Godot`, `godot` on PATH), GDScript. No C# (no .NET SDK installed).
- 3D town seen from an angled top-down/isometric camera. Mobile renderer, portrait 1080×1920 (`canvas_items` stretch, `expand` aspect; the desktop window opens at 540×960).
- Targets: Android and Windows PC first. iPhone is out of scope for now (it needs a Mac). Android export needs the Godot export templates, a JDK and the Android SDK, none of which are installed yet.
- No backend, no accounts, no ads, no analytics. Saves are local, with an export/import code like Frostbite 1.
- No offline progress: the game pauses when the app is backgrounded or the window loses focus.

## Intended architecture (carried over from what worked in Frostbite 1)
- Game rules live in plain GDScript under `scripts/engine/`, with no scene-tree or node dependencies (`RefCounted` classes), so they can be unit-tested headless. The engine owns the state, runs fixed 0.1 s ticks, and queues events that the presentation layer drains.
- Every tunable number lives in one balance file as a named, commented constant; engine logic never hard-codes a number.
- Scenes and UI (`scenes/`, `scripts/game/`, `scripts/ui/`) read engine state and call engine actions; they never mutate state directly.
- Player-facing text lives in `data/` (JSON), not in code.
- Randomness comes from an injected, seeded RNG so tests are deterministic.
- Test framework not chosen yet (GUT or gdUnit4 are the usual options): ask before adding it.

## Assets
- `assets/models/tripo/`: GLB files the user generates by hand in Tripo Studio (the web app) and drops in. The Tripo API has no credits, so do not call `tripo_make` unless the user says they bought API credits.
- `assets/models/blender/`: GLBs exported after cleanup in Blender (scale, pivot, decimation, rigging), via the `blender` MCP server, which needs Blender open. Keep the `.blend` working files in `source_art/blender/` (`.gdignore`d so Godot doesn't import them).
- Free models, textures and HDRIs: Poly Haven via the Blender MCP (`search_assets`/`import_asset`), CC0.
- Art style: chunky, readable at phone size, never copying Whiteout Survival's assets. Meagan and the Jans are the assets that genuinely have to be good.
- `assets/audio/music/`: music, planned from ElevenLabs (no integration yet). `assets/audio/sfx/`: effects.
- Models arrive at arbitrary scale: normalise to 1 unit = 1 metre with the ground at y = 0.

## Commands
- `godot --path . --editor` or `swallowtail launch` opens the editor (Swallowtail's typed tools only appear once the editor is running). `swallowtail doctor` diagnoses the MCP connection.
- `godot --path .` runs the game. Headless: `godot --headless --path . --quit` checks that the project loads.

## How to work
- Plan before coding anything larger than a one-file change, and show the plan first.
- One feature at a time; keep the game runnable after every change.
- After each change, say what to check in the running game.
- Big numbers formatted as 1.2K, 3.4M, 5.6B.
- Ask before adding any dependency or addon.
- Log what felt wrong while playing in `NOTES.md`; it becomes the prompt for the next session.
