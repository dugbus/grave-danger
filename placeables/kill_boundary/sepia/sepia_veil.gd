extends MeshInstance3D

## Presentation-only membrane built from the boundary's exact world perimeter, with no physics or AI state.
const OVERLAY_ORDER := preload("res://ui/hud/overlay_render_order.gd")
const SETTINGS := preload("res://placeables/kill_boundary/sepia/sepia_boundary_settings.tres")
const SHADER_PATH := "res://placeables/kill_boundary/sepia/sepia_veil.gdshader"
const VERTICES_PER_SEGMENT := 6

var visual_time := 0.0
var _surface := ArrayMesh.new()
var _vertices := PackedVector3Array()
var _uvs := PackedVector2Array()
var _material: ShaderMaterial
var _active := false
var _player_height := 0.0
var _follow_player_height := false
var _perimeter_bounds := AABB()


func _ready() -> void:
	# Vertices already contain the owning boundary's full animated world transform.
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh = _surface
	set_process(false)
	visible = false
	if DisplayServer.get_name() == "headless":
		return
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH) as Shader
	# The membrane is drawn after the sepia composite, and depth-tested against actual scene geometry.
	_material.render_priority = OVERLAY_ORDER.DrawPass.BoundaryVeil
	_material.set_shader_parameter(&"veil_color", SETTINGS.veil_color)
	_material.set_shader_parameter(&"veil_height", SETTINGS.veil_height)
	_material.set_shader_parameter(&"opacity", SETTINGS.veil_opacity)
	_material.set_shader_parameter(&"brightness", SETTINGS.veil_brightness)
	_material.set_shader_parameter(&"noise_scale", SETTINGS.veil_noise_scale)
	_material.set_shader_parameter(&"morph_speed", SETTINGS.veil_morph_speed)
	material_override = _material


func set_active(value: bool) -> void:
	_active = value and SETTINGS.veil_enabled
	visible = _active and not _vertices.is_empty()
	set_process(_active)


func _process(delta: float) -> void:
	advance_visual(delta)


## Uses a local visual clock, so morphing cannot advance or pause the boundary's authored timeline.
func advance_visual(delta: float) -> void:
	if not _active:
		return
	visual_time += maxf(delta, 0.0)
	if _material != null:
		_material.set_shader_parameter(&"boundary_time", visual_time)


## The player origin is at their feet; the opaque band rises through their body, even above or below the base.
func set_player_height(height: float) -> void:
	if _follow_player_height and is_equal_approx(height, _player_height):
		return
	_player_height = height
	_follow_player_height = true
	if _material != null:
		_material.set_shader_parameter(&"player_feet_height", height)
		_material.set_shader_parameter(&"follow_player_height", true)
	_update_bounds()


func clear_player_height() -> void:
	if not _follow_player_height:
		return
	_follow_player_height = false
	if _material != null:
		_material.set_shader_parameter(&"follow_player_height", false)
	_update_bounds()


func _update_bounds() -> void:
	if _vertices.is_empty():
		return
	var bounds := _perimeter_bounds
	if _follow_player_height:
		var top := maxf(bounds.end.y, _player_height + SETTINGS.veil_height)
		bounds.position.y = minf(bounds.position.y, _player_height)
		bounds.size.y = top - bounds.position.y
	# Shader extrusion follows the player's height without uploading new vertices every frame.
	custom_aabb = bounds.grow(0.05)


func set_perimeters(perimeters: Array[PackedVector3Array]) -> void:
	var segment_count := 0
	for perimeter in perimeters:
		if perimeter.size() >= 3:
			segment_count += perimeter.size()
	var vertex_count := segment_count * VERTICES_PER_SEGMENT
	var topology_changed := vertex_count != _vertices.size()
	_vertices.resize(vertex_count)
	if topology_changed:
		_uvs.resize(vertex_count)
	var offset := 0
	for perimeter in perimeters:
		if perimeter.size() < 3:
			continue
		for index in perimeter.size():
			_write_segment(offset, perimeter[index], perimeter[(index + 1) % perimeter.size()])
			offset += VERTICES_PER_SEGMENT
	if topology_changed:
		_surface.clear_surfaces()
		if vertex_count > 0:
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = _vertices
			arrays[Mesh.ARRAY_TEX_UV] = _uvs
			_surface.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE
			)
	elif vertex_count > 0:
		_surface.surface_update_vertex_region(0, 0, _vertices.to_byte_array())
	if vertex_count > 0:
		# In-place vertex uploads do not recalculate bounds when an animated boundary moves.
		var bounds := AABB(_vertices[0], Vector3.ZERO)
		for vertex in _vertices:
			bounds = bounds.expand(vertex)
		_perimeter_bounds = bounds
		_update_bounds()
	visible = _active and vertex_count > 0


func _write_segment(offset: int, start: Vector3, finish: Vector3) -> void:
	var rise := Vector3.UP * SETTINGS.veil_height
	_vertices[offset] = start
	_vertices[offset + 1] = finish
	_vertices[offset + 2] = start + rise
	_vertices[offset + 3] = finish
	_vertices[offset + 4] = finish + rise
	_vertices[offset + 5] = start + rise
	_uvs[offset] = Vector2.ZERO
	_uvs[offset + 1] = Vector2.RIGHT
	_uvs[offset + 2] = Vector2(0.0, 1.0)
	_uvs[offset + 3] = Vector2.RIGHT
	_uvs[offset + 4] = Vector2.ONE
	_uvs[offset + 5] = Vector2(0.0, 1.0)
