# Frostbite: Meagan vs. the Cold — Game Design Brief

Oct 16, 2026 · @Jan

## Concept & pitch

Frostbite is a cosy incremental survival game for one player: Meagan keeps a furnace burning through an endless winter while rescuing an ever-growing crowd of frozen Jans and putting them to work. Keep the heat up, rescue more Jans, build more, survive the blizzards, and when the thaw comes start again with a stronger city.

It plays like the Whiteout Survival ads: a furnace at the centre, survivors staggering in from the snow, a city that grows outward. The twist is that every survivor is Jan, every line of dialogue is written for Meagan, and every milestone is an in-joke. It is a love letter disguised as an idle game.

- Platform: web game built for iPhone Safari, installed from Share → Add to Home Screen so it runs full-screen like an app; portrait, one-handed play
- Session shape: 10 to 30 minute sittings; the game pauses when closed and nothing happens between sessions
- Tone: warm, silly, slightly dramatic in the way survival games are; never grim
- Audience: one person. Nothing about the game needs to work for anyone else

## Characters

Meagan is the only leader; the Jans are the only survivors. There are no other named characters.

**Meagan** is the player avatar. She stands by the furnace, walks out to rescue arriving Jans when tapped, and is the one every Jan reports to. Her stats are the city's stats: heat, population, output. She never dies; the Jans are the ones at risk, which keeps the stakes warm rather than punishing.

**The Jans** are identical in silhouette and different in one visible quirk each. A newly rescued Jan is a plain Jan; variants unlock as the city grows and are assigned on rescue by weighted chance. Each variant has a small job bonus and a short bio on the collection screen.

