shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.72);

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float distance_from_center = length(centered_uv);
	float shadow_alpha = (1.0 - smoothstep(0.2, 1.0, distance_from_center)) * shadow_color.a;

	ALBEDO = shadow_color.rgb;
	ALPHA = shadow_alpha;
}
