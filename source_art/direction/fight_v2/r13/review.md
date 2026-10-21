**Overall: 8.9/10.** Readability **9.0**, feel/juice **8.9**, design depth/progression **9.0**, phone UX **8.8**.

**Readability and progression are at 9 now.** Progression’s score reflects the visible upgrade, resource and encounter structure; screenshots cannot establish its long-term balance. These strips show contact placement and attack stages, but cannot independently verify smooth playback or the reported timing fixes. The remaining ceiling is contact geometry, crowded combat graphics and screen allocation.

1. **Make the stick visibly connect.**
   **See:** In `contact_closeup`, the cream burst sits on the wolf’s muzzle while the stick extends diagonally below it. In the clearest contact frames, the burst appears roughly **20–30 px from the visible shaft**. It reads as a punch with a stick trailing behind.
   **Phone impact:** Correct damage timing still feels disconnected when the weapon and impact occupy different places.
   **Change:** Adjust the contact pose so the striking section passes within **4–6 px** of the burst centre. Preserve the corrected timing. Give the wolf a directional head/shoulder reaction over **60–90 ms**, then settle over **120–160 ms**. Fix the pose before enlarging the effect.

2. **Reduce competing combat outlines.**
   **See:** `melee_close` and `outpost` stack terracotta wedges, player-centred circles, amber enemy rings and health bars. `bear_swipe` and `troll_slam` are understandable alone; their large geometry would dominate a mixed encounter.
   **Phone impact:** Players must decode several overlapping shapes precisely when they need to move.
   **Change:** Reserve the strongest **4–5 px terracotta boundary** for a committed attack. Use **2 px, lower-opacity outlines** during preparation. Keep the stated **100 ms** post-impact hold, then fade within **60 ms**. Reduce amber counter indicators to a **90–120° arc**, **2–3 px** thick, on the enemy’s exposed side; avoid another nearly complete circle.

3. **Bring the bear and troll up to the character-art standard.**
   **See:** Compared with Meagan and the wolves, the bear looks like stacked brown ovals; the troll’s long cylindrical arms and flat end caps dominate its silhouette.
   **Phone impact:** Their attack poses resemble rotating construction pieces, weakening both threat recognition and impact.
   **Change:** Give the bear a distinct muzzle, shoulder hump and **10–14 px paw masses**. Shorten the troll’s forearms approximately **15–20%**, taper them, and replace circular ends with broad mitten-like fists. Use **three large value groups** per creature and restrained wash texture. Keep anatomical detail subordinate to the silhouette.

4. **Make the ranged attack readable without following a hairline.**
   **See:** In `raider_throw`, the projectile is tiny and dark, its targeting line is faint, and the attacker is often cropped at the edge. The large ring around Meagan carries more visual weight than the incoming object.
   **Phone impact:** The player sees that something is targeting them more readily than where the shot currently is.
   **Change:** Give hostile projectiles a **10–12 px silhouette**, a **1–2 px cream edge**, and a **14–20 px terracotta tail**. Fade the targeting line at release so the moving shot becomes the primary cue. Keep the warning’s single entrance.

5. **Reduce the Armory sheet’s vertical footprint.**
   **See:** `armory_sheet` occupies roughly **395 px**, or **41%** of the screen. The resource rows, shortage sentence and delivery button repeat closely related information.
   **Phone impact:** Inspecting progression obscures much of the playable area and creates unnecessary reading.
   **Change:** Target **330–350 px** total height. Combine material status into **“Materials 8/25 · Need 17”**, retain the concrete wolf breakpoint, and use a **52–56 px** action button. Give the quiet × a **44×44 px minimum hit target**. Keep the longer explanation behind Details.

6. **Separate approaching waves from immediate offscreen threats more decisively.**
   **See:** `wave_hud` has outlined chevrons and a separate **“20m ×4”** badge; their association is weaker than the shapes themselves. Combat strips also show distance labels clipped along the top crop.
   **Phone impact:** Filled versus outlined is a useful distinction, but players still have to connect direction, distance and count.
   **Change:** Attach each badge directly to its marker with a **4–6 px gap**. Keep the complete marker group **12–16 px inside the safe viewport**, below the HUD. Use **24–28 px** filled attacker markers and **18–22 px** outlined wave markers. Merge same-direction threats within approximately **20°**.

**Verdict: fix first — weapon-to-impact alignment and overlapping combat cues still weaken the game’s central phone interaction.**