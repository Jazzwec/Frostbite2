# BACKLOG.md

Work for unattended runs (see AFK.md), in priority order.
- **safe** items have rules in the brief or need no design call. Claude does them in order and ticks them off.
- **on hold** items wait for a decision; Claude skips them.
- **needs you** items wait for the user.

Add, reorder or delete items freely; Claude only reads this file at the start of each iteration.

## Safe

Polish and quality first, then new content.

- [x] **1. Save and continue (safe).** Done 2026-10-20 (AFK).
  - **What:** the winter survives closing the game.
  - **How:** serialize `GameState` to `user://save.json` every 10 s, on pause or focus loss and on quit; load it on launch if it exists. A new winter (Play again) deletes the save. Engine-side `to_dict()`/`from_dict()` with a version number.
  - **Done when:**
    - A test round-trips a mid-game state (Jans, sites, wolves, bag, stores, timers).
    - In the game, quitting and relaunching continues where it left off.
    - Game over shows the card again, not a frozen world.

- [x] **2. First-minute hints (safe).** Done 2026-10-20 (AFK).
  - **What:** a new player learns the loop with no text wall.
  - **How:** a short chain of hints, each shown until it's done:
    1. "Drag anywhere to move"
    2. "Chop Wood in the forest" (an arrow points to the nearest forest)
    3. "Bring Wood to the furnace"
    4. "Thaw the frozen Jan" (arrow)
    5. "Drop extra stuff at the Stockpile"
  - **Text:** in `data/tips.json`, starting from the drafts in `docs/frostbite1/content/tips.json`.
  - **Remember them:** hints that are done are stored in `user://settings.cfg`, so they don't repeat. Play again doesn't repeat them either.
  - **Done when:** a fresh profile sees each hint in turn and they never block touches.

- [x] **3. Zoom (safe).** Done 2026-10-20 (AFK).
  - **What:** two-finger pinch on phones and the mouse wheel on desktop.
  - **How:** zoom the camera between `VIEW_HEIGHT` 16 and 34 (default 22). One-finger drag stays the joystick.
  - **Done when:** both zoom inputs work in the running game and the joystick is unaffected. Pinch is checked by injecting two touch events through `runtime eval`.

