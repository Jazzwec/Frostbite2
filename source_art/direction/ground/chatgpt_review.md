1. **Soften the warmth boundary.** Compared with image 1, image 2 has a noticeably scalloped cream-to-blue edge, especially below the town. It makes the shrinking heat zone look patchy and can obscure its extent. Keep one broad, rounded boundary; feather it across roughly 30–45 screen pixels and reduce smaller edge fluctuations.

2. **Give the paths a clearer direction.** In image 2, the warm paths merge into the cream disc, so routes from the furnace to pads and the Stockpile are difficult to trace. Use broad, continuous strokes about 24–36 screen pixels wide, with a muted peach-grey tint slightly darker than the surrounding cream. Keep their contrast below the pads; avoid outlined edges.

3. **Reduce the snow’s mottling near gameplay objects.** Image 3’s repeated blue-white patches compete with the small wood resource and the character’s feet. Reduce wash contrast by roughly 25% and enlarge the texture features, particularly the small bright flecks. Preserve stronger blue-grey hollows in open snow, away from resource silhouettes and pad edges.

4. **Make the wash more consistent across the warmth transition.** Image 2’s cream area reads substantially smoother than image 3’s cool snow, making the ground feel like two different surfaces. Carry the same low-contrast paper grain through both, changing primarily the colour and warmth. No obvious hard tile seams are visible in these captures, but the recurring cloudy patches could reveal repetition over a larger scrolling area.

The paths are currently quieter than the pads—sometimes too quiet to read as routes. Ground contrast does not seriously obscure characters; small resources are more vulnerable.

Verdict: fix first — clarify routes and quiet the cool-snow texture before locking the ground.
---
**Applied (2026-10-20):**
1. The warm edge wanders less and more broadly and is feathered over the outer fifth of the radius.
2. The paths are a darker peach-grey and a little stronger, still below the pads, with soft edges, so they aren't inked.
3. The snow wash shows at 70% of its contrast, and its repeat is larger (20 m).
4. Both sides share the same wash; only the tint changes.

`town.png` and `forest.png` are after these fixes. FPS in the busy scene: about 430.
