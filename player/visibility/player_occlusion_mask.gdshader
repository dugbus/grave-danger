shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_default, cull_back, shadows_disabled;
stencil_mode write, compare_always, 37;

// Mark only the frontmost player pixels that survive the ordinary scene depth test. Hidden player
// surfaces fail depth and remain unmarked, while a small offset lets the authored visible surface
// win over its numerically identical mask pass.
uniform float visible_surface_bias : hint_range(0.0, 0.2) = 0.015;

void vertex() {
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view_position.z += visible_surface_bias;
	POSITION = PROJECTION_MATRIX * view_position;
}

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
