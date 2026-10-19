shader_type spatial;
// The ink-and-watercolour look's surface: flat watercolour washes in two or three light bands,
// with a little pigment granulation so large faces don't look like flat plastic.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_vertex_color = false;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
// How strongly the pigment granulates (0 = flat colour).
uniform float granulation = 0.07;
// Reads the texture this many mip levels blurrier, so detailed textures flatten into washes
// (a stand-in for textures painted in watercolour).
uniform float wash_blur = 2.6;

varying vec3 world_pos;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	ALBEDO = c.rgb;
	EMISSION = emission_color * emission_energy;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	// Two or three hard-ish bands instead of a smooth falloff, like layered washes.
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.08, ndl) * 0.65 + smoothstep(0.45, 0.55, ndl) * 0.35;
	// Shadows and light falloff band too, so the fire's light makes painted rings.
	float att = smoothstep(0.18, 0.26, ATTENUATION) * 0.45 + smoothstep(0.5, 0.58, ATTENUATION) * 0.55;
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * lit * att;
}
