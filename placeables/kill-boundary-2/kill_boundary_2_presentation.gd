@tool
class_name GDKillBoundary2Presentation
extends Node3D

## Flame and ghost presentation driven by canonical geometry.

const FLAME_SHADER := preload(
	"res://placeables/kill_boundary/effects/kill_boundary_flame_effect.gdshader"
)
const GHOST_SHADER := preload(
	"res://placeables/kill_boundary/effects/kill_boundary_ghost_effect.gdshader"
)
const GHOST_TEXTURE := preload("res://Assets/placeables/kill_boundary/ghost.png")
const VISUAL_SEGMENT := preload("res://placeables/kill-boundary-2/boundary_visual_segment.tscn")
const GHOST_RIBBON_SEGMENTS := 18
const EDITOR_GHOST_CYCLE_OFFSET := 0.38
const EDITOR_GHOST_MINIMUM_EMISSION := 12.0
const EDITOR_GHOST_MAXIMUM_EDGE_SOFTNESS := 0.14
const EDITOR_GHOST_OPACITY_MULTIPLIER := 1.8

var settings: GDKillBoundary2Settings
var render_effect := GDKillBoundary2Settings.RenderEffect.Flame
var flame_material: ShaderMaterial
var ghost_material: ShaderMaterial
var ghost_mesh: ArrayMesh
var segments: Array[MeshInstance3D] = []
var ghosts: Array[MeshInstance3D] = []
var current_points := PackedVector2Array()
var effect_time := 0.0
var effects_enabled := true
var _ghost_random := RandomNumberGenerator.new()


func configure(
	new_settings: GDKillBoundary2Settings, new_effect: GDKillBoundary2Settings.RenderEffect
) -> void:
	settings = new_settings
	render_effect = new_effect
	_create_materials()
	_ensure_counts()


func set_render_effect(value: GDKillBoundary2Settings.RenderEffect) -> void:
	render_effect = value
	_apply_visibility()


func set_effects_enabled(value: bool, keep_visuals := false) -> void:
	effects_enabled = value or keep_visuals
	_apply_visibility()


func advance_effect_time(delta: float) -> void:
	effect_time += maxf(delta, 0.0)
	_apply_material_parameters()
	_update_ghost_billboards()


func apply_geometry(points: PackedVector2Array) -> void:
	current_points = points
	if settings == null:
		return
	_ensure_counts()
	var reference_segment_spacing := _get_reference_segment_spacing(points)
	for index in points.size():
		var start := points[index]
		var finish := points[(index + 1) % points.size()]
		var delta := finish - start
		var length := delta.length()
		var mesh_instance := segments[index]
		var visual_size := Vector3(
			length + settings.flame_visual_depth, settings.flame_height, settings.flame_visual_depth
		)
		(mesh_instance.mesh as BoxMesh).size = visual_size
		mesh_instance.set_instance_shader_parameter(&"fire_size", visual_size)
		mesh_instance.set_instance_shader_parameter(&"segment_half_length", length * 0.5)
		mesh_instance.set_instance_shader_parameter(
			&"noise_along_offset", (float(index) + 0.5) * reference_segment_spacing
		)
		mesh_instance.position = Vector3(
			(start.x + finish.x) * 0.5,
			settings.flame_y + settings.flame_height * 0.5,
			(start.y + finish.y) * 0.5
		)
		mesh_instance.rotation = Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
	_update_ghosts()
	_apply_visibility()


func _create_materials() -> void:
	flame_material = ShaderMaterial.new()
	flame_material.shader = FLAME_SHADER
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	var texture := NoiseTexture3D.new()
	texture.width = 64
	texture.height = 64
	texture.depth = 64
	texture.seamless = true
	texture.normalize = true
	texture.noise = noise
	flame_material.set_shader_parameter(&"sample_noise", texture)
	ghost_material = ShaderMaterial.new()
	ghost_material.shader = GHOST_SHADER
	ghost_material.set_shader_parameter(&"ghost_texture", GHOST_TEXTURE)
	_apply_material_parameters()


