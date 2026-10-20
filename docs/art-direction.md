# Frostbite2 art direction: ink & watercolour picture book

Agreed with the user on 2026-10-20 after three rounds of mock-ups (`source_art/direction/board.html`, round 3 "inked"). This document is the rulebook for every model, texture, icon and shader change. Its reference images are `source_art/direction/round3/inked/lineup.png` and `gameplay.png`.

## Pillars
1. **A Nordic children's picture book come to life.** Hand-inked, slightly wobbly outlines over soft watercolour washes on warm paper. The 3D is there for the camera and the light; it should never look like a 3D render.
2. **Chunky and readable at phone size.** Large clean colour areas, few materials, no thin parts, no surface noise. Every character and building reads as a silhouette first.
3. **Warmth is the picture.** Amber firelight pools around the furnace; beyond it the snow and shade go cool blue. As the heat falls the warm area shrinks.
4. **A real place.** A Svalbard or Norwegian fishing village: Falu-red, ochre and faded-teal timber houses, woodpiles, sleds, ice holes and a fieldstone-and-iron village furnace (never a sci-fi generator).
5. **Its own motifs.** A pair of mittens, a crooked sun and the furnace-mouth mark, repeated on doors, signs, coats and sleds. They are the game's signature; use them instead of generic decoration.

## Palette
| Name | Hex | Use |
| --- | --- | --- |
| Falu red | `#B2412E` | Meagan's parka, some house walls. **No Jan ever wears it.** |
| Ochre | `#C9973F` | Houses, Meagan's mustard scarf, wood and rope |
| Faded teal | `#5E8A87` | Houses, sleds |
| Deep teal | `#35666B` | The Jans' parkas (darker than faded teal so they hold against cool snow) |
| Snow | `#EEF2F2` | Snow and paper |
| Blue shadow | `#7F93A6` | Shade, cold snow, distant forest |
| Deep ink | `#2C3440` | Outlines and dark details (never pure black) |
| Firelight | `#F2B266` | The furnace mouth, windows, warm snow near the fire |

UI accents may brighten these for contrast, but stay within the same hues.

## Characters
- **Meagan:** the brightest thing on screen. Deep Falu-red parka with a cream fur-trimmed hood, a thick dark-brown braid, a long mustard scarf, dark trousers and tan boots. She is the only red figure.
- **Jans:** one shared silhouette so a crowd reads at a glance: stocky, a full round brown beard, a red bead nose, a navy knitted beanie, chunky mittens and a **deep-teal** work parka. Variants change only one big prop (apron and ladle, blanket, clipboard, headphones).
- **Proportions:** moderately stylised, head about a fifth of the height; small dot or bean eyes and minimal features; mitten hands; clean and friendly, never dirty or worn.
- **Wolves:** blue-grey, a darker ink back, no gore.

## Shapes and materials
- Round, chunky, slightly crooked. Exaggerated roofs with thick snow caps, oversized doors, fat logs.
- Painted wood and stone textures with broad washes, not photo textures. The Poly Haven props are placeholders.
- Low poly is fine and expected: the ink lines and washes carry the detail, not the geometry.

## In the engine
`InkLook` (`scripts/game/ink/`) is the look, on by default:
- `ink_toon` bands the light into a few watercolour washes with pigment granulation, warm in the sun and cool blue in shade.
- `ink_lines` inks silhouettes and major seams in deep ink, 1–2 px at phone resolution, thinner inside, and ignores small colour speckle.
- `ink_paper` adds pigment pooling at edges and a light paper grain under the HUD.
- `ink_ground` paints the snowfield: a watercolour wash, cool hollows and packed paths.

## Icons
Watercolour icons with a thick deep-ink outline, in `assets/ui/icons/` (128 px, cut from `source_art/icons/sheet.png`). They sit inline in rich labels through `UiTheme.icon(name, size)`, at 36–48 px on the 1080-wide layout; a number keeps its word next to its icon.
- The DEV panel's Ink look toggle switches it off, for comparison.

## Prompt template (ChatGPT and Tripo references)
Start with the subject, then add this block unchanged and pass `round3/inked/lineup.png` (or an earlier image in the same set) as `--ref`:

> Rendered in INK AND WATERCOLOUR PICTURE-BOOK style: hand-inked slightly wobbly dark outlines, soft watercolour colour washes with visible paper grain, gently simplified shapes, like a Nordic children's picture book brought into a 3D game with toon shading and outlines. Palette: Falu red #B2412E, ochre #C9973F, faded teal #5E8A87, snow #EEF2F2, blue shadow #7F93A6, deep ink #2C3440, firelight #F2B266. Designed like a real indie game's art style with deliberate simplification and restraint: few materials, large clean colour areas, no surface texture noise, no rendered glow or bloom, no sparkles, no glossy plastic, no big shiny Disney-style eyes, no chibi proportions, no generic 3D animated-movie look, no over-detailed props, no text, no labels, no UI.

For a Tripo reference, also ask for a single object, front three-quarter view, on plain light grey, with flat even lighting (Tripo bakes shadows into the texture otherwise).

## Not this
- Whiteout Survival's look or assets.
- Glossy "animated movie" 3D, bloom, sparkles, big shiny eyes, chibi heads.
- Grime, wear and photoreal textures.
- Pure black outlines or a heavy full-screen filter over unchanged assets.
