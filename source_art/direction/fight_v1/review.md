**Readability: 4/10. Feel: 5/10, provisionally.** These slowed frame strips show poses and clutter; they cannot verify real-time cadence, hit timing or movement responsiveness. Strip 1 barely communicates a projectile; strip 2 makes the stick more legible than the ranged attack. Strip 3 loses combat beneath rewards and particles. Strip 4 exposes overlapping wolves and unclear bite preparation.

Fix these five, in order. Pixel targets below assume a **390 px-wide phone viewport**.

1. **Remove UI from the fight’s silhouette.**  
   **What I see:** In strip 3, enormous “+15 Food +3…” text crosses Meagan and the wolves. Furnace/Upgrade labels compete with heads throughout; health bars are broad, heavy rectangles. **The specified “small loot pop” is visibly broken.**  
   **Why it hurts:** The reward obscures the next threat precisely when the player needs to react.  
   **Change:** Use one **12–14 px icon-and-number reward**, placed **24 px above the encounter**, rising **12 px over 0.6 s**. Combine rewards arriving within **0.35 s**. Hide nearby building labels during combat. Restore **24 × 3 px wolf bars**, **36 × 4 px Meagan bar**, with **5 px overlap offsets**.

2. **Make an incoming bite unmistakable before adding more impact effects.**  
   **What I see:** Strip 4’s wolves overlap Meagan and one another; I cannot identify a clear planted crouch or committed bite wedge. Ground ovals are more noticeable than attack direction.  
   **Why it hurts:** Being surrounded reads as continuous contact damage, rather than attacks the player can dodge.  
   **Change:** During the **0.40 s wind-up**, hold position, lower the shoulders about **20%**, and draw the specified **70° wedge** in muted rust with a **1.5 px ink edge**, matching the actual bite footprint. Keep only **two attackers committed**, starting **≥0.25 s apart**; enforce **0.8 m centre spacing**. Reserve the **18 px broken ink ring** for Meagan’s single target. Verify those rules in motion; the stills do not establish whether the logic is broken.

3. **Give the snowball a visible release and flight.**  
   **What I see:** Strip 1 ends with an extended mitten, but no clearly readable travelling snowball. In strip 2, the long stick dominates the ranged-to-melee transition.  
   **Why it hurts:** Ranged damage looks automatic and disconnected from Meagan’s gesture.  
   **Change:** Give the ball a **6–8 px minimum screen diameter**, warm-white fill and **1 px blue-grey outline**, with a short **12–18 px tapered trail**. Release visibly from the mitten at **0.18 s**. Tuck the stick close to her opposite side during throws; bring it into the sweep pose only after the throw finishes.

4. **Make the stick’s contact explain which wolf took damage.**  
   **What I see:** Strips 2–4 show long horizontal, diagonal and upright stick poses, but the contact moment is difficult to isolate. Broad sweeps pass through a crowded group.  
   **Why it hurts:** A visually broad attack promises multiple hits, while the spec damages one target.  
   **Change:** Keep the **0.16 s anticipation / 0.08 s sweep**, but concentrate the sweep into a **60–80° arc aimed through the locked target**. Add a restrained **2 px ochre stroke for 80 ms** along the stick tip’s path. At **0.24 s**, synchronize target squash, **0.25 m knockback** and **50 ms visual hit-stop**. Keep the legs moving independently.

5. **Replace square particle clouds with readable hit and defeat states.**  
   **What I see:** Strip 3’s white square bursts erase wolf anatomy; strip 4 also shows blocky white patches. A pale wolf could read as a flash or a defeat—the distinction is unclear.  
   **Why it hurts:** Players cannot quickly tell which threats remain active, and the squares break the watercolour treatment.  
   **Change:** Use **4–6 irregular, blue-shadow-edged flecks**, confined to a **12–18 px burst lasting 0.18 s**. Preserve the wolf’s ink outline during the **70 ms cream hit tint**. On defeat, remove its bar and target ring immediately, show the **0.18 s tip + 0.12 s settle**, then the scramble and outward escape. Keep particles below the head and back silhouette.

Verdict: fix first — reward text hides combat, ranged attacks lack a clear projectile read, and incoming bites need unmistakable tells.