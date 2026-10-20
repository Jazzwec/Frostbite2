shader_type spatial;
// A struck enemy's flash (fight_v2 review 1): a warm rim of light round its silhouette and a
// faint warm glaze on its face, instead of turning the whole body white, so its shape still
// reads through the hit. Used as a material_overlay for about 80 ms; `strength` fades it.
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 rim_color : source_color = vec4(1.0, 0.78, 0.42, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float rim_power = 3.0;
uniform float glaze = 0.05;

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	ALBEDO = rim_color.rgb * (rim + glaze) * strength;
}
