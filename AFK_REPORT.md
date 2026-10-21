# AFK_REPORT.md

What happened during unattended runs, newest run first. Each run starts with a heading giving the start time and the deadline. Each item gets:
- the commits
- what to check in the game
- any new `[proto]` numbers
- anything that felt wrong

A "Needs you" list goes at the end.

## Run 2026-10-21, 07:54 → 10:00 (Fight v2 follow-ups)

### F1. Wave balance report
- **What:** `docs/balance/fight_v2_sims.md`, which covers:
  - the four Armory plans out to wave 20;
  - time-to-kill per kind at every Armory level (sweeps, snowballs, guard strikes, counters);
  - when guards and Meagan fall;
  - a row for every fight `[proto]` number.

  `tests/sim_waves.gd` now prints it as Markdown, and `WaveSim` counts the extra columns. No balance number changed. Tests: 178 passed.
- **Check:** read the report's "What it says".
- **Felt wrong:**
  - Past the spending cap (wave 12+), enemy HP keeps growing ×1.2 a wave, and nothing on the player's side grows after Armory 10. So even on schedule, wave 18 (about 32:00) loses 100 and wave 19 loses 223. Every winter ends there whatever she buys.
  - The Armory sheet's "a wolf in N sweeps" counts a strength-1 wolf, which understates it from wave 13.

## Run 2026-10-20, 20:15 → done (animation polish)

The task: Astra's review of the animations, best practices from the web, then polish. Frame strips of every clip were captured at quarter speed (`source_art/direction/anim_v1/`), and Astra reviewed them (`review.md`). Two of its lowest scores (Jan fishing and chopping, Meagan storing) were my capture's fault, not the game's: the camera followed the wrong Jan, and Meagan was still walking. Its real findings are backlog items N1–N7.

ChatGPT budget: counted from `tools/chatgpt/calls.log` line 152 onwards.

### N1. Wolves that read
- **What changed:**
  - **Spacing:** wolves closer than 1 m are drawn apart in the view, so a pack never reads as one dark mass. A fighting wolf stands back half a body, so its snout, not its middle, is at the fight distance.
  - **Rhythm:** each wolf's trot starts at its own phase.
  - **The attack:** a 0.25 s crouch with a 12° lean back (anticipation), a 0.1 s lunge, a 0.05 s (3-frame) hold at the bite, then a 0.22 s recovery.
- **Why only the view:** moving the pack apart in the engine pushed a wolf out of a fight and changed gameplay, which an existing test caught, so the engine is unchanged.
- **Check in the game:** DEV → Wolves, then watch them come in and fight Meagan.

### N2. Jans don't merge
- **What changed:**
  - Each hauler drops his load at his own spot in a row along the stockpile's front, 0.75 m apart: 5 spots at the main stockpile, 3 at a small one.
  - Stockpiles now have an obstacle body, so Jans and Meagan walk round them instead of across the deck (the navmesh bakes round it).
- **Check in the game:** several Jans delivering at once.

### N3, N5 and N7 (first part). Impacts, fishing and overlays
- **Impacts with weight (N3):** every blow (chop, scavenge, hammer, Meagan's and the guards' strikes) holds the clip still for 0.05 s (3 frames of hit-stop) and squashes the character 5% down and out, springing back over 0.09 s with volume kept. This is in `CharacterRig`, so Meagan and every Jan get it. Off-screen rigs skip it.
- **Fishing that reads (N5):**
  - The float bobs gently (about a second a cycle) and dips at the bite.
  - The rod lift and lean back at the bite were already in the clip.
  - There's one "+N" per blow or catch, for what she gathered since the last one, beside the spot rather than over her. Her stack no longer pops a number per piece.
- **Overlays (N7):**
  - The bag readout is about 25% smaller and sits a little higher.
  - "Wolves raided the furnace!" floats higher over the furnace, as a pop, clear of the fight.
- **Check in the game:** chop and fish, and watch the "+N" and the small squash on each blow.

### N4 and N6. A walk with weight; unloading and paying that read
- **Walk (N4):**
  - With her bag over 60% full she walks with a heavier `walk_loaded` clip: 0.72 s a stride, leaning 9° into the load, ±21° legs, less bounce, and arms swinging less.
  - Her stack sits snug against her back (it stood 0.5 m behind her and looked detached in side view). It leans out of her turns and back as she sets off, a beat late (follow-through, up to about 7°).
- **Unloading and paying (N6):**
  - Each piece leaving her stack dips her body 5° (`CharacterRig.dip`).
  - Each one landing pulses the stockpile (6%) or knocks the building she's paying.
- **Check in the game:** walk with a full bag, then empty it at a stockpile and pay a pad.

### N8. From Astra's second review
The second review (`source_art/direction/anim_v1/review_2.md`) scored every clip up: walk 5→6, chop 5→6, fish 4→5, unload 3→4, haul 3→4, trot 5→6, fight 2→4, Jan chopping 5, Jan seated fishing 3.

- **Applied:**
  - **Splitting:** Jans split logs with an overhead `split` clip. They raise the axe over their head for 0.25 s, bring it down onto the middle of the stump in 0.1 s, then the hit-stop and recovery. Chips and sound come at the stump.
  - **Fishing:** the rod dips harder at the bite before the lift, for her and the Jans.
  - **Her stack:** lower (7 pieces at 0.72 scale, about head height) and sways at most 4°.
  - **Fights:** the stockpile label hides while wolves are about.
  - **A bug from V8:** the Jans' seated fishing clip had lost its splash, sound and thrown fish, because the impact handler only knew the old clip name.
