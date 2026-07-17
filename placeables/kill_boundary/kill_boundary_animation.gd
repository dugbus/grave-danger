@tool
@abstract
extends "res://placeables/kill_boundary/kill_boundary_core.gd"


func _sync_animation_player() -> void:
	if not is_inside_tree():
		return

	_ensure_boundary_nodes()
	if boundary_animation == null:
		boundary_animation = _create_default_animation()
	_upgrade_boundary_animation_tracks(boundary_animation)

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null:
		return

	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")
	var library := AnimationLibrary.new()
	library.add_animation(DEFAULT_ANIMATION_NAME, boundary_animation)
	animation_player.add_animation_library("", library)
	animation_player.assigned_animation = DEFAULT_ANIMATION_NAME


func _create_default_animation() -> Animation:
	var animation := Animation.new()
	animation.resource_name = String(DEFAULT_ANIMATION_NAME)
	var animation_duration := _get_default_animation_duration()
	animation.length = animation_duration
	animation.loop_mode = Animation.LOOP_LINEAR

	var movement_speed_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(movement_speed_track, MOVEMENT_SPEED_TRACK_PATH)
	animation.track_set_interpolation_loop_wrap(movement_speed_track, false)
	animation.track_insert_key(movement_speed_track, 0.0, movement_speed)

	var size_x_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(size_x_track, BOUNDARY_SIZE_X_TRACK_PATH)
	animation.track_insert_key(size_x_track, 0.0, DEFAULT_ANIMATED_BOUNDARY_SIZE)
	animation.track_insert_key(size_x_track, animation_duration, DEFAULT_ANIMATED_BOUNDARY_SIZE)

	var size_y_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(size_y_track, BOUNDARY_SIZE_Y_TRACK_PATH)
	animation.track_insert_key(size_y_track, 0.0, DEFAULT_ANIMATED_BOUNDARY_SIZE)
	animation.track_insert_key(size_y_track, animation_duration, DEFAULT_ANIMATED_BOUNDARY_SIZE)

	var rotation_z_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(rotation_z_track, BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH)
	animation.track_insert_key(rotation_z_track, 0.0, boundary_rotation_z_radians)
	animation.track_insert_key(rotation_z_track, animation_duration, boundary_rotation_z_radians)

	var shape_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(shape_track, NodePath(".:shape_morph"))
	animation.track_insert_key(shape_track, 0.0, shape_morph)
	animation.track_insert_key(shape_track, animation_duration, shape_morph)
	return animation


func _get_default_animation_duration() -> float:
	if curve == null or movement_speed <= 0.0001:
		return 0.1
	return maxf(curve.get_baked_length() / movement_speed, 0.1)


func _sync_movement_to_animation() -> void:
	if not is_inside_tree():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	var center := _get_center_node() as PathFollow3D
	if animation_player == null or center == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	if animation_player.current_animation.is_empty():
		return
	var animation_position := animation_player.current_animation_position
	if (
		not Engine.is_editor_hint()
		and animation_player.is_playing()
		and animation_position + 0.001 < last_animation_position
	):
		movement_cycle_distance += _calculate_travel_distance(animation, animation.length)

	_sync_boundary_scale_rotation_to_animation(animation, animation_position)
	_set_center_progress(center, movement_cycle_distance + _calculate_travel_distance(animation, animation_position))
	last_animation_position = animation_position


func _update_removed_boundary_visuals(delta: float) -> void:
	elapsed_time += delta
	runtime_effect_time += delta
	_sync_movement_to_animation()
	_sync_boundary(true)
	_update_ghost_billboards()


func _sync_editor_preview_animation() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	var center := _get_center_node() as PathFollow3D
	if animation_player == null or center == null or not animation_player.has_animation(DEFAULT_ANIMATION_NAME):
		return

	var animation := animation_player.get_animation(DEFAULT_ANIMATION_NAME)
	var preview_time := _get_editor_preview_time(animation_player, animation)
	_sync_boundary_scale_rotation_to_animation(animation, preview_time)
	_set_center_progress(center, _calculate_travel_distance(animation, preview_time))
	last_animation_position = preview_time


