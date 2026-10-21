**Overall: 8.9/10.** Readability **9.0**, feel/juice **8.8**, design depth/progression **9.0**, phone UX **8.9**. **Readability and progression are at 9 now.** Against the supplied round-14 baseline, these changes address local problems; impact feedback and crowded combat still keep the overall score below 9. Motion judgments here are limited to the sampled frames and your stated timings.

All sizes below refer to the 540×960 view.

1. **Separate enemy warnings from Meagan’s counter cue.**  
   In **melee_close** and **outpost**, overlapping rust-coloured sectors, health bars and weapon lines crowd the space around her feet. In **bear_swipe**, the gold counter arc competes with the much larger sector outline. On a phone, the player needs to distinguish “danger” from “act now” immediately. Keep warning outlines at **2 px**, with **8–12% rust fill**; reserve the strongest outline for the final **120 ms** before impact. Keep the counter’s existing dimensions, but give its bead a **7 px bright pulse for 80 ms** when the opportunity opens. Fade resolved warnings within **60 ms**.

2. **Make the stick’s contact read as impact rather than another small marker.**  
   **contact_closeup** places the burst on the wolf, but the cream core still resembles a bead; in **mixed_wave**, that small mark competes with several other effects. The player can miss the connection between the swing and damage at normal speed. Keep the **9 px core** and body occlusion. Give the exposed edge a **1 px warm umber accent**, and keep the strongest contact shape visible for **50–65 ms**. Try **25–35 ms hit-stop on Meagan and the struck enemy only**. Preserve the stated head snap before adding more particles.

3. **Bring bear and troll silhouettes up to the wolf’s level of definition.**  
   Across **bear_swipe** and **troll_slam**, the bear remains a stack of rounded brown masses; the troll’s raised fists can read as flat paddles on tubes. Their attack identities depend heavily on the ground warnings. Enlarge the bear’s light muzzle area by roughly **25%**, separate its near foreleg from its chest with a **3–4 px silhouette notch**, and distinguish its paw from the leg. Give the troll a **4–6 px thumb notch** and one broad knuckle plane. Use **three main value groups**, with restrained ink edges rather than additional surface detail.

4. **Make the troll’s actual slam outweigh its anticipation.**  
   **troll_slam** spends considerable visual area on the raised pose and boundary, then resolves into comparatively faint snow and small marks. The attack risks feeling less powerful when it lands than while it charges. At contact, compress the torso downward **5–7 px over 45 ms**; throw **6–8 irregular snow clumps, 4–8 px across**, outward by **15–25 px**. Expand one broken ground wash for **100–140 ms**, then dissipate it within **220 ms**. Keep the timing ring removed.

5. **Give airborne shards a more consistent focal point.**  
   In **raider_throw**, the flying shard has a narrow, grey profile against the blue-white ground; its tiny moving shadow is another competing mark. Once the aim line disappears, the projectile itself must carry the dodge information. Keep the **15×8 px head**, but use a dark blue-grey upper face and a cream leading edge that stays **2 px thick through rotation**. Make the existing **22 px tail** start **3 px wide** and taper to zero. Keep its shadow substantially lighter than the head.

6. **Reduce the amount of combat attention spent on the top HUD.**  
   **wave_hud** combines heat, six resource/status entries, wave count, enemy count and reinforcement timing above two large buttons. **armory_sheet** gives the upgrade task a clearer hierarchy than the combat screen gives the next threat. During waves, collapse secondary resources into an expandable row and target **95–105 px total HUD height**, down from roughly **122 px**. Give enemy count and reinforcement time distinct, stable positions. In the Armory, increase **Details** to at least a **44 px-high touch target**; retain the task-specific main button.

**Verdict: fix first — resolve combat-cue competition and strengthen contact/slam feedback before calling this 9/10.**