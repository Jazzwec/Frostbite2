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
