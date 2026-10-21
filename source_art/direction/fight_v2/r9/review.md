**Overall: 8.9/10.** Readability **8.9**, feel/juice **8.8**, design depth/progression **9.0**, phone UX **9.0**.

**Design/progression and phone UX are at 9 now.** Contact readability and crowded combat still hold the overall score below 9. I’m judging the visible poses and effects; these strips cannot verify how the revised hit-stop feels at speed. Round 8 comparisons rely on your supplied scores and change list.

1. **Make contact the strongest visual event.**  
   In *mixed_wave*, *melee_close* and *outpost*, the cream sweep and outlined counter ring register more clearly than the actual strike. The troll’s snow splash reads as a landing, but its damage contact remains less distinct. On a phone, the player needs an immediate answer to “did that connect?”
   
   Keep the stated **25/32 px burst footprints**, but concentrate them: add an opaque **8–10 px cream impact core**, **3–4 short terracotta accents**, and fewer, thicker rays. Draw the core above the struck silhouette at contact; let rays extend beyond it. Hold the core for **60–80 ms**, then clear the whole burst within **140 ms**. Improve contrast before adding more particles or longer hit-stop.

2. **Separate the bear’s attack pose from its recovery pose.**  
   Across *bear_swipe*, the body remains a rounded, low-information mass; the sector and ring explain more than the animal. *Troll_slam* has a clearer raised-arms-to-landing change, although its upright forearms resemble tubes. Players should recognize an attack without reading floor graphics.
   
   Give the bear a visible **15–20° shoulder wind-up**, a near paw extending **10–14 px beyond its body**, and a clearly lowered head during recovery. Give the troll broader, flattened fists and a **6–8 px torso drop** on landing. Those silhouette changes should remain readable with every telegraph hidden.

3. **Resolve overlapping health bars in close fights.**  
   In *melee_close*, especially the bottom-middle frame, Meagan’s green bar and the left wolf’s red bar nearly form one continuous strip. *Outpost* compounds this with several targets at different depths. Thin stems cannot reliably recover ownership once bars touch.
   
   Enforce **6 px horizontal separation** between unrelated bars. When that is impossible, stagger enemy bars vertically by **10–12 px**, with stems still ending at their owners. Give Meagan’s bar priority at its usual position. Apply this only during collisions so the interface does not constantly rearrange itself.

4. **Keep counter windows identifiable when bodies overlap them.**  
   The isolated bear and troll rings are understandable; wolf rings in *melee_close* become partial orange loops beneath a crowd. Their similarity to the large-enemy recovery rings makes the available interaction harder to locate quickly.
   
   Keep the facing ellipse and disappearing segments, but render its leading **5–6 px cream bead above characters**, with a **1 px dark ochre border**. Keep the remaining ring on the ground. Maintain a **4–6 px visible clearance** around each enemy’s projected footprint. This preserves the body fit while giving the player one dependable moving cue.

5. **Make incoming raider shots easier to separate from snow and outgoing shots.**  
   *Raider_throw* shows distinguishable projectile designs, but the dark shards are still small, while cream snowballs compete with falling snow. The removed aim line also makes the projectile itself responsible for communicating direction.
   
   Increase shards from **17×7 to roughly 20×9 px**, using a solid dark blue-grey head and a **12–16 px terracotta trail**. Give snowballs a consistent **2 px blue-grey rim** and a **7–10 px pale-blue trail**. Keep both above ground effects. Prioritize these moving silhouettes over additional targeting lines.

6. **Expose the enemies emerging from the outpost.**  
   *Outpost* is materially harder to parse than the open-field strips: stakes, the structure, clustered raiders and wolves merge near the entrance. A player can see a threat without seeing its attack preparation.
   
   Fade foreground stakes to **30–35% opacity** when they overlap an attacker. Spread waiting enemies laterally by approximately **18–24 px**, and move attack-ready enemies at least **16 px clear of the entrance silhouette** before their wind-up begins. Preserve the crowd behind them, but make the next actionable threat visible.

Verdict: fix first — contact confirmation and overlapping combat cues still make the busiest encounters harder to read than the underlying combat design deserves.