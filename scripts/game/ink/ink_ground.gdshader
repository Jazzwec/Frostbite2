shader_type spatial;
// The town's snowfield, painted: a watercolour snow wash (assets/textures/snow_wash.png) laid
// twice at different sizes and angles so it doesn't visibly repeat, broad blue-grey shadow
// washes, trodden tracks from the furnace to every plot and the Stockpile, and soft shade pooled
// round everything standing in it (both set by main.gd from the state, as tiles open and things
// are built). The tracks stay paler than the pads, so travel routes stay quiet.

uniform sampler2D snow_tex : source_color, filter_linear_mipmap, repeat_enable;
// Metres per repeat of the snow wash.
uniform float tile_m = 20.0;
// How much of the wash's own contrast shows (1 = as painted), around its average colour.
uniform float wash_contrast = 0.7;
// Slightly blue-grey snow, near-white kept for the lit highlights (AFK V3, 2026-10-20, from the
// reviews): wash_mean was (0.886, 0.908, 0.925), shadow_strength 0.28.
uniform vec3 wash_mean : source_color = vec3(0.855, 0.878, 0.91);
uniform vec3 shadow_tint : source_color = vec3(0.8, 0.86, 0.94);
uniform float shadow_strength = 0.42;
// The whole wash, a little warm-grey: the rendered snow averaged #D8E4F4, too blue; the review's
// target is about #DEE5EB, with #BCCDDD in the hollows (V3).
uniform vec3 snow_tint : source_color = vec3(1.0, 0.98, 0.91);
// Trodden snow: a cool blue-grey track broken into footprints, not a warm road (ink_v3, 2026-10-20).
uniform vec3 path_color : source_color = vec3(0.76, 0.81, 0.89);
uniform float path_strength = 0.8;
uniform float path_width = 1.6;
// Each path is a segment from (x, y) to (z, w), in world x/z metres.
uniform vec4 paths[64];
uniform int path_count = 0;
// Soft blue shade pooled round everything standing in the snow: x, z, radius (set by main.gd).
uniform vec4 contacts[96];
uniform int contact_count = 0;
uniform vec3 contact_tint : source_color = vec3(0.72, 0.8, 0.92);
uniform float contact_strength = 0.6;

varying vec3 world_pos;

#include "res://scripts/game/ink/ink_common.gdshaderinc"

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	return distance(p, a + ab * t);
}

void fragment() {
	vec2 p = world_pos.xz;
	vec2 q = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p;
	vec3 c = mix(texture(snow_tex, p / tile_m).rgb, texture(snow_tex, q / (tile_m * 2.3) + 0.37).rgb, 0.5);
	c = mix(wash_mean, c, wash_contrast) * snow_tint;

	// Broad shadow washes, like the cool hollows between drifts.
	// Broad and quiet (ink_v3 review): low frequencies and a wide ramp, so no blocky clusters.
	float hollow = value_noise(p * 0.035) * 0.75 + value_noise(p * 0.08) * 0.25;
	c *= mix(vec3(1.0), shadow_tint, smoothstep(0.45, 0.85, hollow) * shadow_strength);

	// Packed paths with wobbly painted edges.
	float d = 1000.0;
	for (int i = 0; i < path_count; i++) {
		d = min(d, segment_distance(p, paths[i].xy, paths[i].zw));
	}
	d += (value_noise(p * 0.9) - 0.5) * 0.5;
	// A wide soft edge: a gradual change, so the ink pass doesn't outline the path.
	float path = 1.0 - smoothstep(path_width * 0.2, path_width * 0.5 + 0.5, d);
	// Footprints: the track is darker in small blots and paler between them.
	float steps = smoothstep(0.4, 0.7, value_noise(p * 2.2)) * 0.35 + 0.65;
	c = mix(c, path_color * c / 0.9, path * path_strength * steps);

	// Contact shade: a soft pool under and around each standing thing, darkest at its foot, so
	// nothing meets the snow with a hard edge.
	float shade = 0.0;
	for (int i = 0; i < contact_count; i++) {
		float r = contacts[i].z;
		float dc = distance(p, contacts[i].xy) + (value_noise(p * 0.8 + float(i)) - 0.5) * r * 0.25;
		// Tight and darkest at the foundation, fading quickly (ink_v3 review).
		float s1 = 1.0 - smoothstep(r * 0.7, r * 1.15, dc);
		shade = max(shade, s1 * s1);
	}
	c *= mix(vec3(1.0), contact_tint, shade * contact_strength);

	ALBEDO = c * warmth_tint(world_pos);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
