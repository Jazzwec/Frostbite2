# NOTES

What felt wrong while playing, and what's still open. This file is the prompt for the next session.

## Handover (end of session, 2026-10-20)

**Where things stand.** Frostbite2 is a playable hypercasual prototype in the agreed **ink & watercolour** style. Everything is committed and pushed to `Jazzwec/Frostbite2` (last commit `138d0ea`), and the 91 tests pass. `CLAUDE.md` describes the architecture; `docs/art-direction.md` is the art rulebook (pillars, palette, characters, the prompt template).
- **Game:** a drag joystick, the carry stack, the Stockpile, build pads, the furnace objective with a game-over card, blizzards, wolves, save and continue, first-minute hints, milestones, auto-assign, the Jans screen, zoom (16–34 m) and synthesized audio.
- **The look (on by default; DEV → Ink look, or `-- --no-ink`, to compare):** banded watercolour light, wobbly ink lines, a paper pass, and a warm wash round the furnace that shrinks with the heat. The snowfield is painted (`ink_ground`), with paths to every pad.
- **Assets:**
  - Meagan, the Jan (recoloured to deep teal #35666B) and the wolf are Tripo models cleaned up in Blender.
  - Three low-poly Blender pines make the forests.
  - Watercolour icons are in `assets/ui/icons/`.
  - The furnace is a Meshy model (meshy-6, 45 credits for the pilot), made through the new **asset pipeline**: the `asset-pipeline` skill, `tools/blender/cleanup.py`, `chatgpt.py image --for-3d` and `tests/test_assets.gd`. The other buildings are still greybox shapes in code.
- **UI from the last pass:** Meagan's green health bar (the guards' are blue), her red silhouette through whatever hides her, one Jan bubble at a time kept on screen, the game-over stat tiles and the milestone chime.
- **Before and after:** `source_art/direction/before_after.png`.

**Waiting on the user:**
- **Try the zoom range** (16–34 m) and sign off the `[proto]` numbers in `balance.gd`.
- **A real-phone performance check.** On desktop the busy scene runs at about 400 FPS with the ink look on.
- **`assets/models/tripo/Meagan.glb`** has an uncommitted change by the user. Leave it alone: don't stage or process it until they say so.
- **The open review items** below (under Open questions → Art direction): greybox buildings and plots, bubbles under the top buttons, small icon sizes, and whether the warm disc becomes a gameplay rule.

**Next, in order:**
1. **Building and character models from the ink references** in `source_art/concept/ink/` (Meagan, a Jan, the Bunkhouse, the Lumber Yard; the furnace is done), following the `asset-pipeline` skill.
   - The furnace's ChatGPT review (`source_art/direction/furnace_meshy/review.md`) says its fire mouth reads flat and its stonework is busy and muddy. Options: a simpler reference (fewer, larger stones, broad washes), a `meshy_retexture` (10 credits), or a brighter animated glow in `SiteView`.
   - Meshy characters work with `ModelRig` after `cleanup_character` renames their bones (checked 2026-10-20). A Meshy Jan is made and rigged (`assets/models/meshy/jan_meshy6_rigged.glb`), closer to the ink reference than the Tripo Jan; **ask the user** whether it replaces `jan.glb`.
   - Either the user makes them in Tripo Studio and drops the files in, or they're made with **Meshy** (below), which spends credits.
   - Buildings need no rig; they replace the greybox parts in `SiteView`, keeping the fire light, embers and pad.
2. **The rest of `BACKLOG.md`.** It can also run as an AFK `/loop` (see `AFK.md`).

**Meshy (new, 2026-10-20).** The user installed the Meshy MCP server (`meshy-mcp-server`, user scope, npm `@meshy-ai/meshy-mcp-server` 0.6.4, key in its env).
- **It loads from the next session on.** It was tested by hand and has 28 tools: image/multi-image/text to 3D, retexture, remesh, rig, animate, convert and resize.
- **Credits:** the balance was 3,100 monthly credits, refreshing on 2026-11-20.
- **It costs real credits:** say the cost and ask before every paid call. `meshy_check_balance`, `meshy_list_tasks`, `meshy_list_models` and `meshy_list_animations` are free.
- **Output** goes through the same Blender cleanup as the Tripo models (decimate, 1024 texture, metres, export the active scene only).

