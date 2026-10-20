shader_type spatial;
// An enemy attack's tell on the snow (fight_v2 reviews 2, 3): one muted terracotta treatment, a
// 17% wash over the whole danger zone and a fill that advances (to 27%) from the attacker to the edge as the
// strike comes. The fill's leading edge is soft, so the only hard edge is the zone's boundary
// (a separate line mesh). The mesh is drawn in the tell's local space, the attacker at the origin.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 color : source_color = vec4(0.66, 0.3, 0.2, 1.0);
uniform float wash = 0.17;
uniform float fill = 0.1;
// How far the fill has come, as a share of the reach, and how soft its leading edge is.
uniform float progress = 0.0;
uniform float soft = 0.25;
uniform float reach = 1.0;
uniform float fade = 1.0;

varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float r = length(local) / reach;
	float inside = 1.0 - smoothstep(progress - soft, progress, r);
	ALBEDO = color.rgb;
	ALPHA = (wash + fill * inside) * fade;
}
