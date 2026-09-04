@tool
extends EditorDebuggerPlugin
class_name GDPlaythroughPositionEditorDebugger

signal position_sample_received(
	session_id: int,
	level_scene_path: String,
	elapsed_seconds: float,
	local_position: Vector3
)
signal playthrough_finished(session_id: int)

const CAPTURE_PREFIX := "playthrough_position_markers"
const SAMPLE_MESSAGE := "playthrough_position_markers:sample"


func _has_capture(capture: String) -> bool:
	return capture == CAPTURE_PREFIX


func _capture(message: String, data: Array, session_id: int) -> bool:
	return capture_message(message, data, session_id)


func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	if session != null:
		session.stopped.connect(_on_session_stopped.bind(session_id))


## Validates and forwards one namespaced game message to the editor plugin.
func capture_message(message: String, data: Array, session_id: int) -> bool:
	if message != SAMPLE_MESSAGE:
		return false
	if data.size() != 3 or not data[0] is String \
			or not data[1] is float or not data[2] is Vector3:
		return true
	position_sample_received.emit(
		session_id,
		data[0] as String,
		data[1] as float,
		data[2] as Vector3
	)
	return true


func _on_session_stopped(session_id: int) -> void:
	playthrough_finished.emit(session_id)
