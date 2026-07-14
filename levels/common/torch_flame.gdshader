shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.52, 1.0);
uniform vec4 body_color : source_color = vec4(1.0, 0.28, 0.015, 1.0);
uniform vec4 tip_color : source_color = vec4(0.72, 0.025, 0.002, 1.0);
uniform float emission_strength : hint_range(0.0, 8.0, 0.1) = 3.5;
uniform float movement_speed : hint_range(0.0, 12.0, 0.1) = 5.5;


float random_value(vec2 position) {
	return fract(sin(dot(position, vec2(127.1, 311.7))) * 43758.5453);
}


float smooth_noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 fraction = fract(position);
	fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	float bottom = mix(random_value(cell), random_value(cell + vec2(1.0, 0.0)), fraction.x);
	float top = mix(
		random_value(cell + vec2(0.0, 1.0)),
		random_value(cell + vec2(1.0, 1.0)),
		fraction.x
	);
	return mix(bottom, top, fraction.y);
}


void vertex() {
	vec3 particle_scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	mat4 billboard_model = mat4(
		vec4(INV_VIEW_MATRIX[0].xyz * particle_scale.x, 0.0),
		vec4(INV_VIEW_MATRIX[1].xyz * particle_scale.y, 0.0),
		vec4(INV_VIEW_MATRIX[2].xyz * particle_scale.z, 0.0),
		MODEL_MATRIX[3]
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_model;
}


void fragment() {
	float height = 1.0 - UV.y;
	float animated_noise = smooth_noise(vec2(UV.x * 5.0, height * 7.0 - TIME * movement_speed));
	float sway = sin(height * 9.0 + TIME * movement_speed * 1.7) * 0.045;
	sway += (animated_noise - 0.5) * 0.13 * (0.25 + height);

	float half_width = mix(0.43, 0.035, pow(height, 0.72));
	float distance_from_center = abs(UV.x - 0.5 - sway);
	float soft_edge = 1.0 - smoothstep(half_width * 0.62, half_width, distance_from_center);
	float base_fade = smoothstep(0.0, 0.1, height);
	float tip_fade = 1.0 - smoothstep(0.78, 1.0, height);
	float breakup = smoothstep(0.08, 0.42, animated_noise + (1.0 - height) * 0.28);
	float alpha = soft_edge * base_fade * tip_fade * mix(0.62, 1.0, breakup);

	vec4 flame_color = mix(core_color, body_color, smoothstep(0.08, 0.58, height));
	flame_color = mix(flame_color, tip_color, smoothstep(0.58, 0.94, height));
	float hot_core = 1.0 - smoothstep(0.0, max(half_width * 0.5, 0.001), distance_from_center);
	flame_color = mix(flame_color, core_color, hot_core * (1.0 - height) * 0.8);

	ALBEDO = flame_color.rgb;
	EMISSION = flame_color.rgb * emission_strength;
	ALPHA = flame_color.a * alpha;
}
