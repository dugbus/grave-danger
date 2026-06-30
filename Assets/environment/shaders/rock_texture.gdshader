// rock_texture.gdshader
// Godot 4 – StandardMaterial3D replacement shader
// Produces a procedural rough rock surface with layered noise,
// ambient occlusion approximation, and subtle colour variation.
//
// Usage:
//   1. Select your MeshInstance3D in the scene.
//   2. In the Inspector, set Material → New ShaderMaterial.
//   3. Set Shader → Load → this file.
//   4. Tune the uniforms in the Inspector to taste.

shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// ── Appearance ──────────────────────────────────────────────────────────────
uniform vec3  rock_color_dark  : source_color = vec3(0.18, 0.15, 0.12);
uniform vec3  rock_color_light : source_color = vec3(0.55, 0.50, 0.44);
uniform vec3  moss_color       : source_color = vec3(0.20, 0.28, 0.14);
uniform float moss_amount      : hint_range(0.0, 1.0)  = 0.15;

// ── Surface ──────────────────────────────────────────────────────────────────
uniform float roughness_base   : hint_range(0.0, 1.0)  = 0.92;
uniform float metallic_value   : hint_range(0.0, 1.0)  = 0.0;
uniform float normal_strength  : hint_range(0.0, 4.0)  = 1.6;

// ── Noise ────────────────────────────────────────────────────────────────────
uniform float noise_scale      : hint_range(0.5, 20.0) = 6.0;   // overall tiling
uniform float detail_scale     : hint_range(1.0, 40.0) = 18.0;  // fine cracks
uniform int   octaves          : hint_range(1, 8)       = 6;     // fbm depth


// ────────────────────────────────────────────────────────────────────────────
//  Utility: hash & noise
// ────────────────────────────────────────────────────────────────────────────

vec3 hash3(vec3 p) {
    p = vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    );
    return fract(sin(p) * 43758.5453123);
}

// Smooth value noise in 3-D
float vnoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);   // smoothstep

    float n000 = dot(hash3(i + vec3(0,0,0)) * 2.0 - 1.0, f - vec3(0,0,0));
    float n100 = dot(hash3(i + vec3(1,0,0)) * 2.0 - 1.0, f - vec3(1,0,0));
    float n010 = dot(hash3(i + vec3(0,1,0)) * 2.0 - 1.0, f - vec3(0,1,0));
    float n110 = dot(hash3(i + vec3(1,1,0)) * 2.0 - 1.0, f - vec3(1,1,0));
    float n001 = dot(hash3(i + vec3(0,0,1)) * 2.0 - 1.0, f - vec3(0,0,1));
    float n101 = dot(hash3(i + vec3(1,0,1)) * 2.0 - 1.0, f - vec3(1,0,1));
    float n011 = dot(hash3(i + vec3(0,1,1)) * 2.0 - 1.0, f - vec3(0,1,1));
    float n111 = dot(hash3(i + vec3(1,1,1)) * 2.0 - 1.0, f - vec3(1,1,1));

    return mix(
        mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
        mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y),
        u.z
    ) * 0.5 + 0.5;
}

// Fractional Brownian Motion – sums octaves for large-scale rock shapes
float fbm(vec3 p, int oct) {
    float value     = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float total_amp = 0.0;

    for (int i = 0; i < oct; i++) {
        value     += vnoise(p * frequency) * amplitude;
        total_amp += amplitude;
        amplitude *= 0.5;
        frequency *= 2.13;   // slightly irrational → avoids axis-aligned bands
        // Rotate slightly each octave to break up grid artefacts
        p = vec3(p.y, p.z, p.x);
    }
    return value / total_amp;
}