## Moves the editor animation preview to the arrival time for the requested path point.
## Returns the preview time, or `-1.0` when the point cannot be previewed.
func preview_path_point_in_animation(point_index: int) -> float:
	if not Engine.is_editor_hint() or curve == null:
		return -1.0
	if point_index < 0 or point_index >= curve.point_count:
		return -1.0

	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	if animation_player == null or boundary_animation == null:
		return -1.0

	_sync_path_point_animation_markers()
	var marker_name := StringName(PATH_POINT_MARKER_PREFIX + str(point_index + 1))
	if not boundary_animation.has_marker(marker_name):
		return -1.0

	var point_time := boundary_animation.get_marker_time(marker_name)
	animation_player.assigned_animation = DEFAULT_ANIMATION_NAME
	animation_player.seek(point_time, true)
	editor_preview_time = point_time
	editor_preview_initialized = true
	_sync_editor_preview_animation()
	return point_time


func _set_center_progress(center: PathFollow3D, target_progress: float) -> void:
	var sanitized_progress := maxf(target_progress, 0.0)
	if Engine.is_editor_hint() and is_zero_approx(sanitized_progress) and is_zero_approx(center.progress):
		center.progress = 0.001
	center.progress = sanitized_progress
	_apply_boundary_scale_rotation()


func _apply_boundary_scale_rotation() -> void:
	var center := get_node_or_null(BOUNDARY_CENTER_NAME) as Node3D
	if center == null:
		return

	center.scale = Vector3(boundary_scale_x, 1.0, boundary_scale_z)
	center.rotation = Vector3(0.0, boundary_rotation_z_radians, 0.0)


func _sync_boundary_scale_rotation_to_animation(animation: Animation, time: float) -> void:
	var sample_time := clampf(time, 0.0, animation.length)
	boundary_scale_x = _sample_float_animation_track(
		animation,
		BOUNDARY_SCALE_X_TRACK_PATH,
		sample_time,
		IDENTITY_BOUNDARY_SCALE
	)
	boundary_scale_z = _sample_float_animation_track(
		animation,
		BOUNDARY_SCALE_Z_TRACK_PATH,
		sample_time,
		IDENTITY_BOUNDARY_SCALE
	)
	boundary_rotation_z_radians = _sample_float_animation_track(
		animation,
		BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH,
		sample_time,
		0.0
	)


func _sample_float_animation_track(
	animation: Animation,
	track_path: NodePath,
	time: float,
	fallback: float
) -> float:
	var track := animation.find_track(track_path, Animation.TYPE_VALUE)
	if track < 0 or animation.track_get_key_count(track) == 0:
		return fallback

	var sampled_value: Variant = animation.value_track_interpolate(track, time)
	if typeof(sampled_value) != TYPE_FLOAT and typeof(sampled_value) != TYPE_INT:
		return fallback
	return float(sampled_value)


func _upgrade_boundary_animation_tracks(animation: Animation) -> void:
	var legacy_vector_track := animation.find_track(LEGACY_SCALE_ROTATION_TARGET_TRACK_PATH, Animation.TYPE_VALUE)
	if legacy_vector_track >= 0:
		_upgrade_boundary_scale_rotation_tracks_from_source(animation, legacy_vector_track, true)
		animation.remove_track(legacy_vector_track)

	var legacy_scale_track := animation.find_track(LEGACY_SCALE_TRACK_PATH, Animation.TYPE_SCALE_3D)
	if legacy_scale_track >= 0:
		_upgrade_boundary_scale_rotation_tracks_from_source(animation, legacy_scale_track, false)
		animation.remove_track(legacy_scale_track)

	_ensure_boundary_size_tracks(animation)


func _ensure_boundary_size_tracks(animation: Animation) -> void:
	if animation.find_track(BOUNDARY_SIZE_X_TRACK_PATH, Animation.TYPE_VALUE) < 0:
		_add_default_boundary_size_track(animation, BOUNDARY_SIZE_X_TRACK_PATH, boundary_size_x)
	if animation.find_track(BOUNDARY_SIZE_Y_TRACK_PATH, Animation.TYPE_VALUE) < 0:
		_add_default_boundary_size_track(animation, BOUNDARY_SIZE_Y_TRACK_PATH, boundary_size_y)


