# Concept references for Tripo Studio

The PNGs here are reference images, made with ChatGPT (`tools/chatgpt/chatgpt.py image`, prompts in `*.prompt.txt`). They're for making the 3D models in Tripo Studio and are never used in the game directly. This folder is `.gdignore`d.

| Reference | Export as | Rig |
|---|---|---|
| `meagan.png` | `meagan.glb` | Humanoid |
| `jan.png` | `jan.glb` | Humanoid |
| `wolf.png` | `wolf.glb` | Quadruped |
| `furnace.png` | `furnace.glb` | — |
| `lumber_yard.png` | `lumber_yard.glb` | — |

## How to make a model
1. In Tripo Studio, choose **Image to Model** and upload the PNG. For assets without a reference, use **Text to Model** with the prompts below.
2. **Settings:**
   - **Style:** cartoon or stylized, if offered.
   - **Mesh:** smart low-poly, or a face limit of about 8k for characters, 6–10k for buildings and 1–2k for props.
   - **Textures:** on, with PBR on. Standard texture size is fine; don't use the HD 4k option.
3. **Characters:** click **Rig**: humanoid for Meagan and the Jan, quadruped for the wolf. Skip Tripo's preset animations; the game makes its own work animations.
4. **Export as GLB** to `C:\Claude Code\Frostbite2\assets\models\tripo\<file name>`. Claude takes care of the scale, the pivot, the decimation and wiring it into the game.

**Priority:**
1. Meagan
2. Jan
3. Furnace
4. Wolf
5. Pine tree and stump
6. The other buildings
7. Props and tools

## Text prompts (Text to Model)
**Negative prompt,** where Tripo has a field for it: `realistic, photorealistic, gritty, horror, text, logo, watermark, base, pedestal, ground plane, multiple objects, extra limbs`

### Characters
- **meagan.glb:** Stylized chunky cartoon 3D game character, young woman named Meagan, cheerful friendly face, rosy cheeks, pink-magenta puffy winter parka, white knitted bobble hat, mustard-yellow scarf, white mittens, brown snow boots, small brown backpack, rounded simple shapes, big readable silhouette, slightly oversized head, hand-painted soft colours, T-pose, full body, mobile game asset, low poly
- **jan.glb:** Stylized chunky cartoon 3D game character, friendly bearded man named Jan, round red nose, orange-brown puffy winter parka, blue knitted beanie, blue mittens, dark snow boots, stocky rounded body, slightly oversized head, warm smile, hand-painted soft colours, T-pose, full body, mobile game asset, low poly
- **wolf.glb:** Stylized chunky cartoon 3D game wolf, grey and white fur in simple chunky shapes, glowing yellow eyes, slightly mischievous but not scary, rounded body, short sturdy legs, standing on all fours in a neutral pose, side-readable silhouette, hand-painted colours, mobile game asset, low poly

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
