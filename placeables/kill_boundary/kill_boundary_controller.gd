@tool
extends "res://placeables/kill_boundary/kill_boundary_rendering.gd"


func _update_runtime_boundary() -> void:
	_apply_boundary_to_segments(strip_meshes, strip_collisions)


func _update_ghost_boundary() -> void:
	_apply_ghosts_to_boundary(ghost_meshes)
	_update_ghost_billboards()


func _update_runtime_blockers() -> void:
	var no_meshes: Array[MeshInstance3D] = []
	_apply_player_blockers_to_segments(no_meshes, blocker_collisions)
	_update_player_blockers_enabled()


func _apply_boundary_to_segments(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void:
	var points := _get_boundary_points()
	var perimeter_offset := 0.0
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var segment_length := delta.length()
		var midpoint := (start + finish) * 0.5
		var visual_size := Vector3(segment_length + flame_visual_depth, flame_height, flame_visual_depth)
		var mesh_instance := meshes[i]
		mesh_instance.visible = _is_flame_effect_active()
		(mesh_instance.mesh as BoxMesh).size = visual_size
		mesh_instance.set_instance_shader_parameter("fire_size", visual_size)
		mesh_instance.set_instance_shader_parameter("segment_half_length", segment_length * 0.5)
		mesh_instance.set_instance_shader_parameter("noise_along_offset", perimeter_offset + segment_length * 0.5)
		mesh_instance.rotation = Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var segment_position := Vector3(midpoint.x, flame_y + flame_height * 0.5, midpoint.y)

		if collisions.is_empty():
			mesh_instance.position = segment_position
		else:
			var collision := collisions[i]
			var area := collision.get_parent() as Area3D
			area.position = segment_position
			area.rotation = mesh_instance.rotation
			mesh_instance.position = Vector3.ZERO
			mesh_instance.rotation = Vector3.ZERO
			(collision.shape as BoxShape3D).size = Vector3(segment_length + flame_thickness, flame_height, flame_thickness)
		perimeter_offset += segment_length


func _apply_ghosts_to_boundary(meshes: Array[MeshInstance3D], is_editor_preview := false) -> void:
	if meshes.is_empty():
		return

	var points := _get_boundary_points()
	var ghost_index := 0
	var spirits_visible := _is_ghost_effect_active() and ghost_ribbons_per_segment > 0
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var outward := Vector2(delta.y, -delta.x).normalized()
		for slot in ghost_ribbons_per_segment:
			var mesh_instance := meshes[ghost_index]
			var rng := _create_ghost_rng(ghost_index)
			var along := (float(slot) + rng.randf_range(0.12, 0.88)) / float(ghost_ribbons_per_segment)
			var ground_position := start.lerp(finish, clampf(along, 0.0, 1.0))
			ground_position += outward * rng.randf_range(-flame_visual_depth * 0.35, flame_visual_depth * 0.35)

			mesh_instance.visible = spirits_visible
			mesh_instance.position = Vector3(ground_position.x, flame_y, ground_position.y)
			mesh_instance.rotation = Vector3.ZERO
			mesh_instance.extra_cull_margin = maxf(ghost_height_range.y + ghost_rise_distance + ghost_wave_amplitude, 1.0)
			_configure_ghost_ribbon(mesh_instance, rng, is_editor_preview)
			ghost_index += 1


func _configure_ghost_ribbon(
	mesh_instance: MeshInstance3D,
	rng: RandomNumberGenerator,
	is_editor_preview := false
) -> void:
	var height := rng.randf_range(ghost_height_range.x, ghost_height_range.y)
	var width := rng.randf_range(ghost_width_range.x, ghost_width_range.y)
	var size_ratio := (
		0.0
		if is_equal_approx(ghost_height_range.x, ghost_height_range.y)
		else inverse_lerp(ghost_height_range.x, ghost_height_range.y, height)
	)
	mesh_instance.set_instance_shader_parameter("ghost_width", width)
	mesh_instance.set_instance_shader_parameter("ghost_height", height)
	mesh_instance.set_instance_shader_parameter("rise_distance", ghost_rise_distance * rng.randf_range(0.72, 1.18))
	mesh_instance.set_instance_shader_parameter(
		"emerge_depth",
		height * rng.randf_range(ghost_emerge_depth_ratio_range.x, ghost_emerge_depth_ratio_range.y)
	)
	mesh_instance.set_instance_shader_parameter(
		"rise_speed",
		rng.randf_range(ghost_rise_speed_range.x, ghost_rise_speed_range.y)
	)
	var cycle_offset := rng.randf()
	if is_editor_preview:
		cycle_offset = EDITOR_GHOST_PREVIEW_CYCLE_OFFSET
	mesh_instance.set_instance_shader_parameter("cycle_offset", cycle_offset)
	mesh_instance.set_instance_shader_parameter("wave_phase", rng.randf_range(0.0, TAU))
	mesh_instance.set_instance_shader_parameter(
		"wave_amplitude",
		ghost_wave_amplitude * rng.randf_range(0.45, 1.3) * lerpf(0.85, 1.15, size_ratio)
	)
	mesh_instance.set_instance_shader_parameter(
		"wave_frequency",
		rng.randf_range(ghost_wave_frequency_range.x, ghost_wave_frequency_range.y)
	)
	mesh_instance.set_instance_shader_parameter(
		"wave_speed",
		rng.randf_range(ghost_wave_speed_range.x, ghost_wave_speed_range.y)
	)
	mesh_instance.set_instance_shader_parameter("lean", rng.randf_range(ghost_lean_range.x, ghost_lean_range.y))
	mesh_instance.set_instance_shader_parameter("opacity", rng.randf_range(ghost_opacity_range.x, ghost_opacity_range.y))


func _update_ghost_billboards() -> void:
	if ghost_meshes.is_empty() or not _is_ghost_effect_active():
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	for mesh_instance in ghost_meshes:
		if not is_instance_valid(mesh_instance) or not mesh_instance.visible:
			continue

		var target := camera.global_position
		target.y = mesh_instance.global_position.y
		if mesh_instance.global_position.distance_squared_to(target) <= 0.0001:
			continue

		mesh_instance.look_at(target, Vector3.UP)


func _create_ghost_rng(index: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 918273 + index * 104729
	return rng


func _sanitize_positive_range(value: Vector2, minimum: float) -> Vector2:
	var low := maxf(minf(value.x, value.y), minimum)
	var high := maxf(maxf(value.x, value.y), low)
	return Vector2(low, high)


func _apply_player_blockers_to_segments(meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]) -> void:
	var points := _get_boundary_points()
	var center_offset := flame_thickness * 0.5 + player_blocking_outset + player_blocking_thickness * 0.5
	for i in boundary_segments:
		var start := points[i]
		var finish := points[(i + 1) % boundary_segments]
		var delta := finish - start
		var segment_length := delta.length()
		var outward := Vector2(delta.y, -delta.x).normalized()
		var midpoint := (start + finish) * 0.5 + outward * center_offset
		var blocker_size := Vector3(segment_length + center_offset * 2.0, player_blocking_height, player_blocking_thickness)
		var segment_rotation := Vector3(0.0, atan2(-delta.y, delta.x), 0.0)
		var segment_position := Vector3(midpoint.x, flame_y + player_blocking_height * 0.5, midpoint.y)
		if not meshes.is_empty():
			var mesh_instance := meshes[i]
			mesh_instance.visible = player_blocking_enabled
			mesh_instance.position = segment_position
			mesh_instance.rotation = segment_rotation
			(mesh_instance.mesh as BoxMesh).size = blocker_size

		if collisions.is_empty():
			continue

		var collision := collisions[i]
		var body := collision.get_parent() as StaticBody3D
		body.position = segment_position
		body.rotation = segment_rotation
		(collision.shape as BoxShape3D).size = blocker_size


func _get_boundary_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var first_shape := floori(shape_morph)
	var second_shape := mini(first_shape + 1, MAX_SHAPE_INDEX)
	var shape_blend := shape_morph - float(first_shape)
	for i in boundary_segments:
		var perimeter_ratio := float(i) / float(boundary_segments)
		var first_point := _get_shape_profile_point(first_shape, perimeter_ratio)
		var second_point := _get_shape_profile_point(second_shape, perimeter_ratio)
		points.append(first_point.lerp(second_point, shape_blend))
	return points


func _get_shape_profile_point(shape_index: int, perimeter_ratio: float) -> Vector2:
	var angle := perimeter_ratio * TAU + PI * 0.25
	var direction := Vector2(cos(angle), sin(angle))
	var half_size := bounds_size * runtime_bounds_multiplier * 0.5
	match shape_index:
		SHAPE_RECTANGLE:
			return _get_rectangle_profile_point(half_size, perimeter_ratio)
		SHAPE_CIRCLE:
			return direction * minf(half_size.x, half_size.y)
		_:
			return direction * minf(half_size.x, half_size.y)


func _get_rectangle_profile_point(half_size: Vector2, perimeter_ratio: float) -> Vector2:
	var side_progress := fposmod(perimeter_ratio, 1.0) * 4.0
	var side_index := floori(side_progress)
	var along_side := side_progress - float(side_index)
	match side_index:
		0:
			return Vector2(lerpf(half_size.x, -half_size.x, along_side), half_size.y)
		1:
			return Vector2(-half_size.x, lerpf(half_size.y, -half_size.y, along_side))
		2:
			return Vector2(lerpf(-half_size.x, half_size.x, along_side), -half_size.y)
		_:
			return Vector2(half_size.x, lerpf(-half_size.y, half_size.y, along_side))


func _update_player_blockers_enabled() -> void:
	var disabled := not _runtime_effects_enabled() or not player_blocking_enabled or _has_dead_flame_vulnerable_body()
	for collision in blocker_collisions:
		if is_instance_valid(collision):
			collision.disabled = disabled


func _has_dead_flame_vulnerable_body() -> bool:
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not is_instance_valid(body):
			continue

		if body.has_method("is_dead") and bool(body.call("is_dead")):
			return true

	return false


func _create_near_flame_audio() -> void:
	var stream := GDAudio.load_stream(_get_boundary_audio_path())
	if stream == null:
		return

	near_flame_audio_player = AudioStreamPlayer.new()
	near_flame_audio_player.name = "NearFlameAudio"
	near_flame_audio_player.bus = &"SFX"
	var loop_stream := stream.duplicate() as AudioStream
	if loop_stream is AudioStreamMP3:
		(loop_stream as AudioStreamMP3).loop = true
	near_flame_audio_player.stream = loop_stream
	near_flame_audio_player.volume_db = _get_boundary_audio_volume_db(near_flame_audio_min_db)
	add_child(near_flame_audio_player)
	near_flame_audio_player.play()


func _get_boundary_audio_path() -> String:
	if _is_ghost_effect_active():
		return GHOST_BOUNDARY_SOUND_PATH

	return NEAR_FLAMES_SOUND_PATH


func _get_boundary_audio_volume_db(base_volume_db: float) -> float:
	if _is_ghost_effect_active():
		return base_volume_db + GHOST_BOUNDARY_VOLUME_BOOST_DB

	return base_volume_db


func _apply_flame_heat(delta: float) -> void:
	if not _runtime_effects_enabled():
		return

	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		if not _is_inside_flame_damage_height(body_3d.global_position):
			continue

		var outside_depth := _get_outside_flame_depth(body_3d.global_position)
		var touching_flames := flame_touching_bodies.has(body_3d)
		if not touching_flames and outside_depth <= 0.0:
			var inside_edge_distance := _get_inside_edge_distance(body_3d.global_position)
			touching_flames = inside_edge_distance <= flame_damage_inner_depth

		if not touching_flames and outside_depth <= 0.0:
			continue

		var damage_multiplier := 1.0
		if outside_depth > 0.0:
			var outside_ratio := clampf(outside_depth / maxf(outside_damage_ramp_depth, 0.001), 0.0, 1.0)
			damage_multiplier = lerpf(1.0, maxf(max_outside_damage_multiplier, 1.0), outside_ratio)

		if body_3d.has_method("apply_flame_damage"):
			body_3d.apply_flame_damage(flame_damage_per_second * damage_multiplier * delta)
		elif body_3d.has_method("die_from_flames"):
			body_3d.die_from_flames()


func _update_near_flame_audio(delta: float) -> void:
	if near_flame_audio_player == null:
		return

	if not _runtime_effects_enabled():
		near_flame_audio_player.volume_db = _get_boundary_audio_volume_db(near_flame_audio_min_db)
		return

	var closest_distance := INF
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if not body is Node3D:
			continue

		var body_3d := body as Node3D
		if not is_instance_valid(body_3d):
			continue

		closest_distance = minf(closest_distance, _get_distance_to_flames(body_3d.global_position))

	var target_volume := near_flame_audio_min_db
	if closest_distance < INF:
		var closeness := 1.0 - clampf(closest_distance / maxf(near_flame_audio_distance, 0.001), 0.0, 1.0)
		closeness = pow(closeness, near_flame_audio_curve)
		target_volume = lerpf(near_flame_audio_min_db, near_flame_audio_max_db, closeness)

	target_volume = _get_boundary_audio_volume_db(target_volume)
	var t := 1.0 - exp(-near_flame_audio_lag * delta)
	near_flame_audio_player.volume_db = lerpf(near_flame_audio_player.volume_db, target_volume, t)


func _sink_removed_boundary(seconds: float, distance: float) -> void:
	var duration := maxf(seconds, 0.05)
	var drop_distance := maxf(distance, 0.1)
	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		position + Vector3.DOWN * drop_distance,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)


