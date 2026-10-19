# NOTES

What felt wrong while playing, and what's still open. This file is the prompt for the next session.

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
- [ ] Hunting ground: a frozen pond. She crouches at a hole with a rod and bobber; every few seconds a fish splashes out into her bag.
- [ ] Scrap heap: pickaxe strikes with sparks. Furnace: she tosses logs in and the fire flares. Construction: hammering with dust. Piles: she hugs a box and items fly to or from her bag.
- [ ] A frozen Jan: she rubs her hands and blows warm breath; the ice shatters. Bag full: a shrug and "Bag full!".
- [ ] Jans chop at stumps, fish at ice holes and hammer at anvils in front of their building, shiver and slow down when it's cold, and warm their hands when the Stockpile is full of what they make. Guards thrust spears; wolves flash white when hit.

**Pressure** (use the DEV panel: Furnace +1, Wolves, Blizzard)
- [ ] Blizzard: warning banner, forecast countdown, heavier snow and fog, drain ×3, then an all-clear banner.
- [ ] Wolves: banner, wolves with health bars head for the furnace, detour to working Jans, guards (Barracks job) and Meagan fight them, kills drop loot.
- [ ] Meagan injured: she lies down and can't move until the attack ends.

## Open questions

- **Numbers marked `[proto]` in `scripts/engine/balance.gd`** need your sign-off: walk 6 m/s, build pad 1.4 m, furnace feed from the Stockpile 5 Wood/s, gather range 3 m, building reach 4.5 m, rescue range 2 m, first Jan after 5 s, wolf detour 7 m, guard ring 4 m.
- **Guards are weak:** by the brief, without kits they deal half damage (1.5/s), so 2 guards struggle against 3 wolves. Kits and gear aren't in the prototype yet.
- **Trees:** Poly Haven's trees are far too heavy for phones, so forests are greybox cones. Real trees will need Tripo or Blender low-poly models.
- **Hunting or fishing?** The hunting grounds now look like ice fishing (your choice), but the rules and text still say Hunting. Rename the job and spots to Fishing in the brief?
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
