shader_type spatial;

uniform sampler2D tiled_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float level_width = 20.0;
uniform float level_height = 20.0;
uniform vec2 floor_overscan = vec2(2.0, 2.0);
uniform vec2 floor_tile_size = vec2(8.0, 8.0);
uniform float fade_margin : hint_range(0.0, 8.0) = 0.2;

void fragment() {
    vec2 level_size = max(vec2(level_width, level_height), vec2(0.001));
    vec2 floor_size = level_size + floor_overscan * 2.0;
    vec2 level_uv = (UV * floor_size - floor_overscan) / level_size;
    vec2 tile_count = level_size / max(floor_tile_size, vec2(0.001));
    vec3 tex_color = texture(tiled_texture, level_uv * tile_count).rgb;

    vec2 edge_dist = min(UV, vec2(1.0) - UV) * floor_size;
    float closest_edge = min(edge_dist.x, edge_dist.y);
    float fade = smoothstep(0.0, fade_margin, closest_edge);

    ALBEDO = mix(vec3(0.0), tex_color, fade);
}
