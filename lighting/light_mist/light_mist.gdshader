shader_type fog;

uniform float density = 0.004;
uniform vec4 scattering_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform float noise_scale = 0.32;
uniform float noise_strength = 0.28;
uniform vec3 drift_velocity = vec3(0.018, 0.006, 0.012);
uniform float visual_time = 0.0;

float mist_hash(vec3 point) {
	point = fract(point * 0.1031);
	point += dot(point, point.yzx + 33.33);
	return fract((point.x + point.y) * point.z);
}

float mist_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	return mix(
		mix(mix(mist_hash(cell), mist_hash(cell + vec3(1.0, 0.0, 0.0)), blend.x),
			mix(mist_hash(cell + vec3(0.0, 1.0, 0.0)), mist_hash(cell + vec3(1.0, 1.0, 0.0)), blend.x), blend.y),
		mix(mix(mist_hash(cell + vec3(0.0, 0.0, 1.0)), mist_hash(cell + vec3(1.0, 0.0, 1.0)), blend.x),
			mix(mist_hash(cell + vec3(0.0, 1.0, 1.0)), mist_hash(cell + vec3(1.0)), blend.x), blend.y), blend.z);
}

void fog() {
	// A continuous field in all three world axes avoids screen-space bands or a flat moving sheet.
	vec3 position = (WORLD_POSITION - drift_velocity * visual_time) * noise_scale;
	float noise = mist_noise(position) * 0.65 + mist_noise(position * 2.03 + vec3(17.1, 9.2, 13.7)) * 0.35;
	DENSITY = density * mix(1.0 - noise_strength, 1.0 + noise_strength, noise);
	ALBEDO = scattering_color.rgb;
	// No emission: existing lights alone reveal the mist, leaving unlit air dark.
}
