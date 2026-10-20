shader_type spatial;
// The ink line, drawn in screen space on a full-screen quad: wherever depth jumps (silhouettes,
// one thing in front of another) or colour changes sharply. It works the same on every mesh,
// however its normals are split. Silhouettes get the full line; colour edges a thinner, lighter
// one, measured on a slightly blurred picture so texture speckle doesn't ink. The line wanders a
// little, by a wobble pinned to the world, so it stays still on a still picture and moves with
// the surface instead of crawling over it.

render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// Deep ink, a little warm: blue-brown rather than black.
uniform vec4 ink : source_color = vec4(0.2, 0.21, 0.26, 0.82);
// Silhouette line width in viewport pixels (1080 x 1920).
uniform float width_px = 1.8;
// Colour-edge lines: their width and how strong they are against a silhouette.
uniform float inner_width_px = 0.8;
uniform float inner_strength = 0.2;
// A depth jump this big (metres) draws a line.
uniform float depth_threshold = 0.18;
// A colour difference this big draws a line (0 to about 3).
uniform float color_threshold = 0.9;
// How far the line wanders (pixels), and the size of its wander (metres).
uniform float wobble_px = 1.0;
uniform float wobble_scale = 1.6;
// How often the wobble re-seeds (frames a second): a gentle hand-drawn boil.
uniform float boil_fps = 8.0;
// How much of the outlined thing's own colour the line takes, and how dark that shade is.
uniform float local_tint = 0.55;
uniform float local_darken = 0.38;

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

vec3 view_pos(vec2 uv, mat4 inv_projection) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.xyz / v.w;
}

float view_depth(vec2 uv, mat4 inv_projection) {
	return -view_pos(uv, inv_projection).z;
}

// The picture, softened over about 4 x 4 pixels (four bilinear taps), so single-pixel speckle
// on textured clothing doesn't count as a colour edge.
vec3 soft(vec2 uv, vec2 px) {
	return (texture(screen_tex, uv + px * vec2(0.75, 0.75)).rgb + texture(screen_tex, uv + px * vec2(-0.75, 0.75)).rgb
			+ texture(screen_tex, uv + px * vec2(0.75, -0.75)).rgb + texture(screen_tex, uv + px * vec2(-0.75, -0.75)).rgb) * 0.25;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	// Wobble pinned to the surface under this pixel.
	vec3 world = (INV_VIEW_MATRIX * vec4(view_pos(SCREEN_UV, INV_PROJECTION_MATRIX), 1.0)).xyz;
	vec2 n = (world.xz + world.y * 0.5) * wobble_scale;
	// The line boils: its wobble re-seeds a few times a second, like redrawn frames.
	float frame = floor(TIME * boil_fps);
	n += vec2(hash(vec2(frame, 1.0)), hash(vec2(frame, 2.0))) * 9.0;
	vec2 jitter = vec2(value_noise(n), value_noise(n + 17.3)) - 0.5;
	vec2 uv = SCREEN_UV + jitter * wobble_px * px;

	vec2 o = px * width_px;
	float c = view_depth(uv, INV_PROJECTION_MATRIX);
	// The biggest depth jump to a neighbour, and the nearest of them: the line takes the colour
	// of the thing in front.
	float jump = 0.0;
	float nearest = c;
	vec2 near_uv = uv;
	vec2 dirs[4] = vec2[](vec2(o.x, 0.0), vec2(-o.x, 0.0), vec2(0.0, o.y), vec2(0.0, -o.y));
	for (int k = 0; k < 4; k++) {
		float d = view_depth(uv + dirs[k], INV_PROJECTION_MATRIX);
		jump = max(jump, abs(d - c));
		if (d < nearest) {
			nearest = d;
			near_uv = uv + dirs[k];
		}
	}
	float edge = smoothstep(depth_threshold, depth_threshold * 1.6, jump);

	vec2 oi = px * inner_width_px;
	vec3 dx = soft(uv + vec2(oi.x, 0.0), px) - soft(uv - vec2(oi.x, 0.0), px);
	vec3 dy = soft(uv + vec2(0.0, oi.y), px) - soft(uv - vec2(0.0, oi.y), px);
	float contrast = length(dx) + length(dy);
	edge = max(edge, smoothstep(color_threshold, color_threshold * 1.5, contrast) * inner_strength);

	// No line along the screen's own edge.
	vec2 inside = step(o * 2.0, uv) * step(uv, 1.0 - o * 2.0);
	// A darker shade of what it outlines, not one flat ink, so the drawing doesn't look stamped.
	vec3 local = texture(screen_tex, near_uv).rgb;
	ALBEDO = mix(ink.rgb, local * local_darken, local_tint);
	ALPHA = edge * ink.a * inside.x * inside.y;
}
