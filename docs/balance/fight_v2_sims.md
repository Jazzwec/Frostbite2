# Fight v2: the wave sims (2026-10-21)

Evidence for signing off the fight `[proto]` numbers (NOTES.md, "Fight v2"). Nothing here changes a number: it's what the current ones do.

**How it was made:** `godot --headless --path . -s res://tests/sim_waves.gd` prints every table below (this file is its output, with the reading on top). `WaveSim` (`tests/wave_sim.gd`) plays waves 1–20 on their real clock with seed 7: Meagan by the furnace, two guards, a level 1 Barracks, the store refilled every half second, no blizzards. It runs four Armory plans:

- **none, standing:** Armory 1 all run, with Meagan standing by the furnace;
- **none, defending:** Armory 1, with Meagan running at the raider nearest the store, as a player would;
- **late:** ChatGPT's upgrade schedule three minutes late;
- **schedule:** Armory 5 by 15:00, 7 by 22:00 and 10 by 30:00.

**Limits:**
- There's one seed and a simple player: the sim's Meagan never dodges a tell and never chases a thief past 14 m.
- The store is always full, so the pantry floor and starvation never come into play.
- The Armory sheet's "a wolf in N sweeps" line counts a strength-1 wolf, as the time-to-kill tables do. From wave 13 the waves are stronger than that.

## What it says

1. **The Armory curve does its job up to wave 17.**
   - Left at Armory 1, a defending Meagan holds waves 1–6. Wave 7 breaks through (31 lost), and waves 9–11 lose 50, 87 and 113, which is the steer's "decisive breaches by 9–11".
   - Three minutes late, the store holds until wave 13 (10 lost). Waves 14–18 then lose 47–156 each.
   - On schedule, nothing is lost until wave 16 (16), then 20 at wave 17.
2. **Past the spending cap, nothing answers the waves (from wave 18, about 32:00).**
   - From wave 12 a wave's budget is over 96, and its enemies get tougher instead: ×3.5 HP at wave 18 and ×5.1 at wave 20.
   - Armory 10 is the top, so even on schedule wave 18 loses 100, wave 19 223 and wave 20 168. A wolf at wave 20 takes 4 sweeps at Armory 10, and a troll 36.
   - So every winter ends in raids she can't hold by about 33 minutes, whatever she buys. That may be the intended end of a run, but it's a design call (see "Needs you" in AFK_REPORT.md).
3. **Guards fall early without upgrades.**
   - At Armory 1, the first guard falls in wave 4 when she stands, and in wave 7 when she defends. After that both go down in almost every raid. A downed guard stays down until the raid ends, and from wave 13 the raids overlap, so some raids start with both already down.
   - On schedule, no guard falls until wave 14 (27:41).
   - A bear needs 45 strikes from an Armory 1 guard and knocks one down in 3 hits, so a bear or troll wave without Meagan beside the guards always takes them out.
4. **Meagan goes down only in the late waves.**
   - Defending at Armory 1, she's first knocked down in wave 12. On schedule, it's wave 19.
   - Before that she's never down, so in this sim `MEAGAN_DOWN_TIME`, `MEAGAN_GETUP_HP` and `CATCH_GRACE` matter only once a run is already lost.
5. **Counters are a small share of the damage.**
   - About one in eight of her hits lands on a recovering enemy (1–25% a raid), and about a quarter of the guards' (0–60%). The guards' share is higher because they stand still while being struck.
   - The 1.5× is a bonus for good timing, not something the balance depends on: the sim's Meagan never aims for it.
6. **The two-striker cap holds:** never more than 2 melee enemies attack her at once, even with 24 on the map.

## The `[proto]` numbers, row by row

