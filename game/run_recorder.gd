extends Node
class_name GDRunRecorder

## Captures one compact sample after every gameplay physics frame and saves it per level.

signal repository_feedback_status(message: String, succeeded: bool)

const RUN_RECORDING := preload("res://game/run_recording.gd")
const FEEDBACK_REPORT_STORE := preload(
    "res://ui/hud/player_feedback/player_feedback_report_store.gd"
)
const FrameEncoder := preload("res://game/run_frame_encoder.gd")
const DriftTracker := preload("res://game/run_drift_tracker.gd")
# Public sizing constants retained for recorder diagnostics and long-lived tests.
const INITIAL_BUFFER_SIZE := FrameEncoder.INITIAL_BUFFER_SIZE
const NORMAL_FRAME_SIZE := FrameEncoder.NORMAL_FRAME_SIZE
const ABSOLUTE_FRAME_SIZE := FrameEncoder.ABSOLUTE_FRAME_SIZE
const DRIFT_CHECKPOINT_INTERVAL_FRAMES := 60
const LIVE_FEEDBACK_PATH := "user://run_recordings/latest_feedback.json"
const LIVE_FEEDBACK_SAMPLE_INTERVAL_SECONDS := 0.25
const LIVE_FEEDBACK_BEFORE_SECONDS := 2.0
const LIVE_FEEDBACK_AFTER_SECONDS := 3.0
const DEFAULT_REPOSITORY_REPORT_DIRECTORY := "res://feedback/reports"
const DEFAULT_REPOSITORY_ARCHIVE_DIRECTORY := "res://feedback/archive"
const DEFAULT_MAXIMUM_REPOSITORY_REPORTS := 20
const DEFAULT_MAXIMUM_REPOSITORY_BYTES := 25 * 1024 * 1024
const DEFAULT_MAXIMUM_PLAYBACK_BYTES := 5 * 1024 * 1024
const RUN_RECORDER_GROUP: StringName = &"run_recorder"

var level_id := ""
var storage_directory := RUN_RECORDING.STORAGE_DIRECTORY
var live_feedback_path := LIVE_FEEDBACK_PATH
var save_task_owner: Node
var recording_root: Node
var level_scene_path := ""
var player: Node3D
var pivot: Node3D
var camera: Camera3D
var frame_payload := PackedByteArray()
var bytes_used := 0
var frame_count := 0
var camera_fov := 34.0
var previous_player_position := Vector3.ZERO
var previous_camera_position := Vector3.ZERO
var recording_enabled := false
var recording_saved := false
var save_task_id := -1
var recording_elapsed_seconds := 0.0
var run_settings: Dictionary = {}
var session_context: Dictionary = {}
var drift_nodes: Dictionary = {}
var drift_node_paths: Array[String] = []
var drift_checkpoints: Array[Dictionary] = []
var feedback_markers: Array[Dictionary] = []
var live_feedback_samples: Array[Dictionary] = []
var last_live_feedback_sample_seconds := -LIVE_FEEDBACK_SAMPLE_INTERVAL_SECONDS
var active_live_feedback_marker: Dictionary = {}
var repository_report_directory := DEFAULT_REPOSITORY_REPORT_DIRECTORY
var repository_archive_directory := DEFAULT_REPOSITORY_ARCHIVE_DIRECTORY
var maximum_repository_reports := DEFAULT_MAXIMUM_REPOSITORY_REPORTS
var maximum_repository_bytes := DEFAULT_MAXIMUM_REPOSITORY_BYTES
var maximum_playback_bytes := DEFAULT_MAXIMUM_PLAYBACK_BYTES
var latest_repository_report_id := ""
var repository_report_due_seconds := -1.0
var repository_report_finalized := false
var _frame_encoder := FrameEncoder.new()
var _drift_tracker := DriftTracker.new()


func _ready() -> void:
	add_to_group(RUN_RECORDER_GROUP)


