**Overall: 8.9/10.** Readability and design depth are at **9 now**. Phone UX still keeps the whole experience below 9.

| Area | Round 10 | Round 11 |
|---|---:|---:|
| Readability | 9.0 | **9.0** |
| Feel / juice | 8.8 | **8.9** |
| Design depth / progression | 9.0 | **9.0** |
| Phone UX | 8.9 | **8.7** |

These are different encounters, not before/after pairs. The comparison with round 10 relies on your change list; still frames cannot verify the feel of hit-stop, recoil or full-speed reaction windows.

All proposed pixel sizes below refer to the **540 × 960 phone view**.

1. **Separate enemy danger, player attacks and counter timing visually.**  
   **What I see:** Bear and troll warnings use terracotta boundaries and cream emphasis; Meagan’s sweep also has a cream-edged sector. Gold counter rings add another outlined ground shape. In the melee and outpost strips, those signals overlap directly beneath the fighters.  
   **Why it hurts:** Individual shapes are readable, but their meaning takes interpretation during the busiest moment.  
   **Change:** Reserve terracotta wash and boundaries exclusively for enemy damage areas. Render Meagan’s sweep as a **3 px cream arc lasting 80–110 ms**, without an enclosed sector. Keep counter feedback gold, with a **2 px dark outline** around the existing 8 px bead. Do not enlarge every signal.

2. **Make Meagan’s position and facing survive the troll encounter.**  
   **What I see:** Wolves mostly leave her upper body readable. The troll’s raised limbs dominate the warning, and its lowered pose crowds her weapon and lower body. A flat red show-through conveys presence better than facing.  
   **Why it hurts:** Players need to know where their feet are relative to the damage boundary and which way their attack points.  
   **Change:** When an enemy obscures her, add a **2 px warm-cream contour** to the revealed red silhouette and preserve the weapon silhouette too. Adjust the troll’s arm spread or pose by approximately **15%** to leave a visible corridor around her head and shoulders. Anchor every danger shape to the actual landing point.

3. **Protect the strike from health-bar clutter.**  
   **What I see:** In `melee_close`, multiple bars bracket Meagan’s head and weapon. The cream hit core is identifiable in `mixed_wave` and `outpost`, but competes with cream telegraph edges and overlapping bodies.  
   **Why it hurts:** The player should register “my hit connected” before inspecting remaining health.  
   **Change:** Keep bars **8–10 px above the visible silhouette**, resolve collisions with **6 px minimum separation**, and reduce inactive enemies’ bars to **60% opacity**. Give the existing hit core a brief **2 px dark ochre rim for its first 35–45 ms**. Keep the current burst size until motion review proves it insufficient.

4. **Give incoming ranged attacks an actionable direction cue.**  
   **What I see:** Raider attacks cross substantial empty space, while attackers are frequently clipped at the frame edge. The outlined snowballs are easier to identify than the small dark shards; the thin targeting lines remain visually weak.  
   **Why it hurts:** Seeing a projectile beside Meagan can be too late to understand where to evade.  
   **Change:** For an off-screen attacker, show a **12–14 px terracotta wedge**, inset **18 px from the edge**, starting **300–400 ms before projectile entry**. Point it along the incoming trajectory and remove it once the projectile is visible. Verify this at **1× speed**; the slowed strip cannot establish fairness.

5. **Reduce navigation competition during raids.**  
   **What I see:** `wave_hud` combines a large upper-right arrow, a separate `20m ×4` marker and another large left arrow. Their similar treatment does not clearly distinguish destination guidance from combat information.  
   **Why it hurts:** Three competing directions weaken the immediate “what should I respond to?” decision.  
   **Change:** Use **22–26 px terracotta enemy chevrons** and a distinct **18–20 px muted teal objective marker**. During combat, fade noncombat guidance to **40% opacity**. Keep marker groups inside a **20 px safe inset** and outside the upper HUD/button region.

6. **Put the armory’s decision ahead of its explanation.**  
   **What I see:** The wolf breakpoint, **3 → 2 sweeps**, is the strongest progression information. It sits below descriptive copy, while the material shortage is explained again through both a sentence and inventory rows.  
   **Why it hurts:** The useful choice takes more reading than necessary on a phone.  
   **Change:** Put **“Next level: wolf defeated in 2 sweeps”** directly beneath the title in **22–24 px type**. Follow with the smaller stat changes, then **“Need 17 more Materials”** beside the delivery button. Move flavour text to the bottom or collapse it.

Verdict: **fix first** — clarify overlapping combat signals and preserve Meagan’s silhouette before adding more effects.