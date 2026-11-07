extends RefCounted

## Instance-local material adapters. Imported meshes, textures, shaders, and materials stay read-only.
const MASK_INCLUDE := '#include "res://placeables/kill_boundary/sepia/sepia_mask.gdshaderinc"\n'
const SURFACE_PATH := "res://placeables/kill_boundary/sepia/sepia_surface.gdshader"
const CLIP_CODE := """
	vec3 sepia_world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sepia_coverage = sepia_mask(sepia_world);
	float sepia_dither = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
	if (sepia_coverage >= 1.0 || sepia_coverage > sepia_dither) { discard; }
"""

var materials: Array[ShaderMaterial] = []
var _cache: Dictionary[Material, ShaderMaterial] = {}
var _nodes: Array[GeometryInstance3D] = []
var _overrides: Array[Material] = []
var _overlays: Array[Material] = []
var _surfaces: Array[Array] = []


func bind_geometry(geometry: GeometryInstance3D) -> void:
	if geometry in _nodes or DisplayServer.get_name() == "headless":
		return
	var mesh: Mesh
	if geometry is MeshInstance3D:
		mesh = (geometry as MeshInstance3D).mesh
	elif geometry is MultiMeshInstance3D and (geometry as MultiMeshInstance3D).multimesh != null:
		mesh = (geometry as MultiMeshInstance3D).multimesh.mesh
	elif geometry is GPUParticles3D:
		mesh = (geometry as GPUParticles3D).draw_pass_1
	if mesh == null:
		return
	_nodes.append(geometry)
	_overrides.append(geometry.material_override)
	_overlays.append(geometry.material_overlay)
	var previous_surfaces: Array[Material] = []
	if geometry.material_override != null:
		geometry.material_override = adapt(geometry.material_override)
	elif geometry is MeshInstance3D:
		var instance := geometry as MeshInstance3D
		for index in mesh.get_surface_count():
			previous_surfaces.append(instance.get_surface_override_material(index))
			instance.set_surface_override_material(index, adapt(instance.get_active_material(index)))
	else:
		geometry.material_override = adapt(mesh.surface_get_material(0))
	_surfaces.append(previous_surfaces)
	if geometry.material_overlay != null:
		geometry.material_overlay = adapt(geometry.material_overlay)


func adapt(source: Material) -> ShaderMaterial:
	if source == null:
		source = StandardMaterial3D.new()
	if _cache.has(source):
		return _cache[source]
	var result := ShaderMaterial.new()
	var shader := Shader.new()
	if source is ShaderMaterial:
		var authored := source as ShaderMaterial
		if authored.shader == null:
			return null
		shader.code = inject_mask(authored.shader.code)
		result.shader = shader
		for parameter in authored.shader.get_shader_uniform_list():
			var parameter_name := parameter["name"] as StringName
			result.set_shader_parameter(parameter_name, authored.get_shader_parameter(parameter_name))
	elif source is BaseMaterial3D:
		var authored := source as BaseMaterial3D
		var template := load(SURFACE_PATH) as Shader
		var code := template.code
		# Alpha is a compile-time pipeline decision: opaque enemies must keep writing depth.
		if authored.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
			code = code.replace("\tif (use_alpha) { ALPHA = color.a; }\n", "")
			code = code.replace(
				"\tif (alpha_scissor > 0.0) { ALPHA_SCISSOR_THRESHOLD = alpha_scissor; ALPHA = color.a; }\n", ""
			)
		elif authored.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			code = code.replace("\tif (use_alpha) { ALPHA = color.a; }\n", "")
			code = code.replace("if (alpha_scissor > 0.0) {", "{")
		else:
			code = code.replace(
				"\tif (alpha_scissor > 0.0) { ALPHA_SCISSOR_THRESHOLD = alpha_scissor; ALPHA = color.a; }\n", ""
			)
			if authored.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
				code = code.replace("render_mode ", "render_mode depth_prepass_alpha, ")
		if authored.cull_mode == BaseMaterial3D.CULL_BACK:
			code = code.replace("cull_disabled", "cull_back")
		elif authored.cull_mode == BaseMaterial3D.CULL_FRONT:
			code = code.replace("cull_disabled", "cull_front")
		if authored.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			code = code.replace("render_mode ", "render_mode unshaded, ")
		shader.code = inject_mask(code)
		result.shader = shader
		_copy_standard_parameters(authored, result)
	else:
		push_error("Sepia cannot adapt material: " + source.get_class())
		return null
	result.render_priority = source.render_priority
	_cache[source] = result
	materials.append(result)
	if source.next_pass != null:
		result.next_pass = adapt(source.next_pass)
	return result


## Inserts clipping at the fragment entry so custom outlines and animated effects retain their code.
static func inject_mask(code: String) -> String:
	var expression := RegEx.new()
	expression.compile("void\\s+fragment\\s*\\(\\s*\\)\\s*\\{")
	var match_result := expression.search(code)
	if match_result == null:
		return code + "\n" + MASK_INCLUDE + "\nvoid fragment() {\n" + CLIP_CODE + "\n}\n"
	return code.insert(match_result.get_end(), "\n" + CLIP_CODE).insert(match_result.get_start(), MASK_INCLUDE)


func set_regions(
	points: PackedVector2Array, counts: Vector4i, count: int, feather: float, inversions := Vector4i.ZERO
) -> void:
	for material in materials:
		material.set_shader_parameter(&"sepia_points", points)
		material.set_shader_parameter(&"sepia_counts", counts)
		material.set_shader_parameter(&"sepia_inversions", inversions)
		material.set_shader_parameter(&"sepia_region_count", count)
		material.set_shader_parameter(&"sepia_feather", feather)


func restore() -> void:
	for index in _nodes.size():
		var geometry := _nodes[index]
		if not is_instance_valid(geometry):
			continue
		geometry.material_override = _overrides[index]
		geometry.material_overlay = _overlays[index]
		if geometry is MeshInstance3D:
			var instance := geometry as MeshInstance3D
			for surface in _surfaces[index].size():
				instance.set_surface_override_material(surface, _surfaces[index][surface] as Material)
	_nodes.clear()
	_overrides.clear()
	_overlays.clear()
	_surfaces.clear()
	materials.clear()
	_cache.clear()


func _copy_standard_parameters(source: BaseMaterial3D, target: ShaderMaterial) -> void:
	target.set_shader_parameter(&"albedo", source.albedo_color)
	target.set_shader_parameter(&"texture_albedo", source.albedo_texture)
	target.set_shader_parameter(&"use_albedo_texture", source.albedo_texture != null)
	target.set_shader_parameter(&"use_vertex_color", source.vertex_color_use_as_albedo)
	target.set_shader_parameter(&"roughness_value", source.roughness)
	target.set_shader_parameter(&"metallic_value", source.metallic)
	target.set_shader_parameter(&"use_normal_texture", source.normal_enabled and source.normal_texture != null)
	target.set_shader_parameter(&"texture_normal", source.normal_texture)
	target.set_shader_parameter(&"normal_scale", source.normal_scale)
	target.set_shader_parameter(&"uv_scale", source.uv1_scale)
	target.set_shader_parameter(&"uv_offset", source.uv1_offset)
	target.set_shader_parameter(&"use_alpha", source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)
	target.set_shader_parameter(&"alpha_scissor", source.alpha_scissor_threshold)
	if source.emission_enabled:
		target.set_shader_parameter(&"emission_color", source.emission * source.emission_energy_multiplier)
		target.set_shader_parameter(&"texture_emission", source.emission_texture)
		target.set_shader_parameter(&"use_emission_texture", source.emission_texture != null)
