shader_type spatial;
// The ink line, drawn in screen space on a full-screen quad: wherever depth jumps (silhouettes,
// one thing in front of another) or colour changes sharply. It works the same on every mesh,
// however its normals are split. The line wanders a little; with boil_fps above 0 it also
// "boils" like hand-inked animation (off by default: the review found it read as noise).

render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 ink : source_color = vec4(0.2, 0.19, 0.27, 0.85);
// Line width in viewport pixels.
uniform float width_px = 1.8;
// A depth jump this big (metres) draws a line.
uniform float depth_threshold = 0.18;
// A colour difference this big draws a line (0 to about 3).
uniform float color_threshold = 1.2;
// How far the line wanders (pixels) and how often it's redrawn per second.
uniform float wobble_px = 1.2;
uniform float boil_fps = 0.0;

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
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float view_depth(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float frame = floor(TIME * boil_fps);
	vec2 n = SCREEN_UV * VIEWPORT_SIZE / 14.0;
	vec2 jitter = vec2(value_noise(n + frame * 3.1), value_noise(n - frame * 1.7)) - 0.5;
	vec2 uv = SCREEN_UV + jitter * wobble_px * px;
	vec2 o = px * width_px;

	float c = view_depth(uv, INV_PROJECTION_MATRIX);
	float jump = max(
		max(abs(view_depth(uv + vec2(o.x, 0.0), INV_PROJECTION_MATRIX) - c), abs(view_depth(uv - vec2(o.x, 0.0), INV_PROJECTION_MATRIX) - c)),
		max(abs(view_depth(uv + vec2(0.0, o.y), INV_PROJECTION_MATRIX) - c), abs(view_depth(uv - vec2(0.0, o.y), INV_PROJECTION_MATRIX) - c)));
	float edge = smoothstep(depth_threshold, depth_threshold * 1.6, jump);

	vec3 dx = texture(screen_tex, uv + vec2(o.x, 0.0)).rgb - texture(screen_tex, uv - vec2(o.x, 0.0)).rgb;
	vec3 dy = texture(screen_tex, uv + vec2(0.0, o.y)).rgb - texture(screen_tex, uv - vec2(0.0, o.y)).rgb;
	float contrast = length(dx) + length(dy);
	edge = max(edge, smoothstep(color_threshold, color_threshold * 1.5, contrast));

	// No line along the screen's own edge.
	vec2 inside = step(o * 2.0, uv) * step(uv, 1.0 - o * 2.0);
	ALBEDO = ink.rgb;
	ALPHA = edge * ink.a * inside.x * inside.y;
}
