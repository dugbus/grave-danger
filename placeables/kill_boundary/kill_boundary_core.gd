@tool
@abstract
extends "res://placeables/kill_boundary/kill_boundary_base.gd"


func _ready() -> void:
	add_to_group("kill_boundary")
	_ensure_boundary_nodes()
	_configure_path_follow()
	_sync_animation_player()
	if boundary_animation != null:
		_sync_boundary_scale_rotation_to_animation(boundary_animation, _get_first_animation_key_time(boundary_animation))
	_apply_boundary_scale_rotation()
	_create_flame_material()
	_create_ghost_material()

	if Engine.is_editor_hint():
		_ensure_editor_preview()
		_sync_editor_preview_animation()
		_sync_boundary()
		set_process(true)
		return

	_sync_movement_to_animation()
	if not _runtime_effects_enabled():
		_set_runtime_effects_enabled(false)
		return

	_create_strips()
	_create_near_flame_audio()
	_sync_boundary()


func _notification(what: int) -> void:
	if Engine.is_editor_hint() or what != NOTIFICATION_VISIBILITY_CHANGED or not is_inside_tree():
		return

	if boundary_removed_for_level:
		return

	_set_runtime_effects_enabled(visible)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_update_speed_change_ripple_retime(delta)
		_update_path_point_animation_markers(delta)
		_sync_editor_preview_animation()
		_sync_boundary()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if boundary_removed_for_level:
		_update_removed_boundary_visuals(delta)
		return

	if not _runtime_effects_enabled():
		_set_runtime_effects_enabled(false)
		return

	_ensure_runtime_effect_nodes()
	elapsed_time += delta
	runtime_effect_time += delta
	_sync_movement_to_animation()
	_sync_boundary()
	_update_ghost_billboards()
	_apply_flame_heat(delta)
	_update_player_blockers_enabled()
	_update_near_flame_audio(delta)


func get_bounds_center() -> Vector3:
	if not is_inside_tree():
		return position + Vector3(0.0, flame_y, 0.0)

	return _get_center_node().global_transform * Vector3(0.0, flame_y, 0.0)


func get_bounds_transform() -> Transform3D:
	if not is_inside_tree():
		return Transform3D(global_basis, get_bounds_center())

	var bounds_transform := _get_center_node().global_transform
	bounds_transform.origin = bounds_transform * Vector3(0.0, flame_y, 0.0)
	return bounds_transform


func get_camera_fit_transform() -> Transform3D:
	var fit_transform := get_bounds_transform()
	var scale_limit := maxf(camera_fit_scale_limit, 0.1)
	fit_transform.basis.x = fit_transform.basis.x.normalized() * minf(fit_transform.basis.x.length(), scale_limit)
	fit_transform.basis.z = fit_transform.basis.z.normalized() * minf(fit_transform.basis.z.length(), scale_limit)
	return fit_transform


func get_bounds_size() -> Vector2:
	if boundary_removed_for_level:
		return Vector2.ZERO

	return bounds_size * runtime_bounds_multiplier


func get_bounds_height() -> float:
	if boundary_removed_for_level:
		return 0.0

	return flame_height


func get_elapsed_time() -> float:
	return elapsed_time


func get_boundary_animation_position() -> float:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null or animation_player.current_animation.is_empty():
		return last_animation_position

	return animation_player.current_animation_position


func get_boundary_animation_duration() -> float:
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return 0.0

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	return animation.length if animation != null else 0.0


