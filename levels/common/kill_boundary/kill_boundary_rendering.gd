@tool
@abstract
extends "res://levels/common/kill_boundary/kill_boundary_retiming.gd"


func _create_flame_material() -> void:
	flame_material = ShaderMaterial.new()
	flame_material.shader = FLAME_SHADER

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.08
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.52

	var noise_texture := NoiseTexture3D.new()
	noise_texture.width = 64
	noise_texture.height = 64
	noise_texture.depth = 64
	noise_texture.seamless = true
	noise_texture.normalize = true
	noise_texture.noise = noise
	flame_material.set_shader_parameter("sample_noise", noise_texture)
	_apply_flame_effect_parameters()


func _create_ghost_material() -> void:
	ghost_material = ShaderMaterial.new()
	ghost_material.shader = GHOST_SHADER
	ghost_material.set_shader_parameter("ghost_texture", GHOST_TEXTURE)
	_apply_ghost_effect_material_parameters()


func _is_flame_effect_active() -> bool:
	return render_effect == EFFECT_FLAME


func _is_ghost_effect_active() -> bool:
	return render_effect == EFFECT_GHOST


func _apply_effect_material_parameters() -> void:
	_apply_flame_effect_parameters()
	_apply_ghost_effect_material_parameters()


func _apply_flame_effect_parameters() -> void:
	if flame_material == null:
		return

	flame_material.set_shader_parameter("boundary_time", runtime_effect_time)
	flame_material.set_shader_parameter("density_multiplier", flame_effect_density)
	flame_material.set_shader_parameter("opacity_multiplier", flame_effect_opacity)
	flame_material.set_shader_parameter("emission_strength", flame_effect_emission)
	flame_material.set_shader_parameter("time_scale", flame_effect_time_scale)
	flame_material.set_shader_parameter("color_core", _color_to_vec3(flame_effect_core_color))
	flame_material.set_shader_parameter("color_mid", _color_to_vec3(flame_effect_mid_color))
	flame_material.set_shader_parameter("color_outer", _color_to_vec3(flame_effect_outer_color))


func _apply_ghost_effect_material_parameters() -> void:
	if ghost_material == null:
		return

	ghost_material.set_shader_parameter("ghost_texture", GHOST_TEXTURE)
	ghost_material.set_shader_parameter("boundary_time", runtime_effect_time)
	ghost_material.set_shader_parameter("ghost_color", _color_to_vec3(ghost_effect_color))
	ghost_material.set_shader_parameter("emission_strength", ghost_effect_emission)
	ghost_material.set_shader_parameter("edge_softness", ghost_effect_edge_softness)


func _color_to_vec3(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)


func _get_ghost_mesh() -> ArrayMesh:
	if ghost_mesh != null:
		return ghost_mesh

	const RIBBON_SEGMENTS := 18
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in RIBBON_SEGMENTS + 1:
		var y := float(i) / float(RIBBON_SEGMENTS)
		vertices.append(Vector3(-1.0, y, 0.0))
		uvs.append(Vector2(0.0, y))
		vertices.append(Vector3(1.0, y, 0.0))
		uvs.append(Vector2(1.0, y))

	for i in RIBBON_SEGMENTS:
		var base := i * 2
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	ghost_mesh = ArrayMesh.new()
	ghost_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ghost_mesh


