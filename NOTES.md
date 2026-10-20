# NOTES

What felt wrong while playing, and what's still open. This file is the prompt for the next session.

## Fight v2: the Armory, waves and the review loop (2026-10-20/21, in progress)

**The user's task:** keep working on the combat until Astra rates it at least 9/10 (elegant hypercasual fighting for phone controls, design and feel), researching best practices throughout. It includes:
- the Armory: 10 levels for Meagan's weapons and the guards' kit;
- waves that scale, so not upgrading in time loses the game;
- new enemy kinds;
- outposts on the map to attack for rewards.

**Done:**
- The engine and views: commits 59ca54a…d2bb6a1.
- Review 1 (6/10, `source_art/direction/fight_v2/r1/review.md`): all seven points are in (commits 1862bef…5e87c6c). An earlier session crashed half-way through these; its partial work is in `git stash` ("crashed session…") for reference only.

**The loop:**
1. Capture with `bash tools/capture/fight_caps.sh source_art/direction/fight_v2/rN`, with the game playing.
2. Review with `python tools/chatgpt/chatgpt.py review <strips> --focus ... --out .../rN/review.md`.
3. Implement the points, one commit each.
4. Repeat until 9/10.

**Sims:** `godot --headless --path . -s res://tests/sim_waves.gd` shows thefts per wave for four Armory plans: none standing, none active, late and schedule. `tests/test_balance.gd` holds the targets.

**New `[proto]` numbers awaiting the user's sign-off:**
- wind-ups, recoveries and HP in `Balance.ENEMIES`;
- `STEAL_FOOD_FLOOR_PER_JAN` (thieves leave 3 Food per Jan);
- `MELEE_EXIT_MULT`, `MEAGAN_TARGET_HOLD`, `OUTPOST_WAKE`, `ENEMY_AIM_LOCK`, `ENEMY_GAP`.

## Hypercasual fighting (2026-10-20, late)

Asked by the user: fighting as hypercasual as the rest. Everyone attacks the nearest opponent, and Meagan has two automatic modes, ranged and melee, swapping to melee when a wolf is within reach.
- **Sources:**
  - web best practices (auto-aim at the nearest with one transparent rule; discrete hits with hit-stop, flash and knockback; telegraphed enemy attacks; medium juice);
  - ChatGPT's steer (`source_art/direction/fight_v1/steer.md`), which gave the numbers;
  - its review afterwards (`review.md`), whose cheap points are in.
- **The rules** are in the brief's Animal attacks section, and the tests in `tests/test_fighting.gd`.

**Check in the game:**
- DEV → Wolves while Meagan stands in the open: she throws snowballs as they come, switches to her stick as they reach her, and goes back to snowballs as they back off.
- Rust wedges warn of each bite; step away and it misses.
- Beaten wolves tumble and run off. Guards strike once a second.

**Open, for you:**
- Every combat number is `[proto]`. The steer warns that wolf health (×1.6 per Furnace level) outgrows her damage: at Furnace Lv 7 a wolf needs about 21 stick hits. It suggests combat upgrades, or a softer curve.
- From the review, not done:
  - a short ochre streak along the stick's path;
  - one reward pop for kills close together;
  - thinner health bars;
  - a snowball trail.
