extends RefCounted
class_name GDLevelRunPlaybackDrift

const POSITION_TOLERANCE := 0.05


static func report_due(
	recording: Dictionary,
	playback_level: Node3D,
	playback_time: float,
	checkpoint_index: int,
	warned_paths: Dictionary
) -> int:
	if not OS.is_debug_build() or playback_level == null:
		return checkpoint_index
	var run_metadata := recording.get("run_metadata", {}) as Dictionary
	var checkpoints := run_metadata.get("drift_checkpoints", []) as Array
	while checkpoint_index < checkpoints.size():
		var checkpoint := checkpoints[checkpoint_index] as Dictionary
		if float(checkpoint.get("time", 0.0)) > playback_time:
			return checkpoint_index
		_report_checkpoint(
			playback_level,
			checkpoint,
			String(run_metadata.get("level_id", "unknown")),
			warned_paths
		)
		checkpoint_index += 1
	return checkpoint_index


static func _report_checkpoint(
	playback_level: Node3D,
	checkpoint: Dictionary,
	recorded_level_id: String,
	warned_paths: Dictionary
) -> void:
	var checkpoint_time := float(checkpoint.get("time", 0.0))
	var states := checkpoint.get("states", []) as Array
	for stored_state: Variant in states:
		var state := stored_state as Dictionary
		var stored_path := String(state.get("path", ""))
		if stored_path.is_empty() or warned_paths.has(stored_path):
			continue
		var actual_node := playback_level.get_node_or_null(NodePath(stored_path)) as Node3D
		if actual_node == null:
			push_warning(
				"Run playback drift in level '%s' at %.2fs: missing tracked node '%s'." \
				% [recorded_level_id, checkpoint_time, stored_path]
			)
			warned_paths[stored_path] = true
			continue
		var expected_position := _array_to_vector3(state.get("position", []))
		var position_error := actual_node.global_position.distance_to(expected_position)
		if position_error <= POSITION_TOLERANCE:
			continue
		var warning_text := (
			"Run playback drift in level '%s' at %.2fs: '%s' is %.3fm from its recording "
			+ "(expected %s, actual %s)."
		) % [
			recorded_level_id,
			checkpoint_time,
			stored_path,
			position_error,
			expected_position,
			actual_node.global_position,
		]
		push_warning(warning_text)
		warned_paths[stored_path] = true


static func _array_to_vector3(value: Variant) -> Vector3:
	if not value is Array:
		return Vector3.ZERO
	var components := value as Array
	if components.size() != 3:
		return Vector3.ZERO
	return Vector3(float(components[0]), float(components[1]), float(components[2]))
