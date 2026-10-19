# BACKLOG.md

Work for unattended runs (see AFK.md), in priority order.
- **safe** items have rules in the brief or need no design call. Claude does them in order and ticks them off.
- **needs you** items wait for the user.

Add, reorder or delete items freely; Claude only reads this file at the start of each iteration.

## Safe

- [ ] **1. Save and continue (safe).**
  - **What:** the winter survives closing the game.
  - **How:** serialize `GameState` to `user://save.json` every 10 s, on pause or focus loss and on quit; load it on launch if it exists. A new winter (Play again) deletes the save. Engine-side `to_dict()`/`from_dict()` with a version number.
  - **Done when:**
    - A test round-trips a mid-game state (Jans, sites, wolves, bag, stores, timers).
    - In the game, quitting and relaunching continues where it left off.
    - Game over shows the card again, not a frozen world.

- [x] **1a. Concept sheets for Tripo (safe, ChatGPT).** Done 2026-10-19: see `source_art/concept/README.md`.
  - **What:** model sheets in one consistent chunky cartoon style, made with the `chatgpt` skill: Meagan (pink parka, white bobble hat, gold scarf), a Jan (orange parka, blue hat, red nose), a wolf, the Furnace and the Lumber Yard.
  - **Style:** generate Meagan first, then use her as `--ref` for the rest.
  - **Where:** `source_art/concept/`, with a `README.md` on how to upload each one to Tripo Studio (image to 3D, auto-rig for the characters).
  - **Done when:** 5 sheets are checked by eye and committed with their prompts. Budget: up to 7 images, counting retries.

