Use this as a **first tuning pass**, with difficulty driven by elapsed waves. **Remove the existing Furnace-based ×1.6 enemy scaling**; otherwise upgrading the town can make combat harder faster than the Armory helps.

The 20–25-minute loss target needs playtesting. One economy change is essential: **reduce fishing from 0.6 to 0.05 Food/s per Jan**. Currently, one fisher supports 36 Jans; ordinary theft is unlikely to cause sustained starvation.

**1) Armory**

Level 1 preserves current combat. Each purchased level `L = 1…10` costs:

`Wood = ceil(40 × 1.30^(L−1))`  
`Materials = ceil(12 × 1.24^(L−1))`

Build/upgrade time: **20 seconds**, one upgrade at a time. Bonuses replace previous values. No Furnace prerequisite.

| Lv | Snowball range / damage / interval | Stick reach / damage / interval / knockback | Guard damage/strike | Guard HP |
|---:|---|---|---:|---:|
| 1 | 7 m / 6 / 0.75 s | 2.5 m / 10 / 0.80 s / 0.35 m | 3 | 30 |
| 2 | 7.2 / 7 / 0.73 | 2.5 / 12 / 0.78 / 0.40 | 4 | 35 |
| 3 | 7.4 / 9 / 0.71 | 2.6 / 14 / 0.76 / 0.45 | 5 | 41 |
| 4 | 7.6 / 11 / 0.69 | 2.6 / 17 / 0.73 / 0.50 | 6 | 48 |
| 5 | 7.8 / 13 / 0.67 | 2.7 / 20 / 0.70 / 0.55 | 7 | 56 |
| 6 | 8.0 / 16 / 0.65 | 2.7 / 24 / 0.67 / 0.60 | 8 | 65 |
| 7 | 8.2 / 19 / 0.63 | 2.8 / 28 / 0.64 / 0.65 | 10 | 75 |
| 8 | 8.4 / 23 / 0.61 | 2.8 / 33 / 0.61 / 0.70 | 12 | 86 |
| 9 | 8.6 / 27 / 0.59 | 2.9 / 39 / 0.58 / 0.75 | 14 | 98 |
| 10 | 8.8 / 32 / 0.57 | 3.0 / 46 / 0.55 / 0.80 | 16 | 112 |

- Stick: **100° sweep, maximum 3 targets**, full damage each. Bears receive **25%** knockback; trolls **0%**.
- Enter stick mode at its reach; return to snowballs at **reach + 0.6 m**. Shared attack timer prevents swap exploits.
- Guards strike every **1 s**; unprovided kit halves damage. Armory construction equips existing guards; new guards require **5 Materials** for kit.

**2) Enemies**

Base values below. Cooldown runs from one attack’s impact to the next wind-up. Wedges and slams lock their position/direction when the tell begins.

| Enemy | HP | Speed m/s | Attack shape / reach | Tell | Damage | Cooldown | Steal capacity¹ | Kill loot | Wave cost | First wave |
|---|---:|---:|---|---:|---:|---:|---:|---|---:|---:|
| Frost fox | 10 | 3.6 | 45° bite wedge / 0.8 m | 0.45 s | 2 | 1.4 s | 5 | 1 Mat | 1 | 3 |
| Wolf | 20 | 2.5 | 60° bite wedge / 1.1 m | 0.40 s | 3 | 1.5 s | 8 | 1 Mat | 2 | 1 |
| Bear | 100 | 1.4 | 110° swipe wedge / 2.2 m | 0.90 s | 10 | 2.6 s | 20 | 5 Mat | 8 | 5 |
| Raider | 30 | 2.1 | Straight ice projectile / 6 m | 0.75 s | 4 | 2.0 s | 15 | 3 Mat | 4 | 4 |
| Ice troll | 240 | 1.1 | Filled circular slam / 3 m radius | 1.40 s | 16 | 4.5 s | 40 | 15 Mat | 20 | 6 |

¹Total resource units, not an amount per resource.

Raider projectiles travel **6 m/s**, radius **0.2 m**, without homing; lock aim **0.3 s before release**. Troll slam has **no safe centre**.

**Necessary AI change:** nearest-opponent targeting stays for Meagan and guards. Enemies pursue stores, fight the nearest defender within **4 m**, and resume their route after **3 s** without landing an attack. Otherwise Meagan can kite every raid indefinitely. Carriers flee without attacking.

**3) Waves**

- First wave: **4:00 active-play time**, independent of Furnace level.
- Gap between starts of waves `n` and `n+1`:  
  `max(75, 150 × 0.94^(n−1))` seconds.
- Warning: **15 s**, showing entry directions and enemy icons.
- Raw budget:  
  `R(n) = round(10 × 1.20^(n−1) × 1.15^floor((n−1)/5))`
- Spendable budget: `B = min(96, R)`.
- Overflow strength: `S = max(1, R/96)`. Multiply HP by **S**, damage by **√S**; round up. Speed, tells, stealing and loot remain unchanged.
- No scaling from Armory, player performance or current resources.

