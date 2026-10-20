# AFK_REPORT.md

What happened during unattended runs, newest run first. Each run starts with a heading giving the start time and the deadline. Each item gets:
- the commits
- what to check in the game
- any new `[proto]` numbers
- anything that felt wrong

A "Needs you" list goes at the end.

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
