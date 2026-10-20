shader_type spatial;
// A footprint pressed into the snow (AFK V6, 2026-10-20): a soft blue-grey oval, darker at its
// heel, fading out as it ages. One material for every print; each print's fade is an instance
// uniform, so a pool of them costs one material.

render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.53, 0.596, 0.678);
uniform float strength = 0.5;
instance uniform float fade = 1.0;

void fragment() {
	// UV across the print: an oval, a little narrower at the toe.
	vec2 p = UV * 2.0 - 1.0;
	p.x *= 1.0 + 0.25 * p.y;
	// A soft, slightly broken watercolour edge.
	float edge = 0.08 * sin(p.x * 9.0 + p.y * 5.0) + 0.06 * sin(p.y * 13.0 - p.x * 4.0);
	float oval = 1.0 - smoothstep(0.35 + edge, 0.95 + edge, length(p));
	float heel = 0.75 + 0.25 * smoothstep(-0.2, 0.8, p.y);
	ALBEDO = tint;
	ALPHA = oval * heel * strength * fade;
}
