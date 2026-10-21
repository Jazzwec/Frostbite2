**Round 7: 8.8/10 overall.** The remaining gap is combat clarity when enemies converge, followed by impact visibility and the Armory’s delivery flow.

| Area | Round 6 | Round 7 |
|---|---:|---:|
| Readability | 8.5 | **8.7** |
| Feel / juice | 8.3 | **8.6** |
| Design depth / progression | 9.0 | **9.0** |
| Phone UX | 8.5 | **8.7** |

**Design depth/progression is at 9 now.** The wave HUD’s information hierarchy is also at 9 in isolation. Combat readability and feel are not there yet. These are screenshot-based scores: the strips show poses and effects, but cannot establish whether the stated hit-stop and recoil timings feel right in motion. The round-to-round comparison uses your supplied round 6 baseline.

### 1. Separate attackers around Meagan—not just their health bars
**See:** In *melee_close*, especially the middle and right panels, wolves overlap into one dark mass beside her. *Outpost* adds ranged attackers behind that melee. *Mixed_wave* is easier to parse because the silhouettes remain farther apart.

**Phone cost:** Players can count bars but cannot reliably identify which body is attacking or recovering. Moving bars solves label collisions; it does not solve combat collisions.

**Change:** Give close attackers distinct approach slots, targeting **12–16 px of visible separation between their heads** at contact distance. Let **two melee enemies occupy contact range**; others reposition **24–36 px behind them**. Offset attack starts by **180–250 ms** so separate threats remain readable without reducing enemy count.

### 2. Make the recovery window survive feet-level clutter
**See:** The bear and troll recovery segments disappear behind bodies, rocks and snow clumps. Wolves expose only fragments of ochre. The broad danger shapes are substantially easier to see than the opportunity that follows.

**Phone cost:** The mechanic asks players to recognize a brief opening using its smallest, most obstructed signal.

**Change:** Place the recovery ring **8–10 px beyond the projected body footprint**, rather than merely beyond the feet. Use **3 px ochre strokes with a 1 px dark under-edge**, keeping all four segments equally weighted. Remove segments clockwise from twelve o’clock. Start with a **600–700 ms counter window**, then tune through playtesting.

### 3. Give edge threats a usable direction and distance
**See:** In *raider_throw*, attackers are repeatedly cropped by the strip edges; that alone does not prove they are offscreen in play. However, the full *wave_hud* shows large direction arrows without a clear indication of urgency or distance.

**Phone cost:** A player can know where to walk without knowing which direction will produce the next hit.

**Change:** For genuinely offscreen attackers, use **24–28 px threat markers**, inset **16 px inside the playable viewport**, with a **12–14 px distance label**. Reserve terracotta for an attack already winding up; use muted ink for pursuit. Keep markers below the HUD and above the movement-control area. Show the **two most immediate threats**.

### 4. Resolve the health-bar cluster’s ownership
**See:** Bars remain individually separated in *melee_close*, but the stacked red rectangles still require tracing back to overlapping wolves. Meagan’s green bar also sits across the upper silhouette area in several combat panels.

**Phone cost:** Players spend attention matching health to bodies instead of reading attack poses.

**Change:** Preserve the stacking rule, but make every displaced bar’s stem **1 px dark ink with a 3 px endpoint directly over its owner**. Maintain **8 px clearance above Meagan’s highest visible head position throughout animation**. Keep target emphasis as a **2 px cream border with a dark outer keyline**; do not enlarge the target bar during impact.

### 5. Make contact effects visible outside the silhouettes
**See:** The troll strip has a tiny contact mark among the arms; wolf impacts are difficult to distinguish from their ochre outlines and recovery effects. The bear’s twist reads more clearly than the actual contact.

**Phone cost:** Anticipation dominates the hit, so successful attacks risk feeling weaker than the danger preceding them.

**Change:** Put the burst at the contact point but project its longest rays **8–12 px beyond the struck silhouette**. Target a **22–28 px total burst diameter** for ordinary hits and **30–34 px for counters**, retaining the cream centre and ink outline. Keep **120 ms** initially; test visibility before adding duration or more particles.

### 6. Make the Armory button describe the next action precisely
**See:** *Armory_sheet* leads with “Wolves: sweeps 3 → 2,” but also presents the shortage twice and offers “Start Lv 4 delivery” while materials are missing.

**Phone cost:** The player must infer whether tapping starts collection, transfers stock, or upgrades the building.

**Change:** Use **“Sweeps to defeat a wolf: 3 → 2”** at **22–24 px**, with secondary stats at **16–17 px**. Consolidate the shortage into **“Collect 17 more Materials, then deliver to the pad.”** If the button starts a delivery objective, label it **“Track Lv 4 delivery”**; if it transfers available resources, use **“Deliver available resources.”** Keep the current large touch target.

**The gap can close without final creature models.** Attacker spacing, unobstructed recovery signals and visible contact can get this to 9. Final models will improve character and finish, but they will not resolve these interaction problems.

Verdict: fix first — crowded melee still obscures who is attacking and when the counter opportunity begins.