**Gotchas:**
- **The class cache.** After adding a `class_name` file, run `godot --headless --path . --import` and `swallowtail editor reload`. If the game still stops at "Identifier not found", call `EditorInterface.get_resource_filesystem().update_file("res://…")` via `swallowtail editor run_script` (details are in CLAUDE.md).
- **Headless tests have no autoloads.** Pure helpers go in classes that don't touch `Game`, `Audio` or `UiTheme` (e.g. `CameraRig.keep_on_screen`, `HpBar`, `FadeCover`).
- **Ink-painted meshes** use `ShaderMaterial`s (`ink_toon`, with `ink_toon_fade` for fading). Code that recolours or fades materials must handle them as well as `StandardMaterial3D`.
- **Swallowtail input:** `swallowtail input click` uses viewport coordinates (1080×1920); `Input.parse_input_event` in `runtime eval` uses window coordinates (540×960). Drive it from Bash, not PowerShell.
- **Blender's glTF exporter** needs `use_active_scene=True` and `use_active_collection=True`. Keep each model in its own `FB2_<Name>` scene.
- **Writing files from Python on Windows:** use `newline='
'`.
- **Big Python edits:** write them to a script file with the Write tool, not a bash heredoc.
- **`user://settings.cfg`** should be `[audio] music=false sfx=true` after tests. Delete `user://save.json` and any `[hints]`/`[milestones]` test values.
- **ChatGPT budget this session:** 8 images and 6 reviews through the Codex CLI. These are free on the user's plan, but keep batches modest.

## Felt wrong while playing

_(nothing logged yet)_

## Prototype play checklist (2026-10-19)

Press Play in the editor (F5), or run `godot --path .`. The window is 540×960, and the mouse stands in for a finger.

**Map and walking**
- [ ] Drag anywhere: a joystick ring appears and Meagan runs that way; let go and she stops. The camera stays on her. She can't leave the snowfield.
- [ ] A short click on a building, resource spot or frozen Jan sends her there.
- [ ] Forest: logs stack on her back with "+2" pops; the counter reads 12/20, then a red MAX. Furnace: logs fly off her stack one by one into the fire, which flares.
- [ ] Stockpile (green pad right of the furnace): stand on it with a full bag of anything; pieces fly into the pile, the bag empties and the heaps and label grow. With the Stockpile stocked, a build pad pays itself while she stands on it, with pieces flying over from the pile; the furnace keeps burning from the Stockpile's Wood.
- [ ] Stop on a plot's pad: its sheet opens; run off and it closes. While building, the pad's ring fills as she stands on it, and nothing is paid off the pad.
- [ ] The scrap heap behind the furnace gives Materials; the Sled Shed (30 Wood) raises the bag limit.
- [ ] Tap a "+" plot → build sheet → pick one → construction site → walk near it with the resources → built (bounce).
- [ ] Tap a building → Upgrade, and −/+ for its Jans.

**Jans**
- [ ] A frozen Jan appears at the map edge after 5 s, then about once a minute. Tap → she walks out → he thaws, says a line, walks to work.
- [ ] Workers' output goes into the Stockpile (its label and heaps grow).
- [ ] At the Jan cap, "No room!" shows and he stays frozen.
- [ ] Idle chatter bubbles every 20–30 s.

**Animations** (2026-10-19)
- [ ] Forest: she walks beside a tree and swings the axe flat into it; chips and snow fly, the tree shakes, and when the stock drops a step a tree topples, leaving a stump.
- [ ] Fishing pond: She crouches at a hole with a rod and bobber; every few seconds a fish splashes out into her bag.
- [ ] Scrap heap: pickaxe strikes with sparks. Furnace: she tosses logs in and the fire flares. Construction: hammering with dust. Piles: she hugs a box and items fly to or from her bag.
- [ ] A frozen Jan: she rubs her hands and blows warm breath; the ice shatters. Bag full: a shrug and "Bag full!".
- [ ] Jans chop at stumps, fish at ice holes and hammer at anvils in front of their building, shiver and slow down when it's cold, and warm their hands when the Stockpile is full of what they make. Guards thrust spears; wolves flash white when hit.

**Sound** (2026-10-19)
- [ ] Music loops without a gap; Music and Sound buttons (top right) mute each and stay muted after a restart.
- [ ] Chop, pickaxe, splash, hammer and axe-on-wolf sounds land on the hit; pops climb in pitch as her stack grows; whoosh and thud as pieces fly into the Stockpile or a pad; fire whoomph at the furnace; footsteps crunch.
- [ ] Build complete jingle, thaw sparkle, wolves howl, raid crash, blizzard horn; in a blizzard the music muffles and wind rises.
- [ ] Jans' work sounds are quieter and fade with distance.