| Variant | Visible tell | Job bonus | Unlock |
| --- | --- | --- | --- |
| Plain Jan | Parka, red nose | None | Start |
| Chef Jan | Apron, ladle | +25% food from Fishing | Kitchen built |
| Sleepy Jan | Blanket, half-shut eyes | Works 20% slower, eats 50% less | Tier 2 |
| Spreadsheet Jan | Clipboard | +25% Research | Research Hut built |
| Lost-His-Keys Jan | Patting pockets | Finds random bonus resources on rescue | Tier 2 |
| Lumberjack Jan | Axe, checked shirt | +25% wood from Chopping | Lumber Yard upgraded |
| DJ Jan | Headphones | +5% to every job per DJ in the city, up to 3 (built rule; "while adjacent" needs positions the game doesn't model) | Tier 3 |
| Veteran Jan | Grey beard, medal | Carries over through prestige, +5% all | First prestige |

Add two or three more variants from real quirks; the collection screen should end up with 10 to 12 Jans in total so there is always one more to find.

## Core loop

The furnace is the single thing to protect; everything else exists to feed it or to grow because of it.

The loop, as a cycle: Furnace heat → rescue arriving Jans → assign Jans to jobs → spend output on buildings → furnace capacity grows → more Jans. Blizzards are the one external pressure acting on the furnace.

Heat decays constantly. Jans burn wood to keep it up, but each Jan also adds to the drain, so the city only grows when furnace capacity grows first. That dependency is the exponential: capacity gates population, population drives output, output buys capacity.

A session plays like this:

1. Open the app. The city is exactly as it was left; a short welcome-back card recaps heat, population and the next blizzard.
2. Tap arriving Jans. Meagan walks over, the Jan thaws, a line of dialogue plays, and the Jan walks to the job that needs him most (Lumber Yard first, then Fishing if eating outruns fishing, then by job share).
3. Drag or tap idle Jans onto jobs. Spare Jans can be left idle at no cost beyond their food.
4. Spend resources on the cheapest useful upgrade. The game should always surface one affordable or nearly affordable thing to buy.
5. Check the forecast. If a blizzard is coming, stockpile wood or pull Jans off research onto chopping.
6. Close the app. The game pauses; nothing burns, nothing grows and nobody arrives until the next sitting.

## Resources

Five resources, and only Heat can run out with consequences. Everything else just slows you down when it is short.

| Resource | Produced by | Spent on | Cap | Notes |
| --- | --- | --- | --- | --- |
| Heat | Burning Wood at the Furnace | Drains automatically; each Jan and each building level adds to drain | Furnace level × 100 | Below 30%: jobs at half speed. At 0: the fire goes out and the winter is over |
| Wood | Chopping; Meagan in the forest | Furnace burn, most buildings, gear | 300 + 50 per Lumber Yard level, × Storehouse | The pacing resource; wood income vs burn rate is the core tension |
| Food | Fishing; Meagan at the fishing ponds; animal kills | Each Jan eats 1/min | 150 × Storehouse | Short food = Jans work 25% slower. Never kills |
| Materials | Building job; Meagan at the scrap heap; Scavenging after Tier 2; animal kills | Higher-tier buildings, furnace upgrades, gear | 100 × Storehouse | The slow resource that gates each tier |
| Knowledge | Research | Permanent multipliers in the Research tree | None | Only resource that is never wasted; always a good sink for spare Jans |

A sixth resource, Warmth Tokens, is earned only at prestige and spent on permanent bonuses. It never resets.

Storehouse multiplies every Wood, Food and Materials cap by 1.25 per level (compounding).

**Start of a winter.** The city starts empty: 0 Jans and 0 of every resource, but the furnace starts full (heat 100, agreed for Frostbite2 on 2026-10-19), and the clock is running. Furnace, Lumber Yard and Fishing Lodge are at Lv 1. Meagan rescues the first Jan herself and gathers the first resources by hand. Like the ads, she works automatically whenever she stands at a forest (5 Wood/s), a fishing pond (3 Food/s) or a scrap heap (1 Materials/s, enough to reach the first Workshop). Cold and hunger don't slow her.

**The map** grows during a winter (Frostbite2, agreed 2026-10-20; see **Areas, small furnaces & treasures**). It's a grid of square tiles: the town starts on a fixed 3 × 3 starting grid, and every other tile is generated from the winter's seed and opened by paying for a small furnace at its border. The camera follows Meagan closely, and a one-finger drag anywhere steers her like a joystick (agreed 2026-10-19). The starting grid holds two forests, one fishing pond and the scrap heap behind the furnace [proto]; opened tiles add more. Each holds a stock (forest 60 Wood, fishing pond 40 Food, scrap heap 15 Materials) that runs down as she gathers and grows back steadily, full again about 3 minutes after being emptied (scrap heaps 4), so she roams between them. Frozen Jans, caravans and animals arrive from the far edges; animals walk faster to keep their roughly 10-second approach.

**Gathering and building (the Stockpile and build pads agreed for Frostbite2 on 2026-10-19; no bag agreed 2026-10-20).** Meagan carries nothing:

- There is no bag. Everything she gathers by hand goes straight into the Stockpile: a "+N" pops at the spot and the resource's icon flies up into its number in the top bar. When the Stockpile is full of that resource she stops and shrugs, under a red "Stockpile full" tag.
- The **Stockpile** next to the furnace is the town's store (Wood, Food and Materials, up to the caps above). Its pad opens a sheet of its stores. Her gathering and the Jans' output goes straight into the Stockpile, and Jans eat from its Food automatically, at a steady rate.
- The furnace holds 30 Wood of fuel per Furnace level. It feeds itself from the Stockpile's Wood at 5 Wood/s [proto]; nobody carries Wood to it.
- The map has plots, each with a **build pad** in front. **The game decides what each plot holds** (agreed 2026-10-20): the starting grid's plots each have a fixed utility building, and plots in opened tiles each hold a producer. Stopping on the pad of an unbuilt plot shows its building and cost (or the Furnace level it needs); paying starts it as a construction site. Stopping on a building's pad opens its panel, where its next upgrade starts. While she stands on the pad of a site under construction or upgrading, it takes what it needs from the Stockpile into its progress ring (20 a second [f1]), and the pieces fall out of the sky onto it; when the ring is full it is built or levels up.
- Tapping a building, resource spot or frozen Jan walks her there, routing around buildings.
- Frozen Jans come two ways (agreed 2026-10-20): **camps** of 1–3 frozen Jans found in opened tiles, and the slow single arrivals, who now wait at a random spot on the frontier (the edge of the opened area). Tapping one walks her out to thaw him; if the city is full he stays frozen and a "No room" message suggests the Furnace or a Bunkhouse.

## Jobs

Five jobs, each tied to one building that sets its rate. Output per Jan is the building's base rate times the Jan's variant bonus times Research multipliers.

| Job | Building | Produces | Base rate per Jan | Unlocks at | Upgrade effect per level |
| --- | --- | --- | --- | --- | --- |
| Chopping | Lumber Yard | Wood | 1.0 / s | Start | +15% rate, +50 Wood cap |
| Fishing | Fishing Lodge | Food | 0.6 / s | Start | +15% rate |
| Building | Workshop | Materials | 0.1 / s | Furnace Lv 2 | +20% rate |
| Research | Research Hut | Knowledge | 0.05 / s | Furnace Lv 3 | +20% rate |
| Scavenging | Expedition Post | Random Wood, Food or Materials in bursts (40 / 25 / 8, Wood twice as likely) | 1 burst / 90 s | Tier 2 | Interval ×0.92, bursts ×1.2 |
| Guarding | Barracks | Defence against animal attacks (30 HP, 3 damage/s each) | — | Furnace Lv 2 | +15% guard strength |

Rate upgrades compound: a job's rate per Jan is base × growth^(level − 1).

Idle Jans still eat and still add to heat drain, so the game nudges players to assign everyone. A one-tap "auto-assign" that fills jobs by current need unlocks at Furnace Lv 4 so the late game does not become micromanagement. It uses the same rule as a newly thawed Jan (Lumber Yard first, then Fishing while eating outruns fishing, then job shares Chopping 3 : Fishing 2 : Building 2 : Research 1), rebalances every 5 seconds moving as few Jans as possible, never touches guards or scavengers, and switches off when the player moves a Jan by hand.

## Buildings & upgrades

The Furnace is the tier gate: each Furnace level raises the Jan cap and unlocks the next ring of buildings. Everything else is a level-up of one job or one cap.

| Building | Role | Max level | Jan cap effect | Unlocks |
| --- | --- | --- | --- | --- |
| Furnace | Heat cap; +5% heat per Wood per level; draws stronger animal attacks | 10 | +4 Jans per level | Each level opens new buildings and Jan variants |
| Lumber Yard | Chopping rate and Wood cap | 25 | — | — |
| Fishing Lodge | Fishing rate | 25 | — | — |
| Storehouse | Food and Materials cap | 15 | — | — |
| Workshop | Building rate; Materials | 20 | — | Furnace Lv 2 |
| Kitchen | Food consumed per Jan, down 5% per level | 10 | — | Furnace Lv 2; unlocks Chef Jan |
| Research Hut | Research rate | 20 | — | Furnace Lv 3; unlocks Spreadsheet Jan |
| Bunkhouse | Jan cap without raising heat drain | 10 | +2 Jans per level | Furnace Lv 3 |
| Expedition Post | Scavenging | 10 | — | Tier 2 (Furnace Lv 4) |
| Watchtower | +1 min blizzard warning and +15 s attack warning per level; arrows from Lv 5 | 10 | — | Tier 2 |
| Hot Springs | Heat drain down 10% per level | 5 | — | Tier 3 (Furnace Lv 7) |
| Barracks | Guarding rate; Weapons, Armour and guard kits are crafted here | 20 | — | Furnace Lv 2 |
| Signal Beacon | Caravans come 8% sooner per level | 10 | — | Furnace Lv 2 |
| Sled Shed | Meagan gathers 10% faster per level [proto, agreed 2026-10-20] | 10 | — | Start |

Every level of every building except the Furnace adds 0.05 heat/s to the drain, so growth always leans on the furnace. Every small furnace (one per opened tile) adds 0.15 heat/s more [proto].

**Producers and utilities (agreed 2026-10-20).** The Lumber Yard, Fishing Lodge and Workshop are **producers**. Apart from the starting Lumber Yard and Fishing Lodge, they're found only in opened tiles, next to the forest, pond or scrap heap they work, and the same producer can appear many times. Each producer holds at most **3 Jans** [proto]; upgrading raises its rate, not its room. So the way to grow is to open more tiles, build more producers and fill them. Every other building is a **utility**, found only on the starting grid, one each, on a fixed plot.

## Areas, small furnaces & treasures

Agreed with the user on 2026-10-20: Frostbite2 plays like a roguelite. Each winter is a run with a new world, and it ends when the heat runs out.

- **Tiles.** The world is a grid of square tiles, 20 × 20 m each [proto] (about one screen). The **starting grid** is 3 × 3 tiles around the furnace, always the same: the Furnace, the starting Lumber Yard and Fishing Lodge, the Stockpile, one fixed plot for each utility building (Sled Shed, Storehouse, Kitchen, Barracks, Bunkhouse, Watchtower, Hot Springs), two forests, one fishing pond and the scrap heap [proto].
- **Opening a tile.** Every closed tile that touches an open one has a gate pad on the shared border, showing its cost. Meagan pays it like a build pad, from the Stockpile: Wood 40 × 1.6^(d − 1), plus Materials 10 × 1.6^(d − 2) from d = 2, where d is the tile's distance from the furnace in tiles [proto].
- **Small furnaces.** Paying installs a **small furnace** on the gate and the tile thaws open. A small furnace never upgrades. It connects to the main furnace, burns from the same heat and adds 0.15 heat/s to the drain [proto], so every new tile makes Wood more pressing and opening one is a choice. When the heat runs out, they all go out together.
- **What a tile holds,** generated from the winter's seed and the tile's position, so it's the same whatever order tiles are opened in:
  - 1–2 resource spots (forest, fishing pond or scrap heap);
  - 0–2 producer plots matching them (forest → Lumber Yard, pond → Fishing Lodge, scrap → Workshop);
  - 35% a camp of 1–3 frozen Jans;
  - 30% a chest;
  - from distance 3, 20% a wolf den that animal attacks then come from [proto].
- **Treasures.** Meagan opens a chest by walking onto it:
  - **Resource cache:** a burst of Wood, Food or Materials that grows with distance.
  - **Boon chest:** rare offers a choice of 2 run-long boons, epic a choice of 3 (quicker building, faster walk, faster gathering, slower heat drain, faster Jans, +1 Jan per producer, a wider warm circle, chests shown from afar…). The game pauses while she chooses.
  - **Gear chest:** an item for one of her three slots (axe: gathering speed; boots: walk speed; sled: gathering speed too), common, rare or epic. She equips it or keeps what she has.
- **End of a run.** Unchanged: at heat 0 the game-over card shows the time survived, now with the tiles opened, and Play again starts a new winter with a new seed.
- **Between runs (to design with the user).** Runs will unlock new content and earn a currency for permanent upgrades. How the currency is earned, perhaps tokens from defeated enemies, is still open, and until then the Prestige section below is on hold.

Tiers are just Furnace level bands: Tier 1 is Furnace 1 to 3, Tier 2 is 4 to 6, Tier 3 is 7 to 10. Each tier changes the city's look (snow depth, lights, decorations) so progress is visible without reading numbers.

The Research tree is a separate list of 15 to 20 one-off purchases bought with Knowledge: percentage multipliers to each job, cheaper Furnace levels, Jan arrival rate, blizzard resistance. It is the long-tail sink once buildings cap out.

The 16 nodes (any order, each costing 10 × 1.5^(nodes bought) Knowledge; names in `research.json`): Chopping, Fishing, Building and Research +15% each; every job +10%; Meagan walks 20% faster; Meagan gathers 10% faster; 10% more heat per Wood; Furnace upgrades 10% cheaper; blizzard drain −20%; heat drain −10%; Jans arrive 15% more often; Jans eat 10% less; scavenging 15% sooner; guards +20% damage; caravan Jans wait 50% longer. Research resets at each thaw.

Weapons, Armour and guard kits are crafted at the Barracks straight from the piles (no carrying), from its row on the Build screen.

## Economy & cost curves

Every repeatable cost follows one formula, so balancing is a matter of tuning a handful of constants in the simulator rather than editing tables.

```latex
\text{cost}(n) = \text{base} \times \text{growth}^{\,n}
```

where n is the number of upgrades already bought (level minus the starting level, so the Furnace's first upgrade is n = 0). Starting constants, all to be tuned in the simulator before any game code is written:

| Item | Base cost | Growth | Currency |
| --- | --- | --- | --- |
| Lumber Yard, Fishing Lodge | 15 Wood | 1.12 | Wood |
| Storehouse, Kitchen | 40 Wood + 5 Materials | 1.15 | Wood, Materials |
| Workshop, Research Hut, Barracks | 60 Wood + 10 Materials | 1.15 | Wood, Materials |
| Bunkhouse, Watchtower, Hot Springs, Expedition Post, Signal Beacon | 120 Wood + 30 Materials | 1.25 | Wood, Materials |
| Sled Shed | 30 Wood | 1.3 | Wood |
| Furnace level | 100 Wood + 20 Materials (Lv 1→2 is Wood only, before Materials exist) | 1.8 | Wood, Materials |
| Weapons, Armour level | 50 Wood + 15 Materials | 1.3 | Wood, Materials |
| Guard kit | 20 Wood + 5 Materials | 1.3 per Weapons + Armour level | Wood, Materials |
| Research tree node | 10 Knowledge | 1.5 per node bought | Knowledge |

Heat drain per second = 0.5 + 0.1 per Jan + 0.05 per building level, reduced by Hot Springs. Each Wood burned gives 10 Heat. So a city of 20 Jans burns 0.25 Wood/s just to stand still, and a Lumber Yard at level 10 with 8 Jans chopping makes about 3.5 Wood/s. That headroom is what players spend on growth.

Target pacing for a first winter, measured by the simulator with an attentive player:

| Milestone | Target time |
| --- | --- |
| Furnace Lv 2, first Chef Jan | 15 minutes |
| Tier 2 (Furnace Lv 4) | 1.5 hours |
| Tier 3 (Furnace Lv 7) | 4 to 5 hours |
| Furnace Lv 10, first prestige available | 10 to 12 hours |

There is no offline progress. The game runs only while open and pauses the moment it is backgrounded, so heat never drains between sessions and nothing is lost by closing the app. Every time in this brief is active play time, which is why the pacing is compressed compared with a typical idle game.

Numbers display as 1.2K, 3.4M, 5.6B and so on from 1,000 upward; the simulator decides whether anything ever reaches B. Jan arrivals: one every 60 seconds at base, slowing as the city nears its cap (× (1 + 2 × fill²), so 180 s at the cap), so new Jans always feel wanted. At most 3 single arrivals wait at the edge; a caravan can push that to 7.

The Economy table's "Lumber Yard Lv 10 with 8 Jans makes about 3.5 Wood/s" example is off: with compounding rates that's about 3.5 Wood/s per Jan.

## Events & pressure

Blizzards are always announced and are about preparing, not reacting. Animal attacks are the second threat; only a Watchtower announces them.

| Event | Trigger | Effect | Counter |
| --- | --- | --- | --- |
| Blizzard | First at 15 minutes, then every 20 to 40 minutes of active play, warned 3 minutes ahead (+1 minute per Watchtower level) | Heat drain ×3 for 2 minutes; no Jan arrivals | Stockpile Wood, move Jans to Chopping, buy Hot Springs |
| Long Night | The first blizzard after reaching Tier 2 and Tier 3, warned 10 minutes ahead | Blizzard lasting 5 minutes | Same, and the first one is the game's tutorial for prestige pressure |
| Jan caravan | First at 10 minutes, then every 15 to 25 minutes (8% sooner per Signal Beacon level) | 3 to 5 Jans arrive at once, one guaranteed rare variant; Jans who wandered off in the cold come back with it | Have cap free, or they wait at the edge for 10 minutes |
| Found a cache | 5% of Scavenging bursts | 75%: 5× a Materials burst. 25%: a free level of a random built building (never the Furnace) | None needed |
| Animal attack | Every 8 to 15 minutes from Furnace Lv 2, never during a blizzard; warned only with a Watchtower | See below | Guards, gear, Meagan, Watchtower |
| Lost-His-Keys Jan finds something | On rescue of that variant | Small random bonus | None needed |

**Keeping the fire burning is the objective (agreed for Frostbite2 on 2026-10-19).** If Heat reaches zero the fire goes out and the winter is over: a card shows how long the village was kept warm (the score; the best time is remembered), a few numbers from the winter, and Play again. It must never feel unfair, so the game warns loudly first: below 25% heat the bar pulses red and a banner and horn fire, and below 10% the bar counts down to the fire going out [proto thresholds]. With no Wood at all, the starting town's fire lasts about 2½ minutes.

### Animal attacks

The furnace's warmth draws wild animals, and a bigger Furnace draws stronger ones: their HP, damage and loot grow ×1.6 per Furnace level above 2. Fights happen on the map in real time. Everyone autofights whatever is in range.

- **Who comes.** Tier 1: wolf packs of 2 to 4. Tier 2: one attack in three adds a bear. Tier 3: a bear every time, and one in five is led by the Old Bear.

  | Animal | HP | Damage/s | Loot (Food / Materials) | Jans scared at the furnace |
  | --- | --- | --- | --- | --- |
  | Wolf | 20 | 2 | 15 / 3 | 1 |
  | Bear | 80 | 6 | 60 / 12 | 2 |
  | Old Bear | 400 | 15 | 300 / 60 | 4 |

- **How they move.** Animals spawn at the map edge and walk to the furnace (about 10 s). An animal passing within reach of a working Jan detours to them; after 3 s beside them that Jan flees for good. Each animal scares at most one Jan. Animals stop to fight any guard or Meagan who comes close.
- **Guards.** Jans on the Guarding job wait in a ring around the furnace and move out to engage animals anywhere in the city. A guard at 0 HP is knocked out until the attack ends, not lost.
- **Gear.** Each guard needs a kit to fight at full strength; without one they deal half damage. Weapons (+20% damage per level) and Armour (−10% losses per level) are level tracks crafted at the Barracks and apply to guards and Meagan. The higher the gear levels, the dearer each kit.
- **Meagan** can join any fight by walking into range: 100 HP, 10 damage/s. At 0 HP she's injured and can't move, gather or rescue until the attack ends, win or lose. She heals after every attack.
- **Watchtower.** Its levels give attack warning (15 s each). From Lv 5 it shoots arrows worth 2 guards, +1 guard per level after that.
- **Breakthrough.** Each animal that reaches the furnace takes 15% of Wood and Food and 20% of heat, scares off Jans for good (see table), then leaves. Armour reduces all of this. Jans lost to animals are gone for good; new Jans keep arriving as usual.
- **Reward.** Every kill drops Food and Materials.

## Prestige: A New Winter

> **On hold (2026-10-20).** Frostbite2 is now a roguelite (see **Areas, small furnaces & treasures**). What carries over between runs (content unlocks and a currency) will be designed with the user, and it may replace this section.

At Furnace level 10 the thaw arrives. Meagan can choose to start A New Winter: the city resets, but Warmth Tokens and Veteran Jans carry over, so the second winter runs roughly twice as fast.

**Reset:** all buildings, resources, Research nodes and Jans except Veterans. The Jan collection is never reset.

**Kept:**

- Warmth Tokens, earned as 1 per Furnace level reached plus 1 per 10 Jans in the city at the thaw. First prestige yields about 14.
- Up to 3 Jans promoted to Veteran Jan (the player picks which). Veterans start the new winter already rescued, keep their variant bonus, and add +5% to all output each.
- Unlocked Jan variants stay unlockable from the start of the next winter.

**Warmth Token shop** (permanent, bought between winters):

Each rank costs the listed price; Warm start has one rank and its 50 Wood starts in the furnace as fuel. Tokens are banked when the thaw screen opens, so they can be spent before the new winter starts. Veterans are picked by kind of Jan, up to 3 plus Old friends.

| Bonus | Cost | Effect |
| --- | --- | --- |
| Warm start | 3 | Begin with Furnace Lv 2 and 50 Wood |
| Thick walls | 4 | Heat drain −5% per rank, 5 ranks |
| Fast feet | 4 | Jan arrival interval −10% per rank, 5 ranks |
| Deep pockets | 5 | Storehouse and Wood caps +25% per rank, 3 ranks |
| Old friends | 6 | +1 Veteran slot per rank, 2 ranks |
| Head start | 8 | All job rates +10% per rank, 5 ranks |

There is no hard ending. The simulator should confirm that by the fourth or fifth winter a full run takes under 3 hours of play, which is where the game settles into a comfortable daily habit rather than a grind.

## Personalisation content

The mechanics are generic; the writing is what makes this hers. All of it lives in plain JSON files so it can be edited without touching game code, and so Claude Code can scaffold the game before the writing is finished.

**Rescue lines** (`rescue_lines.json`): one short line a Jan says when thawed. Target 40 lines, 1 to 12 words each, weighted so rare lines appear less often. Variant Jans get 3 to 5 lines each in their own voice; plain Jans draw from the main pool.

**Jan collection bios** (`jans.json`): one or two sentences per variant for the collection screen, written as if cataloguing a species.

**Milestones** (`milestones.json`): 20 to 25 achievements that pop a card with a one-line message. Built triggers: building level, Jans in the city, Jans rescued ever, a variant found, every variant found, blizzards survived, attacks repelled, research nodes learned, and a pure date trigger for the secret one (fires on or after its `unlockDate`; an empty date keeps it off). Mix generic progress (first Furnace level) with dated or personal ones. Fields: id, trigger, title, message, optional unlock date (for ones that should only fire on or after a real date).

**Blizzard warnings and thaw message**: 5 warning lines, 1 thaw cutscene of 3 to 4 lines, 1 message for the first prestige.

**Idle chatter**: 15 to 20 lines that float above random Jans every 20 to 30 seconds while the city is calm. These do the most work for tone.

**Loading tips**: 10 fake survival tips in the style of the genre.

Placeholder drafts of everything below already exist in `src/content/` so the game runs; each item is ticked when the real writing replaces the draft.

- [ ] Write 40 rescue lines
- [ ] Write 10 to 12 Jan variant bios and pick the final roster
- [ ] Write 20 to 25 milestones with triggers
- [ ] Write blizzard, thaw and prestige lines
- [ ] Write 15 to 20 idle chatter lines
- [ ] Write 10 loading tips
- [ ] Decide the one secret: a milestone that only fires on a date that matters

## Screens & UI

Four screens plus overlays. The City screen is where 90% of play happens and it must work with one thumb.

| Screen | Purpose | What it shows |
| --- | --- | --- |
| City | Main play | Top bar: Heat gauge, Jan count vs cap, Wood, Food, Materials. Centre: the city as a scrolling 2D scene with Meagan at the furnace, Jans on their job tiles, arrivals at the edge. Bottom: a "next upgrade" card showing the cheapest useful purchase, and the blizzard forecast strip |
| Build | Overview of the city | Every building with level, what each level does, next cost and delivery progress. Go sends Meagan there (an unbuilt one gets a construction site on the nearest free plot); building itself happens on the map by carrying |
| Jans | Manage population | One row per job with its output, the kinds of Jan on it and −/+ buttons (+ takes an idle Jan first, else one from the job most over its share); food hunted vs eaten; Auto-assign switch |
| Collection | Reward | Grid of all Jan variants, discovered ones in colour with bio and count rescued, undiscovered as silhouettes |

Overlays: rescue moment (Meagan walks out, speech bubble, Jan joins), milestone card, blizzard warning banner, welcome-back card on launch showing the city's state and the next blizzard timer, thaw cutscene, Warmth Token shop.

Tap targets at least 44 pt; no gesture more complex than drag. Numbers animate when they change. A small bounce and sound on rescue and on purchase (iPhone home-screen web apps cannot trigger haptics). No ads, no timers to skip, no currency to buy.

## Tech & build plan

A mobile-first web game built on Windows with Claude Code and published to GitHub Pages; no Mac, Xcode or App Store account is involved. Meagan installs it from Safari with Add to Home Screen, where it opens full-screen with its own icon. The constants in the Economy section are the source of truth for the engine; tune them with a simulator (a small script that plays the game with a greedy bot and reports time-to-milestone) before changing them in code.

**Stack**

- Vite + TypeScript + Phaser 3 for the City scene; plain HTML/CSS overlays (or Phaser UI) for menus and cards
- One `GameEngine` module in `src/engine/` that owns the tick loop and all rules, with no Phaser or DOM code inside it, so it can be unit-tested with Vitest
- Fixed 10 ticks per second; the renderer reads state and never mutates it directly
- No offline progress: pause on `visibilitychange` (tab hidden or app backgrounded), resume on return
- Save: a JSON snapshot to `localStorage` on every purchase and every 30 seconds, plus a `lastSeen` timestamp for the welcome-back card; an Export save button that shows a copy-able code and an Import save that takes one back, because Safari can clear site storage
- Web app manifest, iOS `apple-mobile-web-app` meta tags, 192 px and 512 px icons, and a service worker so it loads offline once installed
- Content: `jans.json`, `rescue_lines.json`, `milestones.json`, `buildings.json`, `research.json` in `src/content/`; a `balance.ts` holding every constant from the Economy section
- Big-number formatting as a small helper (1.2K, 3.4M, 5.6B); plain JavaScript numbers are enough unless the simulator shows values past 1e15
- Unit tests on `GameEngine`: cost curve, pause and resume, heat-zero behaviour, prestige carry-over
- No backend, no analytics, no accounts, no ads

**Phases for Claude Code**, each a separate session with `CLAUDE.md` and this brief in the repository:

1. **Scaffold.** Vite + TypeScript + Phaser project, portrait layout scaled to an iPhone screen, manifest and iOS meta tags, a snowy background with the furnace and a heat bar. Runs with `npm run dev`.
2. **Engine.** Implement the Economy section in `src/engine/`: resources, Jans, jobs, buildings, costs, blizzards, tick loop, pause on hide, save/load, export/import code, and the unit tests. Wire the heat bar to the real engine.
3. **Meagan.** A controllable character with a placeholder sprite: tap to walk with pathfinding around buildings; tapping a building walks her there and performs its action. Also brought forward from Phase 4: plots, construction sites, her bag, piles and furnace fuel (see Carrying and building).
4. **Carrying and rescues.** Sled Shed (carry limit), scrap heap (early Materials), frozen Jans at the map edge that she walks out to thaw, and thawed Jans walking to the neediest job until the Jans screen exists.
5. **Screens.** Build, Jans and Collection screens as overlays driven by the engine; placeholder shapes for art.
6. **Content and juice.** Load the JSON content, milestones, rescue bubbles, idle chatter, blizzard banner, welcome-back card, number animations, sound effects.
7. **Prestige and polish.** Thaw cutscene, Warmth Token shop, tier visuals, app icon, GitHub Pages deployment with a GitHub Actions workflow.

Each phase ends with the game running on an iPhone: over Wi-Fi from the dev server (`npm run dev -- --host`) during development, and from the GitHub Pages link once deployed. Keep a `NOTES.md` in the repo where you log what felt wrong on the phone; it becomes the prompt for the next session.

## Art & assets

The art direction is ink & watercolour, a Nordic picture book (agreed 2026-10-20). Its rules, palette, character designs and prompt template are in `docs/art-direction.md`, which replaces the flat-cartoon plan and the sprite and SVG asset list that were here. Avoid anything that copies the look of Whiteout Survival's assets; the loop is fair game, the art is not. Meagan and the Jans are the assets that genuinely have to be good.

## Open questions

Decisions that change the build and are yours to make. None of them block Phase 1.

- [ ] Working title: Frostbite is a placeholder. The real title probably comes from an in-joke.
- [ ] Is the game a surprise? If yes, the avatars need to be made without her, which rules out photo-based apps on her phone.
- [ ] Public or private GitHub repository? GitHub Pages on a free account only publishes public repositories; private means testing over Wi-Fi until you make it public.
- [x] Does tapping a building auto-route Meagan there and perform the action? Yes: tapping auto-routes her there; deliveries happen by walking near (see Carrying and building).
- [ ] Idea: a Canteen building that cooks better meals from the food storage; Jans who eat better meals get boosted production. Needs numbers before it's built.
- [ ] Should any Jans be people other than you (a dog, a friend) or is it strictly all-Jans?
- [ ] Target launch moment, if any. The milestone list and the secret date depend on it.
