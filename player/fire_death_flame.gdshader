shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec3 core_color : source_color = vec3(1.0, 0.92, 0.28);
uniform vec3 edge_color : source_color = vec3(1.0, 0.08, 0.005);
uniform float emission_strength = 2.8;

void vertex() {
	vec4 particle_position = MODELVIEW_MATRIX[3];
	float particle_scale_x = length(MODELVIEW_MATRIX[0].xyz);
	float particle_scale_y = length(MODELVIEW_MATRIX[1].xyz);
	float particle_scale_z = length(MODELVIEW_MATRIX[2].xyz);
	MODELVIEW_MATRIX = mat4(
		vec4(particle_scale_x, 0.0, 0.0, 0.0),
		vec4(0.0, particle_scale_y, 0.0, 0.0),
		vec4(0.0, 0.0, particle_scale_z, 0.0),
		particle_position
	);
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float height_ratio = 1.0 - UV.y;
	float flame_width = mix(0.16, 0.92, height_ratio);
	float side_distance = abs(centered_uv.x) / flame_width;
	float base_mask = smoothstep(1.0, 0.58, side_distance);
	float tip_mask = smoothstep(0.0, 0.18, UV.y) * smoothstep(1.0, 0.38, UV.y);
	float flicker = 0.82 + 0.18 * sin(TIME * 19.0 + UV.y * 15.0 + centered_uv.x * 7.0);
	float alpha = base_mask * tip_mask * flicker;
	vec3 flame_color = mix(edge_color, core_color, pow(height_ratio, 1.8));
	ALBEDO = flame_color;
	EMISSION = flame_color * emission_strength;
	ALPHA = alpha;
}