func _add_default_boundary_size_track(animation: Animation, track_path: NodePath, size: float) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, track_path)
	animation.track_set_interpolation_loop_wrap(track, true)
	animation.track_insert_key(track, 0.0, size)
	animation.track_insert_key(track, animation.length, size)


func _upgrade_boundary_scale_rotation_tracks_from_source(
	animation: Animation,
	source_track: int,
	source_has_rotation: bool
) -> void:
	if _has_boundary_scale_rotation_tracks(animation):
		return

	var scale_x_track := _add_boundary_value_track(animation, BOUNDARY_SCALE_X_TRACK_PATH, source_track)
	var scale_z_track := _add_boundary_value_track(animation, BOUNDARY_SCALE_Z_TRACK_PATH, source_track)
	var rotation_z_track := _add_boundary_value_track(animation, BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH, source_track)

	for key_index in animation.track_get_key_count(source_track):
		var key_time := animation.track_get_key_time(source_track, key_index)
		var key_transition := animation.track_get_key_transition(source_track, key_index)
		var source_value := animation.track_get_key_value(source_track, key_index) as Vector3
		var scale_x := source_value.x
		var scale_z := source_value.y if source_has_rotation else source_value.z
		var rotation_z := source_value.z if source_has_rotation else 0.0
		animation.track_insert_key(scale_x_track, key_time, scale_x, key_transition)
		animation.track_insert_key(scale_z_track, key_time, scale_z, key_transition)
		animation.track_insert_key(rotation_z_track, key_time, rotation_z, key_transition)


func _has_boundary_scale_rotation_tracks(animation: Animation) -> bool:
	return (
		animation.find_track(BOUNDARY_SCALE_X_TRACK_PATH, Animation.TYPE_VALUE) >= 0
		and animation.find_track(BOUNDARY_SCALE_Z_TRACK_PATH, Animation.TYPE_VALUE) >= 0
		and animation.find_track(BOUNDARY_ROTATION_Z_RADIANS_TRACK_PATH, Animation.TYPE_VALUE) >= 0
	)


func _add_boundary_value_track(animation: Animation, track_path: NodePath, source_track: int) -> int:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, track_path)
	animation.track_set_interpolation_type(track, animation.track_get_interpolation_type(source_track))
	animation.track_set_interpolation_loop_wrap(
		track,
		animation.track_get_interpolation_loop_wrap(source_track)
	)
	return track


func _get_editor_preview_time(animation_player: AnimationPlayer, animation: Animation) -> float:
	if editor_preview_animation != animation:
		editor_preview_animation = animation
		editor_preview_initialized = false

	if not editor_preview_initialized:
		editor_preview_time = _get_first_animation_key_time(animation)
		editor_preview_initialized = true

	if (
		animation_player.current_animation == DEFAULT_ANIMATION_NAME
		and (
			animation_player.is_playing()
			or absf(animation_player.current_animation_position - editor_preview_time) >= EDITOR_SCRUB_TIME_EPSILON
		)
	):
		editor_preview_time = animation_player.current_animation_position

	return clampf(editor_preview_time, 0.0, animation.length)


func _get_first_animation_key_time(animation: Animation) -> float:
	var first_key_time := INF
	for track_index in animation.get_track_count():
		if animation.track_get_key_count(track_index) == 0:
			continue

		first_key_time = minf(first_key_time, animation.track_get_key_time(track_index, 0))

	if is_inf(first_key_time):
		return 0.0

	return clampf(first_key_time, 0.0, animation.length)


func _calculate_travel_distance(animation: Animation, time: float) -> float:
	var speed_track := animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	if speed_track < 0:
		return maxf(movement_speed, 0.0) * maxf(time, 0.0)

	var key_count := animation.track_get_key_count(speed_track)
	if key_count == 0:
		return maxf(movement_speed, 0.0) * maxf(time, 0.0)
	if key_count == 1:
		return maxf(float(animation.track_get_key_value(speed_track, 0)), 0.0) * maxf(time, 0.0)

	var target_time := clampf(time, 0.0, animation.length)
	var distance := 0.0
	var interval_start := 0.0
	for key_index in key_count:
		var key_time := animation.track_get_key_time(speed_track, key_index)
		if key_time > interval_start:
			var interval_end := minf(key_time, target_time)
			if interval_end > interval_start:
				distance += _integrate_speed_interval(animation, speed_track, interval_start, interval_end)
		if key_time >= target_time:
			return distance
		interval_start = key_time

	if target_time > interval_start:
		distance += _integrate_speed_interval(animation, speed_track, interval_start, target_time)
	return distance


