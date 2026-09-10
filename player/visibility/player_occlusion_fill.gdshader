shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_inverted, cull_back, shadows_disabled;
stencil_mode read, compare_not_equal, 37;

// Inverted hardware depth draws only where the ordinary opaque scene is closer than the player.
uniform vec4 silhouette_colour : source_color = vec4(0.055, 0.16, 0.22, 1.0);
uniform float occlusion_depth_bias : hint_range(0.0, 0.2) = 0.015;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view_position.z += occlusion_depth_bias;
	POSITION = PROJECTION_MATRIX * view_position;
}

void fragment() {
	ALBEDO = silhouette_colour.rgb;
	ALPHA = 1.0;
}
