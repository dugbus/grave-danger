shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled, cull_disabled;

#include "res://placeables/kill_boundary/sepia/sepia_mask.gdshaderinc"

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 sepia_tint : source_color = vec4(0.96, 0.94, 0.86, 1.0);
uniform vec4 sepia_shadow_tint : source_color = vec4(0.25, 0.245, 0.235, 1.0);
uniform float sepia_exposure = 1.2;
uniform float photo_strength = 0.55;
uniform float colour_retention = 0.95;
uniform float film_grain_strength = 0.01;
uniform float film_vignette_strength = 0.05;

float paper_hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 aged_print(vec3 image, vec2 screen_uv, vec2 fragment_pixel) {
	// A stationary paper texture keeps the print calm as time passes; no scratches or exposure flicker.
	vec2 grain_pixel = floor(fragment_pixel / 1.5);
	float grain = paper_hash(grain_pixel) - 0.5;
	vec3 print_color = mix(sepia_shadow_tint.rgb, sepia_tint.rgb, clamp(image + vec3(grain * film_grain_strength), vec3(0.0), vec3(1.0)));
	vec2 frame_position = screen_uv - vec2(0.5);
	float vignette = smoothstep(0.05, 0.5, dot(frame_position, frame_position));
	return print_color * (1.0 - vignette * film_vignette_strength);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	ndc.z = depth * 2.0 - 1.0;
	#endif
	float coverage;
	if (depth > 0.000001) {
		vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		view /= view.w;
		vec3 position_world = (INV_VIEW_MATRIX * view).xyz;
		coverage = sepia_mask(position_world);
	} else {
		// Empty background has no surface position. Project its ray onto each boundary's live base
		// plane to extend the same footprint through map-edge voids, rather than leaving raw black.
		vec4 near_view = INV_PROJECTION_MATRIX * vec4(ndc.xy, 1.0, 1.0);
		float far_z = 0.0001;
		#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		far_z = far_z * 2.0 - 1.0;
		#endif
		vec4 far_view = INV_PROJECTION_MATRIX * vec4(ndc.xy, far_z, 1.0);
		vec3 near_world = (INV_VIEW_MATRIX * (near_view / near_view.w)).xyz;
		vec3 far_world = (INV_VIEW_MATRIX * (far_view / far_view.w)).xyz;
		coverage = sepia_background_mask(near_world, far_world - near_world);
	}
	if (coverage <= 0.0) { discard; }
	vec3 original_rgb = max(texture(scene_color, SCREEN_UV).rgb, vec3(0.0));
	vec3 scene = original_rgb * sepia_exposure;
	// One shared shoulder scales RGB together, retaining channel relationships rather than replacing
	// colour with luminance. Raised print blacks and a mild paper cast supply the photographic fade.
	float peak = max(scene.r, max(scene.g, scene.b));
	vec3 image = scene * ((1.0 - exp(-peak)) / max(peak, 0.000001));
	float luminance = dot(image, vec3(0.2126, 0.7152, 0.0722));
	image = mix(vec3(luminance), image, colour_retention);
	ALBEDO = mix(original_rgb, aged_print(image, SCREEN_UV, FRAGCOORD.xy), photo_strength);
	ALPHA = coverage;
}
