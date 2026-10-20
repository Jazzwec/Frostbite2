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