func _create_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.9, 1.0, 0.38)
	material.emission_enabled = true
	material.emission = Color(0.45, 0.85, 1.0)
	material.emission_energy_multiplier = 0.55
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _create_blocker_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.15, 0.6, 1.0, 0.28)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.35, 0.9)
	material.emission_energy_multiplier = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _ensure_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	preview_material = _create_preview_material()
	blocker_preview_material = _create_blocker_preview_material()
	var preview_container := _get_or_create_editor_preview_container()
	if preview_meshes.is_empty() and preview_ghost_meshes.is_empty() and blocker_preview_meshes.is_empty():
		for child in preview_container.get_children(true):
			preview_container.remove_child(child)
			child.queue_free()

	while preview_meshes.size() < boundary_segments:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Preview%d" % preview_meshes.size()
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = flame_material
		preview_container.add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(mesh_instance)
		mesh_instance.owner = null
		preview_meshes.append(mesh_instance)

	while preview_meshes.size() > boundary_segments:
		var removed_preview: MeshInstance3D = preview_meshes.pop_back()
		removed_preview.queue_free()

	var target_ghost_count := boundary_segments * ghost_ribbons_per_segment
	while preview_ghost_meshes.size() < target_ghost_count:
		var ghost_preview := MeshInstance3D.new()
		ghost_preview.name = "GhostPreview%d" % preview_ghost_meshes.size()
		ghost_preview.mesh = _get_ghost_mesh()
		ghost_preview.material_override = ghost_material
		ghost_preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost_preview.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
		preview_container.add_child(ghost_preview, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(ghost_preview)
		ghost_preview.owner = null
		preview_ghost_meshes.append(ghost_preview)

	while preview_ghost_meshes.size() > target_ghost_count:
		var removed_ghost_preview: MeshInstance3D = preview_ghost_meshes.pop_back()
		removed_ghost_preview.queue_free()

	if preview_center_mesh == null:
		preview_center_mesh = MeshInstance3D.new()
		preview_center_mesh.name = "BoundaryCenterPreview"
		var center_mesh := SphereMesh.new()
		center_mesh.radius = 0.18
		center_mesh.height = 0.36
		preview_center_mesh.mesh = center_mesh
		preview_center_mesh.material_override = preview_material
		preview_container.add_child(preview_center_mesh, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(preview_center_mesh)
		preview_center_mesh.owner = null

	while blocker_preview_meshes.size() < boundary_segments:
		var blocker_mesh := MeshInstance3D.new()
		blocker_mesh.name = "PlayerBlockerPreview%d" % blocker_preview_meshes.size()
		blocker_mesh.mesh = BoxMesh.new()
		blocker_mesh.material_override = blocker_preview_material
		preview_container.add_child(blocker_mesh, false, Node.INTERNAL_MODE_BACK)
		_lock_editor_preview_node(blocker_mesh)
		blocker_mesh.owner = null
		blocker_preview_meshes.append(blocker_mesh)

	while blocker_preview_meshes.size() > boundary_segments:
		var removed_blocker: MeshInstance3D = blocker_preview_meshes.pop_back()
		removed_blocker.queue_free()


func _get_or_create_editor_preview_container() -> Node3D:
	var center := _get_center_node()
	var existing := center.get_node_or_null(EDITOR_PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = EDITOR_PREVIEW_CONTAINER_NAME
	center.add_child(preview_container, false, Node.INTERNAL_MODE_BACK)
	_lock_editor_preview_node(preview_container)
	preview_container.owner = null
	return preview_container


func _lock_editor_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)


func _create_strips() -> void:
	_ensure_runtime_segment_count()


func _ensure_runtime_segment_count() -> void:
	var center := _get_center_node()

	while strip_areas.size() < boundary_segments:
		var i := strip_areas.size()
		var area := Area3D.new()
		area.name = "FlameArea%d" % i
		area.collision_layer = 0
		area.collision_mask = 2
		area.body_entered.connect(_on_flame_body_entered)
		area.body_exited.connect(_on_flame_body_exited)
		center.add_child(area)
		strip_areas.append(area)

		var collision := CollisionShape3D.new()
		collision.name = "FlameCollision%d" % i
		collision.shape = BoxShape3D.new()
		area.add_child(collision)
		strip_collisions.append(collision)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "FlameMesh%d" % i
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.material_override = flame_material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		area.add_child(mesh_instance)
		strip_meshes.append(mesh_instance)

	while strip_areas.size() > boundary_segments:
		var removed_area: Area3D = strip_areas.pop_back()
		strip_collisions.pop_back()
		strip_meshes.pop_back()
		removed_area.queue_free()

	_ensure_ghost_ribbon_count(center)
	_ensure_player_blocker_count(center)


func _ensure_ghost_ribbon_count(center: Node3D) -> void:
	if ghost_material == null:
		_create_ghost_material()

	var target_count := boundary_segments * ghost_ribbons_per_segment
	while ghost_meshes.size() < target_count:
		var i := ghost_meshes.size()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "GhostRibbon%d" % i
		mesh_instance.mesh = _get_ghost_mesh()
		mesh_instance.material_override = ghost_material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
		center.add_child(mesh_instance)
		ghost_meshes.append(mesh_instance)

	while ghost_meshes.size() > target_count:
		var removed_mesh: MeshInstance3D = ghost_meshes.pop_back()
		removed_mesh.queue_free()


func _ensure_player_blocker_count(center: Node3D) -> void:
	while blocker_bodies.size() < boundary_segments:
		var i := blocker_bodies.size()
		var body := StaticBody3D.new()
		body.name = "PlayerBlocker%d" % i
		body.collision_layer = PLAYER_BOUNDARY_BLOCKER_COLLISION_LAYER
		body.collision_mask = 0
		center.add_child(body)
		blocker_bodies.append(body)

		var collision := CollisionShape3D.new()
		collision.name = "PlayerBlockerCollision%d" % i
		collision.shape = BoxShape3D.new()
		body.add_child(collision)
		blocker_collisions.append(collision)

	while blocker_bodies.size() > boundary_segments:
		var removed_body: StaticBody3D = blocker_bodies.pop_back()
		blocker_collisions.pop_back()
		removed_body.queue_free()


func _sync_boundary(update_removed_visuals := false) -> void:
	if not is_inside_tree() or is_syncing_boundary:
		return
	if boundary_removed_for_level and not update_removed_visuals:
		return

	is_syncing_boundary = true
	_apply_effect_material_parameters()

	if Engine.is_editor_hint():
		var target_ghost_count := boundary_segments * ghost_ribbons_per_segment
		if (
			preview_meshes.size() != boundary_segments
			or preview_ghost_meshes.size() != target_ghost_count
			or blocker_preview_meshes.size() != boundary_segments
		):
			_ensure_editor_preview()
		_update_preview_boundary()
		is_syncing_boundary = false
		return

	if not _runtime_effects_enabled() and not update_removed_visuals:
		_set_runtime_effects_enabled(false)
		is_syncing_boundary = false
		return

	_ensure_runtime_segment_count()
	if strip_collisions.size() == boundary_segments and strip_meshes.size() == boundary_segments:
		_update_runtime_boundary()

	if ghost_meshes.size() == boundary_segments * ghost_ribbons_per_segment:
		_update_ghost_boundary()

	if blocker_collisions.size() == boundary_segments:
		_update_runtime_blockers()

	is_syncing_boundary = false


func _update_preview_boundary() -> void:
	if preview_meshes.size() != boundary_segments:
		return

	var no_collisions: Array[CollisionShape3D] = []
	_apply_boundary_to_segments(preview_meshes, no_collisions)
	if preview_ghost_meshes.size() == boundary_segments * ghost_ribbons_per_segment:
		_apply_ghosts_to_boundary(preview_ghost_meshes, true)
	if preview_center_mesh != null:
		preview_center_mesh.position = Vector3(0.0, flame_y + 0.18, 0.0)

	if blocker_preview_meshes.size() == boundary_segments:
		var no_blocker_collisions: Array[CollisionShape3D] = []
		_apply_player_blockers_to_segments(blocker_preview_meshes, no_blocker_collisions)

