shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform sampler2D ghost_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 ghost_color : source_color = vec3(0.58, 0.9, 1.0);
uniform float emission_strength : hint_range(0.0, 20.0) = 6.2;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.28;

instance uniform float ghost_width = 0.48;
instance uniform float ghost_height = 2.75;
instance uniform float rise_distance = 1.2;
instance uniform float emerge_depth = 2.2;
instance uniform float rise_speed = 0.13;
instance uniform float cycle_offset = 0.0;
instance uniform float wave_phase = 0.0;
instance uniform float wave_amplitude = 0.22;
instance uniform float wave_frequency = 6.0;
instance uniform float wave_speed = 1.35;
instance uniform float lean = 0.0;
instance uniform float opacity = 0.72;

varying float life_fade;
varying float height_progress;


void vertex() {
	height_progress = UV.y;
	float age = fract(TIME * rise_speed + cycle_offset);
	float side = VERTEX.x;
	float taper = mix(1.0, 0.55, smoothstep(0.7, 1.0, height_progress));
	float height_wave_fade = smoothstep(0.04, 0.35, height_progress) * (1.0 - smoothstep(0.78, 1.0, height_progress));
	float sway = sin(height_progress * wave_frequency + TIME * wave_speed + wave_phase) * wave_amplitude * height_wave_fade;

	vec3 local_offset;
	local_offset.x = side * ghost_width * taper + sway + lean * height_progress * height_progress;
	local_offset.y = height_progress * ghost_height + age * (rise_distance + emerge_depth) - emerge_depth;
	local_offset.z = cos(height_progress * wave_frequency * 0.72 + TIME * wave_speed * 0.58 + wave_phase) * wave_amplitude * 0.18 * height_wave_fade;

	VERTEX = local_offset;

	float emerge = smoothstep(0.02, 0.2, age);
	float fade_out = 1.0 - smoothstep(0.62, 1.0, age);
	life_fade = emerge * fade_out;
}


void fragment() {
	vec3 sample_color = texture(ghost_texture, vec2(UV.x, 1.0 - UV.y)).rgb;
	float texture_mask = max(sample_color.r, max(sample_color.g, sample_color.b));
	float side_distance = abs(UV.x - 0.5) * 2.0;
	float edge_fade = 1.0 - smoothstep(1.0 - edge_softness, 1.0, side_distance);
	float vertical_fade = smoothstep(0.0, 0.1, height_progress);
	float alpha = texture_mask * edge_fade * vertical_fade * life_fade * opacity;

	if (alpha < 0.004) {
		discard;
	}

	ALBEDO = ghost_color * sample_color;
	EMISSION = ghost_color * sample_color * emission_strength * alpha;
	ALPHA = alpha;
}
