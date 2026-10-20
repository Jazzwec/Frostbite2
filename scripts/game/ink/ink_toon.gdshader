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

#include "res://scripts/game/ink/ink_common.gdshaderinc"

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
	c.rgb *= warmth_tint(world_pos);
	ALBEDO = c.rgb;
	EMISSION = emission_color * emission_energy;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
