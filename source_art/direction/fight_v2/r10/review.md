**Overall: 8.9/10.** Readability **9.0**, feel/juice **8.8**, design depth/progression **9.0**, phone UX **8.9**. **Readability and design are at 9 now.** Design’s score is provisional: screenshots show enemy roles and upgrade clarity, not whether progression stays satisfying.

Against the described round 9 changes, the remaining gap is concentrated in attack contact, overlapping fighters and attention management. These strips let me assess poses and visibility; they cannot establish how the new 70 ms hit hold feels in motion.

1. **Make the moment of contact unmistakable.**  
   Across *mixed wave*, *melee close* and *outpost*, attack wedges and health bars catch the eye before the actual hit. The concentrated burst still occupies very little space among weapons, faces and bar stems. On a phone, damage can register as “the bar changed” rather than “my swing connected.” Increase the cream core from **9 to 12–14 px**, with **three 8–10 px rays**; position it at the weapon/body intersection and draw it above both fighters. Keep the **140 ms total**. Add **4–6 px directional recoil over 80–100 ms**, returning over **140 ms**. Stronger physical response matters more than additional particles.

2. **Keep Meagan’s action visible beside large enemies.**  
   In *troll slam*, the raised arms surround Meagan and the lowered body obscures parts of her weapon and stance. *Melee close* creates a smaller version of the same problem. Losing her hands and feet makes attack direction and escape movement harder to judge. Add a **2 px warm-cream occlusion outline** only where enemies cover her. Offset the troll’s striking pose **8–12 px away from her screen silhouette**, while keeping the attack’s ground position accurate. Preserve at least **12 px of visible weapon beyond her hands** at contact.

3. **Give warning, strike and counter opportunity more distinct visual states.**  
   The bear’s sector, troll’s enormous circle and gold recovery rings all compete as outlined ground shapes. In *troll slam*, the danger area dominates three panels without a comparably clear visual change at impact. A player needs to read timing without studying the animation. Use a **2 px muted terracotta boundary with 8–12% fill** during warning; brighten only the advancing timing edge to **3 px**. Remove the warning within **60 ms of impact**. Reserve ochre for the counter window, with a **3 px arc and 8 px bead**. Keep the existing separation from the body.

4. **Make incoming ranged attacks readable before they reach Meagan.**  
   The dark shards in *raider throw* are visible, but their tapered bodies do not make direction instantly obvious, and attackers sit partly outside the crop. The pale snowballs are weakest over open snow. Keep the shard size; make its **rear trail taper clearly from 5 px to zero over 18–20 px**. Give snowballs a **3 px blue-grey rim**. In the full phone view, show a **24 px terracotta edge cue**, inset **20 px**, only for an incoming offscreen projectile on a collision course.

5. **Untangle the outpost’s first engagement.**  
   Lower stakes help, but *outpost* still stacks wolves, raiders, bars and the structure into one cluster. The player cannot quickly distinguish immediate melee danger from ranged support. Stage wolves through a **60–72 px central approach lane** and hold raiders on two flanks **40–50 px apart**. Fade the outpost label within **150 ms of combat starting**. This needs encounter spacing more than another rendering adjustment.

6. **Clarify the HUD’s simultaneous clocks and destinations.**  
   *Wave HUD* says “4 left” and “Next raid 11s” together, while several edge arrows compete. It is unclear whether another group arrives regardless of the surviving four. If that is the rule, label it **“Reinforcements 11s”** and separate it from **“Wave 7 · 4 enemies”**. Use **18–20 px text**. Group enemy markers within **25°** into one arrow/count, keeping markers at least **24 px from screen edges**. The armory already communicates the useful breakpoint—**3 sweeps → 2**—more clearly than this combat status.

Verdict: fix first — contact feedback and Meagan’s visibility during crowded attacks still hold the fighting below 9/10.