// Domain-warped fbm – creates the irregular, chunky look of rock strata
float rock_fbm(vec3 p, int oct) {
    // First warp pass
    vec3 warp = vec3(
        fbm(p + vec3(1.7, 9.2, 3.4), 3),
        fbm(p + vec3(8.3, 2.8, 5.1), 3),
        fbm(p + vec3(4.1, 6.7, 1.9), 3)
    );
    // Second warp pass (adds depth)
    vec3 warp2 = vec3(
        fbm(p + 4.0 * warp + vec3(3.3, 2.5, 1.0), 3),
        fbm(p + 4.0 * warp + vec3(1.8, 8.2, 7.3), 3),
        fbm(p + 4.0 * warp + vec3(5.2, 3.9, 2.7), 3)
    );
    return fbm(p + 4.0 * warp2, oct);
}

// ────────────────────────────────────────────────────────────────────────────
//  Normal reconstruction from noise gradient (bump mapping)
// ────────────────────────────────────────────────────────────────────────────
vec3 noise_normal(vec3 world_pos, float scale, float strength) {
    float eps = 0.02;
    float base = rock_fbm(world_pos * scale, octaves);
    float dx   = rock_fbm((world_pos + vec3(eps, 0.0, 0.0)) * scale, octaves) - base;
    float dy   = rock_fbm((world_pos + vec3(0.0, eps, 0.0)) * scale, octaves) - base;
    float dz   = rock_fbm((world_pos + vec3(0.0, 0.0, eps)) * scale, octaves) - base;
    return normalize(vec3(-dx, -dy, dz) * strength / eps + vec3(0.0, 0.0, 1.0));
}


// ────────────────────────────────────────────────────────────────────────────
//  Vertex – pass world-space position to fragment
// ────────────────────────────────────────────────────────────────────────────
varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
    v_world_pos    = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


// ────────────────────────────────────────────────────────────────────────────
//  Fragment
// ────────────────────────────────────────────────────────────────────────────
void fragment() {
    vec3  wp    = v_world_pos;

    // ── Large-scale rock structure ──────────────────────────────────────
    float large = rock_fbm(wp * noise_scale, octaves);

    // ── Fine surface detail / micro-cracks ──────────────────────────────
    float detail = fbm(wp * detail_scale, 4);

    // ── Combined height field ────────────────────────────────────────────
    float h = large * 0.75 + detail * 0.25;

    // ── Base colour blend (dark crevices → light peaks) ─────────────────
    vec3 base_col = mix(rock_color_dark, rock_color_light, smoothstep(0.2, 0.8, h));

    // ── Tiny colour variation via a high-frequency noise layer ──────────
    float tint = vnoise(wp * detail_scale * 2.5);
    base_col   = mix(base_col, base_col * vec3(1.1, 1.05, 0.95), (tint - 0.5) * 0.3);

    // ── Moss in crevices (low-height areas, upward-facing normals) ───────
    float facing_up  = clamp(dot(v_world_normal, vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
    float moss_mask  = smoothstep(0.55, 0.45, h) * facing_up;
    vec3  final_col  = mix(base_col, moss_color, moss_mask * moss_amount);

    // ── Ambient-occlusion approximation (darken deep crevices) ──────────
    float ao = clamp(h * 1.3, 0.0, 1.0);
    final_col *= mix(0.55, 1.0, ao);

    // ── Procedural normal (bump) ─────────────────────────────────────────
    // Blend large-scale and detail normals
    vec3 n_large  = noise_normal(wp, noise_scale,  normal_strength);
    vec3 n_detail = noise_normal(wp, detail_scale, normal_strength * 0.4);
    vec3 n_blend  = normalize(n_large + n_detail);
    // Transform into tangent-space expected by Godot
    NORMAL_MAP        = n_blend * 0.5 + 0.5;
    NORMAL_MAP_DEPTH  = 1.0;

    // ── Surface outputs ──────────────────────────────────────────────────
    ALBEDO    = final_col;
    ROUGHNESS = clamp(roughness_base - detail * 0.12, 0.6, 1.0);
    METALLIC  = metallic_value;
    AO        = ao;
    AO_LIGHT_AFFECT = 0.6;
}