func _apply_material_parameters() -> void:
	if settings == null:
		return
	if flame_material != null:
		flame_material.set_shader_parameter(&"boundary_time", effect_time)
		flame_material.set_shader_parameter(&"density_multiplier", settings.flame_effect_density)
		flame_material.set_shader_parameter(&"opacity_multiplier", settings.flame_effect_opacity)
		flame_material.set_shader_parameter(&"emission_strength", settings.flame_effect_emission)
		flame_material.set_shader_parameter(&"time_scale", settings.flame_effect_time_scale)
		flame_material.set_shader_parameter(
			&"color_core", _color_vector(settings.flame_effect_core_color)
		)
		flame_material.set_shader_parameter(
			&"color_mid", _color_vector(settings.flame_effect_mid_color)
		)
		flame_material.set_shader_parameter(
			&"color_outer", _color_vector(settings.flame_effect_outer_color)
		)
	if ghost_material != null:
		ghost_material.set_shader_parameter(&"boundary_time", effect_time)
		ghost_material.set_shader_parameter(
			&"ghost_color", _color_vector(settings.ghost_effect_color)
		)
		ghost_material.set_shader_parameter(
			&"emission_strength",
			resolve_ghost_emission(settings.ghost_effect_emission, Engine.is_editor_hint())
		)
		ghost_material.set_shader_parameter(
			&"edge_softness",
			resolve_ghost_edge_softness(
				settings.ghost_effect_edge_softness, Engine.is_editor_hint()
			)
		)


func _ensure_counts() -> void:
	if settings == null:
		return
	while segments.size() < settings.boundary_segments:
		var segment := VISUAL_SEGMENT.instantiate() as MeshInstance3D
		segment.name = "FlameSegment%d" % segments.size()
		segment.material_override = flame_material
		add_child(segment)
		segments.append(segment)
	while segments.size() > settings.boundary_segments:
		var removed: MeshInstance3D = segments.pop_back()
		removed.queue_free()
	var target_ghosts := settings.boundary_segments * settings.ghost_ribbons_per_segment
	while ghosts.size() < target_ghosts:
		var ghost := MeshInstance3D.new()
		ghost.name = "GhostRibbon%d" % ghosts.size()
		ghost.mesh = _get_ghost_mesh()
		ghost.material_override = ghost_material
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ghost)
		ghosts.append(ghost)
	while ghosts.size() > target_ghosts:
		var removed_ghost: MeshInstance3D = ghosts.pop_back()
		removed_ghost.queue_free()


func _update_ghosts() -> void:
	if settings == null or current_points.size() != settings.boundary_segments:
		return
	var ghost_index := 0
	for segment_index in current_points.size():
		var start := current_points[segment_index]
		var finish := current_points[(segment_index + 1) % current_points.size()]
		var delta := finish - start
		var outward := Vector2(delta.y, -delta.x).normalized()
		for slot in settings.ghost_ribbons_per_segment:
			var ghost := ghosts[ghost_index]
			_ghost_random.seed = 918273 + ghost_index * 104729
			var along := (
				(float(slot) + _ghost_random.randf_range(0.12, 0.88))
				/ float(settings.ghost_ribbons_per_segment)
			)
			var ground := start.lerp(finish, along) + outward * _ghost_random.randf_range(-0.2, 0.2)
			ghost.position = Vector3(ground.x, settings.flame_y, ground.y)
			ghost.set_instance_shader_parameter(
				&"ghost_width",
				_ghost_random.randf_range(
					settings.ghost_width_range.x, settings.ghost_width_range.y
				)
			)
			ghost.set_instance_shader_parameter(
				&"ghost_height",
				_ghost_random.randf_range(
					settings.ghost_height_range.x, settings.ghost_height_range.y
				)
			)
			ghost.set_instance_shader_parameter(&"rise_distance", settings.ghost_rise_distance)
			ghost.set_instance_shader_parameter(
				&"rise_speed", _ghost_random.randf_range(0.075, 0.18)
			)
			ghost.set_instance_shader_parameter(
				&"cycle_offset",
				EDITOR_GHOST_CYCLE_OFFSET if Engine.is_editor_hint() else _ghost_random.randf()
			)
			ghost.set_instance_shader_parameter(&"wave_phase", _ghost_random.randf_range(0.0, TAU))
			ghost.set_instance_shader_parameter(&"wave_amplitude", settings.ghost_wave_amplitude)
			ghost.set_instance_shader_parameter(
				&"wave_frequency", _ghost_random.randf_range(3.4, 8.6)
			)
			ghost.set_instance_shader_parameter(&"wave_speed", _ghost_random.randf_range(0.7, 1.9))
			ghost.set_instance_shader_parameter(&"lean", _ghost_random.randf_range(-0.28, 0.28))
			ghost.set_instance_shader_parameter(
				&"opacity",
				resolve_ghost_opacity(
					_ghost_random.randf_range(0.92, 1.18), Engine.is_editor_hint()
				)
			)
			ghost.set_instance_shader_parameter(
				&"emerge_depth", _ghost_random.randf_range(0.72, 1.02)
			)
			ghost_index += 1


