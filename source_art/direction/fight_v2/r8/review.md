**Overall: 8.9/10.** Readability **8.9**, feel/juice **8.7**, design depth/progression **9.0**, phone UX **9.0**.

**Design/progression and phone UX are at 9 now.** The remaining gap is combat feedback: distinguishing danger, opportunity and contact when several things overlap. Final creature models are not the blocker. Timing recommendations below need checking at normal speed; the slowed strips make anticipation easier to read.

1. **Make contact the strongest visual event.**  
   **See:** Across mixed-wave, melee and outpost, the visible hit sparks remain small punctuation between bodies. The troll’s raised arms read more clearly than its landing; its impact is a faint pale ring.  
   **Phone cost:** Players can identify an attack without confidently seeing whether it connected, countered or killed.  
   **Change:** Keep the 25/32 px bursts, but place their centres at the visible contact edge and carry **at least 12–16 px of rays beyond the silhouette**. Give ordinary hits **50–60 ms hit-stop** and counters **80–90 ms**, affecting the combatants. Add **6–8 px recoil over 90 ms**. Give the troll landing a **100–140 ms irregular snow splash**, clearly stronger than its preparation.

2. **Separate incoming danger from the counter opportunity.**  
   **See:** Bear and troll danger areas use pale washes and dark outlines; the counter rings introduce another outlined ground shape. In close melee, ring segments also compete with weapon trails.  
   **Phone cost:** The player must interpret several similar marks precisely when attention is busiest.  
   **Change:** Reserve **ochre exclusively for the counter window**. Use muted terracotta **#B75F49 at 16–20% opacity**, with a **2 px perimeter**, for incoming danger. Remove that area when the counter window starts. Use a brighter cream trail without an ochre outline for Meagan’s swing. Preserve the current **0.6–0.7 s** window before changing balance.

3. **Make counter-ring depletion unambiguous.**  
   **See:** The segmented rings are visible around wolves, but bear and troll bodies obscure substantial portions. Separate ochre fragments can read as miscellaneous action effects.  
   **Phone cost:** “Counter available” is more apparent than “how much time remains.”  
   **Change:** Fit the ellipse to each creature’s ground silhouette with **8–10 px clearance**. Keep the existing stroke weight; add a **5 px cream leading bead** to the clockwise depletion edge. Fade spent segments completely. Avoid pulsing or expanding the ring, which would confuse time remaining with attack range.

4. **Strengthen offscreen threat priority.**  
   **See:** In `wave_hud`, the muted **“20m ×4”** marker is much quieter than the two ochre wave arrows, and its label is small.  
   **Phone cost:** A general spawn warning can command more attention than an enemy already preparing an attack.  
   **Change:** Use **16 px semibold distance/count text** on a compact cream backing. Keep approaching markers at **24 px**, but enlarge winding-up markers to **30 px** with a terracotta fill and **2 px dark edge**. During a wind-up, reduce wave arrows to **50% opacity**. Keep the thief capsule visually distinct.

5. **Finish health-bar ownership in crowded fights.**  
   **See:** Side slots make `melee_close` clearer than the crowded outpost encounters. In mixed-wave and outpost, bars still sit among weapons, heads and neighbouring bodies; the thin stems are difficult to follow.  
   **Phone cost:** The cream target border identifies a bar more reliably than it identifies the corresponding creature.  
   **Change:** Try **1.5 px stems and 3 px endpoint dots**. Keep bars **6 px apart** and within **18 px horizontally** of their owner where possible. When that cannot fit, suppress full-health waiting-enemy bars first; retain active attackers and damaged enemies.

6. **Give thrown projectiles their own readable silhouette.**  
   **See:** `raider_throw` has small pale balls against pale snow, tiny dark darts, and long fine targeting lines. The line often communicates the threat more clearly than the projectile.  
   **Phone cost:** Players struggle to judge approach speed and the moment to react.  
   **Change:** Render snowballs at **10–12 px diameter** with a **1.5 px blue-grey outline**; give darts a **14–18 px visible length**. Add a **20–28 px tapered trail lasting 70–90 ms**. Fade the aiming line within **80 ms of release**, letting the moving projectile become the primary cue.

Verdict: **fix first** — contact feedback and overlapping combat cues still prevent consistently readable fighting at phone speed.