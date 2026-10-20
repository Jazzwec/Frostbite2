The revision reduces the scratchy black outlines and paper noise, and adds better warm–cool separation. It only partly fixes the white-paper dominance and overpowering yellow fire. The warm area reads as furnace light, but its safe-zone boundary is too vague to guide movement reliably.

1. **Reduce the furnace’s yellow clipping.** In images 2–3, the furnace remains a nearly flat, fluorescent-yellow patch, much like image 1. It pulls attention away from nearby activity and loses surface detail at phone size. Shift the broad fill toward orange-gold, reduce its saturation by roughly 20–30%, and reserve pale yellow for a small central highlight.

2. **Give the safe zone a readable outer edge.** Image 2’s amber wash dissolves into cream snow; in image 3, the busy scene makes its extent harder to judge. Players need to know whether Meagan is inside safety without inspecting the ground. Keep the soft interior, but concentrate the amber-to-cool-blue transition within the outer 10–15% of the radius. Avoid a hard outline; make the actual gameplay boundary match this transition.

3. **Lower the snow’s near-white coverage.** Images 2–3 still contain large pale areas that flatten the scene and weaken the warmth cue. Image 4 uses more blue-grey shadow to hold the snow together. Move the shader’s neutral snow tint toward a light, muted blue-grey, keeping the brightest whites for highlights. Let furnace warmth tint that base instead of bleaching it.

4. **Finish softening the darkest ink.** Image 2’s lines are thinner and less scratchy than image 1, but furnace and prop contours still become near-black bands. Those bands dominate small silhouettes. Reduce outline opacity another 15–25%, bias shadow ink toward desaturated blue-brown, and suppress internal edges before weakening exterior silhouettes. Judge thickness at final phone resolution.

5. **Remove the remaining broad paper patches.** Fine grain is less intrusive in image 2, but rectangular tonal patches remain conspicuous across the lower snow in images 2–3. They read as screen dirt and compete with the safe-zone wash. Halve their contrast and break up their rectangular boundaries. The claimed world-pinned wobble needs a motion check; still images cannot confirm that crawling is fixed.

Verdict: fix first — the safe-zone boundary remains ambiguous, and the yellow furnace still overpowers the shader’s improved colour balance.
---
**Applied (2026-10-20):**
1. The fire's glow is capped in the ink look (`EMISSION_CAP`), so it paints orange, and point lights only glaze (`point_light_scale`), so there's no yellow pool on the snow.
2. The warm disc is even inside and turns cool over its outer eighth.
3. The snowfield is a light blue-grey that the warmth tints cream.
4. Lighter ink (alpha 0.65) and weaker inner lines.
5. The paper wash is halved. The rectangular patches are the ground's own pieces, not paper; the painted ground (item 1c) replaces them.

Not applied: "make the gameplay boundary match". The game has no warm-zone rule yet; the disc is only a picture of the heat. `after.png` is after these fixes; `busy.png` is the busy scene after them.
