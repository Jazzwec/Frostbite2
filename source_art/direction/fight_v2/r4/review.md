**Overall: 8/10**, up from 7.5. Readability **8**, feel/juice **7.5**, design depth/progression **8.5**, phone UX **8**. These scores judge the captures and stated rules; six-frame strips cannot establish how responsive combat feels.

**Near 9:** the Armory’s owned/needed/shortfall explanation, delivery wording and “sweeps to beat a wolf” breakpoint. The attack-slot and wind-up scheduling rules are also near 9 in principle. **Below 9:** contact readability, counterattack communication, crowded combat and the forecast HUD.

The bear and troll strips communicate attack territory more clearly than `melee_close` and `mixed_wave`. The full-phone HUD exposes a different problem: too much small information competes above a largely empty playfield. These are complementary views of round 4, not before/after evidence.

All sizes below refer to the **540 × 960 viewport**.

1. **Make the locked attack unmistakably different from the warning.**  
   **What I see:** The bear sector and troll circle are readable, but their thin brown boundaries and pale fills remain visually similar across the tell frames. Small melee sectors get lost among bodies and weapons.  
   **Why it hurts:** A player needs to recognize “this is where it will land” without inspecting a gradual opacity change.  
   **Change:** Keep the 17–27% wash, but make the lock a discrete transition: **3 px dark terracotta boundary with a 1.5–2 px cream outer keyline**, held through impact. Stop fill advancement at lock. Keep the existing **0.4/0.45/0.55 s** timings until real-speed testing shows a timing problem; improve the signal first.

2. **Expose the counterattack window through a clearly vulnerable pose.**  
   **What I see:** The bear’s extended paw and troll’s grounded fists help, but neither strip makes the **1.5× damage opportunity** self-evident. The bear still looks fairly upright and active during recovery.  
   **Why it hurts:** Your strongest new depth mechanic risks feeling like unexplained damage variation. Players cannot deliberately exploit a window they cannot identify.  
   **Change:** During recovery, lower the bear’s head and shoulders **8–10 px** and hold its paw planted; tip the troll’s torso forward with both fists visibly grounded. Trial **0.45 s bear / 0.55 s troll** recovery. Give successful counters a distinct cream-and-ochre impact and a brief **“Counter”** label for the first three occurrences, then retire the label.

3. **Give hits a stronger physical consequence.**  
   **What I see:** In `mixed_wave` and `outpost`, the impact stars remain small accents inside overlapping silhouettes. The troll’s slam changes pose, but the sampled ground impact looks light for its size.  
   **Why it hurts:** A star alone does not reliably distinguish a connected hit from a nearby swing. Large enemies also lack perceived weight.  
   **Change:** Try **30–32 px ordinary impacts, 40 px kills**, with an opaque cream centre and terracotta rays, lasting **120–150 ms**. Add **50–65 ms enemy hit-stop** and **5–7 px recoil**, keeping movement input responsive. Give the troll a single **70–90 px broken snow puff**, lasting **180–220 ms**, rather than more persistent effects.

4. **Separate melee bodies as clearly as their attack schedules.**  
   **What I see:** `melee_close` still places wolves directly beneath Meagan; `outpost` crowds both shoulders. Red bars form a stack whose ownership requires inspection.  
   **Why it hurts:** Limiting attackers solves damage fairness, but players still need to see their character, escape gaps and current target.  
   **Change:** Give the two active melee slots at least **70° angular separation** and maintain **10–14 px visible space between ground footprints**. Keep waiting enemies another **24–32 px** back. Use a **2 px owner stem** when a bar is displaced; limit displacement to **16 px** before resolving the underlying overlap.

5. **Make the forecast readable without decoding an icon sentence.**  
   **What I see:** `wave_hud` combines “Wave 7: 4 left,” the next-wave countdown and four tiny composition counts on one line. The raid strip repeats almost the same countdown.  
   **Why it hurts:** The next decision is buried in compressed symbols, while two timers spend attention on the same event.  
   **Change:** Keep **“Wave 7 · 4 left”** at **18 px** in the panel. Put composition on a separate **24–28 px-high row**, with **22–24 px icons and 16–18 px counts**. Let the raid strip own the countdown. The **32 px edge arrows** are sufficiently large; improve the information hierarchy before enlarging them.

6. **Show the relationship between stolen loot and its carrier.**  
   **What I see:** In `theft`, the ochre “5” and “15” badges can read as rewards or damage numbers. “Up in 4” sits directly across Meagan’s fallen body.  
   **Why it hurts:** The crucial recovery objective is ambiguous precisely when the player has lost control.  
   **Change:** Attach the loot badge to the carrier’s bar with a short stem and include a **12–14 px sack icon** beside the amount. Preserve that pairing on edge arrows. Move **“Up in 4s”** into a cream-backed **22 px** label about **30 px above her body**. Show **“Recover stolen supplies”** once on revival; the grace period itself can remain invisible.

7. **Bring the large enemies closer to the picture-book finish.**  
   **What I see:** The bear reads as smooth brown segments; the troll’s limbs resemble assembled blue capsules. Both look flatter and more mechanically jointed than Meagan and the environment.  
   **Why it hurts:** Their size magnifies the style mismatch, and circular joints compete with the attack silhouette.  
   **Change:** Integrate shoulder and hip shapes, soften internal joint outlines, and reserve the strongest **1.5–2 px ink contour** for the outer silhouette. Use **three broad value groups** with restrained watercolour variation inside them. Preserve the enlarged paw and fist silhouettes; avoid adding small fur or ice details.

**Verdict: fix first — locked attacks, counter windows and hit consequences still need to read instantly at phone size.**