- [x] **15. One readout above Meagan (safe, polish).** Done 2026-10-20 (AFK).
  - **What:** the labels stacked over her (the node's stock, "12/20", "12 Wood") become one compact readout: the bag count, with "MAX" in red when full and the carried resources on one short line under it. From the ChatGPT review of her model (NOTES.md).
  - **Done when:** a screenshot shows a single readout that never overlaps her head or the furnace labels, and the "+N" pops still show.

- [x] **16. Smaller building nameplates (safe, polish).** Done 2026-10-20 (AFK).
  - **What:** world labels are wider than the buildings. Use a smaller nameplate (name and level only), and move upgrade and stock details into the tap sheet. From the ChatGPT review of the Jans (NOTES.md).
  - **Done when:** at the default zoom no nameplate is wider than its building, and every number is still reachable in a sheet.

- [x] **17. Fade canopies over Meagan (safe, polish).** Done 2026-10-20 (AFK).
  - **What:** tree crowns (and roofs, if any) between the camera and Meagan fade to about 35% opacity while she's behind them, and back when she leaves. From the ChatGPT review of her model.
  - **Done when:** a screenshot of her chopping inside a forest shows her clearly, and FPS stays the same.

- [x] **18. Wolves spread around their target (safe, polish).** Done 2026-10-20 (AFK).
  - **What:** attacking wolves take separate slots around whoever they fight (Meagan, a Jan or the furnace), about one wolf-body apart, instead of piling on one spot. From the ChatGPT review of the wolf (NOTES.md).
  - **How:** engine-side in `combat.gd`, with the slot spacing in `balance.gd` marked `[proto]`. Damage rules don't change.
  - **Done when:** a test shows three wolves on one target end up in different slots, and a screenshot shows them spread out.

- [x] **10. Building-complete juice (safe).** Done 2026-10-20 (AFK).
  - **What:** a confetti and snow burst, a short camera shake and a level-up pop number when a building finishes or levels up. The furnace levelling up gets a bigger flare and a ring of light.
  - **Done when:** screenshots show it, and FPS stays high.

- [x] **11. Phone UI audit (safe).** Done 2026-10-20 (AFK).
  - **What:** every tap target is at least 120 px at 1080 wide, no text is under 30 px, and the HUD, banner, sheet, DEV and sound buttons, joystick and game-over card don't overlap.
  - **Sizes:** check with screenshots at 1080×1920, and also at 1080×2400 (a tall phone) by changing the window size in `runtime eval`.
  - **Done when:** whatever needed fixing is fixed, with before and after screenshots described in the report.

- [x] **12. Performance pass (safe).** Done 2026-10-20 (AFK).
  - **What:** measure FPS and draw calls with 20 Jans, 4 wolves and a blizzard (use the DEV tools), then fix the biggest costs, e.g. share materials and meshes, pool `Fx.throw` items, and cut the snow particles on low FPS.
  - **Done when:** the numbers before and after are in the report.

- [x] **13. Test coverage (safe).** Done 2026-10-20 (AFK).
  - **What:** add tests for the engine rules that don't have any yet. Read `tests/` and the `scripts/engine/` functions to find them: for example `arrival_interval`, blizzard scheduling edge cases, guards returning to their posts, and caps with a Storehouse.
  - **Done when:** the new tests pass, and none of the existing ones were weakened.

- [x] **4. Kitchen (safe).** Done 2026-10-20 (AFK).
  - **What:** a new building from the brief: food eaten per Jan −5% per level, unlocks at Furnace Lv 2, cost and growth from the brief's economy table.
  - **Where:** add it to `balance.gd`, `economy.food_eaten_per_second`, the build list and `SiteView.LOOKS` (with a cooking-pot prop).
  - **Done when:** a test covers the food reduction, and it can be built from a pad in the game.

- [x] **5. Watchtower and attack warnings (safe).** Done 2026-10-20 (AFK).
  - **What:** a new building from the brief: +1 min blizzard warning and +15 s attack warning per level. Tier 2: check the brief's tier table for the Furnace level.
  - **Attack warnings:** with a Watchtower, wolves are announced ahead with a banner and the forecast strip ("Wolves in 0:30"). Without one there's still no warning, as now.
  - **Done when:** tests cover both warning lengths, and the warning banner shows in the game.

- [x] **6. Hot Springs (safe).** Done 2026-10-20 (AFK).
  - **What:** a new building from the brief: heat drain −10% per level, Tier 3 (Furnace Lv 7). The cost comes from the brief's economy table.
  - **Done when:** a test covers the drain reduction, and it's in the build list at Furnace Lv 7.

- [x] **7. Jans screen (safe).** Done 2026-10-20 (AFK).
  - **What:** the brief's Jans screen. It opens from a HUD button and has one row per job: the job's output per second, its Jans, and −/+ buttons (as the building sheet does), plus food hunted vs eaten.
  - **Leave out:** the auto-assign switch, which is item 9.
  - **Done when:** the job counts in the game change from the screen.

- [x] **8. Milestones (safe).** Done 2026-10-20 (AFK).
  - **What:** achievement cards from `docs/frostbite1/content/milestones.json`, copied to `data/`.
  - **Triggers:** only those the game can already detect: building levels, Jans in the city, Jans rescued, blizzards survived and attacks repelled. Skip variant and research triggers until those exist.
  - **Showing them:** each pops a card for 3 s with a chime once, and they're stored in `user://settings.cfg`.
  - **Done when:** tests cover the trigger checks, and a card shows in the game.

- [x] **9. Auto-assign (safe).** Done 2026-10-20 (AFK).
  - **What:** the brief's rule. It unlocks at Furnace Lv 4 and rebalances every 5 s to the neediest-job rule, moving as few Jans as possible. It never moves guards and switches off when the player moves a Jan by hand.
  - **Where:** a toggle on the Jans screen.
  - **Done when:** there are engine tests for the rebalancing.

- [x] **1a. Concept sheets for Tripo (safe, ChatGPT).** Done 2026-10-19: see `source_art/concept/README.md`.
  - **What:** model sheets in one consistent chunky cartoon style, made with the `chatgpt` skill: Meagan (pink parka, white bobble hat, gold scarf), a Jan (orange parka, blue hat, red nose), a wolf, the Furnace and the Lumber Yard.
  - **Style:** generate Meagan first, then use her as `--ref` for the rest.
  - **Where:** `source_art/concept/`, with a `README.md` on how to upload each one to Tripo Studio (image to 3D, auto-rig for the characters).
  - **Done when:** 5 sheets are checked by eye and committed with their prompts. Budget: up to 7 images, counting retries.

## Art: ink & watercolour (decided 2026-10-20)

The user committed to the ink & watercolour direction; the rules are in `docs/art-direction.md`. These come in this order, each its own commit with a ChatGPT review. The user's `Meagan.glb` stays untouched.

- [x] **A1. Art direction doc.** `docs/art-direction.md`; the brief, CLAUDE.md and NOTES.md point to it.
- [x] **A2. Ink look: steadier and on by default.**
  - **What:** following ChatGPT's review of the test (`source_art/direction/ink_test/chatgpt_review.md`):
    - 1–2 px silhouette lines and thinner inner lines in blue-brown ink.
    - Small colour speckle ignored, and no 8 fps wobble.
    - Less paper grain.
    - Amber light around the furnace, cool blue beyond it.
  - **Done when:** `InkLook` is on at start (the DEV toggle still compares), before/after screenshots and FPS are logged, and a ChatGPT review is folded in.
- [ ] **1c. Painted snow ground (ChatGPT).**
  - **What:** a tileable watercolour snow wash on the ground, blue-grey shadow patches, and warm packed paths between the furnace, the Stockpile and the plots. The routes stay quieter than the pads.
  - **Done when:** there are no visible seams, the FPS is checked, and a ChatGPT review finds it readable.
- [ ] **A3. Jans in faded teal (Blender).** Recolour `jan.glb`'s parka and the greybox Jan colours, so no Jan wears Meagan's red.
- [ ] **1b. Watercolour icons (ChatGPT).**
  - **What:** Wood, Food, Materials, Heat, Jans and Bag, plus blizzard, wolves, cold and a milestone star.
  - **Where:**
    - In `assets/ui/icons/`.
    - Shown in the top bar, `BagReadout`, the sheets, the warning banners and the milestone cards.
  - **Rule:** the text still says what each number is the first time it's seen.
- [ ] **14. Low-poly pines (Blender).**
  - **What:** 2–3 chunky pines under 1,500 triangles, with flat watercolour colours.
  - **Where:** `source_art/blender/trees.blend`, exported to `assets/models/blender/`, used in `NodeView` forests.
  - **Keep:** the stump/crown split (felling, toppling) and the crown fading.
- [ ] **U1. Meagan's health bar** green and wider; the guards' bars blue.
- [ ] **U2. Meagan's outline** shown through whatever hides her.
- [ ] **U3. Bubbles and stats:** chatter bubbles kept inside the screen; bigger game-over stats.
- [ ] **U4. Milestone chime:** its own sound in `tools/audio/make_audio.py`.
- [ ] **A4. New Tripo references in the ink style:**
  - Meagan, Jan, and the furnace, cabin and wood store kit.
  - In `source_art/concept/ink/`, for the user to remake in Tripo Studio.

## Needs you (Claude won't touch these unattended)

- The `[proto]` numbers in `balance.gd`: walk speed, pad size, furnace feed, warning thresholds, ranges.
- Score as minutes or as "days survived".
- Research Hut, Knowledge and the Research tree: big, and its place in the hypercasual loop needs a call.
- Caravans and the Signal Beacon, Expedition Post and scavenging, guard kits and gear, bears, Jan variants and the Collection screen, Prestige: all big systems to plan with you first.
- ElevenLabs music and sound: needs an API key.
