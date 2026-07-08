shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 warning_color : source_color = vec4(0.95, 0.02, 0.0, 1.0);
uniform float edge_start : hint_range(0.0, 1.0) = 0.24;
uniform float edge_end : hint_range(0.0, 1.0) = 0.82;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.18;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float drift = sin(TIME * 0.9) * 0.018;
	centered_uv += vec2(drift, cos(TIME * 0.7) * 0.012);

	float edge_distance = length(centered_uv * vec2(1.0, 0.72));
	float vignette = smoothstep(edge_start, edge_end, edge_distance);
	float pulse = 1.0 + sin(TIME * 4.5) * pulse_strength;
	float alpha = clamp(vignette * intensity * pulse, 0.0, 0.72);

	COLOR = vec4(warning_color.rgb, alpha);
}
