# AFK.md: rules for unattended runs

How Claude works on Frostbite2 while the user is away. It's started with, for example:

```
/loop Work through BACKLOG.md for Frostbite2 until 03:00. Follow AFK.md.
```

These rules override the "plan first, show the plan, ask before guessing" rules in CLAUDE.md, but only for items in BACKLOG.md marked **safe**. Everything else in CLAUDE.md still applies.

## Each iteration
1. **Check the clock first.** If it's past the deadline in the `/loop` prompt, or no unticked **safe** item is left, write the closing summary in `AFK_REPORT.md`, commit and push it, and end the loop.
2. **Pick the first unticked safe item** in `BACKLOG.md`, in order. Don't skip ahead unless it's blocked.
3. **Implement it in small steps.** Follow the item's "done when" lines exactly, and don't add scope.
   - Engine changes get tests in `tests/`.
   - Every number goes in `balance.gd`, with its source noted. A number the brief doesn't give is marked `[proto]` and listed in the report.
   - Player-facing text goes in `data/*.json`, starting from the drafts in `docs/frostbite1/content/`.
4. **Verify:**
   - `godot --headless --path . -s res://tests/run_tests.gd` passes.
   - Play it through Swallowtail (`scene play`, `runtime eval`, `runtime screenshot`): the feature visibly works, and `runtime errors` is empty.
   - After adding a `class_name` or an autoload, run `swallowtail editor reload`.
   - Remove any test values written to `user://` (best time, saves).
5. **Commit and push.** One commit per item (or per clear step of a big item), with a clear message and the Co-Authored-By line. Push with `git push origin main`.
6. **Record it:**
   - Tick the item in `BACKLOG.md`.
   - Add an entry to `AFK_REPORT.md`: the item, the commits, what to check in the game, any `[proto]` numbers, and anything that felt wrong.
   - Update the CLAUDE.md "Current state" section and the NOTES.md checklist where the item changes them.
7. Then schedule the next wakeup.

## When something goes wrong
- **Tests fail, or the feature doesn't work after two honest attempts:**
  1. Revert your uncommitted changes to that item's files with `git checkout -- <files>`, never `reset --hard`.
  2. Note it in the report with the error.
  3. Move on to the next item.
- **An item turns out to need a design decision:** stop that item, list the question in the report under "Needs you", and move on.
- **The Godot editor isn't reachable** (`swallowtail status` isn't `running`): launch it once with `swallowtail launch`. If that fails, carry on with engine-only work and say so in the report.
- **Never run destructive git commands:** no force push, no `reset --hard`, no `clean`, no history rewrite.

## Never while unattended
- Work on items marked **needs you**, or change brief rules beyond what an item says.
- Delete files you didn't create in this run.
- Add addons, plugins or Python packages.
- Spend credits: Tripo API, ElevenLabs, or anything paid.
- Touch anything outside `C:\Claude Code\Frostbite2`. The Blender MCP may only change the Frostbite2 source `.blend` files.
- Change `.claude/settings.json`, permissions or the user's global settings.