func _set_runtime_motion_paused(paused: bool) -> void:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		return

	animation_player.speed_scale = 0.0 if paused else 1.0
	if not paused and autoplay_boundary_animation and _runtime_effects_enabled() and not animation_player.is_playing():
		animation_player.play(DEFAULT_ANIMATION_NAME)


func _resume_runtime_motion_after(token: int, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if token == runtime_pause_token and is_inside_tree() and not boundary_removed_for_level:
		_set_runtime_motion_paused(false)


func _animate_runtime_bounds_multiplier(target_multiplier: float, seconds: float) -> void:
	if boundary_removed_for_level:
		return

	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()

	runtime_bounds_tween = create_tween()
	runtime_bounds_tween.tween_method(
		func(value: float) -> void:
			if boundary_removed_for_level:
				return
			runtime_bounds_multiplier = maxf(value, 0.01)
			_sync_boundary(),
		runtime_bounds_multiplier,
		maxf(target_multiplier, 0.01),
		maxf(seconds, 0.01)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _restore_runtime_bounds_after(multiplier: float, active_seconds: float, transition_seconds: float) -> void:
	await get_tree().create_timer(maxf(active_seconds, 0.01)).timeout
	if is_inside_tree() and not boundary_removed_for_level:
		active_runtime_bounds_multipliers.erase(multiplier)
		_animate_runtime_bounds_multiplier(_get_target_runtime_bounds_multiplier(), transition_seconds)


func _get_target_runtime_bounds_multiplier() -> float:
	var multiplier := permanent_runtime_bounds_multiplier
	for active_multiplier in active_runtime_bounds_multipliers:
		multiplier *= active_multiplier
	return maxf(multiplier, 0.01)


func _get_distance_to_flames(world_position: Vector3) -> float:
	var outside_depth := _get_outside_flame_depth(world_position)
	if outside_depth > 0.0:
		return 0.0

	return maxf(_get_inside_edge_distance(world_position), 0.0)


func _get_inside_edge_distance(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	return _get_signed_distance_to_boundary(Vector2(local_position.x, local_position.z))


func _get_outside_flame_depth(world_position: Vector3) -> float:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	return maxf(-_get_signed_distance_to_boundary(Vector2(local_position.x, local_position.z)), 0.0)


func _get_signed_distance_to_boundary(point: Vector2) -> float:
	var polygon := _get_boundary_points()
	var closest_distance := INF
	for i in polygon.size():
		closest_distance = minf(closest_distance, _distance_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()]))
	return closest_distance if Geometry2D.is_point_in_polygon(point, polygon) else -closest_distance


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _is_inside_flame_damage_height(world_position: Vector3) -> bool:
	var local_position: Vector3 = _get_center_node().global_transform.affine_inverse() * world_position
	var margin := maxf(flame_damage_vertical_margin, 0.0)
	return local_position.y >= flame_y - margin and local_position.y <= flame_y + flame_height + margin


func _on_flame_body_entered(body: Node3D) -> void:
	if not flame_touching_bodies.has(body):
		flame_touching_bodies.append(body)


func _on_flame_body_exited(body: Node3D) -> void:
	flame_touching_bodies.erase(body)