func _sync_path_point_animation_markers() -> void:
	if boundary_animation == null or curve == null:
		return

	_ensure_animation_reaches_path_end(boundary_animation)
	var desired_markers: Dictionary[StringName, float] = {}
	for point_index in curve.point_count:
		var point_position := curve.get_point_position(point_index)
		var point_distance := curve.get_closest_offset(point_position)
		var marker_time := _find_time_for_travel_distance(boundary_animation, point_distance)
		if marker_time >= 0.0:
			var marker_name := StringName(PATH_POINT_MARKER_PREFIX + str(point_index + 1))
			desired_markers[marker_name] = marker_time

	for existing_name_string in boundary_animation.get_marker_names():
		var existing_name := StringName(existing_name_string)
		if (
			String(existing_name).begins_with(PATH_POINT_MARKER_PREFIX)
			and not desired_markers.has(existing_name)
		):
			boundary_animation.remove_marker(existing_name)

	for marker_name in desired_markers:
		var marker_time := desired_markers[marker_name]
		if boundary_animation.has_marker(marker_name):
			var time_matches := is_equal_approx(boundary_animation.get_marker_time(marker_name), marker_time)
			var color_matches := boundary_animation.get_marker_color(marker_name).is_equal_approx(PATH_POINT_MARKER_COLOR)
			if time_matches and color_matches:
				continue
			boundary_animation.remove_marker(marker_name)
		boundary_animation.add_marker(marker_name, marker_time)
		boundary_animation.set_marker_color(marker_name, PATH_POINT_MARKER_COLOR)


func _ensure_animation_reaches_path_end(animation: Animation) -> bool:
	var path_length := curve.get_baked_length()
	var current_distance := _calculate_travel_distance(animation, animation.length)
	if current_distance >= path_length - 0.001:
		return false

	var final_speed := _sample_float_animation_track(
		animation,
		MOVEMENT_SPEED_TRACK_PATH,
		animation.length,
		movement_speed
	)
	final_speed = maxf(final_speed, 0.0)
	if final_speed <= 0.0001:
		return false

	var additional_duration := (path_length - current_distance) / final_speed
	animation.length += additional_duration
	return true


func _update_path_point_animation_markers(delta: float) -> void:
	var source_signature := _get_path_marker_source_signature()
	if source_signature != editor_path_marker_observed_signature:
		editor_path_marker_observed_signature = source_signature
		editor_path_marker_stable_time = 0.0
		return

	if source_signature == editor_path_marker_synced_signature:
		return

	editor_path_marker_stable_time += delta
	if (
		editor_path_marker_stable_time < EDITOR_PATH_MARKER_REFRESH_DELAY
		or not _is_editor_animation_edit_safe()
	):
		return

	_sync_path_point_animation_markers()
	editor_path_marker_synced_signature = source_signature


func _update_speed_change_ripple_retime(delta: float) -> void:
	if boundary_animation == null:
		return

	var speed_signature := _get_speed_track_signature(boundary_animation)
	if editor_speed_animation_snapshot == null:
		editor_speed_animation_snapshot = boundary_animation.duplicate(true) as Animation
		editor_speed_observed_signature = speed_signature
		return

	if speed_signature != editor_speed_observed_signature:
		editor_speed_observed_signature = speed_signature
		editor_speed_stable_time = 0.0
		return

	if speed_signature == _get_speed_track_signature(editor_speed_animation_snapshot):
		return

	editor_speed_stable_time += delta
	if (
		editor_speed_stable_time < EDITOR_PATH_MARKER_REFRESH_DELAY
		or not _is_editor_animation_edit_safe()
	):
		return

	if ripple_retime_after_speed_key_edit:
		_ripple_retime_tracks_after_speed_change(editor_speed_animation_snapshot, boundary_animation)
	editor_speed_animation_snapshot = boundary_animation.duplicate(true) as Animation
	editor_speed_observed_signature = _get_speed_track_signature(boundary_animation)
	editor_speed_stable_time = 0.0
