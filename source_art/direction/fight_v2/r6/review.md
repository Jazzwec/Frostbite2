**Overall: 8.6/10**, versus the reported 8.5 for round 5. The remaining gap is combat clarity when bodies, bars and feedback overlap.

| Area | Round 6 | What keeps it below 9 |
|---|---:|---|
| Readability | **8.5** | Close melee still merges targets, faces and weapons. |
| Feel / juice | **8.3** | Contact lacks a strong visual punctuation; large enemies look mechanically posed. |
| Design depth / progression | **9** | Enemy roles, recovery counters, theft recovery and meaningful upgrade breakpoints are present. |
| Phone UX | **8.5** | Combat cues compete at character scale; upgrade information needs faster scanning. |

**Design depth/progression is at 9 now. None of the other areas is yet.** These scores judge the visible frames; still strips cannot establish how the revised timing feels at normal speed.

1. **Resolve the remaining melee pileups before adding more effects.**  
   **See:** `mixed_wave` is easier to parse than `melee_close`. In close melee, wolves still overlap each other and Meagan’s weapon; several bars cross heads. The troll also hides much of her body. Angular separation alone is not producing clear screen silhouettes.  
   **Phone cost:** Players cannot reliably distinguish the current threat, selected target and player facing.  
   **Change:** Add a screen-space separation pass: keep attacking enemy centres roughly **55–65 px apart**, and waiting enemies **30–40 px farther out**. Preserve a **24 px clear pocket around Meagan’s head**. Resolve all nearby bar collisions with **6 px gaps**, including enemy-to-enemy collisions; use short stems when displaced.

2. **Make the actual hit the strongest instant in the exchange.**  
   **See:** Several contact frames in `mixed_wave`, `melee_close` and `troll_slam` read as a small pale dot or overlapping poses. The intended unequal-ray impact is not consistently apparent.  
   **Phone cost:** Damage can feel automatic rather than caused by the player’s swing.  
   **Change:** Keep the **32 px hit / 40 px kill** sizes, but give the cream burst a **2 px warm-ink outline** and draw it above bodies. Place it at the contact point, outside the health-bar lane. Target **70–90 ms hit-stop**, **6–8 px enemy recoil over 100 ms**, and a burst lasting **100–140 ms**. Keep camera shake for heavy hits and kills.

3. **Separate danger, targeting and recovery into unmistakable visual states.**  
   **See:** Bear/troll danger outlines are thin brown shapes on snow; recovery uses a segmented ochre ring. Around wolves and outpost enemies, gold edging and rings compete with each other.  
   **Phone cost:** The player must decode several similar outlines during a short counter opportunity.  
   **Change:** Reserve **terracotta for incoming danger**, **cream plus ink for the target lock**, and **ochre for recovery**. Give danger areas a **12–16% terracotta wash**, a **2 px outline**, and one stronger edge pulse during the final **180 ms**. Make recovery rings **5 px thick**, with four broad gaps, **8–10 px outside the feet**; drain their visible segments across the recovery window.

4. **Give the bear and troll readable attack poses, not just readable floor shapes.**  
   **See:** The bear’s swipe has little visible shoulder/paw extension across its strip. The troll’s raised cylindrical arms dominate its silhouette, while its lowered pose communicates limited weight. Both are substantially more primitive than Meagan and the wolves.  
   **Phone cost:** Players depend on ground indicators because the creatures themselves provide weak attack information.  
   **Change:** Push the bear into a **15–20° shoulder twist** with its striking paw clearly outside the torso. Give the troll a **15% anticipation compression**, then a **20% forward body drop** on impact. Integrate its cylinder joints into broader tapered limbs and consolidate the crystals into **three readable clusters**.

5. **Make stolen supplies readable while the thief is moving away.**  
   **See:** In `theft`, the sack and number are tightly packed inside tiny capsules; the badge competes with the large “Up in…” label. The supplied frames do not establish whether the returning-player prompt solves reacquisition.  
   **Phone cost:** Losing supplies risks feeling unexplained, and the recovery target can disappear before its value registers.  
   **Change:** Use a capsule at least **50 × 24 px**, a **16 px sack**, **16 px numerals**, and **6 px internal spacing**. Keep it **8 px above the thief’s bar**. On revival, show “Recover stolen supplies!” for **2 seconds**, with two restrained **100%→115%** badge pulses; retain the same capsule on the edge arrow.

6. **Give projectiles enough presence between launch and contact.**  
   **See:** `raider_throw` distinguishes cream snowballs from dark shards, but the shard bodies and terracotta trails remain tiny. The targeting line is often easier to notice than the projectile.  
   **Phone cost:** Players can understand who is aiming yet miss the object they should dodge.  
   **Change:** Make shards **16–18 px long and 6–8 px wide**, with a **2 px dark contour** and **18–24 px tapered trail**. Keep the launch gap. Fade the aim line within **80 ms of release**, so attention transfers to flight.

7. **Promote decisions and reduce competing HUD text.**  
   **See:** `wave_hud` places active-wave status and the next-raid countdown in separate stacked panels. `armory_sheet` presents four equally weighted stat rows above delivery requirements, despite the wolf breakpoint being the clearest gameplay benefit.  
   **Phone cost:** The player spends extra time connecting related information and finding the upgrade’s practical value.  
   **Change:** Put **“Wave 7 · 4 left”** and **“Next raid 11s”** in one **40–44 px status row**, retaining amber only for the final five seconds. In the armory, lead with **“Wolves: 3 sweeps → 2” at 20–22 px**; move numerical stats below at **16–18 px**. Make **“17 more materials needed”** the single prominent requirement directly above the delivery button.

Verdict: **fix first** — close-melee separation, hit feedback and combat-state cues still prevent reliable one-glance reading at phone size.