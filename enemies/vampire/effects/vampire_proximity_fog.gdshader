shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.46, 0.08, 0.72, 1.0);
uniform float drift_speed : hint_range(0.0, 2.0) = 0.32;
uniform float distortion_strength : hint_range(0.0, 0.04) = 0.009;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 fraction = fract(point);
	vec2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
	float bottom = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), blend.x);
	float top = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), blend.x);
	return mix(bottom, top, blend.y);
}

float fog_noise(vec2 point) {
	float value = noise(point) * 0.58;
	value += noise(point * 2.07 + 13.4) * 0.28;
	value += noise(point * 4.13 - 7.2) * 0.14;
	return value;
}

void fragment() {
	vec2 drift = vec2(TIME * drift_speed, -TIME * drift_speed * 0.61);
	float broad_fog = fog_noise(UV * vec2(4.2, 3.1) + drift);
	float curling_fog = fog_noise(UV * vec2(8.5, 6.0) - drift * 1.7);
	float fog_shape = smoothstep(0.34, 0.82, broad_fog * 0.7 + curling_fog * 0.45);

	vec2 centered = UV - vec2(0.5);
	float edge_fog = smoothstep(0.18, 0.72, length(centered));
	float fog_amount = clamp(intensity * (0.18 + fog_shape * 0.62 + edge_fog * 0.35), 0.0, 0.88);

	vec2 distortion = vec2(
		fog_noise(UV * 11.0 + drift * 2.4) - 0.5,
		fog_noise(UV.yx * 10.0 - drift * 2.1) - 0.5
	) * distortion_strength * intensity;
	vec3 screen_color = texture(screen_texture, SCREEN_UV + distortion).rgb;
	vec3 purple_screen = mix(screen_color, screen_color * fog_color.rgb, 0.38 * intensity);
	vec3 final_color = mix(purple_screen, fog_color.rgb, fog_amount * 0.58);
	COLOR = vec4(final_color, 1.0);
}
