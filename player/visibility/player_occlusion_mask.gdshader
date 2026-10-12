shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_default, cull_back, shadows_disabled;
stencil_mode write, compare_always, 37;

// Cover the outline's full hull around visible player surfaces. Moving this expanded mask towards
// the camera by its expansion prevents the player's own depth from hiding bits of the hull and
// leaking yellow at exposed edges. Scenery farther in front still rejects the mask normally.
uniform float visible_surface_bias : hint_range(0.0, 0.2) = 0.015;
uniform float outline_width : hint_range(0.005, 0.15) = 0.035;

void vertex() {
	VERTEX += NORMAL * outline_width;
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view_position.z += visible_surface_bias + outline_width;
	POSITION = PROJECTION_MATRIX * view_position;
}

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
