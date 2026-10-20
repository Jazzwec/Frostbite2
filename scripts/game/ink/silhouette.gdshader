shader_type spatial;
// Meagan's silhouette where something stands in front of her: drawn only where she's hidden
// (the depth test is inverted), as a flat wash in her own Falu red, so the player never loses her.
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.7, 0.25, 0.18, 0.65);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