func pause_runtime_for(seconds: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	runtime_pause_token += 1
	_set_runtime_motion_paused(true)
	_resume_runtime_motion_after(runtime_pause_token, maxf(seconds, 0.01))
	return true


func expand_runtime_bounds_percent(percent: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	permanent_runtime_bounds_multiplier *= multiplier
	runtime_bounds_multiplier = _get_target_runtime_bounds_multiplier()
	_sync_boundary()
	return true


func expand_runtime_bounds_percent_for(percent: float, active_seconds: float, transition_seconds: float) -> bool:
	if boundary_removed_for_level or not _runtime_effects_enabled():
		return false

	var multiplier := 1.0 + maxf(percent, 0.0) * 0.01
	if multiplier <= 1.0:
		return false

	active_runtime_bounds_multipliers.append(multiplier)
	_animate_runtime_bounds_multiplier(_get_target_runtime_bounds_multiplier(), transition_seconds)
	_restore_runtime_bounds_after(multiplier, active_seconds, transition_seconds)
	return true


func remove_for_level(sink_seconds := 1.0, sink_distance := 3.0) -> bool:
	if boundary_removed_for_level:
		return false

	runtime_pause_token += 1
	if runtime_bounds_tween != null and runtime_bounds_tween.is_valid():
		runtime_bounds_tween.kill()
	_sync_movement_to_animation()
	_sync_boundary()
	boundary_removed_for_level = true
	_set_runtime_effects_enabled(false, true)
	set_process(false)
	_sink_removed_boundary(sink_seconds, sink_distance)
	return true


func _runtime_effects_enabled() -> bool:
	return not boundary_removed_for_level and is_inside_tree() and visible


func _ensure_runtime_effect_nodes() -> void:
	if strip_areas.is_empty():
		_create_strips()
	if near_flame_audio_player == null:
		_create_near_flame_audio()


func _set_runtime_effects_enabled(enabled: bool, keep_visuals := false) -> void:
	if boundary_removed_for_level and enabled:
		return

	for area in strip_areas:
		if is_instance_valid(area):
			area.monitoring = enabled

	for collision in strip_collisions:
		if is_instance_valid(collision):
			collision.disabled = not enabled

	for mesh in strip_meshes:
		if is_instance_valid(mesh):
			mesh.visible = (enabled or keep_visuals) and _is_flame_effect_active()

	for mesh in ghost_meshes:
		if is_instance_valid(mesh):
			mesh.visible = (enabled or keep_visuals) and _is_ghost_effect_active()

	if not enabled:
		flame_touching_bodies.clear()

	for collision in blocker_collisions:
		if is_instance_valid(collision):
			collision.disabled = true if not enabled else not player_blocking_enabled

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player != null:
		if (
			enabled
			and autoplay_boundary_animation
			and animation_player.has_animation(DEFAULT_ANIMATION_NAME)
			and not animation_player.is_playing()
		):
			animation_player.play(DEFAULT_ANIMATION_NAME)
		elif not enabled and keep_visuals:
			animation_player.speed_scale = 1.0
			if (
				autoplay_boundary_animation
				and animation_player.has_animation(DEFAULT_ANIMATION_NAME)
				and not animation_player.is_playing()
			):
				animation_player.play(DEFAULT_ANIMATION_NAME)
		elif not enabled and animation_player.is_playing():
			animation_player.stop(true)

	if near_flame_audio_player != null:
		near_flame_audio_player.stream_paused = not enabled
		if not enabled:
			near_flame_audio_player.volume_db = near_flame_audio_min_db


func begin_runtime_animation() -> void:
	_sync_boundary()
	play_runtime_animation()


func play_runtime_animation() -> void:
	if not autoplay_boundary_animation or not _runtime_effects_enabled():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player != null and animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		movement_cycle_distance = 0.0
		last_animation_position = 0.0
		var center := _get_center_node() as PathFollow3D
		if center != null:
			var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
			_sync_boundary_scale_rotation_to_animation(animation, 0.0)
			_set_center_progress(center, 0.0)
		animation_player.play(DEFAULT_ANIMATION_NAME)


func _ensure_boundary_nodes() -> void:
	if curve == null:
		curve = _create_default_curve()

	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as PathFollow3D
	if center == null:
		center = PathFollow3D.new()
		center.name = BOUNDARY_CENTER_NAME
		add_child(center)
		_set_authored_owner(center)

	_configure_path_follow()

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = ANIMATION_PLAYER_NAME
		add_child(animation_player)
		_set_authored_owner(animation_player)
	animation_player.root_node = NodePath("..")


func _set_authored_owner(node: Node) -> void:
	if not Engine.is_editor_hint():
		return

	var edited_scene_root := get_tree().edited_scene_root
	if edited_scene_root != null and (edited_scene_root == self or edited_scene_root.is_ancestor_of(self)):
		node.owner = edited_scene_root
	elif owner != null:
		node.owner = owner
	else:
		node.owner = self


func _create_default_curve() -> Curve3D:
	var default_curve := Curve3D.new()
	default_curve.add_point(Vector3.ZERO)
	default_curve.add_point(Vector3(4.0, 0.0, 0.0))
	return default_curve


func _configure_path_follow() -> void:
	var path_follow := get_node_or_null(BOUNDARY_CENTER_NAME) as PathFollow3D
	if path_follow == null:
		return

	path_follow.rotation_mode = PathFollow3D.ROTATION_NONE
	path_follow.loop = loop_boundary_path


func _get_center_node() -> Node3D:
	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as Node3D
	if center != null:
		return center

	return self