- **Not done (bigger or design calls):**
  - one attacking wolf at a time, with the others waiting a body length back in lanes, and the victim recoiling;
  - each piece going back → hands → pile, with Meagan keeping the front delivery spot;
  - Jan's seated knees showing past his coat (the rig has no knees);
  - a shoulder strap on her stack;
  - showing her axe's contact patch on the trunk.

### Closing summary (20:46)
- **All items done:** N1–N8, one commit each (N3/N5/N7 and N4/N6 shared one), all pushed. Tests: 140, all passing.
- **ChatGPT:** 2 reviews (the first look and a second look).
- **Paid credits:** none.
- **`Meagan.glb`:** never staged.
- **Web sources for the best practices:**
  - skills.cat "animation-principles / game-development" (hit-stop of 2–5 frames, player-first response, follow-through, squash and stretch);
  - bugnet.io "animation basics that make your game feel alive";
  - Cornell CS3152 design lab (walk poses, secondary motion);
  - the Princeton/Adobe secondary-motion paper (Willett 2017).

## Run 2026-10-20, 19:27 → 22:00 (visual polish)

ChatGPT budget: counted from `tools/chatgpt/calls.log` line 145 onwards (8 images, 25 reviews).

### V1. Paper & ink HUD
- **What changed:**
  - `UiTheme` has the palette as named colours (ink, paper, Falu, ochre, teal, firelight).
  - **Cards:** every card (top bar, sheet, bag readout, hints, milestone and offer cards, game over) is cream paper with a thin deep-ink border and a soft 15% shadow, with ink text and Falu-red titles.
  - **Buttons:** main actions are faded teal with an ink outline and paper text, and sink when pressed. The utility row (Jans, Music, Sound, DEV) is a light wash with ink text. "Off" is an opaque muted fill, not faded.
  - **Banners:** washed in Falu red (warnings), cold blue (blizzards) or deep teal (good news).
  - **Heat bar:** a firelight fill, turning blue-shadow when cold, on a warm-grey track.
  - **Text:** the furnace's description is shorter. The dying-fire banner now says "Bring Wood to a Stockpile".
  - **Fix:** a "+0" pop no longer shows for a tiny Jan delivery.
- **Check in the game:** the top bar, a building's sheet, the Jans screen, the DEV panel, a blizzard banner, a milestone card, the game-over card.
- **ChatGPT feedback** (`source_art/direction/hud_v1/review.md`; before 3/10, after 6/10). Applied: ink numbers on the game-over card, the lighter utility buttons, an opaque "off", a visible heat track, the softer shadow, the shorter furnace text. Not done:
  - one banner at a time, with milestones, chatter and the bag readout held back while a banner shows (layout and behaviour);
  - bigger body text (about 42 px);
  - thinner world-label outlines.
- **Note:** the test played a winter to its game-over card and then started a new one, so your saved winter was reset.

### V2. Cosy watercolour icons
- **What changed:**
  - A new icon sheet on Astra (`source_art/icons/v2/sheet.png` and its prompt; 1 image), with the gameplay painting and the lineup as references: thin warm ink lines, loose washes, no sticker outline. All 13 icons, including the house, are on one sheet now.
  - `tools/chatgpt/cut_icons.py` cuts it into `assets/ui/icons/<name>.png` at 128 px, un-blends the white into transparency so the soft edges stay soft, and drops specks a neighbour spilled into a cell. The file names are the same, so no code changes.
  - The top bar's icons are a little bigger (52 px).
- **Check in the game:** the top bar, the bag readout, banners, the game-over card.
- **ChatGPT feedback** (`source_art/icons/v2/review.md`; old 6/10, new 7/10). Applied: no padding in the cut, bigger top-bar icons. Not done, because it needs another image round: simpler small-size versions of Fish, Materials and Wood (fewer speckles, a bigger gear hole), a stronger slate-blue wind curl with two snowflakes, and a bolder thermometer.

