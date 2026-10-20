The pines read as snowy trees at phone size, but their sharp, stacked silhouettes feel more angular than image 4’s rounded picture-book forms. The clusters read as forest; their chop interaction becomes unclear during fading and falling.

1. **Keep falling trees readable.** In image 3, both trunks and crowns become pale, overlapping ghosts that resemble ice shards. On a phone, that obscures the reward for chopping. Release the character-occlusion fade once a tree falls clear of Meagan; restore opacity over **150–250 ms**, then fade it out after landing.

2. **Round off the crown silhouettes.** Images 1–3 show pointed side spikes and abrupt, zigzag tier edges. These dominate at small sizes and clash with image 4’s softer painted shapes. Shorten outward branch tips by **20–25%**, broaden the upper crown, and use **three broad, slightly irregular tiers** with fewer tiny notches.

3. **Make the standing forest visibly harvestable.** In image 1, overlapping crowns hide almost every trunk; the “Wood 60” label carries most of the resource meaning. Space trees roughly **15–20% farther apart** and expose a short, warm-brown trunk on the frontmost trees. Leave a clear chopping approach beside that visible trunk.

4. **Fade the obstruction without dissolving the whole tree.** In image 2, transparent layers accumulate across Meagan and the surrounding trees, creating visual clutter. Keep obstructing crowns at about **30–40% opacity**, retain the trunk/base near full opacity, and restrict fading to trees actually covering her silhouette. Use a **150 ms transition** to avoid popping.

Verdict: fix first — the standing trees read, but the ghosted chopping and falling states weaken the resource interaction.
---
**Applied (2026-10-20):**
1. A felled tree is no longer faded, so it comes back to solid as it topples (`NodeView.fade_covers` only fades standing trees).
2. The pines are rebuilt rounder: three broad tiers (two on the squat one), each with a soft shoulder ring, shallower notches (10 sides) and fuller snow caps.
3. Trees stand about 17% farther apart (1.4–2.8 m from the middle), and each pine shows a short brown trunk under its lowest tier.
4. Already the case: fading only covers crowns that actually cover her, at 30% opacity.

`forest.png`, `fade.png` and `fall.png` are after these fixes. The pines have 168–244 triangles each. FPS in the busy scene: about 400.
