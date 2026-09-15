shader_type spatial;

uniform sampler2D tiled_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 floor_tile_size = vec2(8.0, 8.0);

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 safe_tile_size = max(floor_tile_size, vec2(0.001));
	vec2 tiled_uv = world_position.xz / safe_tile_size;
	ALBEDO = texture(tiled_texture, tiled_uv).rgb;
}
