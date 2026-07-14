shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_add;

uniform vec4 outline_color : source_color = vec4(1.0, 0.46, 0.12, 0.5);
uniform float outline_intensity : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float rim_power : hint_range(1.0, 8.0, 0.1) = 3.2;


void fragment() {
	float facing_ratio = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing_ratio, rim_power);
	ALBEDO = outline_color.rgb;
	EMISSION = outline_color.rgb * (1.8 * outline_intensity * rim);
	ALPHA = outline_color.a * outline_intensity * rim;
}
