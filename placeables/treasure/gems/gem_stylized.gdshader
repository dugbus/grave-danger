shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shadow_color : source_color = vec4(0.025, 0.12, 0.28, 1.0);
uniform vec4 body_color : source_color = vec4(0.05, 0.58, 0.92, 1.0);
uniform vec4 light_color : source_color = vec4(0.62, 0.96, 1.0, 1.0);
uniform vec4 glint_color : source_color = vec4(1.0, 0.96, 0.72, 1.0);
uniform float facet_contrast : hint_range(0.0, 2.0, 0.05) = 1.15;
uniform float rim_energy : hint_range(0.0, 3.0, 0.05) = 0.7;
uniform float glint_energy : hint_range(0.0, 5.0, 0.05) = 1.8;


void fragment() {
    vec3 facet_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
    if (dot(facet_normal, NORMAL) < 0.0) {
        facet_normal = -facet_normal;
    }
    vec3 view_direction = normalize(VIEW);
    vec3 key_direction = normalize(vec3(-0.45, 0.72, 0.53));
    vec3 glint_direction = normalize(vec3(0.35, 0.55, 0.76));

    float key_light = dot(facet_normal, key_direction) * 0.5 + 0.5;
    float facing = clamp(abs(dot(facet_normal, view_direction)), 0.0, 1.0);
    float rim = pow(1.0 - facing, 2.4);
    float facet_light = clamp((key_light - 0.5) * facet_contrast + 0.5, 0.0, 1.0);
    float glint = pow(max(dot(reflect(-view_direction, facet_normal), glint_direction), 0.0), 48.0);

    vec3 jewel_color = mix(shadow_color.rgb, body_color.rgb, smoothstep(0.08, 0.68, facet_light));
    jewel_color = mix(jewel_color, light_color.rgb, smoothstep(0.72, 1.0, facet_light) * 0.72);

    ALBEDO = jewel_color;
    METALLIC = 0.05;
    ROUGHNESS = 0.16;
    SPECULAR = 0.9;
    EMISSION = body_color.rgb * 0.08 + light_color.rgb * rim * rim_energy + glint_color.rgb * glint * glint_energy;
}
