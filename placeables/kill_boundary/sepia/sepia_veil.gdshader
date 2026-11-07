shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform float boundary_time = 0.0;
uniform float morph_speed = 0.4;
uniform float noise_scale = 1.8;
uniform float opacity = 0.35;
uniform float brightness = 1.25;
uniform vec4 veil_color : source_color = vec4(0.92, 0.68, 0.32, 1.0);

uniform float veil_height = 1.6;
uniform float player_feet_height = 0.0;
uniform bool follow_player_height = false;

varying vec3 veil_world;
varying float veil_base_y;

float veil_hash(vec3 point) {
	point = fract(point * 0.1031);
	point += dot(point, point.yzx + 33.33);
	return fract((point.x + point.y) * point.z);
}

float veil_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 fraction = fract(point);
	fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	return mix(
		mix(mix(veil_hash(cell), veil_hash(cell + vec3(1.0, 0.0, 0.0)), fraction.x),
			mix(veil_hash(cell + vec3(0.0, 1.0, 0.0)), veil_hash(cell + vec3(1.0, 1.0, 0.0)), fraction.x), fraction.y),
		mix(mix(veil_hash(cell + vec3(0.0, 0.0, 1.0)), veil_hash(cell + vec3(1.0, 0.0, 1.0)), fraction.x),
			mix(veil_hash(cell + vec3(0.0, 1.0, 1.0)), veil_hash(cell + vec3(1.0)), fraction.x), fraction.y), fraction.z);
}

float veil_fbm(vec3 point) {
	float result = 0.0;
	float weight = 0.57;
	for (int octave = 0; octave < 3; octave++) {
		result += veil_noise(point) * weight;
		point = point * 2.03 + vec3(17.1, 9.2, 13.7);
		weight *= 0.46;
	}
	return result;
}

void vertex() {
	veil_base_y = VERTEX.y - UV.y * veil_height;
	if (follow_player_height) {
		float lower = min(veil_base_y, player_feet_height);
		float upper = max(veil_base_y + veil_height, player_feet_height + veil_height);
		VERTEX.y = mix(lower, upper, UV.y);
	}
	veil_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float time = boundary_time * morph_speed;
	// World-space height keeps the opacity band beside the player on platforms and in midair.
	float band_base = follow_player_height ? player_feet_height : veil_base_y;
	float height = (veil_world.y - band_base) / veil_height;
	// Sampling in world space joins neighbouring segments without a visible texture seam.
	vec3 field = vec3(veil_world.x * noise_scale, height * 2.8 - time * 0.55, veil_world.z * noise_scale);
	float warp = veil_fbm(field * 0.61 + vec3(time * 0.19, 0.0, -time * 0.13));
	float mist = veil_fbm(field + vec3(warp * 1.4, -warp * 0.8, time * 0.23));
	float filaments = pow(clamp(1.0 - abs(sin((mist * 2.4 + height * 0.9 - time * 0.15) * 8.0)), 0.0, 1.0), 4.0);
	float top_fade = 1.0 - smoothstep(0.52 + mist * 0.18, 1.0, height);
	float bottom_fade = smoothstep(0.0, 0.025, height);
	float ribbon = exp(-pow((height - 0.035) / 0.024, 2.0));
	float body = (0.15 + mist * 0.30 + filaments * 0.26) * top_fade * bottom_fade;
	vec3 parchment = mix(veil_color.rgb * 0.45, vec3(1.0, 0.9, 0.65), filaments * 0.68 + ribbon * 0.32);
	ALBEDO = parchment * brightness * (0.8 + filaments * 0.6 + ribbon * 0.9);
	ALPHA = clamp((body + ribbon * 0.68) * opacity, 0.0, 0.82);
}
