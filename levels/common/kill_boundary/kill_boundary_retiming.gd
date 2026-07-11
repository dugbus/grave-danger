@tool
@abstract
extends "res://levels/common/kill_boundary/kill_boundary_animation.gd"


func _get_speed_track_signature(animation: Animation) -> String:
	var speed_track := animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	if speed_track < 0:
		return ""

	var source_values: Array[Variant] = [animation.track_get_key_count(speed_track)]
	for key_index in animation.track_get_key_count(speed_track):
		source_values.append(animation.track_get_key_time(speed_track, key_index))
		source_values.append(animation.track_get_key_value(speed_track, key_index))
	return var_to_str(source_values)


func _is_editor_animation_edit_safe() -> bool:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return false
	var animation_player := get_node_or_null(ANIMATION_PLAYER_NAME) as AnimationPlayer
	return animation_player == null or not animation_player.is_playing()


func _ripple_retime_tracks_after_speed_change(old_animation: Animation, new_animation: Animation) -> bool:
	var old_speed_track := old_animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	var new_speed_track := new_animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	if old_speed_track < 0 or new_speed_track < 0:
		return false

	var key_count := old_animation.track_get_key_count(old_speed_track)
	if key_count != new_animation.track_get_key_count(new_speed_track):
		return false

	var changed_key_index := -1
	for key_index in key_count:
		var old_time := old_animation.track_get_key_time(old_speed_track, key_index)
		var new_time := new_animation.track_get_key_time(new_speed_track, key_index)
		if not is_equal_approx(old_time, new_time):
			return false
		var old_value := float(old_animation.track_get_key_value(old_speed_track, key_index))
		var new_value := float(new_animation.track_get_key_value(new_speed_track, key_index))
		if not is_equal_approx(old_value, new_value):
			if changed_key_index >= 0:
				return false
			changed_key_index = key_index

	if changed_key_index < 0:
		return false

	var changed_key_time := old_animation.track_get_key_time(old_speed_track, changed_key_index)
	var previous_anchor_time := (
		old_animation.track_get_key_time(old_speed_track, changed_key_index - 1)
		if changed_key_index > 0
		else changed_key_time
	)
	var old_next_anchor_time := (
		old_animation.track_get_key_time(old_speed_track, changed_key_index + 1)
		if changed_key_index + 1 < key_count
		else old_animation.length
	)
	var outgoing_duration := old_next_anchor_time - changed_key_time
	if outgoing_duration <= 0.0001:
		return false

	var incoming_scale := 1.0
	if changed_key_index > 0:
		incoming_scale = _get_distance_preserving_interval_scale(
			old_animation,
			new_animation,
			previous_anchor_time,
			changed_key_time
		)
		if incoming_scale <= 0.0:
			return false

	var outgoing_scale := _get_distance_preserving_interval_scale(
		old_animation,
		new_animation,
		changed_key_time,
		old_next_anchor_time
	)
	if outgoing_scale <= 0.0:
		return false

	var new_changed_key_time := (
		previous_anchor_time
		+ (changed_key_time - previous_anchor_time) * incoming_scale
	)
	var new_next_anchor_time := new_changed_key_time + outgoing_duration * outgoing_scale
	var time_delta := new_next_anchor_time - old_next_anchor_time
	_retime_animation_keys_for_speed_intervals(
		new_animation,
		previous_anchor_time,
		changed_key_time,
		old_next_anchor_time,
		new_changed_key_time,
		incoming_scale,
		outgoing_scale,
		time_delta
	)
	_retime_animation_markers_for_speed_intervals(
		new_animation,
		previous_anchor_time,
		changed_key_time,
		old_next_anchor_time,
		new_changed_key_time,
		incoming_scale,
		outgoing_scale,
		time_delta
	)
	return true


func _get_distance_preserving_interval_scale(
	old_animation: Animation,
	new_animation: Animation,
	interval_start: float,
	interval_end: float
) -> float:
	var old_distance := (
		_calculate_travel_distance(old_animation, interval_end)
		- _calculate_travel_distance(old_animation, interval_start)
	)
	var new_distance := (
		_calculate_travel_distance(new_animation, interval_end)
		- _calculate_travel_distance(new_animation, interval_start)
	)
	if old_distance <= 0.0001 or new_distance <= 0.0001:
		return -1.0
	return old_distance / new_distance