### V3. Softer snow and lines (the InkLook tweak you approved)
- **What changed** (the old values are noted in the shader comments):
  - **Ground snow:** slightly blue-grey and warmer. A new `snow_tint` and a darker `wash_mean` bring the open snow from an average of #D8E4F4 (too blue and bright) to #D8DFE8, near the review's #DEE5EB target. The hollows are deeper (`shadow_strength` 0.28 → 0.42).
  - **Snow caps:** a touch blue-grey (#E0E7EC).
  - **Lines:** silhouette lines 1.8 → 1.4 px, ink #4B5865 at 72% (was near-black at 82%), and weaker colour-edge lines (0.2 → 0.12). Lines take more of what they outline (`local_tint` 0.55 → 0.65).
- **FPS:** 165 before, 165 after.
- **Check in the game:** the open snow and the furnace glow at the default zoom and wide. DEV → Ink look still compares.
- **ChatGPT feedback** (`source_art/direction/ink_v5/review.md`). Applied: the snow and ink colours. Not done: a selective line treatment (breaking sunlit snow-rim lines while keeping undersides) and rounded snow-cap volume with a shaded lower band. Both need shader work beyond a tweak.

### V4. Hauled loads that read
- **What changed:**
  - **Loads:** Jans now carry three distinct loads held in front of the chest, about a third of their height (`Tools`: `bundle`, `basket`, `load_crate`, used by the `haul_*` clips):
    - a bundle of three logs tied with two ropes;
    - a honey wicker basket with two fish;
    - a banded crate.
  - **The drop:** at the stockpile a Jan pauses 0.35 s with a snow puff, then walks back empty-handed.
  - **Snow caps:** held tools and loads never get the ink look's snow caps. This also fixes a bug: InkLook ignored `no_snow` on `material_override` meshes (all Shapes). Meshes marked no-snow now get their own copy of the shared ink material, instead of switching snow off for every mesh of that colour.
- **FPS:** 165, unchanged.
- **Check in the game:** follow a Jan from his producer to the Stockpile.
- **ChatGPT feedback** (`source_art/direction/levels_v1/review_v4.md`). Applied: the honey-ochre wicker with a dark rim, the medium-brown bark with pale ends. Not done:
  - fish poking above the basket's sides;
  - a wider, waist-height carrying pose with elbows out;
  - a staged put-down (lower 0.15 s, release, 0.2 s);
  - checking the loads at the normal camera (my shots were close-ups).

### V5. Storing that reads as one action
- **What changed:**
  - Her bag's pieces fly into the stockpile with no "+N" each, and no icon to the top bar each.
  - 0.2 s after she finishes, one small summary ("+14 Wood · +6 Mat") shows over the stockpile, and one icon per resource flies to its top-bar number, which pulses.
  - The stockpile's label hides while she stores, and is back to just "Stockpile · Lv N".
  - `Fx.pop` takes a font size.
- **Check in the game:** empty a mixed bag at the Stockpile.
- **ChatGPT feedback** (`source_art/direction/hud_v1/review_v5.md`: "yes, it reads as one deposit"). Applied: the smaller summary, the shorter delay, the hidden label. Not done: pulsing each counter exactly when its icon lands (it pulses on arrival already).

### V6. Footsteps in the snow
- **What changed:**
  - `Footprints` (`scripts/game/footprints.gd`, shader `ink/footprint.gdshader`): a fixed pool of 120 flat prints sharing one material, each with an instance-uniform fade. They're soft blue-grey (#8798AD) boot shapes with a broken watercolour edge, crisp for 1 s, then melting away over 7 s.
  - Meagan and every walking Jan press one every 0.48 m, left and right 0.18 m apart, each turned a little.
  - Meagan's steps also kick up a 0.2 s snow puff (`Fx` "step").
- **Proto numbers:** `POOL` 120, `LIFE` 7 s, `STEP` 0.48 m, `FOOT_SIDE` 0.09 m, print 0.14 × 0.28 m.
- **FPS:** 165 with and without them.
- **Check in the game:** walk across open snow; watch Jans walk to work and haul.
- **ChatGPT feedback** (`source_art/direction/hud_v1/review_v6.md`): all three points applied (boot-like shape and size, colour and fade, rhythm and spacing).

### V7. Smoke and lantern glow
- **What changed:**
  - **Smoke** (`scripts/game/smoke.gd`): a soft blue-grey plume rises from the furnace's chimney, thicker as it burns harder (`burn_rate`) and thinning as the heat drops. A lighter one rises from each small furnace.
  - **Lanterns:** every lantern post has a faint warm halo at its lantern (measured on the mesh), with no new lights.
- **Gotcha:** GPU particles that are see-through with a colour ramp didn't draw at all in this setup, and see-through billboards come out far fainter than their alpha says. So the smoke is a dozen scripted billboard puffs that rise, drift, swell and shrink away, at near-full alpha with the soft texture doing the fading.
- **FPS:** 162–165.
- **Check in the game:** the furnace from the north (the plume shows best there), small furnaces, lantern posts by the plots.
- **No ChatGPT review for this one**, to save budget: it's subtle at the game camera. A follow-up idea: a stronger, longer plume.

### V8. Stations and idle life like the visual
- **What changed:**
  - **Fishing:** Jans ice-fish sat on a little three-legged stool, with a new `fish_sit` clip (knees forward, the rod out over the hole, a lift at the bite). Meagan keeps her crouched `fish`.
  - **Chopping:** split logs lie scattered round the chopping stump.
  - **Resting Jans** change between warming their hands, stamping their feet (`stamp`) and looking round with hands behind their back (`look_round`), every 6 s, staggered by Jan.
  - **Cold:** Meagan's breath puffs every 2.4 s while it's cold (`Fx` "breath").
- **Check in the game:** a fishing pond's Jans, a Lumber Yard's stump, Jans resting while the store is full, Meagan when the heat drops below a quarter.
- **Felt wrong:** the rig has no knee joint, so the seated legs stick straight out a little. It reads as sitting at the game camera.
- **No ChatGPT review** (budget).

### V9. Tile-opening flame trail
- **What changed:** when a tile opens, a glowing ember leaves the furnace's top and arcs over 1.8 s (4 m high) to the new small furnace, shedding sparks. The small furnace stays dark until it lands, then flares alight with a flame burst and a fire sound (`main.gd _flame_trail`, `StoveView.set_lit`/`light_up`).
- **Check in the game:** open a gate and watch the furnace and the new tile.
- **No ChatGPT review** (budget).

### V10. Bag-full nudge
- **What changed:** once the first-minute hints are done, a full bag still gets a nudge every time: the hint line "Bag full: take it to a Stockpile" (`data/tips.json` `hints.bag_full`) with the hint arrow pointing at the nearest stockpile, over it or at the screen edge.
- **Not quite as planned:** the backlog said the readout would add the words. I put them in the hint line instead, so the small readout over her doesn't grow. It reads more clearly and overlaps nothing.
- **Check in the game:** chop until the bag is full, away from a stockpile.

### Closing summary (20:14)
- **All ten visual-polish items are done** (V1–V10), one commit each, all pushed. The run finished well before 22:00, so the loop stopped early because no safe item was left. Tests: 140, all passing. No runtime errors, and FPS stayed at 162–165 on the town view.
- **ChatGPT budget:** 1 image and 6 reviews (limits 8 and 25).
- **No paid credits** (no Meshy or Tripo). Your `assets/models/tripo/Meagan.glb` was never staged.
- **Your saved data:**
  - Your saved winter was reset: a test played one to the game-over card and started a new one.
  - Your best time now reads 3:32, which came from that test run.
  - I took "store" back out of your done hints, so you'll see the new store hint.
  - Music off and Sound on are as you had them.
- **Needs you:**
  - From the reviews: one banner at a time, with milestone cards, chatter and the bag readout held back while a banner shows; body text about 42 px; thinner world-label outlines.
  - Second-round icons: simpler small-size Fish, Materials and Wood, and a stronger wind and thermometer (another image).
  - Shader work for the snow: rounded snow caps with a shaded lower band, and selective lines (break sunlit snow-rim lines).
  - A wider, waist-height carry pose and fish poking out of the basket.
  - The `[proto]` numbers listed under V6.
  - Still waiting from before: Meagan carrying in her arms, one settings button, the camera angle and character size, a hand-lettered font.

## Run 2026-10-20, 01:11 → 09:00

ChatGPT budget: counted from `tools/chatgpt/calls.log` line 56 onwards.

### 1. Save and continue
- **Commits:** see `git log` ("Save and continue").
- **What changed:**
  - The winter is saved to `user://save.json` every 10 s, on pause, focus loss, quit and game over, and loaded on launch.
  - Play again deletes the save.
  - The save holds the whole engine state (generically, so new fields are covered) and the random generator, with a version number. JSON keeps Vector2s and ints through `JSON.from_native`.
- **Check in the game:**
  - Play a minute, close the window, reopen: everything continues.
  - Let the fire go out, close and reopen: the card shows again.
  - Play again, close, reopen: a fresh winter.
- **Tests:** `tests/test_save.gd` (round trip mid-attack, same play after loading including random rolls, a finished winter stays finished, bad saves refused). 42 pass.
- **New numbers:** `AUTOSAVE_INTERVAL` 10 s (from the backlog, not the brief).
- **Felt wrong / notes:**
  - Swallowtail's `scene stop` kills the game without a close notification, so the save-on-quit path could only be checked through the autosave and the game-over save. A real window close sends the notification.
  - No ChatGPT review: nothing visible changed.
  - Test saves and the test best time were removed from `user://`.

### 2. First-minute hints
- **Commits:** "First-minute hints".
- **What changed:**
  - Five hints in turn: move, chop, fuel, thaw, store.
  - Each is shown until done, with a yellow arrow: bobbing over an on-screen target, or on the screen edge pointing at an off-screen one.
  - The hint line sits above where the sheet opens and moves up when it's open. It never takes touches (checked by dragging on it).
  - Done hints are saved in `settings.cfg`, so they never repeat.
  - Text is in `data/tips.json`, which also holds the 10 loading tips copied from Frostbite 1. One tip was updated for the Stockpile.
- **Check in the game:** delete the `[hints]` section of `user://settings.cfg` (or use a fresh profile) and play the first minute.
- **Tests:** `tests/test_hints.gd`. The rules live in `HintRules` (engine side) so they test headless.
- **New numbers:** `HINT_MOVED_ENOUGH` 2 m `[proto]`.
- **ChatGPT feedback:**
  - Applied: shorter lines, edge arrows on the true screen edge, the line moving above the sheet, a fade-in, and the arrow's bob restarting per hint.
  - Not applied: nothing big. The arrow already sits over the frozen Jan once he's on screen; in the review shot he was off screen.
- **Felt wrong / notes:**
  - The headless test runner reports "passed" even when a test script fails to compile (an autoload missing headless). Worth fixing in item 13 (test coverage).
  - World labels ("Furnace Lv 1", "Fuel 0/30") crowd the on-screen arrow. Item 16 (smaller nameplates) should help.

### 3. Zoom
- **Commits:** "Zoom: pinch and mouse wheel".
- **What changed:**
  - Two-finger pinch zooms on phones and the mouse wheel zooms on desktop (10% per notch), between 16 and 34 m view height, default 22. The view eases to the new height.
  - A second finger cancels the joystick, so Meagan stops instead of running off. The leftover finger doesn't take over until it's lifted.
- **Checked in the game** (events injected through `runtime eval`):
  - 4 wheel notches out reach 32.2 m.
  - A pinch spreading from 100 to 500 px hits the 16 m limit, with Meagan still and the joystick hidden.
  - One-finger drag still steers.
- **Tests:** `tests/test_camera.gd` (pinch and wheel maths and the limits).
- **New numbers:** none beyond the backlog's (16 / 34 / 22 m). The 10% wheel step and the easing speed are camera feel, in `CameraRig`.
- **ChatGPT feedback (not applied, your call):** it would tighten the range to 18–30 m and default to about 25 m. At 22 m nearby buildings clip at the screen edges; at 32 m Meagan gets hard to spot. The backlog gave 16–34 / 22, so I kept those. Label clutter is item 16.

### 15. One readout above Meagan
- **Commits:** "One readout above Meagan".
- **What changed:**
  - Her world-space counter (a big two-line Label3D that collided with the furnace labels) is replaced by `BagReadout`, a small screen-space pill in the HUD above her load: "14/20", or "MAX" in red with a pop when it fills, and "9 Wood · 5 Mat" under it.
  - It's the same size at every zoom, follows her smoothly, and never takes touches.
  - The resource spot she's gathering at hides its own stock label until she's left. The "+N" pops are unchanged.
- **Check in the game:** gather at the scrap heap behind the furnace, then fill the bag.
- **ChatGPT feedback:**
  - Applied: bigger, near-white text (44 / 34 px), more gap above her, smoothed position, a pop when full.
  - Not applied: "FULL 20/20" instead of "MAX", because the backlog asks for "MAX".
- **Felt wrong:** standing on a build pad, the pill sits over the pad's own "Lv 1 / Upgrade" ground label. Item 16 (smaller nameplates) should ease it.

### 16. Smaller building nameplates
- **Commits:** "Smaller building nameplates; the Stockpile gets a sheet".
- **What changed:**
  - Nameplates are name over level ("Lumber Yard / Lv 2") above the roof, auto-sized to fit the building. Before they were 5.7–8.1 m wide on 3.6 m buildings; now at most 3.4 m ("Fishing Lodge / Lv 10" measured 3.36 m in the game).
  - The furnace's "Fuel 14/30" world line went; its sheet already shows fuel.
  - The Stockpile's three stock lines went too. A new Stockpile sheet shows them against their caps. It opens when you tap the Stockpile or stop on its pad.
- **Check in the game:** look at the nameplates at the default zoom, upgrade the Fishing Lodge high with DEV, then tap the Stockpile.
- **Tests:** `tests/test_nameplates.gd`: every building name fits at a readable size.
- **ChatGPT feedback:**
  - Applied: nameplates raised above roof and chimney, tighter line spacing, and tapping the Stockpile opens its sheet.
  - Not applied, your call: a fuel icon next to the furnace nameplate that turns amber below 30% and pulses red below 10%. The heat bar already warns at 25% and counts down at 10%. Also a dark backing behind nameplates (Label3D has none; the outline is thicker instead).
- **Felt wrong:** the bottom sheet is slightly see-through, so ground labels like "+ Build" show faintly through it.

### 17. Fade canopies over Meagan
- **Commits:** "Fade trees and buildings that hide Meagan".
- **What changed:**
  - Tree crowns and buildings standing between the camera and Meagan fade to 30% opacity and drop their shadow while she's behind them. They fade out in about 0.13 s and back in over about 0.23 s.
  - The check is pure camera-space geometry (`FadeCover.covers`).
- **Check in the game:** walk into a forest, and walk behind the Lumber Yard.
- **Tests:** `tests/test_fade_cover.gd` (in front, behind, beside, far ahead). 163–165 FPS with fading active, the same as before.
- **ChatGPT feedback:**
  - Applied: stronger fade (30% rather than 35%), no shadow while faded, quick out and slower in.
  - Not applied, your call: a warm cream outline on Meagan while she's hidden, which is an art-style change. Also a single-silhouette fade: overlapping parts of one tree still show faint layers, much less at 30%.
- **Felt wrong / notes:** `GeometryInstance3D.transparency` silently does nothing in the mobile renderer, so the fade swaps in a per-mesh see-through material copy. Greybox and Shapes meshes fade; imported Poly Haven props (logs, crates) don't, since they have no material override.

### 18. Wolves spread around their target
- **Commits:** "Wolves spread round their target".
- **What changed** (engine, `combat.gd`):
  - Fighting wolves hold `WOLF_FIGHT_DISTANCE` (1.3 m) from their foe, closing in or backing off. Wolves at their target (fighting, or menacing a work site) keep `WOLF_SPACING` (1.3 m) from each other.
  - Together that forms a ring round Meagan or a guard. Damage rules are unchanged.
  - Travelling wolves aren't spread. A first version spread them on the way in too, and one wolf slipped past Meagan to the furnace.
  - Views: wolves face whoever they're fighting (the engine records `foe_pos`), and each wolf's lunge starts at its own point in the cycle.
- **Check in the game:** DEV → Wolves, then stand in their path.
- **Tests:** two new ones in `tests/test_combat.gd`: three wolves on one spot spread at least a body apart and stay in the fight; four wolves all stay fighting and none ends up on top of her. 56 pass.
- **New numbers:** `WOLF_FIGHT_DISTANCE` 1.3 m and `WOLF_SPACING` 1.3 m, both `[proto]`.
- **ChatGPT feedback:**
  - Applied: facing the foe, staggered lunges.
  - Not applied, your call: health-bar styling. Meagan's bar could be green and wider so it's not confused with the wolves' red ones, with each bar centred higher over its wolf. Also darker wolf backs against blue shadows, which is art.
- **Felt wrong:** with wolves 1.3 m from her, their health bars and hers overlap a little at the default zoom.

### 10. Building-complete juice
- **Commits:** "Building-complete juice".
- **What changed:**
  - On "built"/"levelled", `SiteView.celebrate()` bounces the building, bursts confetti (a new multicolour `Fx` kind) and a big snow puff, and hides the nameplate for a second.
  - `main.gd` pops the "Lumber Yard Lv 2!" line in big above the roof.
  - `CameraRig.shake()` gives a short decaying shake (0.14 m, or 0.3 m for the furnace).
  - The furnace also flares at twice the strength and sends out an expanding ring of warm light.
- **Check in the game:** DEV → Furnace +1, and finish a Sled Shed.
- **FPS:** 156–164 during the effects, against 165 before.
- **ChatGPT feedback:**
  - Applied: nameplate hidden during the burst, the level line raised above the roof and smaller, a fainter and quicker furnace ring, fewer but bigger confetti pieces.
  - Not applied: an orange rim and white-hot centre for the furnace flare (fire art, on hold with the style), and a single banner replacing the world text.
- **Felt wrong:** the confetti still reads a little pastel against the snow under the current lighting.

### 11. Phone UI audit
- **Commits:** "Phone UI audit: 120 px tap targets, no overlapping corner buttons".
- **How:** a runtime audit script walked every visible HUD control and checked three things:
  - tap targets at least 120 px
  - text at least 30 px
  - no overlaps between the top bar, sheet, banner, hint line, the Music/Sound/DEV buttons and the dev panel

  It ran in six states (plot sheet, building sheet, Stockpile sheet, dev panel, banner, game-over card) at 1080×1920. It ran again at 1080×2400, emulated by letterboxing the root viewport, because the OS ignores window resizes and a 1200 px window doesn't fit the screen.
- **Before:**
  - Every themed button was 112 px tall, and the sheet's Close button was 96 px.
  - Music, Sound and DEV were 90–112 px tall, and Music overlapped Sound by 6 px.
  - The dev panel overlapped the corner buttons.
  - No text was under 30 px.
- **After:**
  - `BUTTON_HEIGHT` is 120 and Close is 120.
  - The corner buttons have fixed slots (Music, Sound, DEV), 120 px tall, 16 px apart, and clip long labels.
  - The dev panel opens below them.
  - The audit is clean in every state at both sizes. The only exception is the debug-only dev panel over the hint line.
- **ChatGPT feedback, not applied:**
  - The tall-phone panels look shrunk. That's the letterbox emulation: on a real 1080×2400 phone the expand stretch keeps the UI the same size.
  - The faded Music button is deliberate: it shows music is off.
  - Your call: a dedicated chatter bubble kept 48 px inside the screen edges (Jans' chatter Label3Ds clip at the screen edge when a Jan stands near it), and larger, brighter game-over stats.
- **Felt wrong:** world labels near the screen edge (chatter, nameplates) get cut off. They're world-space, so this audit doesn't cover them.

### 12. Performance pass
- **Commits:** "Performance: skip posing off-screen rigs, cheaper sun shadows, snow guard".
- **Test scene:** Furnace Lv 5, 20 Jans at work, 4 wolves (hit points raised so they last), a blizzard, Meagan by the furnace, vsync off, on this desktop (RTX 3060 Ti). Averages of three samples:

  | | FPS | draw calls | objects | triangles |
  |---|---|---|---|---|
  | Before | 334–374 | 232–299 | 377–437 | 167–184k |
  | Off-screen rigs not posed | 395–472 | 227–294 | 372–432 | 177–188k |
  | + single-split sun shadows | 474–491 | 319–321 | 460–465 | 148–163k |

  About +35% overall.
- **How the costs were found:**
  - Switching groups off showed the 38 character rigs were the biggest cost: 393 → 807 FPS with them off.
  - Next came `main.gd`'s per-frame refreshes (→ 1,175) and the HUD (→ 1,419).
  - Sun shadows were about 10%; the blizzard snow, fog and furnace light were negligible on this GPU.
  - The engine tick costs 35 µs.
- **What changed:**
  - Off-screen characters skip bone posing. Their clips still keep time and fire impacts, so work sounds and timing are unchanged.
  - The sun casts one orthogonal shadow split over 45 m instead of four splits over 100 m. The camera never shows more than about 30 m.
  - The snowfall thins to 40% if the game stays under 40 FPS for 3 s, and comes back when it recovers.
- **Not done:**
  - Pooling `Fx.throw` items: they're short-lived and didn't show up in the measurements.
  - Godot's `TIME_PROCESS` monitor proved too noisy to use; FPS was the reliable signal.
- **For the phone port:** check on a real device. The CPU side (rigs, per-frame label refreshes) is the likely limit there, not the GPU.

### 13. Test coverage
- **Commits:** "Tests: stricter runner and nine new rule tests".
- **The runner:**
  - It now fails a test that raises a script error, caught with an `OS.add_logger` logger, and a test file that won't load. Before, both counted as passes, which happened earlier tonight with the hints.
  - Proved with two throwaway probe tests (a missing function, a file that won't compile): both failed as they should, and were then deleted.
- **New tests** (`tests/test_rules.gd`):
  - the next blizzard 20–40 min after one ends, and its warning re-arming
  - the ×3 blizzard drain
  - an attack that falls in a blizzard waiting until 30 s after it
  - guards walking back to their posts on the ring round the furnace
  - a level-2 Storehouse raising all three caps
  - wolf strength from Furnace Lv 3
  - unlocks by Furnace level and max levels
  - the fire's countdown only without fuel
  - one of each building on the plots
- **Count:** 65 tests, all passing. No existing test was changed.

### 4. Kitchen
- **Commits:** "Kitchen: Jans eat 5% less per level".
- **What changed:**
  - The Kitchen comes from the brief: unlocks at Furnace Lv 2, max Lv 10, 40 Wood + 5 Materials growing ×1.15.
  - Food eaten per Jan falls by 5% of the base per level, additive as in Frostbite 1's `kitchenReductionPerLevel`, so Lv 10 halves it. That's `Economy.food_per_jan_per_second`.
  - It's on the build list.
  - Greybox look: cream walls, a burnt-orange roof, a big cooking pot with a ladle over a little fire by the door, and a chimney that puffs steam every 2 s.
  - Its sheet shows "Each Jan eats 0.85 Food a minute."
- **Check in the game:** DEV → Furnace +1, then build a Kitchen on any plot.
- **Tests:** three new ones (the food cut at Lv 1 and Lv 10, the unlock and costs, Food lasting longer over a minute). 68 pass.
- **Text:** the Kitchen line in `data/buildings.json` lost its "Chef Jans start turning up" half, because Jan variants aren't in the game yet. Put it back when they are.
- **ChatGPT feedback:**
  - Applied: a bigger dark pot by the door, a steaming chimney, cream and burnt-orange colours instead of salmon and green.
  - Not applied: merging the pad's "Lv 1 / Upgrade" text into one badge (UI, item 16's area).
- **Felt wrong:** nothing new. The stricter test runner caught a parse error in this change straight away, which is exactly what it's for.

### 5. Watchtower and attack warnings
- **Commits:** "Watchtower: attack and blizzard warnings".
- **The building:** from the brief and Frostbite 1. Tier 2 means Furnace Lv 4; max Lv 10; 120 Wood + 30 Materials, ×1.25.
- **Engine:**
  - `Economy.blizzard_warning` is 3 minutes + 1 minute per level. `Economy.attack_warning` is 15 s per level, and 0 without a Watchtower.
  - `Combat` raises an `attack_warning` event once per attack, never during a blizzard, and re-arms it. A saved `attack_warned` flag holds the state.
- **View:**
  - A banner ("The Watchtower spots wolves coming!") and "Wolves in 0:29" in the forecast strip.
  - Greybox look: a hut with a tall lookout (thick legs, platform, cone roof, red flag).
  - The sheet shows both warning lengths.
- **Check in the game:** DEV → Furnace +1 three times, build a Watchtower, then wait for (or push forward) an attack.
- **Tests:** three new ones (no warning without a Watchtower, 30 s at Lv 2 once and re-armed, blizzards warned 6 minutes ahead at Lv 3). 71 pass.
- **Not done:** arrows from Lv 5 (not in this item). Its text in `data/buildings.json` no longer promises them.
- **ChatGPT feedback:**
  - Applied: the banner no longer carries a countdown that could disagree with the forecast's; a bolder lookout silhouette.
  - Not applied: a wolf icon in the warning, which waits on HUD icons (on hold with the style).

### 6. Hot Springs
- **Commits:** "Hot Springs: heat drain 10% lower per level".
- **What changed:**
  - The building comes from the brief: Furnace Lv 7 (Tier 3), max Lv 5, 120 Wood + 30 Materials, ×1.25.
  - The heat drain (after the blizzard multiplier) is cut by 10% per level, additive as in Frostbite 1's `hotSpringsReductionPerLevel`, so Lv 5 halves it.
  - Greybox look: a blue-grey bath house with a steaming turquoise pool beside it, ringed with pale stones and clear of the build pad.
  - The sheet shows "Heat drain 10% lower: 0.59 heat a second now."
- **Check in the game:** DEV → Furnace +1 six times, then build Hot Springs.
- **Tests:** two new ones (the cut at Lv 1 and Lv 5, inside a blizzard too, and the unlock at Furnace Lv 7). 73 pass.
- **ChatGPT feedback:**
  - Applied: a bigger, deeper pool with a pale rim, and steam every second.
  - Not applied: a curved roof with timber posts (building art, on hold with the style).

### 7. Jans screen
- **Commits:** "Jans screen".
- **What changed:**
  - A "Jans" button joins the row under the top bar. It opens the bottom sheet as the Jans screen (`Sheet.open_jans()`) and closes it again.
  - The screen shows:
    - the idle count, in amber when it's above 0, and the Jans against the cap
    - one row per job: its Jans and output per second, with −/+ using the engine's existing `add_to_job`/`remove_from_job`
    - for jobs without their building, "build a Workshop first" and no buttons
    - Food: net per second with fished and eaten, red when eating wins
  - "1 Jans" is now "1 Jan" here and in the building sheet.
- **Checked in the game:** real taps (Swallowtail input clicks) on Fishing − and Chopping + changed the counts (Fishing 2 → 1, Chopping 4 → 5), and Meagan didn't move.
- **Tests:** none new. No engine logic changed, and the job actions are already covered by `test_add_and_remove_jobs`.
- **ChatGPT feedback:**
  - Applied: the idle count highlighted, two-line rows, locked rows without controls, a net food line.
  - Not applied: a scrolling list (not needed with four jobs), and lock icons (icons are on hold).
- **Left out:** the auto-assign switch, which is item 9.

### 8. Milestones
- **Commits:** "Milestones: cards for what the game can detect".
- **What changed:**
  - `data/milestones.json` is copied unchanged from Frostbite 1: 26 drafts, still placeholder writing.
  - `MilestoneRules` (engine side) supports the triggers the game can detect: building levels (Frostbite 1's camelCase keys mapped to ours), Jans in the city, Jans rescued, blizzards survived, attacks repelled.
  - Variants, research, the Research Hut and the secret date are skipped until they exist; 16 of the 26 are live now.
  - `MilestoneCards` checks twice a second. Each milestone shows once as a card under the button row for 3 s with the `coin` sound, one after another with a short gap, and waits while a warning banner is up. Earned milestones go in `settings.cfg`.
- **Check in the game:** a fresh profile (or delete `[milestones]` from `user://settings.cfg`), then rescue a Jan and DEV → Furnace +1.
- **Tests:** `tests/test_milestones.gd` (key mapping, which milestones are supported, each trigger type at its count). 77 pass.
- **ChatGPT feedback:**
  - Applied: placement just under the button row, waiting for banners, a more opaque card, a gap between cards.
  - Not applied: shorter rewritten lines (the writing is your Frostbite 1 draft, yours to change), a Jan portrait on the card (icons and art are on hold), 4 s instead of the backlog's 3 s.
- **Notes:**
  - The "chime" is the existing `coin` sound. A dedicated chime could be added to `tools/audio/make_audio.py`, but I didn't regenerate the audio unattended.
  - The editor's class cache went stale once after a headless test run ("Could not find type MilestoneCards"); `--import` plus `swallowtail editor reload` fixed it.

### 9. Auto-assign
- **Commits:** "Auto-assign".
- **What changed:**
  - `JobRules.rebalance` follows the brief's rule. It unlocks at Furnace Lv 4 and runs every 5 s (Frostbite 1's `AUTO_JOB`).
  - Idle Jans go to the neediest job (the same rule as a newly thawed Jan). Then at most one Jan moves, from the job most over its share to the neediest. That move only happens when it's urgent (no choppers, or Food eaten faster than fished) or it leaves the donor no worse off than the target, so it settles instead of shuttling. The last chopper is never taken.
  - Guards are never touched. Any hand move switches it off.
  - It's a switch at the bottom of the Jans screen: green "Auto-assign: ON", with a note on the hand-move rule. Before Furnace Lv 4 it's greyed out with "unlocks at Furnace Lv 4".
- **Checked in the game:** six choppers → tap Auto-assign → 3 Chopping, 2 Fishing, 1 Building within 16 s; a hand tap on Fishing − turned it off.
- **Tests:** `tests/test_auto_assign.gd` (unlock, idle Jans to work, one move per rebalance towards the shares, settles over four rebalances, guards untouched, a hand move switches it off). 83 pass.
- **New numbers:** `AUTO_ASSIGN_FURNACE_LEVEL` 4 and `AUTO_ASSIGN_EVERY` 5 s, both from the brief and Frostbite 1.
- **ChatGPT feedback:**
  - Applied: a short state label, green when on, the rule as a note under it, clearer locked text.
  - Not applied: a toggle-switch widget and a lock icon (styling and icons are on hold), and highlighting the counts that changed.
- **Note:** the class cache went stale again after adding `JobRules`. CLAUDE.md now says to run `--import` before `editor reload`.

### Closing summary (02:46)
Every **safe** item in BACKLOG.md is done, so the run stopped early instead of waiting for 09:00. The three remaining items are on hold for the art direction: 1b HUD icons, 1c snow texture and 14 low-poly trees.

**Done tonight, in order:**
1. Save and continue
2. First-minute hints
3. Zoom
15. One readout above Meagan
16. Smaller nameplates, plus the Stockpile sheet
17. Fading trees and buildings over Meagan
18. Wolves spread round their target
10. Building-complete juice
11. Phone UI audit
12. Performance pass
13. Test coverage, plus a stricter test runner
4. Kitchen
5. Watchtower and attack warnings
6. Hot Springs
7. Jans screen
8. Milestones
9. Auto-assign

That's 17 items, one commit each, all pushed. Tests went from 38 to 83, all passing. A final clean-profile run had no runtime errors at 164 FPS.

**ChatGPT budget:** 14 reviews and asks, no images (budget: 25 and 8).

**Left as I found it:** your uncommitted `assets/models/tripo/Meagan.glb` (never staged), the art style (the ink look is still off), and `user://settings.cfg` (your Music off / Sound on restored; no save, no test hints or milestones).

**Needs you:**
- **New numbers to sign off** (all `[proto]` or from the backlog): `AUTOSAVE_INTERVAL` 10 s, `HINT_MOVED_ENOUGH` 2 m, `WOLF_FIGHT_DISTANCE` and `WOLF_SPACING` 1.3 m. Also the zoom range: the backlog's 16–34 m (default 22), where ChatGPT suggested 18–30 m (default about 25).
- **Text:** the Kitchen and Watchtower descriptions dropped "Chef Jans start turning up" and "shoots arrows from Lv 5" until those exist. The milestone and tip texts are still Frostbite 1 drafts.
- **UI calls ChatGPT raised that touch the style:**
  - Meagan's health bar green and wider, so it isn't confused with the wolves'.
  - An outline on Meagan while she's hidden behind something.
  - Chatter bubbles clipping at the screen edge.
  - Bigger game-over stats.
  - Icons in warnings and on milestone cards.
  - A dedicated milestone chime (the card uses the existing `coin` sound).
- **Phone check:** the performance pass measured on a desktop RTX 3060 Ti. On a real phone the CPU side (character rigs, per-frame label refreshes) is the thing to watch.
- **Art direction:** still open (see `source_art/direction/board.html`). Items 1b, 1c and 14 are waiting on it.

**Gotchas learned:**
- After adding a `class_name`, run `godot --headless --path . --import` and then `swallowtail editor reload`; otherwise the game can stop at "Identifier not found" (now in CLAUDE.md).
- `GeometryInstance3D.transparency` does nothing in the mobile renderer, so fading uses per-mesh material copies.
- Headless tests have no autoloads, so code they test must not use `Game`, `Audio` or `UiTheme`.
- The OS ignores window resizes from `runtime eval`, so tall-phone layouts were emulated by letterboxing the root viewport.
