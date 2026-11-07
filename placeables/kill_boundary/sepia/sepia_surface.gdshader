shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform float roughness_value = 1.0;
uniform float metallic_value = 0.0;
uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool use_normal_texture = false;
uniform float normal_scale = 1.0;
uniform vec4 emission_color : source_color = vec4(0.0);
uniform sampler2D texture_emission : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_emission_texture = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform bool use_alpha = false;
uniform float alpha_scissor = 0.0;

void fragment() {
	vec2 uv = UV * uv_scale.xy + uv_offset.xy;
	vec4 color = albedo;
	if (use_albedo_texture) { color *= texture(texture_albedo, uv); }
	if (use_vertex_color) { color *= COLOR; }
	ALBEDO = color.rgb;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	if (use_normal_texture) { NORMAL_MAP = texture(texture_normal, uv).rgb; NORMAL_MAP_DEPTH = normal_scale; }
	EMISSION = emission_color.rgb;
	if (use_emission_texture) { EMISSION *= texture(texture_emission, uv).rgb; }
	if (use_alpha) { ALPHA = color.a; }
	if (alpha_scissor > 0.0) { ALPHA_SCISSOR_THRESHOLD = alpha_scissor; ALPHA = color.a; }
}
