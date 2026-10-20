// The ink look's surface (see ink_toon.gdshader), shared with its see-through twin
// ink_toon_fade.gdshader, which defines INK_FADE.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vertex_color = false;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
// How strongly the pigment granulates (0 = flat colour).
uniform float granulation = 0.07;
// Reads the texture this many mip levels blurrier, to soften speckle. Kept low (2026-10-20): Meshy
// atlases are many small UV islands, and a strong blur averages neighbouring islands (snow into
// walls). Models are flattened in the asset instead (cleanup.py's palette_snap).
uniform float wash_blur = 0.8;
// Snow settles on whatever faces up, so every roof, crate, rock and chimney sits in the same
// winter (ink_v3, 2026-10-20). Its edge wanders like a laid wash. Characters and the closed-tile
// veil turn it off (InkLook), and nothing this close to the ground gets a cap.
uniform float snow_caps = 1.0;
// A touch blue-grey, like the ground's snow (AFK V3, 2026-10-20): was (0.93, 0.95, 0.97).
uniform vec3 snow_color : source_color = vec3(0.878, 0.906, 0.925);
uniform float snow_min_height = 0.12;
#ifdef INK_FADE
// How solid it is while it fades out of Meagan's way (FadeCover).
uniform float opacity = 1.0;
#endif

varying vec3 world_pos;
varying vec3 world_normal;

#include "res://scripts/game/ink/ink_common.gdshaderinc"

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 c = albedo * textureLod(albedo_tex, UV, wash_blur);
	if (use_vertex_color) {
		c *= COLOR;
	}
	// Pigment settles unevenly: broad blotches plus a fine grain, in world space so it stays put.
	vec2 p = world_pos.xz + world_pos.y * 0.7;
	float blotch = value_noise(p * 0.45) * 0.65 + value_noise(p * 2.3) * 0.35;
	c.rgb *= 1.0 + granulation * (blotch - 0.5) * 2.0;
	// A soft, broad ramp with only low-frequency breakup, so faceted models get one connected cap
	// on top rather than stripes and slivers (ink_v3 review).
	float up = normalize(world_normal).y + (value_noise(p * 0.6) - 0.5) * 0.12;
	float cap = smoothstep(0.66, 0.95, up) * 0.92 * snow_caps * step(snow_min_height, world_pos.y);
	c.rgb = mix(c.rgb, snow_color, cap);
	c.rgb *= warmth_tint(world_pos);
	ALBEDO = c.rgb;
	EMISSION = emission_color * emission_energy;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
#ifdef INK_FADE
	ALPHA = opacity;
#endif
}
