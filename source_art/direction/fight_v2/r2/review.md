**Overall: 7/10, up from 6/10.** Readability **6.5** (+1), feel/juice **6.5** (+1), design depth/progression **8** (+0.5), phone UX **6.5** (+1). Feel is provisional: stills show poses and effects, but cannot establish sound quality or real-time responsiveness. Round-one comparisons use your stated changes; these attachments appear to be all round two.

The remaining gap to 9 is distinguishing threats, reading contact, and making decisions with minimal screen clutter.

1. **Separate enemy danger from Meagan’s attack.**  
   **See:** In *melee_close*, rust wedges, gold sweeps, ground rings, bodies and health bars overlap. *Bear_swipe* has a clearer silhouette; *troll_slam* has a readable outer circle, but its advancing fill creates another apparent boundary. Pinning tells to actual hit areas fixes accuracy; interpretation remains crowded.  
   **Phone cost:** Players must distinguish “danger now,” “danger soon” and “my attack” in the same small patch.  
   **Change:** Give enemy danger one consistent treatment: muted terracotta fill at **15–20% opacity**, an outer boundary **2 px during wind-up → 3 px at lock**, and the advancing fill clipped inside it. Make Meagan’s sweep a **3 px pale-gold moving crescent**, with no persistent filled sector. Hide neutral ground rings during combat. Increase the final fixed-aim window from **0.3 to 0.4 s**, initially within the existing wind-ups; validate at **1×**, not slowed playback.

2. **Make enemy poses carry the warning.**  
   **See:** The bear reads as overlapping rounded masses; the troll’s raised spherical hands obscure its head and Meagan. Wolf bodies bunch around her legs. The size hierarchy is present, but the large enemies’ movement is still difficult to infer from silhouette.  
   **Phone cost:** Players depend on floor graphics precisely when bodies cover them. The smooth, bright highlights also pull bear/troll away from the ink-and-watercolour direction.  
   **Change:** Bear: pull one paw visibly **12–16 screen px** back and rotate the torso before swiping. Troll: separate raised fists by **at least one head width**, then lower the torso **8–10 px** at impact. Keep the stated recovery holds, but use unmistakably different recovery silhouettes. Replace small white specular hotspots with broad, muted colour patches and restrained ink contours.

3. **Concentrate feedback at contact.**  
   **See:** Across the melee, bear and troll strips, the health bars often communicate damage more clearly than the contact itself. The stated **80 ms** rim flash is brief, while a uniform **5 px** recoil gives little distinction between attacks.  
   **Phone cost:** Fighting risks feeling like overlapping units draining bars rather than blows connecting.  
   **Change:** Put a **12–18 px cream-and-rust impact mark** at the actual contact point for **100–120 ms**, with **3–5 ink flecks**. Differentiate recoil: **4 px light hit, 7 px sweep, 10 px heavy hit**, returning over **140–200 ms**. Add **35–50 ms hit-stop** only to heavy connections and kills. Keep Meagan’s damage flash red and visibly separate. Judge the sound and visual contact together at normal speed.

4. **Finish the HUD consolidation.**  
   **See:** *Wave_hud* presents the incoming wave in both the forecast and a broad red strip midway down the upper screen. Jans/Menu remain large floating blocks, and “Needs Furnace Lv 2” is clipped at the left edge. *Armory_sheet* avoids the announcement overlap, but retains substantial background UI noise.  
   **Phone cost:** A short-lived banner still interrupts the view during the exact moment players need to locate threats. Tiny enemy icons demand inspection.  
   **Change:** Place the **1.5 s** announcement directly beneath the top panel in a **32–36 px** strip. Then collapse to one **18 px text** forecast row with **20–22 px icons**. Reserve solid red for an active breach/theft; use amber for an approaching wave. Make Jans/Menu **48 px-high** controls anchored together under the HUD. Hide world requirement labels during combat and while a sheet is open.

5. **Make theft recoverable in practice, not just in the economy.**  
   **See:** In *theft*, Meagan lies down throughout the strip while several thieves leave. Their badges read more immediately than their sacks. In *mixed_wave*, the nearest-thief arrow competes with combat.  
   **Phone cost:** “Catch the thieves!” feels contradictory while control is unavailable. Leaving food reserves prevents starvation, but does not prevent helplessness.  
   **Change:** If this is the player’s recovery period, show **“Recovering… 0.8 s”** and give thieves a **1.5–2 s escape delay after control returns**. Use one **30–32 px ochre sack badge** for the nearest thief, with its recoverable quantity in **16 px numerals**. Other thieves need visible sacks, not duplicate floating badges. Keep the nearest arrow **24 px inside the safe edge**.

6. **Expose weapon switching and preserve Meagan’s silhouette.**  
   **See:** *Raider_throw* makes the snowball pose legible in open space; *melee_close* and *outpost* bury the stick and lower body among enemies and bars. The hysteresis and target hold address switching instability, but screenshots cannot demonstrate whether it is resolved.  
   **Phone cost:** Automatic weapon selection feels arbitrary when the player cannot see the selected stance or committed target.  
   **Change:** Hold each ready stance visibly for **at least 200 ms** when circumstances permit. Keep the raised stick tip **12–16 px outside her torso silhouette**. At the **0.16 s** sweep commitment, briefly accent only the chosen enemy’s existing health-bar border. Increase nearby pack separation from **0.7 to roughly 0.9 body widths** and resolve bar overlaps with **8 px minimum vertical gaps**.

7. **Make the Armory communicate affordability and purpose.**  
   **See:** *Armory_sheet* aligns the upgrades, but “Wood 82 / 299” reverses the familiar owned/required reading, and “Mat 25 / 8 short” requires interpretation. The upgrade button looks available despite insufficient materials.  
   **Phone cost:** Players must decode the purchase before deciding whether it helps. Surviving to wave 13 demonstrates tolerance, not yet meaningful progression choices.  
   **Change:** Write **“Wood: 299 owned / 82 needed”** and **“Materials: 8 / 25 — need 17”**, with only the deficit red. Disable the purchase button and label it **“Need 17 materials”**. Keep row labels **18 px** and values **20 px**. Add one accurate outcome, such as **“Wolves: 3 hits → 2”**, only where the damage calculations support it.

For a 9/10 review, test at **540×960 and 1× speed**: aim for **90% correct threat identification**, **80% successful dodges after three exposures**, and **90% correct affordability answers within two seconds**, alongside visibly distinct impacts and a controllable theft recovery.

Verdict: fix first — overlapping combat signals and unclear contact still undermine the core fighting experience on a phone.