shader_type spatial;
// Meagan's silhouette where something stands in front of her: drawn only where she's hidden
// (the depth test is inverted), as a flat wash in her own Falu red, so the player never loses her.
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.545, 0.2, 0.172, 0.8);

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
