shader_type canvas_item;
// The ink-and-watercolour look's one full-screen pass: pigment pooling at colour edges,
// broad uneven washes, and paper grain. It sits under the HUD, so the UI stays crisp.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 paper : source_color = vec3(0.99, 0.985, 0.97);
// Pigment granulates more where the wash is darker (the shade), as it does on real paper.
uniform float shade_grain = 2.5;
// Pigment pooling at the dark side of colour edges, like a drying wash.
uniform float edge_darkening = 0.5;
// Broad blotches of uneven wash, and the fine paper fibre.
uniform float wash = 0.02;
uniform float grain = 0.012;

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

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec3 blur = textureLod(screen_tex, SCREEN_UV, 2.5).rgb;
	c -= max(vec3(0.0), blur - c) * edge_darkening;
	vec2 px = FRAGCOORD.xy;
	float blotch = value_noise(px / 170.0) * 0.6 + value_noise(px / 55.0) * 0.4;
	float fibre = value_noise(px / 2.5) * 0.5 + value_noise(px / 1.2) * 0.5;
	c *= 1.0 + wash * (blotch - 0.5) * 2.0;
	float shade = clamp(1.0 - dot(c, vec3(0.333)), 0.0, 1.0);
	c *= 1.0 + grain * (fibre - 0.5) * 2.0 * (1.0 + shade_grain * shade);
	COLOR = vec4(c * paper, 1.0);
}
