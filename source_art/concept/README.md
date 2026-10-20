# Concept references for 3D models (Tripo or Meshy)

The PNGs here are reference images, made with ChatGPT (`tools/chatgpt/chatgpt.py image --for-3d`, prompts in `*.prompt.txt`). They're for making the 3D models, by hand in Tripo Studio or with Meshy following the `asset-pipeline` skill (`.claude/skills/asset-pipeline/`), and are never used in the game directly. This folder is `.gdignore`d.

## Ink & watercolour references (2026-10-20)

The game's art direction is now ink & watercolour (`docs/art-direction.md`). The references in `ink/` replace the older ones of the same name below; use them for any remake. Their surfaces are painted washes with only light outlines, because the game draws its own ink lines.

| Reference | Export as | Rig | Notes |
|---|---|---|---|
| `ink/meagan.png` | `meagan.glb` | Humanoid | Falu-red parka, braid, mustard scarf. T-pose. |
| `ink/jan.png` | `jan.glb` | Humanoid | Deep-teal parka, so no Jan wears her red. T-pose. |
| `ink/furnace.png` | `furnace.glb` | — | Fieldstone-and-iron village oven, with the furnace-mouth mark. **Made with Meshy (meshy-6), 2026-10-20; in the game.** |
| `ink/bunkhouse.png` | `bunkhouse.glb` | — | Falu-red cabin, mittens on the door. |
| `ink/lumber_yard.png` | `lumber_yard.glb` | — | Ochre woodshed, crooked-sun sign. |