func _apply_visibility() -> void:
	var show_flames := (
		effects_enabled and render_effect == GDKillBoundary2Settings.RenderEffect.Flame
	)
	var show_ghosts := (
		effects_enabled and render_effect == GDKillBoundary2Settings.RenderEffect.Ghost
	)
	for segment in segments:
		segment.visible = show_flames
	for ghost in ghosts:
		ghost.visible = show_ghosts


func _update_ghost_billboards() -> void:
	if render_effect != GDKillBoundary2Settings.RenderEffect.Ghost or not is_inside_tree():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for ghost in ghosts:
		if not ghost.visible:
			continue
		var target := camera.global_position
		target.y = ghost.global_position.y
		if ghost.global_position.distance_squared_to(target) > 0.0001:
			ghost.look_at(target, Vector3.UP)


func _get_ghost_mesh() -> ArrayMesh:
	if ghost_mesh != null:
		return ghost_mesh
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for index in GHOST_RIBBON_SEGMENTS + 1:
		var y := float(index) / float(GHOST_RIBBON_SEGMENTS)
		vertices.append(Vector3(-1.0, y, 0.0))
		vertices.append(Vector3(1.0, y, 0.0))
		uvs.append(Vector2(0.0, y))
		uvs.append(Vector2(1.0, y))
	for index in GHOST_RIBBON_SEGMENTS:
		var base := index * 2
		indices.append_array(
			PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
		)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	ghost_mesh = ArrayMesh.new()
	ghost_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ghost_mesh


func _color_vector(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)


func _get_reference_segment_spacing(points: PackedVector2Array) -> float:
	if points.is_empty():
		return 0.0
	var half_extents := Vector2.ZERO
	for point in points:
		half_extents.x = maxf(half_extents.x, absf(point.x))
		half_extents.y = maxf(half_extents.y, absf(point.y))
	return 4.0 * (half_extents.x + half_extents.y) / float(points.size())


## Makes Ghost previews readable in the editor without changing runtime-authored brightness.
static func resolve_ghost_emission(authored: float, editor_preview: bool) -> float:
	return maxf(authored, EDITOR_GHOST_MINIMUM_EMISSION) if editor_preview else authored


## Makes Ghost preview silhouettes clearer while preserving softer authored runtime edges.
static func resolve_ghost_edge_softness(authored: float, editor_preview: bool) -> float:
	return minf(authored, EDITOR_GHOST_MAXIMUM_EDGE_SOFTNESS) if editor_preview else authored


## Makes Ghost preview texture detail easier to see without changing runtime opacity.
static func resolve_ghost_opacity(authored: float, editor_preview: bool) -> float:
	return authored * EDITOR_GHOST_OPACITY_MULTIPLIER if editor_preview else authored
