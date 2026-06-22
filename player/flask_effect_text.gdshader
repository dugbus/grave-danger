shader_type spatial;
render_mode blend_mix, depth_test_disabled, depth_draw_never, diffuse_lambert, specular_schlick_ggx;

uniform vec4 text_color : source_color = vec4(1.0, 0.94, 0.78, 1.0);
uniform float ambient_strength = 0.38;
uniform float side_shadow = 0.68;
uniform float roughness = 0.94;

varying vec3 local_normal;

void vertex() {
	local_normal = NORMAL;
}

void fragment() {
	float front_light = smoothstep(0.15, 0.92, abs(normalize(local_normal).z));
	float depth_shade = mix(side_shadow, 1.0, front_light);

	float surface_noise = fract(sin(dot(UV * 64.0, vec2(12.9898, 78.233))) * 43758.5453);
	float texture_shade = mix(0.92, 1.06, surface_noise);
	ALBEDO = text_color.rgb * depth_shade * texture_shade;
	ALPHA = text_color.a;
	EMISSION = text_color.rgb * ambient_strength * depth_shade;
	ROUGHNESS = roughness;
}