- [ ] **1b. Resource and HUD icons (safe, ChatGPT).**
  - **What:** icons for Wood, Food (fish), Materials, Heat (flame), Jans and Bag, made with the `chatgpt` skill, with the white keyed out to transparency.
  - **Where:** `assets/ui/icons/`, shown at 48–64 px next to the numbers in the HUD's top bar, the Stockpile label and Meagan's counter (Label3D can't show images, so use a Sprite3D or a small icon row).
  - **Done when:**
    - Screenshots show the icons.
    - A ChatGPT review says they read at phone size.
    - The text still says what each number is the first time it's seen.

- [ ] **1c. Snow ground texture (safe, ChatGPT).**
  - **What:** a seamless, tileable snow texture made with the `chatgpt` skill, at 1k with mipmaps, replacing the flat snow colour on the ground plane. Keep it subtle, so the characters and pads still pop.
  - **Done when:** a screenshot shows no visible seams and a ChatGPT review finds it doesn't hurt readability. Check the FPS too.

- [ ] **2. First-minute hints (safe).**
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

- [ ] **3. Zoom (safe).**
  - **What:** two-finger pinch on phones and the mouse wheel on desktop.
  - **How:** zoom the camera between `VIEW_HEIGHT` 16 and 34 (default 22). One-finger drag stays the joystick.
  - **Done when:** both zoom inputs work in the running game and the joystick is unaffected. Pinch is checked by injecting two touch events through `runtime eval`.

- [ ] **4. Kitchen (safe).**
  - **What:** a new building from the brief: food eaten per Jan −5% per level, unlocks at Furnace Lv 2, cost and growth from the brief's economy table.
  - **Where:** add it to `balance.gd`, `economy.food_eaten_per_second`, the build list and `SiteView.LOOKS` (with a cooking-pot prop).
  - **Done when:** a test covers the food reduction, and it can be built from a pad in the game.

- [ ] **5. Watchtower and attack warnings (safe).**
  - **What:** a new building from the brief: +1 min blizzard warning and +15 s attack warning per level. Tier 2: check the brief's tier table for the Furnace level.
  - **Attack warnings:** with a Watchtower, wolves are announced ahead with a banner and the forecast strip ("Wolves in 0:30"). Without one there's still no warning, as now.
  - **Done when:** tests cover both warning lengths, and the warning banner shows in the game.

- [ ] **6. Hot Springs (safe).**
  - **What:** a new building from the brief: heat drain −10% per level, Tier 3 (Furnace Lv 7). The cost comes from the brief's economy table.
  - **Done when:** a test covers the drain reduction, and it's in the build list at Furnace Lv 7.

- [ ] **7. Jans screen (safe).**
  - **What:** the brief's Jans screen. It opens from a HUD button and has one row per job: the job's output per second, its Jans, and −/+ buttons (as the building sheet does), plus food hunted vs eaten.
  - **Leave out:** the auto-assign switch, which is item 9.
  - **Done when:** the job counts in the game change from the screen.

- [ ] **8. Milestones (safe).**
  - **What:** achievement cards from `docs/frostbite1/content/milestones.json`, copied to `data/`.
  - **Triggers:** only those the game can already detect: building levels, Jans in the city, Jans rescued, blizzards survived and attacks repelled. Skip variant and research triggers until those exist.
  - **Showing them:** each pops a card for 3 s with a chime once, and they're stored in `user://settings.cfg`.
  - **Done when:** tests cover the trigger checks, and a card shows in the game.

- [ ] **9. Auto-assign (safe).**
  - **What:** the brief's rule. It unlocks at Furnace Lv 4 and rebalances every 5 s to the neediest-job rule, moving as few Jans as possible. It never moves guards and switches off when the player moves a Jan by hand.
  - **Where:** a toggle on the Jans screen.
  - **Done when:** there are engine tests for the rebalancing.

- [ ] **10. Building-complete juice (safe).**
  - **What:** a confetti and snow burst, a short camera shake and a level-up pop number when a building finishes or levels up. The furnace levelling up gets a bigger flare and a ring of light.
  - **Done when:** screenshots show it, and FPS stays high.

- [ ] **11. Phone UI audit (safe).**
  - **What:** every tap target is at least 120 px at 1080 wide, no text is under 30 px, and the HUD, banner, sheet, DEV and sound buttons, joystick and game-over card don't overlap.
  - **Sizes:** check with screenshots at 1080×1920, and also at 1080×2400 (a tall phone) by changing the window size in `runtime eval`.
  - **Done when:** whatever needed fixing is fixed, with before and after screenshots described in the report.

- [ ] **12. Performance pass (safe).**
  - **What:** measure FPS and draw calls with 20 Jans, 4 wolves and a blizzard (use the DEV tools), then fix the biggest costs, e.g. share materials and meshes, pool `Fx.throw` items, and cut the snow particles on low FPS.
  - **Done when:** the numbers before and after are in the report.

- [ ] **13. Test coverage (safe).**
  - **What:** add tests for the engine rules that don't have any yet. Read `tests/` and the `scripts/engine/` functions to find them: for example `arrival_interval`, blizzard scheduling edge cases, guards returning to their posts, and caps with a Storehouse.
  - **Done when:** the new tests pass, and none of the existing ones were weakened.

- [ ] **14. Low-poly trees (safe, needs Blender open).**
  - **What:** model two or three chunky low-poly pines (under 1,500 triangles each) in Blender through the Blender MCP.
  - **Where:** save them in `source_art/blender/trees.blend`, export them to `assets/models/blender/`, and use them in `NodeView` forests in place of the cone greybox. Keep the stump/crown split, so felling still works.
  - **If Blender isn't reachable,** skip it and note that in the report.
  - **Done when:** a screenshot shows the new trees, and chopping and toppling still work.

## Needs you (Claude won't touch these unattended)

- The `[proto]` numbers in `balance.gd`: walk speed, pad size, furnace feed, warning thresholds, ranges.
- Hunting or Fishing: renaming the job and the spots.
- Score as minutes or as "days survived".
- Art direction: photoreal Poly Haven props or chunky cartoon Tripo models.
- Research Hut, Knowledge and the Research tree: big, and its place in the hypercasual loop needs a call.
- Caravans and the Signal Beacon, Expedition Post and scavenging, guard kits and gear, bears, Jan variants and the Collection screen, Prestige: all big systems to plan with you first.
- ElevenLabs music and sound: needs an API key.
