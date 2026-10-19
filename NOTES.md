# NOTES

What felt wrong while playing, and what's still open. This file is the prompt for the next session.

## Felt wrong while playing

_(nothing logged yet)_

## Prototype play checklist (2026-10-19)

Press Play in the editor (F5), or run `godot --path .`. The window is 540×960, and the mouse stands in for a finger.

**Map and walking**
- [ ] Drag to pan the view; a short click walks Meagan there (around buildings); the camera recentres when she walks.
- [ ] Forest → bag fills (5 Wood/s); furnace → fuel goes in, the heat bar and fire glow rise.
- [ ] The scrap heap behind the furnace gives Materials; the Sled Shed (30 Wood) raises the bag limit.
- [ ] Tap a "+" plot → build sheet → pick one → construction site → walk near it with the resources → built (bounce).
- [ ] Tap a building → Upgrade, and −/+ for its Jans.

**Jans**
- [ ] A frozen Jan appears at the map edge after 5 s, then about once a minute. Tap → she walks out → he thaws, says a line, walks to work.
- [ ] Workers' output piles up at their building (label above it); she picks Wood/Materials up by walking past.
- [ ] At the Jan cap, "No room!" shows and he stays frozen.
- [ ] Idle chatter bubbles every 20–30 s.

**Pressure** (use the DEV panel: Furnace +1, Wolves, Blizzard)
- [ ] Blizzard: warning banner, forecast countdown, heavier snow and fog, drain ×3, then an all-clear banner.
- [ ] Wolves: banner, wolves with health bars head for the furnace, detour to working Jans, guards (Barracks job) and Meagan fight them, kills drop loot.
- [ ] Meagan injured: she lies down and can't move until the attack ends.

## Open questions

- **Numbers marked `[proto]` in `scripts/engine/balance.gd`** need your sign-off: walk 4 m/s, gather range 3 m, building reach 4.5 m, rescue range 2 m, first Jan after 5 s, wolf detour 7 m, guard ring 4 m.
- **Guards are weak:** by the brief, without kits they deal half damage (1.5/s), so 2 guards struggle against 3 wolves. Kits and gear aren't in the prototype yet.
- **Trees:** Poly Haven's trees are far too heavy for phones, so forests are greybox cones. Real trees will need Tripo or Blender low-poly models.
- **Art direction:** the Poly Haven props are photoreal, while the brief wants chunky cartoon. Decide whether to keep them as placeholders or go straight to Tripo models.

## Next steps (pick with the user)

- Rewrite the brief's Tech & build plan and Art & assets sections for Godot, plus a new phase list.
- Saving (local file, export/import code), then the Build/Jans/Collection screens.
- Remaining buildings, Research, caravans, Jan variants, milestones, prestige.
- Tripo models for Meagan, Jans, wolves and buildings; ElevenLabs music and sound.
- Test framework: GUT or gdUnit4.
- Git hosting: create `Jazzwec/Frostbite2` on GitHub when there's something to share; Git LFS if model and audio files get large.

## Setup still missing

- Godot 4.7.2 export templates, needed for a standalone Windows build. Not needed for playing from the editor.
- Android and iOS export: deliberately left until the port (iOS needs a Mac).
