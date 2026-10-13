shader_type spatial;

render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

// Both artist-authored textures contribute to every flame, with a per-particle phase.
uniform sampler2D fire_texture_a : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D fire_texture_b : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 core_color : source_color = vec3(1.0, 0.86, 0.28);
uniform vec3 middle_color : source_color = vec3(1.0, 0.27, 0.018);
uniform vec3 edge_color : source_color = vec3(0.55, 0.045, 0.008);
uniform float emission_strength = 1.15;
uniform float animation_speed = 1.0;
uniform float turbulence = 0.045;
uniform float sway_amount = 0.045;

varying float particle_age;
varying float particle_phase;

void vertex() {
    // Particle age separates ignition, a bright burning body, and a cooling tip.
    particle_age = INSTANCE_CUSTOM.y;
    particle_phase = INSTANCE_CUSTOM.x;
    float tip_weight = 1.0 - UV.y;
    VERTEX.x += sin(TIME * 4.0 * animation_speed + particle_phase + UV.y * 4.0)
        * sway_amount * tip_weight * tip_weight;

    // Face the camera while preserving the emitter's authored particle scale.
    vec4 particle_position = MODELVIEW_MATRIX[3];
    MODELVIEW_MATRIX = mat4(
        vec4(length(MODELVIEW_MATRIX[0].xyz), 0.0, 0.0, 0.0),
        vec4(0.0, length(MODELVIEW_MATRIX[1].xyz), 0.0, 0.0),
        vec4(0.0, 0.0, length(MODELVIEW_MATRIX[2].xyz), 0.0),
        particle_position
    );
}

void fragment() {
    float height = 1.0 - UV.y;
    vec2 sample_uv = UV;
    sample_uv.x += sin(UV.y * 8.0 - TIME * 3.0 * animation_speed + particle_phase)
        * turbulence * sin(UV.y * 3.14159);
    vec4 first = texture(fire_texture_a, sample_uv);
    vec4 second = texture(fire_texture_b, vec2(1.0 - sample_uv.x, sample_uv.y));
    float blend = 0.5 + 0.5 * sin(particle_phase + particle_age * 3.0);
    vec4 detail = mix(first, second, blend);
    // Luminance also masks packs that contain black rather than transparent borders.
    float density = max(detail.r, max(detail.g, detail.b));
    float heat = clamp(density * 0.85 + (1.0 - height) * 0.25 - particle_age * 0.3, 0.0, 1.0);
    vec3 flame_color = mix(edge_color, middle_color, smoothstep(0.05, 0.55, heat));
    flame_color = mix(flame_color, core_color, smoothstep(0.58, 0.95, heat));
    float life_fade = smoothstep(0.0, 0.12, particle_age)
        * (1.0 - smoothstep(0.45, 1.0, particle_age));
    ALBEDO = flame_color;
    EMISSION = flame_color * emission_strength * density;
    ALPHA = detail.a * smoothstep(0.03, 0.7, density) * life_fade * 0.48;
}
