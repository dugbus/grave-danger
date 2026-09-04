extends RefCounted
class_name GDPlaythroughPositionSampleCollection

var _session_samples: Dictionary = {}


## Adds one sample, extending the last time range when its position is unchanged.
func add_sample(
	session_id: int,
	level_scene_path: String,
	elapsed_seconds: float,
	position: Vector3
) -> bool:
	if level_scene_path.is_empty() or not level_scene_path.begins_with("res://"):
		return false

	var levels := _session_samples.get(session_id, {}) as Dictionary
	var samples := levels.get(level_scene_path, []) as Array
	var safe_time := maxf(elapsed_seconds, 0.0)
	if not samples.is_empty():
		var last_sample := samples.back() as Dictionary
		var last_position := last_sample.get("position", Vector3.ZERO) as Vector3
		if last_position.is_equal_approx(position):
			last_sample["end_time"] = safe_time
			samples[samples.size() - 1] = last_sample
			levels[level_scene_path] = samples
			_session_samples[session_id] = levels
			return true

	samples.append({
		"start_time": safe_time,
		"end_time": safe_time,
		"position": position,
	})
	levels[level_scene_path] = samples
	_session_samples[session_id] = levels
	return true


## Removes and returns all level samples buffered for one finished debug session.
func take_session(session_id: int) -> Dictionary:
	var levels := _session_samples.get(session_id, {}) as Dictionary
	_session_samples.erase(session_id)
	return levels