- Workers still get scared off by a wolf that reaches them (the brief's rule). The steer suggested they flee and come back instead.

## Visual polish AFK run (2026-10-20, 19:27–20:14)

All ten items of BACKLOG.md "Visual polish" are in; details and what to check are in `AFK_REPORT.md`:
- the paper and ink HUD;
- cosy watercolour icons (`tools/chatgpt/cut_icons.py` cuts a sheet);
- softer blue-grey snow and lines;
- Jans' hauled loads (bundle, basket, crate);
- one summary when storing;
- footprints;
- furnace smoke and lantern halos;
- a seated ice-fishing Jan, split logs at the stump, varied resting idles, and Meagan's breath in the cold;
- the flame trail to a new small furnace;
- the bag-full nudge.

The reviews' leftovers are under "Needs you" in the report.

## The bag, small stockpiles, global levels, hauling Jans (2026-10-20, night)

The user changed their mind about the bag. Plan: `~/.claude/plans/make-sure-there-is-ancient-avalanche.md`. All four parts are in and tested (140 tests), one commit each:
1. **Global levels:** every plot of a building shares its level, and its upgrade is paid on any of their pads. The furnace's level is shared with the small furnaces, which now have a pad that opens the furnace's sheet.
2. **Small stockpiles:** one beside each small furnace, all doors into the one store. The Stockpile has its own shared level (every cap ×1.2 per level).
3. **The bag:** 20, +10 per Stockpile level. It empties at any stockpile, and pads take from it before the store.
4. **Hauling:** Jans carry loads (Wood 5, Food 3, Materials 1) to the nearest stockpile.

**Check in the game:**
- chop to MAX and empty the bag at the main and a small stockpile;
- pay a furnace upgrade at a small furnace;
- upgrade a Lumber Yard and see every yard go up;
- watch Jans walk loads to the stockpile.

**New `[proto]` numbers, for your sign-off:**
- the bag's +10 per Stockpile level;
- the Stockpile's cost (60 Wood + 10 Materials, ×1.5 per level, max 10) and its cap ×1.2 per level;
- the loads, Jan walking 3 m/s with a 1.25 path factor;
- the small stockpile's spot;
- the small furnace's pad 2.4 m in.

**Notes:**
- `job_rate` and the sheets still show working speed, not what reaches the store after the walk.
- A wolf can still scare a Jan who is out hauling.
- The dev save is reset (`SAVE_VERSION` 13).

## Model pipeline: every model through GPT -> Meshy -> Blender (2026-10-20, evening)

Plan: `~/.claude/plans/make-sure-there-is-ancient-avalanche.md`. The user approved a 1,200-credit Meshy cap; **1,060 spent** (`assets/models/meshy/ledger.json`, one `<name>.meshy.json` per model). References come from ChatGPT on **gpt-6-astra** (`tools/chatgpt/refs_buildings.py` for buildings, props, trees, chests and tools; `refs_characters.py` for the front/side/back character views).

**Done and in the game (phases B-G):**
- all nine buildings, the furnace (30% taller), the small furnace, wolf den and Stockpile;
- rocks a and b, the boulder, fence, woodpile, boat, jetty, shrub, lantern post, sled, bench, crate and log;
- all three pines;
- the three chests, split into a body and a hinged lid (warm-wood inside; the boon chest 20% taller; opening throws sparks and snow);
- Meagan and the Jan (multi-image from T-pose views, rigged by Meshy);
- the held tools: axe, pickaxe, hammer, rod, spear and the carried fish (`cleanup(hold=..., grip=...)`).

The hand-built kit stays as the fallback (`assets/models/kit/`, `Props.make` falls back blender -> kit -> polyhaven); `Tools.make` keeps its greybox.

**Waiting on the user:** the wolf. Its reference is `source_art/concept/ink/wolf_v2.png` (side three-quarter, grey and cream). Make and rig it in Tripo Studio, drop it in `assets/models/tripo/`, and I clean it up and re-check `WolfView`'s posing.

**Reviews (Astra):**
- Phase C, 5/10: the roofs dominate at the game camera, and the snow wants a warm-ivory lit side and a pale-lavender shaded side.
- Phases D/E, 5.5/10 (`source_art/direction/meshy_v1/review_phase_de.md`). Done: the chest fixes. Open, and they need your call:
  1. A camera 8-12° lower and characters 10-15% bigger, so faces and fronts show.
  2. Simpler characters: broad hair masses, a thicker braid, a bigger scarf, a compact beard, smooth fur bands. That's a v3 round, about 70 credits.
  3. Softer, thinner outlines and blue-grey snow.
  4. Pines with three uneven tiers and more visible green.

**Note:** the dev save (`user://save.json`) has 16 extra tiles open from the chest check; Play again resets it.

## Ink look v3 (2026-10-20, late)

Making the game look like `source_art/direction/round3/inked/gameplay.png`, aimed at a ChatGPT paintover of our own layout (`source_art/direction/ink_v3/paintover.png`). Plan: `~/.claude/plans/make-sure-there-is-ancient-avalanche.md`. All four phases are in:
1. **Shaders:** snow caps, near-white snow with a soft fire glow, trodden tracks, contact shade, drifts round buildings, staked plots, local-colour boiling lines, and labels only near Meagan.
2. **House kit:** every building, in `tools/blender/house_kit.py`.
3. **Set dressing:** `SetDressing`.
4. **Special places:** the frozen-harbour pond, the ice block and the wild-snow frontier.

**Ink v4 (same day):** all six points of `review_final.md` are in:
- a 30% tighter layout with tracks to every spot;
- pads only near Meagan;
- tight contact shade and a furnace light pool;
- one compact label;
- characters about 20% bigger;
- the harbour scene;
- a chunkier kit, with the Stockpile, small furnace, chests and den matching it.

The cheap points of ChatGPT's follow-up (`review_v4.md`, **5/10**) are also in: darker tracks, half the internal linework, darker shaded roof slopes, faint pads, a smaller "Upgrade" and a wider furnace glow. Its other points need the user:
- Move the four corner buttons (Jans, Music, Sound, DEV) into one collapsible button, a UI change.
- Simplify Meagan into three colour masses and enlarge her head and hair by 10–15%: a Meshy retexture or remodel, which costs credits.
- Fill the empty snow between clusters with work areas.

Screens and reviews are in `source_art/direction/ink_v3/`. The list below is what ChatGPT's earlier review (`review_final.md`) wanted; it's now done. They're design calls for the user, because they change layout or UI:
- **Town layout:** tighter clusters (gaps 25–35% smaller) and one packed path linking the furnace, the Stockpile, the houses and the harbour.
- **Pads:** no persistent coloured pad discs; show them only while targeting. A bigger peach light pool at the furnace.
- **Silhouettes:** three big masses per building, thicker posts and snow edges, and the same treatment for the furnace, dock and boat.
- **Harbour:** a working harbour scene (two holes by the jetty, a stool and a crate with a Jan).
- **Labels:** one compact name-and-level label per selected building, with no duplicate levels.
- **Characters:** Meagan and the Jans 20–25% bigger on screen.

Also still greybox: the Stockpile, the small furnace, chests and dens.

## Handover (end of session, 2026-10-20, evening)

**Where things stand.** Frostbite2 is now a **roguelite with a growing world** (agreed with the user on 2026-10-20). Everything is committed and pushed to `Jazzwec/Frostbite2` (last commit `94bec21`), and the **122 tests pass**.
- **The plan:** `C:\Users\jansv\.claude\plans\create-a-workflow-where-snappy-flurry.md`. All six phases are built.
- **The rules:** the brief's **Areas, small furnaces & treasures** section.
- **The architecture:** `CLAUDE.md` (the World, Producers, Treasures and Frontier bullets under Architecture).

**What's in the game now:**
- **Starting grid:** a fixed 3 × 3 grid of 20 m tiles (±30 m). The game decides every plot's building: one utility building each (Storehouse, Kitchen, Barracks, Bunkhouse, Watchtower, Hot Springs), plus the starting Lumber Yard and Fishing Lodge. `start_construction(i)` replaced choosing a building.
- **Gates:** every closed tile touching open ground has a gate on the shared border (stone ring and pad). Choose **Open** in its sheet, then pay on the pad.
  - The tile opens and a **small furnace** is lit on the border: +0.15 heat/s drain, and it never upgrades.
  - The tile's contents come from `WorldGen.tile_contents(run_seed, tile)`, the same in any unlock order: resource spots, producer plots (Lumber Yard, Fishing Lodge, Workshop), a camp of frozen Jans, a chest, and from three rings out a wolf den.
- **Producers** hold 3 Jans each (`jan.site`). Each producer's sheet shows "2/3 Jans" with −/+; the Jans screen moves Jans by job.
- **Chests:**
  - caches pay into the Stockpile;
  - boon chests offer 2 (rare) or 3 (epic) run-long boons;
  - gear chests offer an axe, boots or sled for her slots.
  - The world waits while the `OfferCard` is up.
- **The frontier:** single frozen Jans and wolf packs come from the edge of the open area; dens add wolf spawns.
- **Hints and score:** the last hint points at the nearest gate, and the game-over card counts areas and chests opened.
- **Greybox:** the small furnace, gates, chests, dens and closed tiles (raised slate-blue blocks). Screenshots and ChatGPT reviews are in `source_art/direction/world_tiles/` and `treasures/`.
- **Saves:** `SAVE_VERSION` is 8, so older saves start a fresh winter.
- **No bag (agreed 2026-10-20, after the handover above):** what Meagan gathers goes straight into the Stockpile ("+N" at the spot, the icon flies into the top bar); a full pile stops her with a "Stockpile full" tag; build pads and gates pay from the Stockpile while she stands on them. Following ChatGPT's review, the user chose to have each resource fly as an icon out of its top-bar counter (which pulses) to the building or gate, with a short cream trail, rather than fall from the sky. The Sled Shed is out of the game for now (its plot is gone; `SAVE_VERSION` 8). The sled gear now raises her gathering speed and the Big bag boon became Quick builds. The fuel and store hints are gone. Screens and both ChatGPT reviews: `source_art/direction/no_bag/`.

**Also done this session:**
- **The asset pipeline:** the `asset-pipeline` skill, `tools/blender/cleanup.py` (`cleanup()` for static models, `cleanup_character()` for rigged ones), `tools/blender/rig_names.py` (Meshy → Mixamo bone names; Meshy's spine runs the other way round), `chatgpt.py image --for-3d` and `tests/test_assets.gd`.
- **Ink-style Meshy models** in the game: the furnace, Meagan (9k triangles) and the Jan (5k triangles, because up to 20 are on screen). The Tripo sources are kept as `source_art/blender/*_tripo.blend`.
- **Git LFS** for every binary from commit `bc6dbcb` on. History wasn't rewritten, and a clone needs git-lfs.
- **The Blender MCP addon** is up to date (protocol 14).
- **Meshy credits:** about 2,985 left, refreshing on 2026-11-20.

**Waiting on the user:**
- **Sign off the `[proto]` numbers** (listed under Open questions → Roguelite world):
  - tile size 20 m;
  - small-furnace drain 0.15 heat/s;
  - gate costs;
  - 3 Jans per producer;
  - tile odds;
  - the boon and gear lists and values;
  - and the older ones in `balance.gd`.
- **The meta brainstorm:** what carries over between runs (content unlocks plus a currency, maybe tokens from defeated enemies). The brief's Prestige section is on hold until then.
- **Models** for the small furnace, chests, dens and other buildings, through the `asset-pipeline` skill. Meshy costs credits, so ask before each paid call.
- **A real-phone performance check,** now with many open tiles.

**Next, in order (pick with the user):**
1. **The meta brainstorm,** then write it into the brief and build it.
2. **Review items for the world** (`source_art/direction/world_tiles/review.md`):
   - the gate as one platform with its cost above it;
   - a ring-to-furnace animation when a tile opens;
   - a pulse on the heat bar when the drain rises;
   - a small-furnace model that echoes the main furnace.
3. **Models:** the small furnace, chests, dens, and the remaining buildings from `source_art/concept/ink/`.
4. **Balance play-through:** a full run from a fresh winter, to see whether the drain from small furnaces against Wood income feels strategic.

**Gotchas:**
- **The class cache.** After adding a `class_name` file:
  - run `godot --headless --path . --import`;
  - in the editor, call `EditorInterface.get_resource_filesystem().update_file("res://…")` via `swallowtail editor run_script`;
  - then run `swallowtail editor reload`.
  - Without the editor step, the open editor's play stops at "Identifier not found". The editor's error list keeps old errors, so judge by the game itself.
- **Headless tests have no autoloads.** Views that tests load (`SiteView`, `NodeView`) take the `GameState` as a parameter, not `Game.engine.state`.
- **Driving the game from Swallowtail:**
  - `runtime eval` only runs single-line code;
  - `WorldRules.open_tile(Game.engine.state, 0, Game.engine._events)` opens tiles fast for testing;
  - the camera zoom is the rig's `_zoom`.
- **Long Python edits from Bash:** heredocs over about 130 lines break, so write the script to the scratchpad and run it. Keep `newline='\n'` / LF.
- **Ink-painted meshes** use `ShaderMaterial`s (`ink_toon`, `ink_toon_fade`). The warm wash now takes the main furnace plus up to 16 small furnaces (`warm_spots`).
- **Blender's glTF exporter** needs `use_active_scene=True` and `use_active_collection=True`. `cleanup.py` saves only its own scene to `.blend` (`bpy.data.libraries.write`). Revert Blender to `trees.blend` after scratch work.
- **Blender MCP updates:** `PYTHONIOENCODING=utf-8 UV_SYSTEM_CERTS=true uvx mcp-for-blender@latest update`, then restart Blender.

## Felt wrong while playing

_(nothing logged yet)_

## Prototype play checklist (2026-10-19)

Press Play in the editor (F5), or run `godot --path .`. The window is 540×960, and the mouse stands in for a finger.

**Map and walking**
- [ ] Drag anywhere: a joystick ring appears and Meagan runs that way; let go and she stops. The camera stays on her. She can't leave the snowfield.
- [ ] A short click on a building, resource spot or frozen Jan sends her there.
- [ ] Forest: "+5" pops at the tree about once a second and a log icon flies up into the top bar's Wood number. Nothing stacks on her back. With Wood at its cap she stops, shrugs and a red "Stockpile full" shows over her.
- [ ] With the Stockpile stocked, a build pad or gate takes what it needs while she stands on it, and each piece flies as an icon (with a short trail) out of its number in the top bar onto it, the number pulsing as it leaves; the furnace keeps burning from the Stockpile's Wood by itself.
- [ ] Stop on a plot's pad: its sheet opens; run off and it closes. While building, the pad's ring fills as she stands on it, and nothing is paid off the pad.
- [ ] The scrap heap behind the furnace gives Materials. There is no Sled Shed for now.
- [ ] Tap a "+" plot → build sheet → pick one → construction site → walk near it with the resources → built (bounce).
- [ ] Tap a building → Upgrade, and −/+ for its Jans.

**Jans**
- [ ] A frozen Jan appears at the map edge after 5 s, then about once a minute. Tap → she walks out → he thaws, says a line, walks to work.
- [ ] Workers' output goes into the Stockpile (its label and heaps grow).
- [ ] At the Jan cap, "No room!" shows and he stays frozen.
- [ ] Idle chatter bubbles every 20–30 s.

**Animations** (2026-10-19)
- [ ] Forest: she walks beside a tree and swings the axe flat into it; chips and snow fly, the tree shakes, and when the stock drops a step a tree topples, leaving a stump.
- [ ] Fishing pond: She crouches at a hole with a rod and bobber; every few seconds a fish splashes out and "+3" pops.
- [ ] Scrap heap: pickaxe strikes with sparks. Construction: hammering with dust while pieces fly in from the top bar.
- [ ] A frozen Jan: she rubs her hands and blows warm breath; the ice shatters. Stockpile full: a shrug and "Stockpile full".
- [ ] Jans chop at stumps, fish at ice holes and hammer at anvils in front of their building, shiver and slow down when it's cold, and warm their hands when the Stockpile is full of what they make. Guards thrust spears; wolves flash white when hit.

**Sound** (2026-10-19)
- [ ] Music loops without a gap; Music and Sound buttons (top right) mute each and stay muted after a restart.
- [ ] Chop, pickaxe, splash, hammer and axe-on-wolf sounds land on the hit; a pop with each "+N"; a thud as each piece lands on a pad; footsteps crunch.
- [ ] Build complete jingle, thaw sparkle, wolves howl, raid crash, blizzard horn; in a blizzard the music muffles and wind rises.
- [ ] Jans' work sounds are quieter and fade with distance.

**Pressure** (use the DEV panel: Furnace +1, Wolves, Blizzard)
- [ ] Blizzard: warning banner, forecast countdown, heavier snow and fog, drain ×3, then an all-clear banner.
- [ ] Wolves: banner, wolves with health bars head for the furnace, detour to working Jans, guards (Barracks job) and Meagan fight them, kills drop loot.
- [ ] Meagan injured: she lies down and can't move until the attack ends.

**Meagan's model (2026-10-19)**
- [ ] She's the ink-style Meshy model (2026-10-20), 20% larger than life. She walks with swinging arms and legs, chops with the axe in her hands, crouches to fish, hammers, hugs a crate, swings at wolves and lies down when hurt.
- [ ] Her stack sits on her back (at most 8 pieces), below her head.
- [ ] Jans are the ink-style Meshy Jan model (5k triangles; the 165 FPS figure below was measured with the old 5k Tripo Jan). They chop, fish and hammer either side of their building's pad, which stays clear for Meagan. Frozen Jans hug themselves inside a taller ice block. With 20 Jans and 3 wolves it ran at 165 FPS on desktop (155k triangles).

**The wolf model (2026-10-19)** (DEV → Wolves)
- [ ] Wolves are the Tripo wolf, about Meagan's length. They trot with diagonal leg pairs and a wagging tail, facing where they run.
- [ ] Fighting: tail up, a crouch, a lunge forward with the front paws out, then back, about once a second. When hit, the whole wolf flashes white for a moment and hops back a little.
- [ ] The health bar sits above the head and doesn't hide the ears.

**Save and continue (2026-10-20)**
- [ ] Play a minute (build something, rescue a Jan), close the window, start again: the winter continues where it was, with the same Jans, buildings, Stockpile and timers.
- [ ] Let the fire go out, close and reopen: the game-over card shows again. Play again starts a fresh winter, and reopening after that starts fresh too.

**First-minute hints (2026-10-20)** (to see them again, delete the `[hints]` section of `user://settings.cfg`)
- [ ] A fresh profile shows "Drag anywhere to move", then "Chop Wood for the Stockpile" with an arrow to the nearest forest, "Tap the frozen Jan" (arrow to him) and "Open new ground at a stone ring", each until it's done.
- [ ] Off-screen targets get an arrow on the screen edge; on-screen ones a bobbing arrow above them. The line moves up when a sheet opens, and dragging on it still steers Meagan.
- [ ] Once all four are done they never come back, not after Play again or a restart.

**Zoom (2026-10-20)**
- [ ] The mouse wheel zooms in and out in steps, smoothly, between a close view and a wide one (16 to 34 m tall; it starts at 22).
- [ ] On a phone: two fingers pinch to zoom. While pinching, Meagan doesn't move and the joystick doesn't show; one finger still steers as before.

**One readout above Meagan (2026-10-20, no bag)**
- [ ] Only when the Stockpile is full of what she's gathering: a small dark pill with a red "Stockpile full" and the resource's icon pops up over her head. It's the same size at any zoom and follows her smoothly.
- [ ] The spot she's gathering at hides its own "Materials 12" label until she walks off.

**Smaller nameplates (2026-10-20)**
- [ ] Buildings show a small two-line nameplate (name, then "Lv 2") above the roof, never wider than the building, also at Lv 10.
- [ ] The furnace's fuel is in its sheet. Tapping the Stockpile, or stopping on its pad, opens a sheet with Wood, Food and Materials against their caps.

**Fading trees and buildings over Meagan (2026-10-20)**
- [ ] Walk into a forest: any tree between the camera and her fades to a see-through ghost (and drops its shadow) while she's behind it, then comes back when she steps out.
- [ ] The same for a building she walks behind. The FPS doesn't change.

**Wolves spread round their target (2026-10-20)** (DEV → Wolves, then stand in their way)
- [ ] Wolves fighting Meagan or a guard stop just outside them and fan out a wolf's length apart, facing their foe, instead of piling onto one spot. Their lunges are out of step.
- [ ] A pack still meets her together; no wolf slips past to the furnace because of the spreading.

**Building-complete juice (2026-10-20)** (DEV → Furnace +1, or finish any building)
- [ ] A building that finishes or levels up bounces, shoots coloured confetti from its roof with a snow puff at its base, and the camera gives a short shake. "Lumber Yard Lv 2!" pops in big above the roof and floats away, while the nameplate steps aside for a second.
- [ ] The furnace levelling up flares twice as hard, shakes harder, and sends a soft ring of warm light out across the ground. FPS stays high.

**Phone UI audit (2026-10-20)**
- [ ] Music, Sound and DEV sit in a row under the top bar without touching, each a comfortable thumb size; the DEV panel opens below them.
- [ ] Every button (sheet buttons, Close, −/+, build list) is at least 120 px tall at 1080 wide.

**Kitchen (2026-10-20)**
- [ ] At Furnace Lv 2 the build list offers a Kitchen (40 Wood + 5 Materials). Built, it has cream walls, an orange roof, a big cooking pot by the door and a chimney that puffs steam.
- [ ] Its sheet says how much each Jan eats a minute, 5% less per level. With a Kitchen the Food lasts longer.

**Watchtower (2026-10-20)** (DEV → Furnace +1 three times)
- [ ] At Furnace Lv 4 a Watchtower can be built (120 Wood + 30 Materials): a hut with a tall lookout, a cone roof and a red flag.
- [ ] With it, a wolf attack is announced 15 s ahead per level ("The Watchtower spots wolves coming!", then "Wolves in 0:29" in the forecast), and blizzards a minute sooner per level. Without one, wolves still come unannounced.

**Hot Springs (2026-10-20)** (DEV → Furnace +1 six times)
- [ ] At Furnace Lv 7, Hot Springs can be built (120 Wood + 30 Materials): a bath house with a steaming turquoise pool ringed with pale stones beside it.
- [ ] Each level lowers the heat drain by 10% (Lv 5 halves it); its sheet shows the cut and the drain now. The −/s in the top bar drops when it's built.

**Jans screen (2026-10-20)**
- [ ] The Jans button (row under the top bar) opens a sheet: idle Jans in amber, then one row per job with its Jans and output and −/+ to move Jans; jobs without their building say what to build. Food at the bottom: net per second, fished and eaten, red when eating outpaces fishing.
- [ ] Tapping −/+ changes the job counts at once (and Meagan doesn't move); the Jans button again closes it.

**Milestones (2026-10-20)** (to see them again, delete `[milestones]` from `user://settings.cfg`)
- [ ] The first rescue, Furnace Lv 2, five Jans, the first Storehouse/Workshop, the first blizzard survived, the first attack repelled… each pops a card under the button row for 3 s with a chime, one after another, never over a warning banner.
- [ ] They never show twice, not after Play again or a restart.

**Auto-assign (2026-10-20)** (DEV → Furnace +1 three times)
- [ ] At the bottom of the Jans screen: greyed "Auto-assign unlocks at Furnace Lv 4" before, then a switch. On (green), idle Jans go to work and every 5 s at most one Jan moves towards the job shares, then it settles. Guards are left alone.
- [ ] Tapping any −/+ by hand turns it off.

**Objective: keep the fire burning**
- [ ] A winter starts at 100/100 heat. With no Wood it lasts about 2½ minutes.
- [ ] Below 25%: the bar pulses red, banner and horn. Below 10%: "Fire out in 0:12" on the bar.
- [ ] At 0: music muffles, the card shows your time, best time and stats; Play again starts a fresh winter.

## Open questions

- **Roguelite world (agreed 2026-10-20, being built in phases):** the plan is in the brief's **Areas, small furnaces & treasures** section. These numbers are `[proto]` and need your sign-off:
  - tile size 20 m;
  - small-furnace drain 0.15 heat/s;
  - gate cost (Wood 40 × 1.6^(d−1), Materials from d = 2);
  - 3 Jans per producer;
  - tile odds: camp 35%, chest 30%, wolf den 20% from d = 3.
  - **Tiles and gates are in (Phase 3, greybox).** ChatGPT's review (`source_art/direction/world_tiles/review.md`) still wants:
    - the gate to read as one platform, with the cost above it;
    - a short animation of the stone ring becoming the small furnace and the closed tile lowering;
    - a pulse to the heat bar when the drain rises;
    - a picture-book small-furnace model that echoes the main one (a Meshy job, about 30 credits);
    - an "open an area" hint.
  - **Chests are in (Phase 5, greybox).** They are caches, boon chests (2 or 3 to choose from) and gear (axe, boots, sled). The boon and gear lists and their numbers are `[proto]` in `balance.gd`. Screens are in `source_art/direction/treasures/`.
  - **Camps, the frontier and dens are in (Phase 6).** All six phases of the plan are built. What's left is the meta brainstorm below, the review items above, and models for the small furnace, chests and dens.
  - Still to design together: what carries over between runs (content unlocks plus a currency, maybe tokens from defeated enemies), and the boon and gear lists.
- **Numbers marked `[proto]` in `scripts/engine/balance.gd`** need your sign-off: walk 6 m/s, build pad 1.4 m, low-heat warning 25% (clears at 40%) and countdown 10%, furnace feed from the Stockpile 5 Wood/s, gather range 3 m, rescue range 2 m, sled gear +10/20/30% gathering, the Quick builds boon (+50% pad paying speed), first Jan after 5 s, wolf detour 7 m, guard ring 4 m.
- **Guards are weak:** by the brief, without kits they deal half damage (1.5/s), so 2 guards struggle against 3 wolves. Kits and gear aren't in the prototype yet.
- **Trees:** done (2026-10-20): three low-poly Blender pines replace the greybox cones.
- **ChatGPT feedback on the Jans (not done yet):**
  - World labels are wider than the buildings: use smaller nameplates, with level and upgrade in the tap panel.
  - Simplify the Jan texture into three colour blocks for phone size; this needs a Tripo or texture pass.
  - Lighter roofs and softer building shadows.
- **ChatGPT feedback on Meagan (not done yet):**
  - Merge the stacked labels above her (node stock, "12/20", "12 Wood") into one readout.
  - Make the HUD panel about 25% shorter, with the bag second after heat.
  - Move Music and Sound into a settings button.
  - Fade tree canopies that hide her while she works.
  - Zoom (backlog item 3) will help most.
- **ChatGPT feedback on the wolf (not done yet):**
  - From the game camera they're narrow; a model pass could widen the torso and head by about 20%, enlarge the ears and thicken the tail, and simplify the neck's jagged plates into two or three fur masses.
  - Wolves pile onto Meagan and each other; give attackers separate slots around their target (engine, `combat.gd`).
  - Land the damage on the lunge's contact moment rather than as steady damage per second.
- **Art direction (2026-10-20):** three rounds of mock-ups are in `source_art/direction/board.html`.
  - The user prefers round 3's **ink and watercolour** picture-book style, with the Jans moved off rust-orange so Meagan's red stands out. The town motifs (mittens, crooked sun, furnace-mouth mark) are in.
  - An in-engine test (DEV → Ink look) shows the shader stack works and is cheap. On today's assets it reads as "filtered 3D", so the look mostly depends on new assets:
    - watercolour-painted Tripo textures
    - redesigned characters
    - a painted ground
  - **Decided (2026-10-20, after the AFK run):** the game commits to it. The rules are in `docs/art-direction.md`.
  - **Done the same day:**
    - The ink look is on by default.
    - A painted ground.
    - Jans in deep teal.
    - Watercolour icons.
    - Low-poly pines.
    - Meagan's green bar and red silhouette.
    - Bubbles on screen, game-over tiles and the milestone chime.
    - New Tripo references in `source_art/concept/ink/`.
    - The first picture against the latest: `source_art/direction/before_after.png`.
  - **Still open from the reviews:**
    - The buildings, furnace and empty plots are still greybox; they should be remade from the new references.
    - The pale square empty plots read like UI.
    - Bubbles can still sit under the top buttons.
    - Small-size versions of the icons.
    - "Make the warm disc a gameplay boundary": the disc is only a picture of the heat.
- **Score:** the game-over card scores minutes:seconds survived. Would "days survived" (e.g. one day = 2 minutes) feel better?
- **Art direction:** the Poly Haven props are photoreal, while the brief wants chunky cartoon. Decide whether to keep them as placeholders or go straight to Tripo models.

## Next steps (pick with the user)

- Rewrite the brief's Tech & build plan and Art & assets sections for Godot, plus a new phase list.
- Saving (local file, export/import code), then the Build/Jans/Collection screens.
- Remaining buildings, Research, caravans, Jan variants, milestones, prestige.
- Tripo models for Meagan, Jans, wolves and buildings; ElevenLabs music and sound to replace the synthesized placeholders (needs an API key).
- Test framework: GUT or gdUnit4.
- Git hosting: create `Jazzwec/Frostbite2` on GitHub when there's something to share; Git LFS if model and audio files get large.

## Setup still missing

- Godot 4.7.2 export templates, needed for a standalone Windows build. Not needed for playing from the editor.
- Android and iOS export: deliberately left until the port (iOS needs a Mac).
