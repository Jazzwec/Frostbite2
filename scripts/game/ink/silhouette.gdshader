shader_type spatial;
// Meagan's silhouette where something stands in front of her: drawn only where she's hidden
// (the depth test is inverted), as a flat wash in her own Falu red, so the player never loses her.
render_mode unshaded, depth_test_inverted, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.545, 0.2, 0.172, 0.8);
// A warm-cream contour round the shape, so her facing and her stick read through the cover too
// (fight_v2 review 11).
uniform vec4 contour : source_color = vec4(0.99, 0.93, 0.8, 1.0);
uniform float contour_width = 0.3;

void fragment() {
	float edge = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float c = smoothstep(1.0 - contour_width, 1.0 - contour_width * 0.6, edge);
	ALBEDO = mix(color.rgb, contour.rgb, c);
	ALPHA = mix(color.a, contour.a, c);
}
