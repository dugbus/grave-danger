shader_type spatial;

uniform sampler2D tiled_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(8.0, 87.0); // Adjust tile amount here
uniform float fade_margin : hint_range(0.0, 0.5) = 0.2; // How wide the black fade is

void fragment() {
    // 1. Calculate the tiled texture color
    vec3 tex_color = texture(tiled_texture, UV * uv_scale).rgb;
    
    // 2. Calculate distance to the closest edge (0.0 at edge, 0.5 at center)
    vec2 edge_dist = min(UV, vec2(1.0) - UV);
    float closest_edge = min(edge_dist.x, edge_dist.y);
    
    // 3. Create a smooth gradient fade factor
    float fade = smoothstep(0.0, fade_margin, closest_edge);
    
    // 4. Mix texture with black based on the fade factor
    ALBEDO = mix(vec3(0.0), tex_color, fade);
}
