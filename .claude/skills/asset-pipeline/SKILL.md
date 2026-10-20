---
name: asset-pipeline
description: Make a 3D game model for Frostbite2 end to end — a ChatGPT reference image, Meshy image-to-3D, Blender cleanup, Godot import and wiring. Use when the user asks for a new or remade model (building, prop, character), or when a Tripo or Meshy GLB has been dropped in to be made game-ready.
---

# Asset pipeline: ChatGPT → Meshy → Blender → Godot

One model at a time, in five steps. Meshy spends the user's credits: **state the model and the cost and wait for an OK before every paid call.** ChatGPT runs on the user's ChatGPT plan (no credits), Blender and Godot are free.

| Step | Tool | Output |
|---|---|---|
| 0. Brief | `source_art/concept/README.md` | the asset's row: export name, size, triangle budget, rig |
| 1. Reference | `tools/chatgpt/chatgpt.py image --for-3d` | `source_art/concept/ink/<name>.png` + `.prompt.txt` |
| 2. Generate | Meshy MCP (`meshy_image_to_3d`) | `assets/models/meshy/<name>_<model>.glb` + `<name>.meshy.json` (raw, untouched) |
| 3. Clean up | Blender MCP + `tools/blender/cleanup.py` | `source_art/blender/<name>.blend`, `assets/models/blender/<name>.glb` |
| 4. Wire in | Godot (`Props.PATHS`, `SiteView`, rigs) | the model in the game |
| 5. Check | tests, the running game, `chatgpt.py review` | a commit, pushed |

## 0. Brief
Add or check the asset's row in `source_art/concept/README.md`: export name, height or footprint in metres, triangle budget, rig or not. Sizes come from the game: building plots are about 3.4 × 3 m (`MapData.SITE_HALF_SIZE` 2.0), the furnace is `MapData.FURNACE_RADIUS` 1.8 m, people are about 1.6 m before the rigs' draw scale. **Budgets:** characters ≤ 10k triangles, buildings 6–10k, props 1–2k, foliage ≤ 500. Add the same budget to `BUDGETS` in `tests/test_assets.gd`.

## 1. Reference image (ChatGPT)
```
python tools/chatgpt/chatgpt.py image "<subject: what it is, its parts, materials, colours>" \
    --out source_art/concept/ink/<name>.png --for-3d --ref source_art/direction/round3/inked/lineup.png
```
- `--for-3d` adds what a 3D generator needs (one object, centred, front three-quarter, close to orthographic, plain light grey, flat light, no cast shadow, no ground, no text) and pads the image to a square. Start the subject with the prompt template block from `docs/art-direction.md`.
- Always pass a `--ref` from the same set (the lineup, or the last good reference) so the assets match.
- **Read the image** before going on. Regenerate (at most twice) if there are shadows on the object or the ground, more than one object, a cut-off part, strong perspective, text, or heavy surface noise (Meshy bakes all of it into the model).
- **Characters:** T-pose, arms straight out, legs apart, nothing in the hands. For a better model, make separate front, side and back images (same prompt plus "front view" / "side view" / "back view", each with the front as `--ref`) for `meshy_multi_image_to_3d`, front first. Never one combined turnaround sheet.

## 2. Generate (Meshy)
1. `meshy_check_balance` (free). Tell the user the model, the cost and what they get, and wait for an OK.
2. `meshy_image_to_3d` with `file_path` = the absolute path of the reference and:
   - **Default: `meshy-6`, 30 credits** (won the furnace pilot, see "Pilot results"): `ai_model: "meshy-6"`, `remove_lighting: true` (the only model that strips baked light and shadow), `image_enhancement: false` (keeps the ink look), `should_remesh: true`, `topology: "triangle"`, `target_polycount` about the budget.
   - **Cheaper: `meshy-t2.5` Smart Topology, 15 credits,** for small props where baked shading matters less: `model_type: "smart-topology"`, `ai_model: "meshy-t2.5"`, `target_polycount` = the budget. Cleaner game topology, but light and shadow stay in the texture.
   - Always: `should_texture: true`, `enable_pbr: false` (the ink shader only uses base colour), `texture_resolution: "2k"`, `auto_size: true`, `origin_at: "bottom"`, `target_formats: ["glb"]`. Characters: `pose_mode: "t-pose"`.
   - Not: `lowpoly` (retires 2026-10-30), 4k/8k textures, `geometry_resolution` (Ultra), PBR.
3. `meshy_get_task_status` until it succeeds, then `meshy_download_model` with `format: "glb"`, `save_to: <project>/assets/models/meshy/<name>_<model>.glb`.
4. Write `assets/models/meshy/<name>.meshy.json`: task id, date, `ai_model`, every parameter sent, credits spent, the reference path. Keep the download untouched; it's the source for the cleanup.
- **If a create call times out or returns a 5xx,** the task may exist and be charged: check `meshy_list_tasks` before calling it again. A wait that times out leaves the task running; poll the same id.
- **Rigging (`meshy_rig`, 5 credits):** humanoids only, textured, facing +Z; generate them with `pose_mode: "t-pose"` and pass `input_task_id` plus `height_meters: 1.6`. The rig result isn't saved by `meshy_download_model`: fetch its `rigged_character_glb_url` with curl to `assets/models/meshy/<name>_meshy6_rigged.glb` (the walk/run clips aren't needed; the game makes its own). Meshy's skeleton has 24 bones: Mixamo's limb names without the `mixamorig:` prefix, no fingers, and a spine in the opposite order (Hips → Spine02 → Spine01 → Spine → neck). `tools/blender/rig_names.py` maps it to Mixamo, which `cleanup_character` applies.