func _retime_animation_keys_for_speed_intervals(
	animation: Animation,
	previous_anchor_time: float,
	changed_key_time: float,
	old_next_anchor_time: float,
	new_changed_key_time: float,
	incoming_scale: float,
	outgoing_scale: float,
	time_delta: float
) -> void:
	var new_length := maxf(animation.length + time_delta, 0.1)
	if time_delta > 0.0:
		animation.length = new_length

	for track_index in animation.get_track_count():
		var key_times: Array[float] = []
		var target_times: Array[float] = []
		for key_index in animation.track_get_key_count(track_index):
			var old_key_time := animation.track_get_key_time(track_index, key_index)
			key_times.append(old_key_time)
			target_times.append(_map_two_sided_ripple_retime(
				old_key_time,
				previous_anchor_time,
				changed_key_time,
				old_next_anchor_time,
				new_changed_key_time,
				incoming_scale,
				outgoing_scale,
				time_delta
			))

		for key_index in key_times.size():
			if target_times[key_index] < key_times[key_index]:
				animation.track_set_key_time(track_index, key_index, target_times[key_index])
		for key_index in range(key_times.size() - 1, -1, -1):
			if target_times[key_index] > key_times[key_index]:
				animation.track_set_key_time(track_index, key_index, target_times[key_index])

	if time_delta <= 0.0:
		animation.length = new_length


func _retime_animation_markers_for_speed_intervals(
	animation: Animation,
	previous_anchor_time: float,
	changed_key_time: float,
	old_next_anchor_time: float,
	new_changed_key_time: float,
	incoming_scale: float,
	outgoing_scale: float,
	time_delta: float
) -> void:
	var marker_names := animation.get_marker_names()
	for marker_name_string in marker_names:
		var marker_name := StringName(marker_name_string)
		var old_marker_time := animation.get_marker_time(marker_name)
		var new_marker_time := _map_two_sided_ripple_retime(
			old_marker_time,
			previous_anchor_time,
			changed_key_time,
			old_next_anchor_time,
			new_changed_key_time,
			incoming_scale,
			outgoing_scale,
			time_delta
		)
		if is_equal_approx(old_marker_time, new_marker_time):
			continue
		var marker_color := animation.get_marker_color(marker_name)
		animation.remove_marker(marker_name)
		animation.add_marker(marker_name, new_marker_time)
		animation.set_marker_color(marker_name, marker_color)


func _map_two_sided_ripple_retime(
	time: float,
	previous_anchor_time: float,
	changed_key_time: float,
	old_next_anchor_time: float,
	new_changed_key_time: float,
	incoming_scale: float,
	outgoing_scale: float,
	time_delta: float
) -> float:
	if time <= previous_anchor_time:
		return time
	if time <= changed_key_time:
		return previous_anchor_time + (time - previous_anchor_time) * incoming_scale
	if time < old_next_anchor_time:
		return new_changed_key_time + (time - changed_key_time) * outgoing_scale
	return time + time_delta


func _get_path_marker_source_signature() -> String:
	if boundary_animation == null or curve == null:
		return ""

	var source_values: Array[Variant] = [boundary_animation.length, curve.point_count]
	for point_index in curve.point_count:
		source_values.append(curve.get_point_position(point_index))

	var speed_track := boundary_animation.find_track(MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE)
	if speed_track >= 0:
		for key_index in boundary_animation.track_get_key_count(speed_track):
			source_values.append(boundary_animation.track_get_key_time(speed_track, key_index))
			source_values.append(boundary_animation.track_get_key_value(speed_track, key_index))
	return var_to_str(source_values)


func _find_time_for_travel_distance(animation: Animation, target_distance: float) -> float:
	if target_distance <= 0.0:
		return 0.0
	if _calculate_travel_distance(animation, animation.length) < target_distance:
		return -1.0

	var low_time := 0.0
	var high_time := animation.length
	for _iteration in 24:
		var midpoint := (low_time + high_time) * 0.5
		if _calculate_travel_distance(animation, midpoint) < target_distance:
			low_time = midpoint
		else:
			high_time = midpoint
	return high_time


func _integrate_speed_interval(animation: Animation, speed_track: int, start_time: float, end_time: float) -> float:
	const SAMPLE_COUNT := 8
	var step := (end_time - start_time) / float(SAMPLE_COUNT)
	var weighted_speed := 0.0
	for sample_index in SAMPLE_COUNT + 1:
		var sample_time := start_time + step * float(sample_index)
		var speed := maxf(float(animation.value_track_interpolate(speed_track, sample_time)), 0.0)
		var weight := 1.0 if sample_index == 0 or sample_index == SAMPLE_COUNT else (4.0 if sample_index % 2 == 1 else 2.0)
		weighted_speed += speed * weight
	return weighted_speed * step / 3.0


