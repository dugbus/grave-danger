shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_default, cull_back, shadows_disabled;
stencil_mode write, compare_always, 37;

// Mark visible enemy pixels before the player's silhouette passes. The ordinary depth buffer
// rejects this pass when the player is in front, preserving normal character overlap in both orders.
void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