## 3. Clean up (Blender)
Blender must be open (Blender MCP). Check `get_scene_info`/`bpy.data.is_dirty` first and never discard the user's unsaved work. Static models (buildings, props):
```python
exec(open(r"C:/Claude Code/Frostbite2/tools/blender/cleanup.py", encoding="utf-8").read())
print(cleanup("<name>", r"C:/Claude Code/Frostbite2/assets/models/meshy/<name>_<model>.glb",
              footprint=3.4, max_tris=8000))        # or height=<m>
```
It makes the scene `FB2_<Name>`, joins, welds, drops loose bits, recalculates normals, decimates to the budget, scales to metres, puts the origin at the bottom centre, leaves one opaque base-colour material (texture ≤ 1024, back faces culled), exports the GLB with `use_active_scene`/`use_active_collection`, saves just that scene as `source_art/blender/<name>.blend`, and prints a report. `yaw=` turns a model that doesn't face the camera: the front faces Blender −Y (Godot +Z, towards the camera).

Then `look` with `mode: "angles"`, `shading: "material"`, and from the game's angle (`views: [[0, -0.62, 0.79]]`, the camera's 52° pitch). Fix by hand what the script can't: floating bits, holes, a shadow painted into the texture (paint it out, or retry Meshy with `meshy-6`).

**Rigged characters** (Meshy or Tripo):
```python
exec(open(r"C:/Claude Code/Frostbite2/tools/blender/cleanup.py", encoding="utf-8").read())
print(cleanup_character("<name>", r"C:/Claude Code/Frostbite2/assets/models/meshy/<name>_meshy6_rigged.glb",
                        height=1.6, max_tris=9000))
```
It renames the bones to Mixamo's (`rig_names.py`), decimates only the skinned mesh (weights kept), scales the whole rig to `height`, stands it on the origin, flattens the material and exports with skins. Blender shows the bones very long after a glTF import (glTF has no bone tails); that's display only. Then pose-check it (`look` with the arms swung down and a lean at the waist) and add the name to `HUMANOIDS` in `tests/test_assets.gd`, which checks `ModelRig`'s bones are there.

## 4. Wire in (Godot)
- `godot --headless --path . --import` imports the new GLB. Keep the default import options (they work for every model so far); for a static model without a normal map, untick Ensure Tangents in its `.import` (`meshes/ensure_tangents=false`).
- Props: add the path to `Props.PATHS` (`scripts/game/props.gd`). Buildings: `SiteView` (`scripts/game/site_view.gd`) swaps the greybox for the model and keeps its own light, embers, pad, body and nameplate. Characters: `ModelRig` paths in `meagan.gd` / `jan_view.gd`. Every loader falls back to greybox when the file is missing.
- Leave materials as delivered: `InkLook` replaces every opaque `BaseMaterial3D` with `ink_toon` at runtime and draws the outlines itself, so models need no outline shell and no custom shader.

## 5. Check
1. `godot --headless --path . -s res://tests/run_tests.gd`: `test_assets.gd` checks every model's budget, base at y = 0, centring, height, materials and texture size.
2. Run the game, screenshot at the normal zoom, and `chatgpt.py review` (see the `chatgpt` skill). Check it reads from the game camera and next to Meagan.
3. Update the asset's row in `source_art/concept/README.md` (made with Meshy, which model), commit and push.

## Rules
- Raw downloads (`assets/models/tripo/`, `assets/models/meshy/`) are kept as delivered and are `.gdignore`d. Never touch the user's uncommitted `assets/models/tripo/Meagan.glb`.
- Never call `tripo_make` (no API credits); the user makes Tripo models by hand in Tripo Studio.
- Generations stay private: don't publish to the Meshy Community (paid-plan outputs are the user's only while unpublished).
- Mobile limits: one material per model where possible, textures ≤ 1024, budgets above. At the Android port, turn on `rendering/textures/vram_compression/import_etc2_astc` and profile on a real phone.

## Pilot results
**Furnace, 2026-10-20** (`assets/models/meshy/furnace.meshy.json`, 45 credits): the same square reference through both models, cleaned with `cleanup.py` (8k triangles, 4.2 m footprint).
- **meshy-6 + `remove_lighting` won:** flat, even washes, a clean fire mouth and furnace-mouth mark, close to the reference. 10.2k triangles from the remesh.
- **meshy-t2.5** was darker and muddier, with shading baked into the stones, though its topology was fine.
- Reading `look` front, back, three-quarter and from the game angle was enough to choose.
- **ChatGPT review in game** (`source_art/direction/furnace_meshy/review.md`): it read too small at 3.6 m (re-exported at 4.2 m). The fire mouth reads flat, and the stonework is busier and muddier than the art direction. These are texture problems: next time, ask the reference for fewer, larger stones and broad washes, or try `meshy_retexture` (10 credits) with a style prompt.
- **Anchors:** a model's spots the code needs (the furnace's mouth and chimney top) were measured on the imported mesh (vertex positions, texture colour at each vertex's UV), not guessed.

**Jan, rig check 2026-10-20** (`assets/models/meshy/jan.meshy.json`, 35 credits): meshy-6 T-pose from `ink/jan.png`, rigged by Meshy. Bones as described under Rigging; after `cleanup_character` (10.3k → 9k triangles, 1.6 m), `ModelRig` finds all its bones, the arms swing down and the waist bends cleanly in Blender. It's much closer to the ink reference than the Tripo Jan; whether it replaces `jan.glb` is the user's call (not in the game yet).