| Wave | Start | Raw budget |
|---:|---:|---:|
| 1 | 4:00 | 10 |
| 5 | 13:08 | 21 |
| 8 | 18:39 | 41 |
| 9 | 20:17 | 49 |
| 10 | 21:49 | 59 |
| 11 | 23:15 | 82 |
| 12 | 24:36 | 98 |
| 15 | 28:21 | 170 |

Composition:

- Waves 1–2: wolves only. Wave 3 guarantees **4 foxes**; wave 4 guarantees **2 raiders**; wave 5 guarantees **1 bear**.
- Every **6th wave**: exactly **1 troll**, paid from the budget first.
- Spend remaining points by weighted draws: wolf **40%**, fox **30%**, raider **20%**, bear **10%**. Exclude unavailable/unaffordable types.
- Maximum **40% of total budget in foxes**, **3 bears**, **6 raiders**. Guarantee at least **2 types** from wave 3. Discard an unspendable remainder.
- Spawn groups of **up to 6**, **6 s apart**, maximum **24 living raid enemies**; queue overflow.
- One approach through wave 4; **2 approaches at least 90° apart** thereafter. Spawn **18 m path-distance** from the nearest store.

**Tuning targets:** Armory 1 with two equipped guards should suffer decisive breaches during waves **9–11**. Armory **5 by minute 15**, **7 by minute 22**, and **10 by minute 30** should support survival beyond **35 minutes** with active defence. These are acceptance targets, not established results.

**4) Store-drain loss**

- Furnace and stockpiles access **one shared inventory**; additional buildings do not multiply available loot.
- Within **1 m**, an enemy channels theft for **2 s**. Damage interrupts it; retry after **1 s**.
- Take Food first, then Wood, then Materials, up to carrying capacity. Each enemy steals **once per raid**, then exits along its entry route at **80% normal speed**.
- Killing a carrier instantly restores its exact stolen contents. Storage overflow becomes a **60 s pickup bundle**. Ordinary kill loot is additional.
- Empty-handed enemies leave after a **2 s** unsuccessful theft attempt.
- At zero Food: **30 s grace**, then **one Jan leaves every 20 s**. Pause the timer while Food is positive; reset only after Food stays at **10+ for 20 s**.
- Departure order: **idle → woodworker → other worker → fisher → guard**. Meagan stays.
- When Wood reaches zero, retain heat drain `0.5 + 0.1 × Jans`; show **60 s of remaining warmth** at the current population, adjusting the countdown if population changes. Heat reaching zero ends the run.

**5) Optional outposts**

Roll once when a tile opens. Ring means tile-distance from the Furnace.

- Rings **0–1: 0%**; **2–3: 12%**; **4–5: 18%**; **6+: 24%**.
- Maximum **3 uncleared outposts**, at least **2 tiles apart**; never on the only traversable route.
- Ring multiplier: `P = min(2, 1 + 0.15 × max(0, ring−2))`; multiply defender HP by **P**, damage by **√P**.
- Defenders stay dormant until attacked or Meagan enters their **5 m alert radius**. Leash **10 m** from camp. Outposts never launch raids or steal.

| Kind | Selection weight | Defenders | Clear reward² |
|---|---:|---|---|
| Fox den | 35% | 6 foxes | 10 Materials |
| Wolf hollow | 30% | 4 wolves | 12 Materials |
| Raider camp | 25% | 3 raiders + 2 wolves | Chest: 18 Materials + 20 Wood |
| Bear cave | 10% | 1 bear + 2 wolves | Chest: 20 Materials + 15 Food |

²Multiply rewards by **P**, round up; enemy kill loot remains additional. Chest opens in **1 s**. Cleared camps never respawn. Before wave 5, redistribute the bear weight to fox dens.

**6) Five phone-readability / feel rules**

1. **Silhouette first:** fox = low body/large tail; wolf = long body; bear = broad shoulders; troll = tall asymmetric ice back; raider = upright hood/satchel. Minimum **24 px body height at 390 px viewport width**. Use original designs. Silhouette-first readability is consistent with [Fatshark’s enemy-art approach](https://forums.fatsharkgames.com/t/darktide-101-enemy-character-art-dev-blog/105178).
2. Telegraph every damaging attack with a **2 px rust outline**, **25% fill**, and a distinct sound. Keep ground cues free of paper grain.
3. Maximum **2 simultaneous melee wind-ups within 6 m of Meagan**; a troll slam consumes both slots. Allow at most **1 local raider wind-up** alongside them.
4. Carriers display a **16 px sack icon**, resource colour plus resource symbol, and a visible escape trail; theft displays the exact amount for **1 s**.
5. Hits use **0.06 s animation recoil**, **0.12 s ink flash**, and at most **2 px camera shake**. Loss uses retreat and cooling light; no gore.

To validate the loss timing, I need **starting Jans/resources, Wood income, Meagan’s HP/speed and defeat behaviour, guard recruitment/replacement rules, and typical route lengths**. In particular, retain fishing at 0.6 Food/s only if you accept a different loss mechanism or substantially larger theft.