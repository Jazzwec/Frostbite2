Scores reflect the six sampled poses in each strip. Exact responsiveness, easing and foot sliding need playback; the overlaps and missing action silhouettes are visible here. Timing below assumes **60 fps**.

| Clip | Score | Main issue |
|---|---:|---|
| 1. Meagan walking loaded | 5/10 | Stride reads, but the upper body contributes little sense of weight. |
| 2. Meagan chopping | 5/10 | Axe movement reads; contact and loose-log placement are unclear. |
| 3. Meagan fishing | 4/10 | Almost identical silhouettes; rewards communicate more than the action. |
| 4. Meagan unloading | 3/10 | Shows walking with an unchanged stack, without a readable deposit. |
| 5. Meagan paying a build pad | 3/10 | Visually almost the same as unloading; no clear payment event. |
| 6. Jan hauling | 3/10 | Villagers merge into one another during delivery. |
| 7. Jan fishing seated | 1/10 | The supplied strip shows standing/walking Jans; no seated fishing action is visible. |
| 8. Jan chopping | 1/10 | The supplied strip shows locomotion near the furnace; no chopping action is visible. |
| 9. Wolves trotting | 5/10 | Travel reads, but synchronized poses make the pack feel mechanically linked. |
| 10. Wolves fighting | 2/10 | Bodies overlap heavily; attacker, target and impact become unreadable. |

Compared with image 11, the biggest gap is **clear relationships between hands, tools, cargo and workstations**. The target communicates each job through a distinct silhouette. Several gameplay strips communicate it primarily through labels.

1. **Separate wolves and make each attack readable.**  
   **What:** In 10, wolves collapse into a dark overlapping mass; the raid text also covers the action. In 9, their matching poses reinforce the clump.  
   **Phone impact:** Players cannot identify an incoming strike or understand what damaged the furnace.  
   **Change:** Assign attack positions **0.65–0.85 m apart**, with at most **one attacker per position**. Offset trot cycles by **0.10–0.16 s**. Give attacks **0.25 s anticipation** with a **12° backward lean**, then a **0.25–0.35 m lunge over 0.10 s**, **3-frame impact hold**, and **0.22 s recovery**. Keep the raid banner in the top **10% of the screen**, away from combat.

2. **Fix Jan job states and workstation occupancy before polishing their animation.**  
   **What:** Strips 7 and 8 do not show their named actions; 6 and 7 show substantial body intersections. This suggests incorrect state selection, capture timing, or workstation assignment.  
   **Phone impact:** Workers appear idle or broken, and resource production has no visible cause.  
   **Change:** Give each station a reserved action anchor and queue anchors **0.75 m apart**. Stop translation before entering the work loop; settle position and facing over **0.12 s**. For fishing, lower the body approximately **0.20 m onto a seat** and rotate the rigid legs forward **65–80°**. For chopping, hold feet stationary and drive a **55–70° shoulder arc** toward a fixed contact point. Verify captures include **two complete work cycles**.

3. **Give Meagan’s chop a precise contact and immediate response.**  
   **What:** Strip 2 contains broad axe poses and detached logs, but the relationship between strike, tree contact and reward is weak.  
   **Phone impact:** Chopping can feel like waiting for a counter rather than causing an impact.  
   **Change:** Start visible tool movement within **1–2 frames**. Reach the contact pose in **0.10–0.14 s**, using approximately **60° shoulder rotation**, **8° torso turn** and **6° forward lean**. Hold contact for **2 frames**, then spend **0.20–0.26 s** on recoil and settling. Emit chips and the reward at contact. Spawn logs at that same point, then arc them **0.15 m upward over 0.25 s** toward collection. If scaling is supported, use **0.96 vertical / 1.02 horizontal** body scale for **0.05 s**, then restore.

4. **Replace invisible unloading and payment with visible resource transfers.**  
   **What:** In 4 and 5, the bag remains **16/20** and the carried stack remains visible throughout. Neither strip demonstrates a completed transaction.  
   **Phone impact:** Players cannot tell whether they reached the correct location or whether the interaction worked.  
   **Change:** On entering the interaction radius, begin the transfer within **2 frames**. Remove one visible cargo unit every **0.08–0.12 s**, moving it along a **0.25–0.40 m-high arc lasting 0.18–0.24 s** to the destination. Update the bag and destination count on arrival. Use a **5° body dip over 0.12 s** for unloading; give build-pad arrivals a **6% scale pulse over 0.15 s**. Complete a batch within approximately **0.6 s**.

5. **Make loaded walking distinct, with planted contacts and attached cargo.**  
   **What:** Meagan’s movement in 1, 4 and 5 has similar upright carriage despite the tall load. Some cargo edges appear separated from the body. Jan’s bundle in 6 needs an equally clear hand attachment. Foot sliding is a risk, but cannot be confirmed from these samples.  
   **Phone impact:** Cargo feels weightless; weak attachment makes items look like floating inventory markers.  
   **Change:** Use a loaded step cycle of **0.65–0.75 s**, **6–9° forward lean**, **±18–22° leg swing**, and **0.025–0.04 m body rise**. Derive cycle speed from distance travelled, targeting **0.40–0.50 m per step**. Keep a contacting foot approximately stationary in world space for **0.10–0.14 s** using root compensation. Anchor cargo to the torso or hands; add only **±3° rotation**, delayed **0.06–0.09 s** behind the body. Give scarf and braid **±6–10° overlap** with a similar delay.

6. **Give fishing a visible tension–catch–settle cycle.**  
   **What:** In 3, the rod and body barely change across frames while large “+3” rewards repeatedly appear.  
   **Phone impact:** Fishing reads as passive income with a prop, and the feedback obscures the small physical action.  
   **Change:** During waiting, move the float vertically **0.015–0.025 m** on a **0.8–1.2 s loop**. On a catch, dip it **0.05 m over 0.07 s**, lift the rod **18–25° over 0.12 s**, and lean Meagan back **7°**. Settle over **0.25–0.35 s**. Keep the line attached to both rod tip and float throughout. Show one reward per completed catch, offset **20–28 screen pixels** from the character, lasting **0.45 s**.

7. **Clear the silhouettes and remove orphaned-looking props.**  
   **What:** Bag labels hide heads and tools across several strips; large rewards cover nearby action. Thin detached shapes beside Meagan in 1 and 3 look like edge-on or uncollected props. Logs in 2 lack an obvious supported or moving state.  
   **Phone impact:** These small ambiguous shapes read as rendering faults, while overlays hide the animation cues players need.  
   **Change:** Keep bag labels **12–16 screen pixels above the highest animated head position**, and shrink their current footprint by approximately **25%**. Preserve at least **4–6 pixels of visible separation** between tools and torsos at key poses. Audit each detached item: attach it to a hand, ground it with a contact shadow, or give it a deliberate collection trajectory completed within **0.3 s**. Remove persistent edge-on duplicates.

**Verdict: fix first — missing Jan work actions, intersecting wolves and villagers, and unreadable resource transfers undermine the core gameplay feedback.**