**Pressure** (use the DEV panel: Furnace +1, Wolves, Blizzard)
- [ ] Blizzard: warning banner, forecast countdown, heavier snow and fog, drain ×3, then an all-clear banner.
- [ ] Wolves: banner, wolves with health bars head for the furnace, detour to working Jans, guards (Barracks job) and Meagan fight them, kills drop loot.
- [ ] Meagan injured: she lies down and can't move until the attack ends.

**Meagan's model (2026-10-19)**
- [ ] She's the textured Tripo model, 20% larger than life. She walks with swinging arms and legs, chops with the axe in her hands, crouches to fish, hammers, hugs a crate, swings at wolves and lies down when hurt.
- [ ] Her stack sits on her back (at most 8 pieces), below her head.
- [ ] Jans are the Tripo Jan model. They chop, fish and hammer either side of their building's pad, which stays clear for Meagan. Frozen Jans hug themselves inside a taller ice block. With 20 Jans and 3 wolves it ran at 165 FPS on desktop (155k triangles).

**The wolf model (2026-10-19)** (DEV → Wolves)
- [ ] Wolves are the Tripo wolf, about Meagan's length. They trot with diagonal leg pairs and a wagging tail, facing where they run.
- [ ] Fighting: tail up, a crouch, a lunge forward with the front paws out, then back, about once a second. When hit, the whole wolf flashes white for a moment and hops back a little.
- [ ] The health bar sits above the head and doesn't hide the ears.

**Save and continue (2026-10-20)**
- [ ] Play a minute (build something, rescue a Jan), close the window, start again: the winter continues where it was, with the same Jans, buildings, bag and timers.
- [ ] Let the fire go out, close and reopen: the game-over card shows again. Play again starts a fresh winter, and reopening after that starts fresh too.

**First-minute hints (2026-10-20)** (to see them again, delete the `[hints]` section of `user://settings.cfg`)
- [ ] A fresh profile shows "Drag anywhere to move", then "Chop Wood" with an arrow to the nearest forest, "Bring Wood to the furnace", "Tap the frozen Jan" (arrow to him) and "Drop extras at the Stockpile", each until it's done.
- [ ] Off-screen targets get an arrow on the screen edge; on-screen ones a bobbing arrow above them. The line moves up when a sheet opens, and dragging on it still steers Meagan.
- [ ] Once all five are done they never come back, not after Play again or a restart.

**Zoom (2026-10-20)**
- [ ] The mouse wheel zooms in and out in steps, smoothly, between a close view and a wide one (16 to 34 m tall; it starts at 22).
- [ ] On a phone: two fingers pinch to zoom. While pinching, Meagan doesn't move and the joystick doesn't show; one finger still steers as before.

**One readout above Meagan (2026-10-20)**
- [ ] With anything in her bag, one small dark pill floats above her load: "14/20" with "9 Wood · 5 Mat" under it. It's the same size at any zoom and follows her smoothly.
- [ ] When the bag fills it turns into a red "MAX" with a little pop. The spot she's gathering at hides its own "Materials 12" label until she walks off.

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
- [ ] The first rescue, Furnace Lv 2, five Jans, the first Sled Shed/Storehouse/Workshop, the first blizzard survived, the first attack repelled… each pops a card under the button row for 3 s with a chime, one after another, never over a warning banner.
- [ ] They never show twice, not after Play again or a restart.

**Auto-assign (2026-10-20)** (DEV → Furnace +1 three times)
- [ ] At the bottom of the Jans screen: greyed "Auto-assign unlocks at Furnace Lv 4" before, then a switch. On (green), idle Jans go to work and every 5 s at most one Jan moves towards the job shares, then it settles. Guards are left alone.
- [ ] Tapping any −/+ by hand turns it off.

**Objective: keep the fire burning**
- [ ] A winter starts at 100/100 heat. With no Wood it lasts about 2½ minutes.
- [ ] Below 25%: the bar pulses red, banner and horn. Below 10%: "Fire out in 0:12" on the bar.
- [ ] At 0: music muffles, the card shows your time, best time and stats; Play again starts a fresh winter.

## Open questions

- **Numbers marked `[proto]` in `scripts/engine/balance.gd`** need your sign-off: walk 6 m/s, build pad 1.4 m, low-heat warning 25% (clears at 40%) and countdown 10%, furnace feed from the Stockpile 5 Wood/s, gather range 3 m, building reach 4.5 m, rescue range 2 m, first Jan after 5 s, wolf detour 7 m, guard ring 4 m.
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