func begin_recording(
	recorded_level_id: String,
	player_node: Node3D,
	camera_node: Camera3D,
	recording_save_task_owner: Node = null,
	recorded_root: Node = null,
	recorded_run_settings: Dictionary = {},
	recorded_session_context: Dictionary = {}
) -> bool:
	if recorded_level_id.is_empty() or player_node == null:
		return false

	level_id = recorded_level_id
	player = player_node
	save_task_owner = recording_save_task_owner
	recording_root = recorded_root
	level_scene_path = recording_root.scene_file_path if recording_root != null else ""
	run_settings = recorded_run_settings.duplicate(true)
	session_context = recorded_session_context.duplicate(true)
	pivot = player.get_node_or_null(^"Pivot") as Node3D
	camera = camera_node
	camera_fov = camera.fov if camera != null else camera_fov
	_frame_encoder.reset()
	_sync_encoder_state()
	_discover_drift_nodes()
	recording_enabled = true
	set_physics_process(true)
	return true


func _physics_process(delta: float) -> void:
	if not recording_enabled or player == null:
		return

	if not is_instance_valid(camera) or not camera.current:
		camera = get_viewport().get_camera_3d()
	if camera != null:
		camera_fov = camera.fov

	var movement_input := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down"
	)
	var camera_input := Vector2(
		Input.get_axis(&"camera_rotate_left", &"camera_rotate_right"),
		Input.get_axis(&"camera_zoom_in", &"camera_zoom_out")
	)
	capture_sample(
		delta,
		movement_input,
		camera_input,
		Input.is_action_pressed(&"jump"),
		Input.is_action_pressed(&"drop_carried"),
		player.global_position,
		pivot.rotation.y if pivot != null else 0.0,
		camera.global_transform if camera != null else Transform3D.IDENTITY,
		camera != null
	)


func capture_sample(
	delta: float,
	movement_input: Vector2,
	camera_input: Vector2,
	jump_pressed: bool,
	drop_pressed: bool,
	player_position: Vector3,
	player_yaw: float,
	camera_transform: Transform3D,
	camera_available: bool = true
) -> void:
	var frame_index := frame_count
	var frame_time := recording_elapsed_seconds
	_frame_encoder.encode_frame(
		frame_count == 0,
		delta,
		movement_input,
		camera_input,
		jump_pressed,
		drop_pressed,
		player_position,
		player_yaw,
		camera_transform,
		camera_available
	)
	_sync_encoder_state()
	frame_count += 1
	recording_elapsed_seconds += delta
	_capture_live_feedback_sample(
		movement_input,
		camera_input,
		jump_pressed,
		drop_pressed,
		player_position
	)
	if frame_index % DRIFT_CHECKPOINT_INTERVAL_FRAMES == 0:
		_capture_drift_checkpoint(frame_index, frame_time)


func finish_recording(save_to_disk: bool = true) -> PackedByteArray:
	if recording_saved:
		return frame_payload
	_finalize_repository_feedback_report()
	recording_enabled = false
	set_physics_process(false)
	if save_to_disk and frame_count > 0:
		var run_metadata := _take_run_metadata()
		save_task_id = RUN_RECORDING.queue_save_for_level(
			level_id,
			frame_payload,
			frame_count,
			camera_fov,
			storage_directory,
			run_metadata,
			bytes_used
		)
		if save_task_id == RUN_RECORDING.INVALID_TASK_ID:
			frame_payload.resize(bytes_used)
			push_warning("Could not queue run recording save for level '%s'." % level_id)
		else:
			if is_instance_valid(save_task_owner) \
					and save_task_owner.has_method("register_run_recording_save_task"):
				save_task_owner.register_run_recording_save_task(level_id, save_task_id)
			frame_payload = PackedByteArray()
	else:
		frame_payload.resize(bytes_used)
	recording_saved = true
	return frame_payload


func get_save_task_id() -> int:
	return save_task_id


