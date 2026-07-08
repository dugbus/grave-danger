shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warning_color : source_color = vec4(0.95, 0.02, 0.0, 1.0);

uniform float edge_start : hint_range(0.0, 1.0) = 0.16;
uniform float edge_end : hint_range(0.0, 1.0) = 0.50;

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.18;

uniform float distortion_strength : hint_range(0.0, 0.15) = 0.022;
uniform float chromatic_strength : hint_range(0.0, 0.04) = 0.018;
uniform float disruption_sharpness : hint_range(0.1, 3.0) = 1.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	value += noise(p) * amplitude;
	p *= 2.03;
	amplitude *= 0.5;

	value += noise(p) * amplitude;
	p *= 2.01;
	amplitude *= 0.5;

	value += noise(p) * amplitude;

	return value;
}

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);

	float edge_distance = length(centered_uv);
	float vignette = smoothstep(edge_start, edge_end, edge_distance);
	vignette = pow(vignette, disruption_sharpness);

	float pulse = 1.0 + sin(TIME * 4.5) * pulse_strength;
	float effect = clamp(vignette * intensity * pulse, 0.0, 1.0);

	vec2 from_center = normalize(centered_uv + vec2(0.0001));
	vec2 tangent = vec2(-from_center.y, from_center.x);

	float fine_noise = fbm(UV * 54.0 + vec2(TIME * 9.3, -TIME * 6.8)) * 2.0 - 1.0;
	float sharp_noise = noise(UV * 145.0 + vec2(-TIME * 18.0, TIME * 12.0)) * 2.0 - 1.0;
	float scanline_jitter = sin(UV.y * 420.0 + TIME * 58.0);
	float vertical_jitter = sin(UV.x * 360.0 - TIME * 43.0);

	float broken_bands = step(0.72, noise(vec2(floor(UV.y * 90.0), floor(TIME * 18.0))));

	vec2 distortion =
		tangent * fine_noise * 0.42 +
		from_center * sharp_noise * 0.28 +
		vec2(scanline_jitter, vertical_jitter) * 0.18 +
		vec2(sharp_noise, fine_noise) * broken_bands * 0.45;

	distortion *= distortion_strength * effect;

	vec2 distorted_uv = SCREEN_UV + distortion;

	float chroma = chromatic_strength * effect;

	float r = texture(screen_texture, distorted_uv + from_center * chroma).r;
	float g = texture(screen_texture, distorted_uv).g;
	float b = texture(screen_texture, distorted_uv - from_center * chroma).b;

	vec3 disrupted_screen = vec3(r, g, b);

	float blood_mix = clamp(effect * 0.72, 0.0, 0.72);
	vec3 final_color = mix(disrupted_screen, warning_color.rgb, blood_mix);

	COLOR = vec4(final_color, 1.0);
}
