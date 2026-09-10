shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_inverted, cull_back, shadows_disabled;
stencil_mode read, compare_not_equal, 37;

// Expanded front faces supply a bright edge only where ordinary depth hides the player. Using the
// rear hull here would incorrectly pass the player's own depth test while the character is visible.
uniform vec4 outline_colour : source_color = vec4(1.0, 0.78, 0.15, 1.0);
uniform float outline_width : hint_range(0.005, 0.15) = 0.035;
uniform float occlusion_depth_bias : hint_range(0.0, 0.2) = 0.015;

void vertex() {
	VERTEX += NORMAL * outline_width;
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view_position.z += occlusion_depth_bias;
	POSITION = PROJECTION_MATRIX * view_position;
}

void fragment() {
	ALBEDO = outline_colour.rgb;
	ALPHA = 1.0;
}
