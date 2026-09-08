shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

// Optional editor-only guide. FloorSurface supplies continuous world-scaled UVs.

uniform vec4 tile_colour_a : source_color = vec4(0.10, 0.14, 0.16, 0.04);
uniform vec4 tile_colour_b : source_color = vec4(0.22, 0.26, 0.28, 0.09);
uniform vec4 grid_colour : source_color = vec4(0.48, 0.54, 0.56, 0.24);
uniform float grid_width : hint_range(0.005, 0.15, 0.005) = 0.018;

void fragment() {
	vec2 grid_position = fract(UV);
	vec2 edge_distance = min(grid_position, vec2(1.0) - grid_position);
	float grid = 1.0 - step(grid_width, min(edge_distance.x, edge_distance.y));
	float checker = mod(floor(UV.x) + floor(UV.y), 2.0);
	vec4 tile_colour = mix(tile_colour_a, tile_colour_b, checker);
	vec4 overlay_colour = mix(tile_colour, grid_colour, grid);
	ALBEDO = overlay_colour.rgb;
	ALPHA = overlay_colour.a;
	ROUGHNESS = 0.9;
}
