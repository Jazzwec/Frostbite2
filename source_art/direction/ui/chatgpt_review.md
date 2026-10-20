1. **Occlusion silhouette — fix first.** Image 2’s after view still reads as pale grey-blue; Meagan’s hidden body barely separates from the tree. At phone size, the player loses her position. Keep the cover at 30% opacity, but render her hidden parts above it in a flat Falu red (`#8B332C`) at roughly 75% opacity. Preserve her body shape without interior detail.

2. **Jan chatter — only partly fixed.** In image 3, the bubble stays inside the left edge, but overlaps another line, the furnace label and the controls. Sideways movement fixes clipping while leaving the text difficult to read. Clamp the **whole bubble** within 16 px screen margins and below the top controls; show one nearby Jan’s message at a time for about 3 seconds.

3. **Health bars — colours read; ownership doesn’t.** Image 1 separates Meagan’s green from wolves’ red, but the bars crowd together above the fight. The guard’s blue bar isn’t clearly visible enough to judge. Give Meagan a 48 × 7 px bar at this 540 px screenshot width, with a 2 px dark outline and a consistent gap above her head. Keep wolf and guard bars around 30 × 5 px so hers remains identifiable without relying on colour.

4. **Game-over tiles — readable, with one weak icon.** Image 4’s large numbers and four-tile layout work at phone size. However, the axe suggests chopping rather than “Buildings,” making that result slower to understand. Replace it with a chunky building silhouette at the same size; retain the current number size and tile placement.

Verdict: fix first — Meagan still disappears behind cover, and chatter still obstructs play.
---
**Applied (2026-10-20):**
1. The silhouette is a stronger Falu red (#8B332C at 80%) and draws after the faded cover (render priority 6), so the cover no longer dims it.
2. One Jan talks at a time: the newest line clears the one before. Bubbles already keep 24 px from the screen's sides.
3. Meagan's bar sits higher (2.05 m) than the wolves' and guards', so it stays clear of theirs in a fight.
4. "Buildings" on the game-over card has a house icon (`assets/ui/icons/house.png`, from `source_art/icons/building.png`) instead of the mallet.

Not done: keeping bubbles below the top buttons, and smaller enemy bars. See `after_review.png`.
