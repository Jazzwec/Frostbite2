// Shared by the ink look's surface shaders (ink_toon, ink_ground): noise, the furnace's warm wash
// and the banded watercolour light. The including shader declares `varying vec3 world_pos`.

// The furnace's warmth: a painted disc of warm wash around it (set by InkLook from the heat),
// cool blue beyond. Its edge wanders like a hand-laid wash.
uniform vec3 warm_center = vec3(0.0);
uniform float warm_radius = 12.0;
// The small furnaces' smaller warm patches (agreed 2026-10-20): x, z and radius.
uniform vec4 warm_spots[16];
uniform int warm_spot_count = 0;
// A gentle firelight glow on near-white snow, not orange ground (ink_v3 paintover, 2026-10-20).
uniform vec3 warm_tint : source_color = vec3(1.05, 0.985, 0.9);
uniform vec3 cool_tint : source_color = vec3(0.9, 0.94, 1.0);
uniform float pool_radius = 4.6;
uniform vec3 pool_tint : source_color = vec3(1.09, 0.95, 0.84);
uniform float pool_strength = 0.75;
// How much of a point light's strength paints (the furnace's fire is a strong light).
uniform float point_light_scale = 0.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Warm inside the disc, turning cool over its outer part, so the edge reads at a glance. The edge
// wanders a little, broadly, so it stays one rounded shape.
vec3 warmth_tint(vec3 p) {
	float wander = (value_noise(p.xz * 0.12) - 0.5) * 1.2;
	float d = distance(p.xz, warm_center.xz) + wander;
	// Strongest at the fire and fading out to the edge, like a glow rather than a painted disc,
	// with a last soft step at the radius so the warm area's size still reads.
	float warm = (1.0 - smoothstep(0.0, warm_radius, d)) * 0.7 + (1.0 - smoothstep(warm_radius * 0.8, warm_radius, d)) * 0.3;
	for (int i = 0; i < warm_spot_count; i++) {
		float ds = distance(p.xz, warm_spots[i].xy) + wander * 0.5;
		warm = max(warm, 1.0 - smoothstep(warm_spots[i].z * 0.75, warm_spots[i].z, ds));
	}
	// A tighter peach pool of firelight right round the furnace, about a furnace-width past its
	// base, that dims as the fire does (ink_v3 review).
	float dp = distance(p.xz, warm_center.xz) + wander * 0.4;
	float pool = (1.0 - smoothstep(pool_radius * 0.3, pool_radius, dp)) * clamp((warm_radius - 5.0) / 7.0, 0.2, 1.0);
	return mix(mix(cool_tint, warm_tint, warm), pool_tint, pool * pool_strength);
}

void light() {
	// Two or three hard-ish bands instead of a smooth falloff, like layered washes.
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.08, ndl) * 0.65 + smoothstep(0.45, 0.55, ndl) * 0.35;
	if (LIGHT_IS_DIRECTIONAL) {
		// The sun's shadows band too, so they read as painted shapes.
		float att = smoothstep(0.18, 0.26, ATTENUATION) * 0.45 + smoothstep(0.5, 0.58, ATTENUATION) * 0.55;
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * att;
	} else {
		// Point lights (the furnace's fire) only glaze: the warm wash around the furnace already
		// paints its warmth, so a full-strength light would blow out to a yellow pool.
		DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * ATTENUATION * point_light_scale;
	}
}
