**Overall: 8.9/10.** Readability **8.9**, feel/juice **8.8**, design depth/progression **9.0**, phone UX **9.0**. Design/progression and phone UX are at 9 now. Against the supplied round-16 scores, the remaining blocker is still the clarity and weight of contact, especially when enemies overlap.

The close-up makes the wolf reaction inspectable; **mixed_wave** and **melee_close** show how much of that information disappears during normal combat. The isolated bear and troll attacks read more clearly, but their impact poses still need stronger silhouettes.

1. **Make the hit readable at normal speed.**  
   **See:** In **contact_closeup**, the cream contact splash occupies a tiny space between similarly pale muzzle, hand and snow. In the mixed fight, the weapon and health bars draw more attention than the actual connection.  
   **Phone cost:** Players can register “swing happened” without registering “this enemy took the hit.”  
   **Change:** Increase ordinary splash length from ~14 to **18 px**, keeping its width **7–9 px** and its burnt-orange edge **2 px**. Place most of it beyond the struck silhouette, along the blow direction. Extend visibility from **75 to 95 ms**. Keep counters at **22 px** with gold edging; preserve the bead exclusively for the counter window.

2. **Separate the struck wolf from the combat pile.**  
   **See:** The close-up shows changing head and body orientation, but in **melee_close**, wolves still merge with Meagan’s boots, stick and neighbouring bodies.  
   **Phone cost:** A 5–7 px yield becomes hard to distinguish from pursuit movement. The player cannot confidently identify which wolf was interrupted.  
   **Change:** Trial **8–10 px** of displacement over **60–70 ms**, with the muzzle turning **12–15°** away. Hold the furthest pose for **35–45 ms**, then recover over **120 ms**. During that hold, prevent pursuit movement from immediately closing the gap. Judge this at **1×**, not in the contact strip.

3. **Make imminent warnings dominate overlapping previews.**  
   **See:** **Melee_close** and **outpost** contain intersecting triangular outlines beneath bodies. The bear’s broad sector and troll’s circle are easier to parse because their edges extend into clear snow.  
   **Phone cost:** Players must untangle geometry precisely when they should be reacting. Thin radial lines can look like targeting guides rather than danger boundaries.  
   **Change:** Keep unlocked previews at **20–25% opacity**, with **1 px** sides. During the final **120 ms**, use a **3 px burnt-red outer arc**, **1 px sides at 40% opacity**, and a **5 × 3 px attacker-root wedge** in the same colour. Give only the committed attack this full emphasis; avoid strengthening the entire perimeter.

4. **Push bear and troll impact silhouettes further.**  
   **See:** The bear’s extended paw is visible in the upper-right frame, but its arm and torso remain close in value. The troll’s landing frames remain a cluster of rounded blue-grey forms; the flattened body is less prominent than the warning circle.  
   **Phone cost:** These enemies risk feeling like differently shaped damage zones rather than attacks with distinct weight.  
   **Change:** Lighten the bear’s striking paw by approximately **15%**, preserving a **4–6 px snow gap** between foreleg and chest during anticipation. For the troll, trial **18% squash** and move each fist **6–8 px farther outward** on landing. Preserve the **80 ms landing / 180 ms recovery** timing before adding more effects.

5. **Stop health bars masking combat poses.**  
   **See:** In **melee_close**, bars sit across Meagan’s head and the wolves’ upper silhouettes. In **mixed_wave**, enemy bars, Meagan’s bar and reward text compete in the same small region.  
   **Phone cost:** The HUD obscures the anticipation and recoil that the animation changes are trying to communicate.  
   **Change:** Maintain **8 px clearance above the complete animated silhouette**, rather than above the body centre. Resolve bar collisions vertically in **10 px steps**, with a restrained **1 px leader** where needed. Keep enemy bars around **44–48 × 6 px**, and reserve the wider green bar for Meagan.

6. **Make the collapsed resource control legible.**  
   **See:** In **wave_hud**, the fold marker has a separate position but remains a tiny triangle at the far-right edge. The armory’s explicit outcome and “Track 17 Materials” action communicate their purpose much more clearly.  
   **Phone cost:** A separate position does not by itself tell players that hidden resources are available.  
   **Change:** Use a **12 × 8 px chevron** centred in a **44 × 44 px touch area**, with its centre **24 px from the panel’s right edge**. Reserve that column so the reinforcement text cannot run into it. Rotate the chevron over **100–120 ms** when toggled.

**Verdict: fix first — normal-speed hit confirmation and overlapping attack warnings still keep combat below 9/10.**