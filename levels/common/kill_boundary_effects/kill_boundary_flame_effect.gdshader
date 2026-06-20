shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, fog_disabled;

uniform sampler3D sample_noise : repeat_enable, filter_linear_mipmap;
uniform int raymarch_steps : hint_range(4, 12) = 6;
uniform float time_scale : hint_range(0.0, 2.0) = 0.72;
uniform float density_multiplier : hint_range(0.1, 8.0) = 3.1;
uniform float opacity_multiplier : hint_range(0.0, 1.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 20.0) = 7.0;
uniform float broad_noise_scale : hint_range(0.02, 1.0) = 0.18;
uniform float detail_noise_scale : hint_range(0.05, 2.0) = 0.48;
uniform vec3 color_core : source_color = vec3(1.0, 0.92, 0.42);
uniform vec3 color_mid : source_color = vec3(1.0, 0.28, 0.015);
uniform vec3 color_outer : source_color = vec3(0.48, 0.008, 0.001);

instance uniform vec3 fire_size = vec3(8.0, 1.15, 0.7);
instance uniform float segment_half_length = 4.0;
instance uniform float noise_along_offset = 4.0;

varying vec3 local_vertex;


float hash(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453);
}


vec2 intersect_box(vec3 ray_origin, vec3 ray_direction, vec3 half_size) {
	vec3 safe_direction = sign(ray_direction + vec3(0.000001)) * max(abs(ray_direction), vec3(0.0001));
	vec3 inverse_direction = 1.0 / safe_direction;
	vec3 t0 = (-half_size - ray_origin) * inverse_direction;
	vec3 t1 = (half_size - ray_origin) * inverse_direction;
	vec3 near_values = min(t0, t1);
	vec3 far_values = max(t0, t1);
	float near_distance = max(near_values.x, max(near_values.y, near_values.z));
	float far_distance = min(far_values.x, min(far_values.y, far_values.z));
	return vec2(near_distance, far_distance);
}


float fire_density(vec3 local_position) {
	vec3 half_size = fire_size * 0.5;
	vec3 normalized_position = local_position / fire_size + vec3(0.5);
	float height = clamp(normalized_position.y, 0.0, 1.0);
	float endpoint_distance = max(abs(local_position.x) - segment_half_length, 0.0);
	float segment_distance = length(vec2(endpoint_distance, local_position.z));
	float segment_mask = 1.0 - smoothstep(half_size.z * 0.55, half_size.z, segment_distance);
	float perimeter_position = local_position.x + noise_along_offset;

	float animated_time = TIME * time_scale;
	vec3 fire_coordinates = vec3(perimeter_position, local_position.y, local_position.z);
	vec3 broad_coordinates = fire_coordinates * broad_noise_scale;
	broad_coordinates.y -= animated_time * 0.34;
	float broad_noise = texture(sample_noise, fract(broad_coordinates)).r;

	vec3 detail_coordinates = fire_coordinates * detail_noise_scale;
	detail_coordinates.y -= animated_time * 0.68;
	detail_coordinates.z += broad_noise * 0.24;
	float detail_noise = texture(sample_noise, fract(detail_coordinates)).r;
	float turbulence = mix(broad_noise, detail_noise, 0.48);

	float tongue_height = 0.48 + broad_noise * 0.58 + (detail_noise - 0.5) * 0.16;
	float vertical_shape = 1.0 - smoothstep(tongue_height - 0.12, tongue_height + 0.08, height);
	float breakup_threshold = mix(0.24, 0.61, pow(height, 0.72));
	float broken_flame = smoothstep(breakup_threshold, breakup_threshold + 0.2, turbulence);

	float bottom_fade = smoothstep(0.025, 0.2, height);
	bottom_fade *= bottom_fade;
	float shaped_flame = broken_flame * vertical_shape;
	return shaped_flame * bottom_fade * segment_mask;
}


void vertex() {
	local_vertex = VERTEX;
}


void fragment() {
	vec3 ray_origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 ray_direction = normalize(local_vertex - ray_origin);
	vec2 hit = intersect_box(ray_origin, ray_direction, fire_size * 0.5);

	if (hit.x >= hit.y || hit.y <= 0.0) {
		discard;
	}

	float march_start = max(hit.x, 0.0);
	float march_length = hit.y - march_start;
	float step_length = march_length / float(raymarch_steps);
	float jitter = hash(FRAGCOORD.xy + vec2(noise_along_offset * 91.7)) * step_length;
	float distance_along_ray = march_start + jitter;
	vec3 accumulated_color = vec3(0.0);
	float accumulated_alpha = 0.0;

	for (int step = 0; step < 12; step++) {
		if (step >= raymarch_steps || distance_along_ray >= hit.y || accumulated_alpha > 0.985) {
			break;
		}

		vec3 sample_position = ray_origin + ray_direction * distance_along_ray;
		float density = fire_density(sample_position);
		float height = clamp(sample_position.y / fire_size.y + 0.5, 0.0, 1.0);
		float sample_alpha = 1.0 - exp(-density * density_multiplier * step_length);

		vec3 sample_color = mix(color_outer, color_mid, smoothstep(0.02, 0.42, density));
		float core = smoothstep(0.38, 0.82, density) * (1.0 - smoothstep(0.25, 0.86, height));
		sample_color = mix(sample_color, color_core, core);

		accumulated_color += sample_color * sample_alpha * (1.0 - accumulated_alpha);
		accumulated_alpha += sample_alpha * (1.0 - accumulated_alpha);
		distance_along_ray += step_length;
	}

	if (accumulated_alpha < 0.01) {
		discard;
	}

	ALBEDO = accumulated_color / max(accumulated_alpha, 0.001);
	EMISSION = ALBEDO * emission_strength;
	ALPHA = accumulated_alpha * opacity_multiplier;
}