| Number (balance.gd) | Value | What it does in the sim |
|---|---|---|
| `ENEMIES` HP (35–45% over the steer's) | fox 14, wolf 29, raider 43, bear 135, troll 320 | The time-to-kill tables. At Armory 1 a wolf takes 3 sweeps (1.8 s) and a bear 14 (10.6 s). At Armory 10 it's 1 and 3. The HP sets where the schedule plan stops holding (wave 16–17) and where Armory 1 breaks (wave 7). |
| `ENEMIES` wind-ups (`tell`) and `lock` | 0.65–1.2 s; bear 0.45, troll 0.55 | They set each kind's attack cycle (the "About every" column) and so how often bites land: in the defending runs a third to all of the bites in a raid land, because the sim's Meagan doesn't step out of tells. The dodge window they make is untested by the sim. |
| `ENEMIES` recoveries (`recover`) | 0.6–0.7 s | The window counted as "on recovery": about one in eight of her hits and a quarter of the guards'. |
| `ENEMIES` widths, `ENEMY_GAP` | 0.56–1.26 m; 0.9 | Spacing only. They don't change any count in the sim. They limit how many fit round a defender, which the striker cap already bounds. |
| `STEAL_FOOD_FLOOR_PER_JAN` | 3 Food per Jan | Never reached: the sim keeps the store full. It needs a sim with a real economy, or a playtest. |
| `MEAGAN_DOWN_TIME`, `MEAGAN_GETUP_HP` | 6 s, half HP | Her downs: none before wave 12 at Armory 1, or wave 19 on schedule. After that, about one a wave. She's back in each raid it happens in. |
| `CATCH_GRACE` | 3 s | "Caught" counts thieves killed while carrying. There are 0–2 a wave, and she's rarely down in a wave that's still being held, so the grace seldom decides one. Its real job, letting the player catch up after a knock-down, needs a playtest. |
| `RECOVERY_DAMAGE_MULT` | 1.5× | As for recoveries above. With about one in eight of her hits on a recovery, it adds about 6% to her damage. The time-to-kill tables show the counter count in brackets: a wolf in 2 counters, not 3 sweeps, at Armory 1. |
| `ENEMY_MAX_ENGAGED`, `ENEMY_WAIT_BACK` | 2 strikers; 1.8 widths | "Most attacking her at once" is never over 2. |
| `ENEMY_WINDUP_STAGGER` | 0.3 s | It spaces her two attackers' tells, so they don't start together. It's a readability rule, and the sim doesn't count it. |
| `STRIKE_SLOTS` / `WAIT_SLOTS` | −10°/190°; −55°/235° | Placement only (her sides and diagonals). No effect on the counts. |
| `MELEE_EXIT_MULT` (with `MEAGAN_MELEE_EXIT_TIME`) | 1.25× reach, 0.4 s | Mode swaps: 2–26 a raid. Without the hysteresis she would swap every time an enemy crosses 2.5 m. |
| `MEAGAN_TARGET_HOLD` | 0.4 s | Keeps her on one target. The sim has no count for it; its effect is on what the player can predict. |
| `OUTPOST_WAKE` | 0.8 s | Not exercised: there are no outposts in the wave sim. F2 adds tests for the wake. |
| `ENEMY_AIM_LOCK` | 0.4 s | As for the wind-ups above: the sim never dodges, so the misses in the defending runs come from her running, not from reading the lock. |

## The waves

| Wave | Starts | Gap to next | Budget | Spent | Strength (HP ×) | Make-up (seed 7) |
|---:|---:|---:|---:|---:|---:|---|
| 1 | 4:00 | 150 s | 10 | 10 | 1.00 | 5 wolf |
| 2 | 6:30 | 141 s | 12 | 12 | 1.00 | 6 wolf |
| 3 | 8:51 | 132 s | 14 | 14 | 1.00 | 4 wolf, 6 fox |
| 4 | 11:03 | 124 s | 17 | 17 | 1.00 | 3 raider, 1 wolf, 3 fox |
| 5 | 13:08 | 117 s | 21 | 21 | 1.00 | 2 bear, 1 wolf, 3 fox |
| 6 | 15:05 | 110 s | 29 | 29 | 1.00 | 1 troll, 1 bear, 1 fox |
| 7 | 16:55 | 103 s | 34 | 34 | 1.00 | 1 bear, 1 raider, 9 wolf, 4 fox |
| 8 | 18:38 | 97 s | 41 | 41 | 1.00 | 2 bear, 2 raider, 8 wolf, 1 fox |
| 9 | 20:16 | 91 s | 49 | 49 | 1.00 | 1 bear, 6 raider, 8 wolf, 1 fox |
| 10 | 21:47 | 85 s | 59 | 59 | 1.00 | 3 bear, 4 raider, 7 wolf, 5 fox |
| 11 | 23:13 | 80 s | 82 | 82 | 1.00 | 6 raider, 21 wolf, 16 fox |
| 12 | 24:34 | 75 s | 98 | 96 | 1.02 | 1 troll, 2 bear, 6 raider, 11 wolf, 14 fox |
| 13 | 25:50 | 75 s | 118 | 96 | 1.23 | 3 bear, 6 raider, 18 wolf, 12 fox |
| 14 | 27:05 | 75 s | 141 | 96 | 1.47 | 3 bear, 6 raider, 19 wolf, 10 fox |
| 15 | 28:20 | 75 s | 170 | 96 | 1.77 | 3 bear, 6 raider, 20 wolf, 8 fox |
| 16 | 29:35 | 75 s | 234 | 96 | 2.44 | 3 bear, 6 raider, 14 wolf, 20 fox |
| 17 | 30:50 | 75 s | 281 | 96 | 2.93 | 3 bear, 6 raider, 19 wolf, 10 fox |
| 18 | 32:05 | 75 s | 337 | 96 | 3.51 | 1 troll, 3 bear, 4 raider, 14 wolf, 8 fox |
| 19 | 33:20 | 75 s | 405 | 96 | 4.22 | 3 bear, 6 raider, 15 wolf, 18 fox |
| 20 | 34:35 | 75 s | 486 | 96 | 5.06 | 3 bear, 6 raider, 18 wolf, 12 fox |

## Armory: none, Meagan standing by the furnace

| Wave | At | Armory | Enemies | Most alive | Thefts | Lost | Caught | Her downs | Guards down (first) | Her hits (on recovery) | Guard hits (on recovery) | Bites landed | Most attacking her at once | Mode swaps | Over |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|
| 1 | 4:00 | 1 | 5 | 6 | 1 | 8 | 0 | 0 | 0 | 14 (14%) | 10 (50%) | 6 of 6 | 0 | 0 | 4:34 |
| 2 | 6:30 | 1 | 6 | 6 | 2 | 16 | 0 | 0 | 0 | 14 (7%) | 13 (23%) | 7 of 7 | 0 | 0 | 6:59 |
| 3 | 8:51 | 1 | 10 | 10 | 4 | 23 | 0 | 0 | 0 | 18 (11%) | 12 (42%) | 8 of 8 | 0 | 0 | 9:20 |
| 4 | 11:04 | 1 | 8 | 8 | 2 | 10 | 0 | 0 | 1 (11:24) | 32 (0%) | 9 (11%) | 4 of 4 | 0 | 4 | 11:39 |
| 5 | 13:08 | 1 | 8 | 8 | 2 | 28 | 0 | 0 | 1 (13:28) | 21 (14%) | 13 (38%) | 10 of 10 | 0 | 0 | 14:06 |
| 6 | 15:05 | 1 | 5 | 6 | 0 | 0 | 0 | 0 | 1 (15:24) | 66 (3%) | 12 (42%) | 7 of 7 | 0 | 0 | 16:15 |
| 7 | 16:56 | 1 | 13 | 13 | 9 | 81 | 0 | 0 | 2 (17:12) | 26 (4%) | 21 (33%) | 15 of 16 | 0 | 0 | 17:46 |
| 8 | 18:39 | 1 | 13 | 13 | 5 | 70 | 0 | 0 | 2 (19:01) | 41 (10%) | 20 (20%) | 11 of 11 | 2 | 2 | 19:40 |
| 9 | 20:16 | 1 | 17 | 17 | 11 | 111 | 0 | 1 | 2 (20:33) | 38 (11%) | 20 (15%) | 18 of 18 | 1 | 2 | 21:20 |
| 10 | 21:47 | 1 | 19 | 19 | 14 | 157 | 0 | 0 | 2 (22:10) | 25 (12%) | 17 (12%) | 11 of 11 | 0 | 0 | 22:50 |
| 11 | 23:13 | 1 | 37 | 24 | 27 | 247 | 0 | 1 | 2 (23:36) | 49 (20%) | 16 (31%) | 21 of 21 | 2 | 6 | 24:21 |
| 12 | 24:34 | 1 | 38 | 24 | 23 | 232 | 0 | 0 | 2 (25:00) | 53 (9%) | 19 (16%) | 16 of 16 | 2 | 10 | 25:50 |
| 13 | 25:50 | 1 | 39 | 24 | 30 | 265 | 1 | 1 | 2 (26:16) | 56 (14%) | 16 (19%) | 19 of 19 | 2 | 8 | — |
| 14 | 27:05 | 1 | 39 | 24 | 37 | 344 | 0 | 1 | 0 | 34 (3%) | 0 (—) | 0 of 0 | 0 | 0 | 28:14 |
| 15 | 28:20 | 1 | 42 | 24 | 38 | 317 | 0 | 0 | 2 (28:37) | 49 (10%) | 10 (30%) | 6 of 6 | 0 | 0 | 29:27 |
| 16 | 29:35 | 1 | 47 | 24 | 44 | 358 | 0 | 1 | 2 (29:54) | 54 (7%) | 11 (9%) | 7 of 7 | 1 | 2 | 30:43 |
| 17 | 30:51 | 1 | 36 | 24 | 30 | 309 | 0 | 1 | 2 (31:12) | 60 (12%) | 11 (45%) | 19 of 20 | 2 | 4 | 32:04 |
| 18 | 32:06 | 1 | 29 | 24 | 29 | 311 | 0 | 1 | 2 (32:29) | 37 (11%) | 10 (50%) | 7 of 7 | 0 | 0 | 33:14 |
| 19 | 33:21 | 1 | 40 | 24 | 40 | 356 | 0 | 1 | 2 (33:44) | 53 (2%) | 11 (36%) | 7 of 7 | 0 | 0 | — |
| 20 | 34:36 | 1 | 43 | 24 | 43 | 368 | 0 | 2 | 0 | 65 (6%) | 0 (—) | 9 of 9 | 2 | 2 | — |

## Armory: none, Meagan defending

| Wave | At | Armory | Enemies | Most alive | Thefts | Lost | Caught | Her downs | Guards down (first) | Her hits (on recovery) | Guard hits (on recovery) | Bites landed | Most attacking her at once | Mode swaps | Over |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|
| 1 | 4:00 | 1 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 12 (17%) | 8 (50%) | 6 of 9 | 2 | 2 | 4:20 |
| 2 | 6:30 | 1 | 6 | 6 | 1 | 0 | 1 | 0 | 0 | 15 (13%) | 10 (30%) | 7 of 7 | 0 | 2 | 6:48 |
| 3 | 8:51 | 1 | 10 | 10 | 0 | 0 | 0 | 0 | 0 | 21 (10%) | 9 (44%) | 10 of 11 | 2 | 4 | 9:10 |
| 4 | 11:04 | 1 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 24 (25%) | 5 (60%) | 3 of 6 | 1 | 10 | 11:31 |
| 5 | 13:08 | 1 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 32 (16%) | 15 (20%) | 7 of 9 | 1 | 12 | 13:49 |
| 6 | 15:05 | 1 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 43 (12%) | 4 (0%) | 6 of 6 | 1 | 8 | 15:49 |
| 7 | 16:56 | 1 | 13 | 12 | 3 | 31 | 0 | 0 | 2 (17:14) | 38 (18%) | 23 (26%) | 20 of 21 | 2 | 6 | 17:43 |
| 8 | 18:39 | 1 | 13 | 13 | 0 | 0 | 0 | 0 | 1 (19:05) | 60 (7%) | 22 (18%) | 10 of 13 | 1 | 12 | 19:38 |
| 9 | 20:16 | 1 | 17 | 17 | 4 | 50 | 0 | 0 | 2 (20:36) | 40 (13%) | 21 (19%) | 15 of 16 | 1 | 10 | 21:07 |
| 10 | 21:47 | 1 | 19 | 19 | 7 | 87 | 0 | 0 | 2 (22:16) | 59 (8%) | 19 (26%) | 21 of 21 | 2 | 12 | 23:01 |
| 11 | 23:13 | 1 | 37 | 24 | 13 | 113 | 0 | 0 | 2 (23:37) | 79 (14%) | 19 (21%) | 12 of 21 | 2 | 22 | 24:20 |
| 12 | 24:34 | 1 | 38 | 24 | 16 | 196 | 0 | 1 | 2 (25:02) | 78 (10%) | 20 (30%) | 22 of 26 | 2 | 5 | — |
| 13 | 25:50 | 1 | 39 | 24 | 22 | 241 | 0 | 1 | 0 | 75 (12%) | 0 (—) | 7 of 15 | 2 | 11 | 27:05 |
| 14 | 27:05 | 1 | 39 | 24 | 30 | 294 | 0 | 1 | 2 (27:29) | 67 (12%) | 14 (14%) | 19 of 24 | 2 | 10 | — |
| 15 | 28:20 | 1 | 42 | 24 | 32 | 304 | 0 | 1 | 0 | 70 (1%) | 0 (—) | 4 of 12 | 2 | 8 | 29:29 |
| 16 | 29:35 | 1 | 47 | 24 | 34 | 299 | 0 | 1 | 2 (29:56) | 90 (7%) | 12 (17%) | 17 of 35 | 2 | 12 | — |
| 17 | 30:51 | 1 | 36 | 24 | 31 | 314 | 0 | 1 | 0 | 66 (11%) | 0 (—) | 10 of 21 | 2 | 8 | — |
| 18 | 32:06 | 1 | 29 | 24 | 25 | 285 | 0 | 1 | 0 | 57 (7%) | 0 (—) | 2 of 6 | 2 | 8 | 33:11 |
| 19 | 33:21 | 1 | 40 | 24 | 35 | 322 | 0 | 1 | 2 (33:44) | 78 (18%) | 10 (30%) | 14 of 28 | 2 | 9 | — |
| 20 | 34:36 | 1 | 43 | 24 | 41 | 358 | 0 | 1 | 0 | 74 (11%) | 0 (—) | 12 of 20 | 2 | 10 | — |

## Armory: late, Meagan defending

| Wave | At | Armory | Enemies | Most alive | Thefts | Lost | Caught | Her downs | Guards down (first) | Her hits (on recovery) | Guard hits (on recovery) | Bites landed | Most attacking her at once | Mode swaps | Over |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|
| 1 | 4:00 | 1 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 12 (17%) | 8 (50%) | 6 of 9 | 2 | 2 | 4:20 |
| 2 | 6:30 | 1 | 6 | 6 | 1 | 0 | 1 | 0 | 0 | 15 (13%) | 10 (30%) | 7 of 7 | 0 | 2 | 6:48 |
| 3 | 8:51 | 1 | 10 | 10 | 1 | 0 | 1 | 0 | 0 | 19 (11%) | 9 (44%) | 9 of 10 | 2 | 4 | 9:09 |
| 4 | 11:04 | 2 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 20 (15%) | 4 (25%) | 1 of 2 | 1 | 4 | 11:27 |
| 5 | 13:08 | 3 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 26 (4%) | 6 (33%) | 4 of 4 | 1 | 12 | 13:38 |
| 6 | 15:05 | 4 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 28 (11%) | 1 (0%) | 3 of 3 | 1 | 8 | 15:35 |
| 7 | 16:56 | 4 | 13 | 12 | 0 | 0 | 0 | 0 | 0 | 31 (6%) | 14 (14%) | 3 of 4 | 1 | 6 | 17:27 |
| 8 | 18:39 | 5 | 13 | 12 | 0 | 0 | 0 | 0 | 0 | 29 (14%) | 10 (10%) | 4 of 4 | 1 | 8 | 19:09 |
| 9 | 20:16 | 5 | 17 | 16 | 1 | 5 | 0 | 0 | 1 (20:40) | 35 (11%) | 16 (38%) | 13 of 13 | 2 | 6 | 20:51 |
| 10 | 21:47 | 6 | 19 | 18 | 0 | 0 | 0 | 0 | 1 (22:22) | 40 (15%) | 19 (11%) | 10 of 12 | 1 | 12 | 22:28 |
| 11 | 23:13 | 6 | 37 | 21 | 0 | 0 | 0 | 0 | 1 (23:50) | 58 (9%) | 29 (17%) | 15 of 16 | 1 | 20 | 23:56 |
| 12 | 24:34 | 6 | 38 | 21 | 0 | 0 | 0 | 0 | 1 (25:18) | 58 (14%) | 36 (17%) | 12 of 14 | 0 | 22 | 25:25 |
| 13 | 25:50 | 7 | 39 | 24 | 3 | 10 | 1 | 0 | 1 (26:24) | 64 (17%) | 30 (40%) | 21 of 22 | 2 | 12 | 26:47 |
| 14 | 27:05 | 7 | 39 | 24 | 15 | 123 | 0 | 0 | 2 (27:36) | 56 (9%) | 24 (29%) | 18 of 20 | 1 | 14 | 28:01 |
| 15 | 28:20 | 8 | 42 | 24 | 7 | 47 | 0 | 0 | 2 (28:53) | 71 (11%) | 33 (21%) | 28 of 28 | 1 | 14 | 29:15 |
| 16 | 29:35 | 8 | 47 | 24 | 17 | 97 | 2 | 0 | 2 (30:09) | 90 (8%) | 30 (23%) | 19 of 25 | 2 | 20 | 30:38 |
| 17 | 30:51 | 9 | 36 | 24 | 13 | 92 | 0 | 0 | 2 (31:22) | 95 (7%) | 24 (17%) | 19 of 21 | 2 | 12 | 31:48 |
| 18 | 32:06 | 9 | 29 | 24 | 15 | 156 | 0 | 0 | 2 (32:39) | 64 (13%) | 27 (30%) | 18 of 21 | 1 | 14 | — |
| 19 | 33:21 | 10 | 40 | 24 | 18 | 208 | 0 | 1 | 0 | 71 (0%) | 0 (—) | 2 of 2 | 2 | 16 | 34:22 |
| 20 | 34:36 | 10 | 43 | 24 | 16 | 168 | 0 | 1 | 2 (35:05) | 111 (11%) | 25 (32%) | 22 of 27 | 2 | 12 | — |

## Armory: schedule, Meagan defending

| Wave | At | Armory | Enemies | Most alive | Thefts | Lost | Caught | Her downs | Guards down (first) | Her hits (on recovery) | Guard hits (on recovery) | Bites landed | Most attacking her at once | Mode swaps | Over |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---|---|---:|---:|---:|
| 1 | 4:00 | 1 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 12 (17%) | 8 (50%) | 6 of 9 | 2 | 2 | 4:20 |
| 2 | 6:30 | 2 | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 14 (14%) | 7 (43%) | 3 of 3 | 0 | 2 | 6:45 |
| 3 | 8:51 | 2 | 10 | 10 | 0 | 0 | 0 | 0 | 0 | 17 (18%) | 5 (40%) | 3 of 6 | 2 | 4 | 9:05 |
| 4 | 11:04 | 3 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 18 (17%) | 2 (50%) | 1 of 2 | 1 | 4 | 11:26 |
| 5 | 13:08 | 4 | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 23 (13%) | 3 (0%) | 3 of 3 | 1 | 8 | 13:33 |
| 6 | 15:05 | 5 | 5 | 6 | 0 | 0 | 0 | 0 | 0 | 26 (8%) | 1 (0%) | 2 of 2 | 1 | 8 | 15:33 |
| 7 | 16:56 | 5 | 13 | 12 | 0 | 0 | 0 | 0 | 0 | 27 (11%) | 16 (13%) | 5 of 7 | 1 | 8 | 17:27 |
| 8 | 18:39 | 6 | 13 | 12 | 0 | 0 | 0 | 0 | 0 | 25 (20%) | 9 (44%) | 6 of 6 | 1 | 8 | 19:06 |
| 9 | 20:16 | 6 | 17 | 16 | 0 | 0 | 0 | 0 | 0 | 34 (18%) | 15 (20%) | 9 of 9 | 1 | 8 | 20:46 |
| 10 | 21:47 | 6 | 19 | 18 | 0 | 0 | 0 | 0 | 0 | 35 (14%) | 22 (5%) | 5 of 7 | 1 | 8 | 22:25 |
| 11 | 23:13 | 7 | 37 | 22 | 0 | 0 | 0 | 0 | 0 | 49 (8%) | 29 (21%) | 11 of 14 | 1 | 18 | 23:56 |
| 12 | 24:34 | 7 | 38 | 22 | 0 | 0 | 0 | 0 | 0 | 53 (11%) | 32 (19%) | 13 of 15 | 0 | 20 | 25:25 |
| 13 | 25:50 | 8 | 39 | 23 | 1 | 0 | 1 | 0 | 0 | 59 (15%) | 30 (37%) | 17 of 18 | 1 | 16 | 26:36 |
| 14 | 27:05 | 8 | 39 | 24 | 0 | 0 | 0 | 0 | 1 (27:41) | 62 (10%) | 36 (36%) | 21 of 23 | 1 | 20 | 27:52 |
| 15 | 28:20 | 9 | 42 | 24 | 0 | 0 | 0 | 0 | 1 (29:05) | 71 (13%) | 36 (28%) | 20 of 20 | 1 | 22 | 29:09 |
| 16 | 29:35 | 9 | 47 | 22 | 3 | 16 | 1 | 0 | 0 | 77 (9%) | 37 (19%) | 17 of 18 | 2 | 26 | 30:24 |
| 17 | 30:51 | 10 | 36 | 24 | 4 | 20 | 0 | 0 | 1 (31:25) | 86 (9%) | 32 (28%) | 18 of 21 | 1 | 12 | 31:44 |
| 18 | 32:06 | 10 | 29 | 24 | 7 | 100 | 0 | 0 | 1 (32:44) | 73 (11%) | 36 (31%) | 21 of 21 | 1 | 22 | — |
| 19 | 33:21 | 10 | 40 | 24 | 19 | 223 | 0 | 1 | 1 (33:44) | 75 (1%) | 3 (0%) | 4 of 5 | 1 | 14 | 34:26 |
| 20 | 34:36 | 10 | 43 | 24 | 16 | 168 | 0 | 1 | 2 (35:05) | 111 (11%) | 25 (32%) | 22 of 27 | 2 | 12 | — |

## Time to kill (strength 1)

### Stick sweeps: hits, seconds (hits on a recovering enemy, ×1.5)

| Armory | Frost fox | Wolf | Raider | Bear | Ice troll |
|---:|---|---|---|---|---|
| 1 | 2, 1.0 s (1) | 3, 1.8 s (2) | 5, 3.4 s (3) | 14, 10.6 s (9) | 32, 25.0 s (22) |
| 2 | 2, 1.0 s (1) | 3, 1.8 s (2) | 4, 2.5 s (3) | 12, 8.8 s (8) | 27, 20.5 s (18) |
| 3 | 1, 0.2 s (1) | 3, 1.7 s (2) | 4, 2.5 s (3) | 10, 7.0 s (7) | 23, 16.9 s (16) |
| 4 | 1, 0.2 s (1) | 2, 0.9 s (2) | 3, 1.7 s (2) | 8, 5.3 s (6) | 19, 13.3 s (13) |
| 5 | 1, 0.2 s (1) | 2, 0.9 s (1) | 3, 1.6 s (2) | 7, 4.4 s (5) | 16, 10.7 s (11) |
| 6 | 1, 0.2 s (1) | 2, 0.9 s (1) | 2, 0.9 s (2) | 6, 3.6 s (4) | 14, 8.9 s (9) |
| 7 | 1, 0.2 s (1) | 2, 0.8 s (1) | 2, 0.8 s (2) | 5, 2.8 s (4) | 12, 7.2 s (8) |
| 8 | 1, 0.2 s (1) | 1, 0.2 s (1) | 2, 0.8 s (1) | 5, 2.6 s (3) | 10, 5.7 s (7) |
| 9 | 1, 0.2 s (1) | 1, 0.2 s (1) | 2, 0.8 s (1) | 4, 1.9 s (3) | 9, 4.8 s (6) |
| 10 | 1, 0.2 s (1) | 1, 0.2 s (1) | 1, 0.2 s (1) | 3, 1.3 s (2) | 7, 3.5 s (5) |

### Snowballs: hits, seconds at 5 m

| Armory | Frost fox | Wolf | Raider | Bear | Ice troll |
|---:|---|---|---|---|---|
| 1 | 3, 2.0 s | 5, 3.5 s | 8, 5.7 s | 23, 17.0 s | 54, 40.2 s |
| 2 | 2, 1.2 s | 5, 3.4 s | 7, 4.8 s | 20, 14.3 s | 46, 33.3 s |
| 3 | 2, 1.2 s | 4, 2.6 s | 5, 3.3 s | 15, 10.4 s | 36, 25.3 s |
| 4 | 2, 1.1 s | 3, 1.8 s | 4, 2.5 s | 13, 8.7 s | 30, 20.5 s |
| 5 | 2, 1.1 s | 3, 1.8 s | 4, 2.5 s | 11, 7.2 s | 25, 16.5 s |
| 6 | 1, 0.5 s | 2, 1.1 s | 3, 1.8 s | 9, 5.7 s | 20, 12.8 s |
| 7 | 1, 0.5 s | 2, 1.1 s | 3, 1.7 s | 8, 4.9 s | 17, 10.5 s |
| 8 | 1, 0.5 s | 2, 1.1 s | 2, 1.1 s | 6, 3.5 s | 14, 8.4 s |
| 9 | 1, 0.5 s | 2, 1.0 s | 2, 1.0 s | 5, 2.8 s | 12, 6.9 s |
| 10 | 1, 0.5 s | 1, 0.5 s | 2, 1.0 s | 5, 2.7 s | 10, 5.6 s |

### One guard's strikes (one a second, Barracks Lv 1), and the guard's HP

| Armory | Guard HP | Frost fox | Wolf | Raider | Bear | Ice troll |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 30 | 5 | 10 | 15 | 45 | 107 |
| 2 | 35 | 4 | 8 | 11 | 34 | 80 |
| 3 | 41 | 3 | 6 | 9 | 27 | 64 |
| 4 | 48 | 3 | 5 | 8 | 23 | 54 |
| 5 | 56 | 2 | 5 | 7 | 20 | 46 |
| 6 | 65 | 2 | 4 | 6 | 17 | 40 |
| 7 | 75 | 2 | 3 | 5 | 14 | 32 |
| 8 | 86 | 2 | 3 | 4 | 12 | 27 |
| 9 | 98 | 1 | 3 | 4 | 10 | 23 |
| 10 | 112 | 1 | 2 | 3 | 9 | 20 |

### Past the spending cap: stick sweeps at Armory 10 as the waves' strength grows

| Wave | Strength | Frost fox | Wolf | Raider | Bear | Ice troll |
|---:|---:|---:|---:|---:|---:|---:|
| 12 | 1.02 | 1 | 1 | 1 | 3 | 8 |
| 13 | 1.23 | 1 | 1 | 2 | 4 | 9 |
| 14 | 1.47 | 1 | 1 | 2 | 5 | 11 |
| 15 | 1.77 | 1 | 2 | 2 | 6 | 13 |
| 16 | 2.44 | 1 | 2 | 3 | 8 | 17 |
| 17 | 2.93 | 1 | 2 | 3 | 9 | 21 |
| 18 | 3.51 | 2 | 3 | 4 | 11 | 25 |
| 19 | 4.22 | 2 | 3 | 4 | 13 | 30 |
| 20 | 5.06 | 2 | 4 | 5 | 15 | 36 |

### What each kind does to a defender: hits to knock down Meagan (100 HP) and a guard (Armory 1 / 10)

| Kind | Damage | About every | Meagan | Guard Lv 1 | Guard Lv 10 |
|---|---:|---:|---:|---:|---:|
| Frost fox | 2 | 2.0 s | 50 | 15 | 56 |
| Wolf | 3 | 2.1 s | 34 | 10 | 38 |
| Raider | 4 | 3.0 s | 25 | 8 | 28 |
| Bear | 10 | 3.5 s | 10 | 3 | 12 |
| Ice troll | 16 | 5.7 s | 7 | 2 | 7 |

