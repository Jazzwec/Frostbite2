Use **snowballs at range and a wooden walking-stick sweep up close**. Both suit the picture-book world and read clearly without elaborate weapons. These are proposed starting values for playtesting.

1. **Meagan’s attacks**
   - **Ranged:** mitten-thrown snowball; **7 m range, 6 damage every 0.75 s** = **8 DPS**. Unlimited; no inventory cost. Projectile speed **18 m/s**, diameter **0.22 m**, shallow arc, slight homing toward the selected wolf. No splash or friendly fire.
   - **Melee:** walking-stick sweep; **2.5 m reach, 10 damage every 0.8 s** = **12.5 DPS**. Hits **one target**, despite the sweeping animation.
   - All combat distances use **horizontal centre-to-centre distance**; furnace distance uses its footprint edge.
   - These values make melee stronger and defeat a **20 HP wolf in two melee hits or four snowballs**.

2. **Automatic switching and movement**
   - Enter melee when the nearest enemy is **≤2.5 m** away. Return to ranged only after **no enemy is within 3 m for 0.3 s**.
   - During that hysteresis band, melee cannot hit beyond **2.5 m**; briefly wait rather than stretching the weapon.
   - Finish an attack already underway before switching. Use **one shared cooldown**; switching never resets it or grants an extra attack.
   - Attack while walking at **100% movement speed**. Rotate shoulders/body toward the target while legs follow movement; never auto-walk Meagan toward an enemy.
   - Pause gathering, building and depositing when an enemy enters **7 m**. Resume **1 s** after the last enemy leaves that radius or is defeated. Preserve progress and bag contents.

3. **One targeting rule, with explicit roles**
   - **Combatants select the nearest eligible opponent at each attack start**; lock that target through the attack. No mid-swing switching. Equal distances resolve by stable entity ID.
   - **Meagan:** nearest living wolf within her current attack range.
   - **Guards:** nearest wolf within **6 m**; pursue up to **8 m from their post**, then return. Keep **30 HP**, **1.6 m reach**; deal **3 damage every 1 s**.
   - **Wolves:** nearest Meagan/guard within **5 m**; otherwise move toward the furnace. Reconsider movement targets every **0.2 s**, but never change a committed bite.
   - **Workers are noncombatants:** flee when a wolf comes within **3 m**, at **3 m/s**, toward a sheltered muster point away from the approach. Resume after **3 s with no wolf within 5 m**. No fighting or worker-chasing detours.
   - At the furnace, require **1 s uninterrupted raiding** before applying the existing loss and leaving. Cancel the raid if a combatant enters **2.5 m**.

4. **Wolf bite**
   - **3 damage every 1.5 s** preserves the existing **2 DPS**.
   - Start within **1.4 m**: **0.40 s crouch/growl → 0.12 s lunge → 0.28 s recovery → 0.70 s cooldown**.
   - Lunge **0.6 m maximum**; stop at collisions. Track the victim for the first **0.25 s** of wind-up, then lock direction.
   - At impact, hit the committed victim only if within **0.95 m** and a **70° forward cone**. Moving clear avoids damage; no guaranteed hits after retreating.
   - Bite knockback: **0.15 m over 0.10 s**, without disabling player input. Ordinary hits never cancel wolf wind-ups; this prevents permanent stagger.

5. **Required procedural animations**
   
   | Animation | Timing and pose |
   |---|---|
   | Melee | **0.16 s** shoulder/body wind-up; **0.08 s** sweep, impact at **0.24 s**; **0.20 s** recovery; rest until **0.80 s** |
   | Snowball | **0.12 s** hand back; **0.06 s** throw, release at **0.18 s**; **0.18 s** recovery; rest until **0.75 s** |
   | Guard strike | Same melee poses; rest until **1 s** |
   | Wolf bite | Timings above; lower head/body during crouch, stretch forward during lunge |
   | Hit reaction | **0.06 s** lean/squash, **0.12 s** return; additive, without cancelling attacks |
   | Knockdown/defeat | **0.18 s** body tip, **0.12 s** settle; disable combat immediately at zero HP |
   
   For defeated wolves, follow the tumble with a **0.35 s scramble upright and 0.6 s fleeing fade**. No corpse or blood. Keep leg locomotion independent of upper-body attacks.

6. **Hit and defeat feedback**
   - Reference phone size: **390 logical pixels wide**; scale proportionally.
   - Every hit: **70 ms warm-cream tint**, **8% squash**, **4–6 watercolour flecks**, **12–18 px burst**, **0.18 s lifetime**, soft impact sound.
   - Wolf displacement from Meagan: **0.25 m melee**, **0.10 m ranged**, over **0.10 s**; guards: **0.10 m**.
   - Meagan melee impact: **50 ms attacker/victim visual hit-stop**—equivalent to three frames at 60 FPS. Keep simulation, joystick and camera responsive. Guard/projectile hits get **no hit-stop**.
   - Shake only when Meagan is bitten or defeats a wolf: **1.5 px, 90 ms**, maximum **once per 0.25 s**. Defeat adds **8 flecks across 24 px** and a distinct soft sound.
   - Damaged-unit HP bars: **24 × 3 px**, Meagan **36 × 4 px**; hide after **2 s** without damage. Damage numbers off.
   - Avoid full-screen flashes, stacked shake, gore and glowing particle clouds. Provide reduced-motion controls; communicate danger through pose and sound as well as colour. [Accessibility guidance](https://gameaccessibilityguidelines.com/full-list/)

7. **Readability with eight combatants in 6 m**
   - Give each unit a **0.35 m movement radius** and steer toward **0.8 m centre spacing**. Player movement takes priority over crowd avoidance.
   - Wolves and guards approach separate angular slots around their selected target; slots change positioning, **never target priority**.
   - Allow at most **two wolves winding up/lunging simultaneously** in the encounter, with wind-up starts separated by **≥0.25 s**. Waiting wolves circle without telegraphing.
   - Show only Meagan’s selected target marker: **18 px broken ink ring**. Show each committed bite with a **70° ground wedge matching its final hit area**, appearing during the **0.40 s wind-up**.
   - Offset overlapping HP bars vertically by **5 px**. Limit simultaneous impact sounds to **three** and live impact particles to **40**. Preserve enemy silhouettes above snow effects.

**The missing balance inputs are movement speeds, camera scale and Meagan’s upgrade curve.** Especially check wolf HP scaling: **20 × 1.6⁵ ≈ 210 HP** after five increases, requiring **21 base melee hits**. Match combat upgrades to that growth or soften the HP curve.