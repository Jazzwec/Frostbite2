**Overall: 8.5/10** — up from round 4’s 8.  
**Readability: 8 · Feel/juice: 8 · Design depth/progression: 9 · Phone UX: 8.5.**

**Now at 9:** the Armory’s upgrade comparison and progression, and the attack-scheduling rules as described. The sampled frames cannot establish whether the scheduling consistently feels that good in motion.

1. **Separate bodies at contact, not just approach slots.**  
   `melee_close` still becomes a knot of wolves, weapon, health bars and hit effects. `outpost` has the same problem; `mixed_wave` is easier to parse because the bodies remain more distinct. On a phone, identifying the next attacker still takes deliberate inspection. Keep the 70° minimum, but target **100–120° separation** when space permits. Prevent waiting enemies from overlapping either active attacker’s silhouette. Keep enemy bars **8 px from Meagan’s bar**, with **6 px between displaced bars**, retaining the stems. This is the largest remaining obstacle to 9.

2. **Make locked attacks and recovery distinguishable without watching the entire animation.**  
   The cream lock edge is visible in `bear_swipe` and `troll_slam`, but it sits against almost white snow. The recovery poses still read partly as another orientation of a bulky body—especially the bear. Missing either state means taking damage or missing the counter window. At 540×960, use a consistent **3 px dark inner boundary plus 3 px cream outer boundary**, with the cream backed by the dark edge throughout. At recovery onset, remove the attack footprint immediately and put a small **ochre broken halo beneath the enemy**, lasting exactly the existing **0.42/0.55 s** window. Keep it behind the feet so it survives model replacement without adding another floating label.

3. **Give raider projectiles a readable flight silhouette.**  
   `raider_throw` is much less legible than the bear and troll attacks: white balls disappear into snow, while the small dark projectiles resemble debris. The thin targeting line carries more information than the attack itself. Give hostile projectiles a **10–12 px minimum silhouette**, **2 px dark blue-grey outline**, and **18–24 px tapered terracotta trail**. Keep Meagan’s snowballs cream and blue. Preserve a **12 px visible gap** between the projectile and the throwing hand at release. Players should recognise ownership and direction in peripheral vision.

4. **Move counter feedback out of the fight.**  
   In `melee_close`, “Counter!” covers Meagan and an attacker; in `mixed_wave`, it competes with the health bars. The existing impact centres also resemble small flowers when isolated in these frames. Keep the **32/40 px impact sizes**, but use **three or four unequal, directional rays** pointing away from contact. Place the introductory counter label **24 px above the highest nearby health bar**, at **22–24 px type**, for about **450 ms**. Keep the counter star at contact. The reward should clarify the successful hit without concealing the next threat.

5. **Make stolen supplies read as a pursuit objective, not ordinary loot.**  
   In `theft`, the sack-and-number badges are readable, but their gold treatment resembles the reward badges in `mixed_wave`. While Meagan is down, the enemy’s ownership of those supplies is less obvious than the respawn countdown. Put carried amounts on a **cream capsule with a 2 px terracotta border**, attached **8 px above the thief’s bar**. Use that exact capsule beside the offscreen arrow. On revival, hold “Recover stolen supplies!” below the top HUD for **2 seconds**, and pulse the nearest carrier’s capsule **twice over 600 ms**.

6. **Reduce the HUD’s competition during combat.**  
   `wave_hud` occupies roughly the top **215 px—22% of the screen**. Its amber countdown strip competes with the heat bar, while the next-wave composition asks players to decode four tiny silhouettes. The Armory comparison is clearer because its information has an explicit reading order. Make the countdown strip **cream with dark text**, turning amber only at **5 seconds**. Give each upcoming enemy icon-and-count pair **8 px separation**, with **18 px numerals**. After the composition has appeared for **3 seconds**, collapse that row until the final **5 seconds**, reclaiming roughly **30 px** during the fight.

Verdict: fix first — contact clutter and weak attack-state separation still obscure decisions at phone size.