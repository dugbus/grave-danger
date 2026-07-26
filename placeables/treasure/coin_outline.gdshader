shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, blend_add, fog_disabled;

uniform vec4 outline_color : source_color = vec4(1.0, 0.72, 0.12, 0.45);
uniform float outline_emission : hint_range(0.0, 4.0, 0.1) = 3.0;
uniform float outline_width : hint_range(0.0, 0.04, 0.001) = 0.012;


void vertex() {
	VERTEX += NORMAL * outline_width;
}


void fragment() {
	ALBEDO = outline_color.rgb;
	EMISSION = outline_color.rgb * outline_emission;
	ALPHA = outline_color.a;
}
