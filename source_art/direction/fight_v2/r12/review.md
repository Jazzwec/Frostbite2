**Overall: 8.9/10 — unchanged from round 11.** Readability and design/progression are at **9.0** now. Feel/juice is **8.9**; phone UX is **8.8**. The remaining gap is concentrated in crowded combat, impact feedback and screen-edge guidance.

These scores reflect the supplied frames; the slowed strips show poses and tells, but cannot establish how responsive combat feels at full speed.

1. **Keep Meagan’s attack readable when bodies overlap.**  
   **Seen:** The troll’s lower-middle and lower-right frames still swallow much of her torso and weapon. In `melee_close` and `outpost`, wolves crowd both sides of her stick. The cream contour helps locate her, but her action remains harder to identify than the enemy’s.  
   **Phone cost:** Players lose the connection between their input, her swing and the result.  
   **Change:** Draw the occluded portion of her stick and striking hand above enemies during the attack, with a **2 px cream contour and 1 px dark keyline**. Keep this selective reveal through contact and **120 ms afterward**. Adjust the troll’s forearms so her head and attacking hand remain separated in screen space.

2. **Make enemy danger readable before its final, heavy outline.**  
   **Seen:** Early bear and troll boundaries are faint; later frames become large, dark geometric outlines. The troll circle dominates the scene, while the bear’s sector intersects Meagan and the bear’s body.  
   **Phone cost:** The player must interpret an outline partly hidden by characters while also tracking the advancing line. The dangerous ground itself is insufficiently explicit.  
   **Change:** Add a restrained **8–12% terracotta wash inside the actual damage footprint**. Retain the **2 px boundary and 3 px advancing line**, but keep the locked double-line treatment within **5 px total apparent width**. Hold the completed footprint for **80–120 ms through impact**, then clear it. Reserve that fill strictly for damaging ground.

3. **Give contact a stronger visual punctuation than preparation.**  
   **Seen:** The tells occupy substantial space; the hit cores in `mixed_wave` and `troll_slam` are small pale spots. Meagan’s cream sweep is much less prominent than the enemy geometry.  
   **Phone cost:** Attacks can read as characters moving beside one another rather than connecting. The stated **40 ms** ochre rim is particularly brief.  
   **Change:** Keep the fast **100 ms swing**, but leave a tapered cream contact streak for another **60 ms**. Hold the ochre-rimmed core for **70–90 ms**, at **14–18 px** across. Pair successful melee contact with **3–5 px enemy recoil over 90–120 ms**. Make counters a larger version of this same impact language.

4. **Make edge warnings reliably distinguishable from scenery.**  
   **Seen:** In `wave_hud`, the right-side “20m ×4” card is readable, but the pale left chevron resembles a wooden environmental marker. Across the strips, distance cards are frequently clipped by the crop; the full portrait view is the stronger evidence for placement.  
   **Phone cost:** Players must search the perimeter and decode whether an arrow means danger, navigation or decoration.  
   **Change:** Clamp complete marker-and-card groups **16 px inside the playable viewport**, below the HUD and above the thumb area. Use solid terracotta with a **1–2 px cream backing** for active attackers. Show upcoming waves with an **outlined chevron**, rather than relying solely on reduced opacity. Give the offscreen-shot wedge a **single 120 ms expansion** when its warning begins.

5. **Make the Armory’s next action visually dominant.**  
   **Seen:** The progression promise leads appropriately, but **Close** has the strongest filled colour. “Track Lv 4 delivery” is pale enough to resemble a disabled button, and the trailing description crowds the bottom of the sheet.  
   **Phone cost:** The player understands the upgrade but can still hesitate over what to press next.  
   **Change:** Give **Track Lv 4 delivery** the filled teal treatment and cream text; retain a **56–60 px** button height. Turn Close into a quiet **44 × 44 px** top-right control. Shorten the shortage line to **“Deliver 17 more Materials”** and move the explanatory paragraph behind a Details disclosure. Preserve **20–24 px bottom padding**.

Verdict: fix first — resolve combat occlusion, impact feedback and edge-warning clarity before calling this 9/10.