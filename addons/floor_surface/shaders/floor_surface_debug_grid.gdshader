shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 tile_colour_a : source_color = vec4(0.16, 0.42, 0.48, 1.0);
uniform vec4 tile_colour_b : source_color = vec4(0.24, 0.58, 0.50, 1.0);
uniform vec4 grid_colour : source_color = vec4(0.75, 1.0, 0.65, 1.0);
uniform float grid_width : hint_range(0.005, 0.15, 0.005) = 0.025;

void fragment() {
	vec2 grid_position = fract(UV);
	vec2 edge_distance = min(grid_position, vec2(1.0) - grid_position);
	float grid = 1.0 - step(grid_width, min(edge_distance.x, edge_distance.y));
	float checker = mod(floor(UV.x) + floor(UV.y), 2.0);
	vec3 tile_colour = mix(tile_colour_a.rgb, tile_colour_b.rgb, checker);
	ALBEDO = mix(tile_colour, grid_colour.rgb, grid);
	ROUGHNESS = 0.9;
}