## Applies the shared repository location and retention limits for player bug reports.
func configure_feedback_repository(feedback_settings: Resource) -> void:
	if feedback_settings == null:
		return
	repository_report_directory = String(feedback_settings.get(
        "repository_report_directory"
	))
	repository_archive_directory = String(feedback_settings.get(
        "repository_archive_directory"
	))
	maximum_repository_reports = int(feedback_settings.get(
        "maximum_repository_reports"
	))
	maximum_repository_bytes = roundi(
		float(feedback_settings.get("maximum_repository_mebibytes")) * 1024.0 * 1024.0
	)
	maximum_playback_bytes = roundi(
		float(feedback_settings.get("maximum_playback_mebibytes")) * 1024.0 * 1024.0
	)


## Marks one recorded frame with a compact state snapshot for focused Codex inspection.
func mark_feedback(note: String, snapshot: Dictionary = {}) -> void:
	if not recording_enabled:
		return
	if not latest_repository_report_id.is_empty() and not repository_report_finalized:
		_finalize_repository_feedback_report()
	feedback_markers.append({
		"frame": maxi(frame_count - 1, 0),
		"time": recording_elapsed_seconds,
		"created_unix_time": int(Time.get_unix_time_from_system()),
		"note": note.strip_edges(),
		"snapshot": snapshot.duplicate(true),
	})
	active_live_feedback_marker = feedback_markers[-1]
	latest_repository_report_id = FEEDBACK_REPORT_STORE.create_report(
		repository_report_directory,
		repository_archive_directory,
		level_id,
		active_live_feedback_marker,
		maximum_repository_reports,
		maximum_repository_bytes,
		level_scene_path
	)
	if not latest_repository_report_id.is_empty():
		active_live_feedback_marker["report_id"] = latest_repository_report_id
		feedback_markers[-1] = active_live_feedback_marker
		repository_report_due_seconds = recording_elapsed_seconds \
			+ LIVE_FEEDBACK_AFTER_SECONDS
		repository_report_finalized = false
		repository_feedback_status.emit(
			"BUG REPORT MARKED",
			true
		)
	else:
		repository_feedback_status.emit(
			"FEEDBACK MARKED LOCALLY — REPORT STORAGE FULL",
			false
		)
	_write_live_feedback()


## Attaches optional written context to the newest marker without creating another report.
func update_latest_feedback_note(note: String) -> void:
	if feedback_markers.is_empty():
		return
	var clean_note := note.strip_edges()
	feedback_markers[-1]["note"] = clean_note
	active_live_feedback_marker = feedback_markers[-1]
	_write_live_feedback()
	if latest_repository_report_id.is_empty():
		return
	FEEDBACK_REPORT_STORE.update_report_note(
		repository_report_directory,
		latest_repository_report_id,
		clean_note
	)
	if repository_report_finalized:
		_finalize_repository_feedback_report(true)


func _exit_tree() -> void:
	finish_recording()


func _discover_drift_nodes() -> void:
	_drift_tracker.discover(recording_root)
	drift_nodes = _drift_tracker.tracked_nodes
	drift_node_paths = _drift_tracker.tracked_paths


func _capture_drift_checkpoint(frame_index: int, frame_time: float) -> void:
	# Preserve the public configuration seam used by callers that prepare drift
	# tracking directly before requesting a checkpoint.
	_drift_tracker.tracked_nodes = drift_nodes
	_drift_tracker.tracked_paths = drift_node_paths
	var checkpoint := _drift_tracker.capture(frame_index, frame_time)
	if not checkpoint.is_empty():
		drift_checkpoints.append(checkpoint)