Tip for Tripo and Meshy: ask for **flat, even lighting** in the texture (Meshy's `meshy-6` with `remove_lighting` also strips it), so the game's own light and shade aren't fighting light baked into the model.

## Earlier references (soft cartoon, 2026-10-19)

| Reference | Export as | Rig |
|---|---|---|
| `meagan.png` | `meagan.glb` | Humanoid |
| `jan.png` | `jan.glb` | Humanoid |
| `wolf.png` | `wolf.glb` | Quadruped |
| `furnace.png` | `furnace.glb` | — |
| `lumber_yard.png` | `lumber_yard.glb` | — |
| `hunting_lodge.png` | `hunting_lodge.glb` | — |
| `stockpile.png` | `stockpile.glb` | — |
| `construction.png` | `construction.glb` | — |
| `sled_shed.png` | `sled_shed.glb` | — |
| `storehouse.png` | `storehouse.glb` | — |
| `workshop.png` | `workshop.glb` | — |
| `barracks.png` | `barracks.glb` | — |
| `bunkhouse.png` | `bunkhouse.glb` | — |
| `scrap_heap.png` | `scrap_heap.glb` | — |
| `ice_hole.png` | `ice_hole.glb` | — |
| `stump.png` | `stump.glb` | — |
| `pine_tree.png` | `pine_tree.glb` | — |
| `axe.png` | `axe.glb` | — |
| `pickaxe.png` | `pickaxe.glb` | — |
| `hammer.png` | `hammer.glb` | — |
| `fishing_rod.png` | `fishing_rod.glb` | — |
| `spear.png` | `spear.glb` | — |
| `wolf_v2.png` | `wolf.glb` | Quadruped (optional remake) |

## How to make a model
1. In Tripo Studio, choose **Image to Model** and upload the PNG. For assets without a reference, use **Text to Model** with the prompts below.
2. **Settings:**
   - **Style:** cartoon or stylized, if offered.
   - **Mesh:** smart low-poly, or a face limit of about 8k for characters, 6–10k for buildings and 1–2k for props.
   - **Textures:** on, with PBR on. Standard texture size is fine; don't use the HD 4k option.
3. **Characters:** click **Rig**: humanoid for Meagan and the Jan, quadruped for the wolf. Skip Tripo's preset animations; the game makes its own work animations.
4. **Export as GLB** to `C:\Claude Code\Frostbite2\assets\models\tripo\<file name>`. Claude takes care of the scale, the pivot, the decimation and wiring it into the game.

**Status (2026-10-19):** Meagan, Jan and the wolf are made and in the game. Every asset below now has a reference image, so use **Image to Model** with the PNG of the same name. Still to make, in this order:
1. `furnace.glb`, `lumber_yard.glb`
2. `hunting_lodge.glb`, `stockpile.glb`, `construction.glb`
3. `sled_shed.glb`, `storehouse.glb`, `workshop.glb`, `barracks.glb`, `bunkhouse.glb`
4. `scrap_heap.glb`, `ice_hole.glb`, `stump.glb`; `pine_tree.glb` only if the Blender-made trees (BACKLOG item 14) don't look good enough
5. Tools: `axe.glb`, `pickaxe.glb`, `hammer.glb`, `fishing_rod.glb` (the bobber floats apart in the image; if Tripo leaves it as a separate piece, that's fine), `spear.glb`
6. Optional: a wolf remake from `wolf_v2.png`, exported as `wolf.glb` over the current one. It's softer and fluffier than the first wolf and reads better from above.

## Text prompts (Text to Model)
**Negative prompt,** where Tripo has a field for it: `realistic, photorealistic, gritty, horror, text, logo, watermark, base, pedestal, ground plane, multiple objects, extra limbs`

### Characters
- **meagan.glb:** Stylized chunky cartoon 3D game character, young woman named Meagan, cheerful friendly face, rosy cheeks, pink-magenta puffy winter parka, white knitted bobble hat, mustard-yellow scarf, white mittens, brown snow boots, small brown backpack, rounded simple shapes, big readable silhouette, slightly oversized head, hand-painted soft colours, T-pose, full body, mobile game asset, low poly
- **jan.glb:** Stylized chunky cartoon 3D game character, friendly bearded man named Jan, round red nose, orange-brown puffy winter parka, blue knitted beanie, blue mittens, dark snow boots, stocky rounded body, slightly oversized head, warm smile, hand-painted soft colours, T-pose, full body, mobile game asset, low poly
- **wolf.glb:** Stylized chunky cartoon 3D game wolf, grey and white fur in simple chunky shapes, glowing yellow eyes, slightly mischievous but not scary, rounded body, short sturdy legs, standing on all fours in a neutral pose, side-readable silhouette, hand-painted colours, mobile game asset, low poly
  - **Remake, optional:** add "wide chunky torso and broad head, big upright ears, thick bushy tail, smooth simple neck ruff with no jagged plates, dark charcoal back, blue-grey sides, pale muzzle and paws, readable from above". The current wolf reads narrow from the game camera.

### Buildings
Each one has its entrance and details on the front, about a 3.4 × 3 m footprint.
- **furnace.glb:** Stylized chunky cartoon 3D game building, giant round stone furnace with a big glowing orange fire opening at the front, thick riveted iron bands, tall stout chimney with a little smoke cap, snow on top, warm cosy look, arctic village centrepiece, front-facing, hand-painted colours, mobile game asset, low poly
- **lumber_yard.glb:** Stylized chunky cartoon 3D game building, small wooden lumber yard cabin with a red-brown roof covered in snow, stacks of chopped logs and a chopping stump with an axe at the front, warm window light, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **hunting_lodge.glb:** Stylized chunky cartoon 3D game building, cosy log fishing lodge with a snowy dark roof, fishing rods and a drying rack of fish at the front, small ice hole with a bucket beside the door, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **sled_shed.glb:** Stylized chunky cartoon 3D game building, small blue-grey wooden shed with a wide open front showing a wooden sled, snowy roof, ropes and harness hanging on the wall, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **storehouse.glb:** Stylized chunky cartoon 3D game building, sturdy tan wooden storehouse with big double doors, crates and sacks stacked outside, snowy roof, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **workshop.glb:** Stylized chunky cartoon 3D game building, grey stone and timber workshop with an anvil, a workbench and hanging tools at the front, small chimney, snowy roof, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **barracks.glb:** Stylized chunky cartoon 3D game building, small dark-red wooden guard barracks with a red banner flag on a pole, a rack of wooden spears by the door, snowy roof, friendly not military, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **bunkhouse.glb:** Stylized chunky cartoon 3D game building, warm yellow wooden bunkhouse cabin with glowing windows, a little porch, a stack of firewood, snowy orange roof, cosy home for villagers, arctic village, front-facing, hand-painted colours, mobile game asset, low poly
- **stockpile.glb:** Stylized chunky cartoon 3D game prop, wooden pallet stockpile with stacked logs, wooden crates and a basket of fish, snow dusting, arctic village storage, hand-painted colours, mobile game asset, low poly
- **construction.glb:** Stylized chunky cartoon 3D game prop, wooden building scaffold frame under construction, planks, a ladder, a small pile of logs and a hammer, snow dusting, hand-painted colours, mobile game asset, low poly

### Nature and props
- **pine_tree.glb:** Stylized chunky cartoon 3D pine tree, three stacked rounded green tiers with thick snow on top, short brown trunk, simple shapes, hand-painted colours, mobile game asset, very low poly
- **stump.glb:** Stylized chunky cartoon 3D tree stump with visible rings on top, snow dusting, hand-painted colours, mobile game asset, very low poly
- **scrap_heap.glb:** Stylized chunky cartoon 3D pile of salvage scrap, broken crates, rusty metal plates, old pipes and gears half buried in snow, hand-painted colours, mobile game asset, low poly
- **ice_hole.glb:** Stylized chunky cartoon 3D frozen pond patch with a round dark ice-fishing hole, chunky ice edges and a small snow rim, flat, hand-painted colours, mobile game asset, very low poly
- **Tools** (`axe.glb`, `pickaxe.glb`, `hammer.glb`, `fishing_rod.glb`, `spear.glb`): Stylized chunky cartoon 3D game item, a [woodcutter's axe / pickaxe / hammer / fishing rod with a red bobber / wooden spear], oversized chunky proportions, hand-painted colours, mobile game asset, very low poly