func _capture_live_feedback_sample(
	movement_input: Vector2,
	camera_input: Vector2,
	jump_pressed: bool,
	drop_pressed: bool,
	player_position: Vector3
) -> void:
	if recording_elapsed_seconds - last_live_feedback_sample_seconds \
			< LIVE_FEEDBACK_SAMPLE_INTERVAL_SECONDS:
		return
	last_live_feedback_sample_seconds = recording_elapsed_seconds
	live_feedback_samples.append({
		"time": recording_elapsed_seconds,
		"frame": maxi(frame_count - 1, 0),
		"position": _vector3_to_array(player_position),
		"movement": [movement_input.x, movement_input.y],
		"camera_control": [camera_input.x, camera_input.y],
		"jump": jump_pressed,
		"drop": drop_pressed,
	})
	var keep_after := recording_elapsed_seconds - LIVE_FEEDBACK_BEFORE_SECONDS
	if not active_live_feedback_marker.is_empty():
		keep_after = minf(
			keep_after,
			float(active_live_feedback_marker.get("time", 0.0)) \
				- LIVE_FEEDBACK_BEFORE_SECONDS
		)
	while live_feedback_samples.size() > 1 \
			and float(live_feedback_samples[0].get("time", 0.0)) < keep_after:
		live_feedback_samples.pop_front()
	if active_live_feedback_marker.is_empty():
		_finalize_repository_feedback_report_if_due()
		return
	_write_live_feedback()
	_finalize_repository_feedback_report_if_due()
	if recording_elapsed_seconds >= float(
		active_live_feedback_marker.get("time", 0.0)
	) + LIVE_FEEDBACK_AFTER_SECONDS:
		active_live_feedback_marker = {}


func _write_live_feedback() -> void:
	if active_live_feedback_marker.is_empty():
		return
	var directory := live_feedback_path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(directory) != OK \
			and not DirAccess.dir_exists_absolute(directory):
		push_warning("Could not create the live player feedback directory.")
		return
	var feedback_file := FileAccess.open(live_feedback_path, FileAccess.WRITE)
	if feedback_file == null:
		push_warning("Could not write the live player feedback marker.")
		return
	feedback_file.store_string(JSON.stringify({
		"level_id": level_id,
		"marker": active_live_feedback_marker,
		"samples": live_feedback_samples,
	}))


func _finalize_repository_feedback_report_if_due() -> void:
	if repository_report_due_seconds < 0.0 \
			or recording_elapsed_seconds < repository_report_due_seconds:
		return
	_finalize_repository_feedback_report()


func _finalize_repository_feedback_report(force_overwrite: bool = false) -> void:
	if latest_repository_report_id.is_empty() \
			or (repository_report_finalized and not force_overwrite) \
			or frame_count <= 0:
		return
	var report_marker := feedback_markers[-1] if not feedback_markers.is_empty() else {}
	var report_metadata := {
		"level_id": level_id,
		"settings": run_settings.duplicate(true),
		"session": session_context.duplicate(true),
		"feedback_markers": [report_marker.duplicate(true)],
		"drift_checkpoints": drift_checkpoints.duplicate(true),
		"report_capture_time": recording_elapsed_seconds,
	}
	var playback_saved := bool(FEEDBACK_REPORT_STORE.save_report_playback(
		repository_report_directory,
		repository_archive_directory,
		latest_repository_report_id,
		frame_payload,
		frame_count,
		camera_fov,
		report_metadata,
		bytes_used,
		maximum_playback_bytes,
		maximum_repository_reports,
		maximum_repository_bytes
	))
	repository_report_finalized = true
	repository_report_due_seconds = -1.0
	repository_feedback_status.emit(
        "BUG REPORT READY TO COMMIT"
		if playback_saved else "BUG REPORT SAVED WITHOUT PLAYBACK",
		playback_saved
	)


func _take_run_metadata() -> Dictionary:
	var run_metadata := {
		"level_id": level_id,
		"settings": run_settings,
		"drift_checkpoints": drift_checkpoints,
		"feedback_markers": feedback_markers,
	}
	if not session_context.is_empty():
		run_metadata["session"] = session_context
	# Recording has stopped, so transfer these immutable containers to the save worker instead
	# of deep-copying potentially several minutes of checkpoint data on the gameplay thread.
	run_settings = {}
	session_context = {}
	drift_checkpoints = []
	feedback_markers = []
	return run_metadata


func _sync_encoder_state() -> void:
	frame_payload = _frame_encoder.payload
	bytes_used = _frame_encoder.bytes_used
	previous_player_position = _frame_encoder.previous_player_position
	previous_camera_position = _frame_encoder.previous_camera_position


func _vector3_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
