extends SceneTree

## Replays the newest recorded player session and emits selectable JSONL diagnostics.

const SESSION_OPTIONS := preload("res://game/codex_session_options.gd")
const RUN_RECORDING := preload("res://game/run_recording.gd")
const LEVEL_MAPPING := preload("res://levels/level_mapping.tres")
const PLAYBACK_PLAYER_SCRIPT := preload("res://ui/screens/level_run_playback_player.gd")
const RUN_PLAYBACK_SESSION_GROUP: StringName = &"run_playback_session"
const OUTPUT_PREFIX := "CODEX_REPLAY "
const LIVE_FEEDBACK_PATH := "user://run_recordings/latest_feedback.json"
const REPOSITORY_FEEDBACK_DIRECTORY := "res://feedback/reports"
const REPOSITORY_FEEDBACK_ARCHIVE_DIRECTORY := "res://feedback/archive"

var options: Dictionary = {}
var output_file: FileAccess
var visual_session_root: Node3D
var playback_level: Node3D
var playback_player: Node3D
var playback_pivot: Node3D
var playback_camera: Camera3D


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    options = SESSION_OPTIONS.parse(OS.get_cmdline_user_args())
    var errors := options.get("errors", []) as Array[String]
    if not errors.is_empty():
        _emit_error("; ".join(errors))
        _finish(2)
        return
    if bool(options.get("help", false)):
        _print_help()
        _finish(0)
        return

    var mode := int(options.get("mode", SESSION_OPTIONS.SessionMode.Disabled))
    if mode == SESSION_OPTIONS.SessionMode.ListRecordings:
        _list_recordings()
        _finish(0)
        return
    if mode != SESSION_OPTIONS.SessionMode.Replay \
            and mode != SESSION_OPTIONS.SessionMode.Feedback:
        _emit_error(
            "Pass --codex-replay, --codex-new-feedback, or --codex-list-recordings."
        )
        _finish(2)
        return
    if bool(options.get("visual", false)) and not bool(options.get("confirmed", false)):
        _emit_error("Visual replay requires explicit user readiness confirmation.")
        _finish(4)
        return
    if not _open_output_file():
        _finish(2)
        return

    var level_id := ""
    var recording := {}
    var feedback_marker := {}
    var live_feedback_samples: Array = []
    var is_live_feedback := false
    var feedback_source := "saved_recording"
    var feedback_level_scene_path := ""
    if mode == SESSION_OPTIONS.SessionMode.Feedback:
        var feedback_recording := _load_newest_feedback_recording()
        level_id = String(feedback_recording.get("level_id", ""))
        recording = feedback_recording.get("recording", {}) as Dictionary
        feedback_marker = feedback_recording.get("marker", {}) as Dictionary
        live_feedback_samples = feedback_recording.get("samples", []) as Array
        is_live_feedback = bool(feedback_recording.get("live", false))
        feedback_source = String(feedback_recording.get("source", feedback_source))
        feedback_level_scene_path = String(feedback_recording.get(
            "level_scene_path",
            ""
        ))
    else:
        level_id = _resolve_recorded_level_id(String(options.get("level", "")))
    if level_id.is_empty():
        _emit_error(
            "No saved feedback marker was found."
            if mode == SESSION_OPTIONS.SessionMode.Feedback
            else "No matching player recording was found."
        )
        _finish(3)
        return
    if recording.is_empty() and not is_live_feedback:
        recording = RUN_RECORDING.load_for_level(level_id)
    if is_live_feedback:
        _emit_live_feedback(
            level_id,
            feedback_marker,
            live_feedback_samples,
            feedback_source
        )
        _finish(0)
        return
    if recording.is_empty():
        _emit_error("The recording for level '%s' could not be decoded." % level_id)
        _finish(3)
        return

    if mode == SESSION_OPTIONS.SessionMode.Feedback:
        _emit_feedback_context(level_id, recording, feedback_marker)
        _log_feedback_window(level_id, recording, feedback_marker)
        if bool(options.get("visual", false)) \
                and not await _play_visual_recording(
                    level_id,
                    recording,
                    feedback_level_scene_path
                ):
            _finish(3)
            return
        _emit_summary("complete", level_id, recording)
        _finish(0)
        return

    _emit_recording_metadata(level_id, recording)
    if bool(options.get("visual", false)):
        if not await _play_visual_recording(level_id, recording):
            _finish(3)
            return
    else:
        _log_recording_samples(level_id, recording)
    _emit_summary("complete", level_id, recording)
    _finish(0)


func _resolve_recorded_level_id(level_reference: String) -> String:
    var normalized_reference := level_reference.strip_edges()
    if normalized_reference.is_empty() or normalized_reference.to_lower() == "latest":
        return RUN_RECORDING.get_latest_level_id()

    var level_index := int(LEVEL_MAPPING.find_level_index(normalized_reference))
    if level_index >= 0:
        return String(LEVEL_MAPPING.get_level_id(level_index))
    if FileAccess.file_exists(RUN_RECORDING.get_path_for_level(normalized_reference)):
        return normalized_reference
    return ""


func _load_newest_feedback_recording() -> Dictionary:
    var report_reference := String(options.get("feedback_report", "latest"))
    var repository_feedback := _load_repository_feedback(String(options.get(
        "feedback_report",
        "latest"
    )))
    if not repository_feedback.is_empty():
        if bool(repository_feedback.get("live", false)):
            var matching_live_feedback := _load_live_feedback()
            var repository_marker := repository_feedback.get("marker", {}) as Dictionary
            var live_marker := matching_live_feedback.get("marker", {}) as Dictionary
            if String(repository_marker.get("report_id", "")) == String(
                live_marker.get("report_id", "")
            ):
                matching_live_feedback["source"] = "live_repository_report"
                return matching_live_feedback
        return repository_feedback
    if not report_reference.is_empty() and report_reference.to_lower() != "latest":
        return {}
    var live_feedback := _load_live_feedback()
    if not live_feedback.is_empty():
        return live_feedback
    for listed_recording: Dictionary in RUN_RECORDING.list_recordings():
        var level_id := String(listed_recording.get("level_id", ""))
        var recording := RUN_RECORDING.load_for_level(level_id)
        if recording.is_empty():
            continue
        var metadata := recording.get("run_metadata", {}) as Dictionary
        var markers := metadata.get("feedback_markers", []) as Array
        if markers.is_empty():
            continue
        return {
            "level_id": level_id,
            "recording": recording,
            "marker": markers[-1],
        }
    return {}


func _load_repository_feedback(report_reference: String) -> Dictionary:
    var report_paths := _get_report_paths(REPOSITORY_FEEDBACK_DIRECTORY)
    var normalized_reference := report_reference.strip_edges()
    if report_paths.is_empty() \
            or (
                not normalized_reference.is_empty()
                and normalized_reference.to_lower() != "latest"
            ):
        report_paths.append_array(_get_report_paths(
            REPOSITORY_FEEDBACK_ARCHIVE_DIRECTORY
        ))
    report_paths.sort_custom(
        func(left: String, right: String) -> bool:
            return FileAccess.get_modified_time(left) > FileAccess.get_modified_time(right)
    )

    var selected_report := {}
    var selected_report_path := ""
    for report_path in report_paths:
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
        if not parsed is Dictionary:
            continue
        var report := parsed as Dictionary
        if normalized_reference.is_empty() or normalized_reference.to_lower() == "latest" \
                or String(report.get("report_id", "")) == normalized_reference:
            selected_report = report
            selected_report_path = report_path
            break
    if selected_report.is_empty():
        return {}

    var report_id := String(selected_report.get("report_id", ""))
    var marker := (selected_report.get("marker", {}) as Dictionary).duplicate(true)
    marker["report_id"] = report_id
    var recording := RUN_RECORDING.load_for_level(
        report_id,
        selected_report_path.get_base_dir()
    )
    var level_scene_file := String(selected_report.get("level_scene_file", ""))
    var level_scene_path := selected_report_path.get_base_dir().path_join(
        level_scene_file
    ) if not level_scene_file.is_empty() else ""
    if not recording.is_empty():
        return {
            "level_id": String(selected_report.get("level_id", "")),
            "marker": marker,
            "recording": recording,
            "source": "repository_report",
            "level_scene_path": level_scene_path,
        }
    return {
        "level_id": String(selected_report.get("level_id", "")),
        "marker": marker,
        "samples": [],
        "live": true,
        "source": "repository_report_without_playback",
    }


func _get_report_paths(directory: String) -> Array[String]:
    var paths: Array[String] = []
    var access := DirAccess.open(directory)
    if access == null:
        return paths
    for file_name in access.get_files():
        if file_name.ends_with(".json"):
            paths.append(directory.path_join(file_name))
    for child_directory in access.get_directories():
        paths.append_array(_get_report_paths(directory.path_join(child_directory)))
    return paths


func _load_live_feedback() -> Dictionary:
    if not FileAccess.file_exists(LIVE_FEEDBACK_PATH):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
        LIVE_FEEDBACK_PATH
    ))
    if not parsed is Dictionary:
        return {}
    var feedback := parsed as Dictionary
    var marker := feedback.get("marker", {}) as Dictionary
    if marker.is_empty():
        return {}
    return {
        "level_id": String(feedback.get("level_id", "")),
        "marker": marker,
        "samples": feedback.get("samples", []),
        "live": true,
        "source": "live_player_feedback",
    }


func _emit_live_feedback(
    level_id: String,
    marker: Dictionary,
    samples: Array,
    source: String
) -> void:
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Summary,
        {
            "event": "live_feedback",
            "level_id": level_id,
            "marker_time": float(marker.get("time", 0.0)),
            "sample_count": samples.size(),
        }
    )
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Feedback,
        {
            "level_id": level_id,
            "frame": int(marker.get("frame", 0)),
            "time": float(marker.get("time", 0.0)),
            "note": String(marker.get("note", "")),
            "snapshot": marker.get("snapshot", {}),
            "live": true,
        }
    )
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Metadata,
        {
            "level_id": level_id,
            "metadata": {
                "source": source,
                "created_unix_time": int(marker.get("created_unix_time", 0)),
            },
        }
    )
    for raw_sample: Variant in samples:
        if not raw_sample is Dictionary:
            continue
        var sample := raw_sample as Dictionary
        _emit_channel(
            SESSION_OPTIONS.LogChannel.Position,
            {
                "level_id": level_id,
                "frame": int(sample.get("frame", 0)),
                "time": float(sample.get("time", 0.0)),
                "position": sample.get("position", []),
            }
        )
        _emit_channel(
            SESSION_OPTIONS.LogChannel.Input,
            {
                "level_id": level_id,
                "frame": int(sample.get("frame", 0)),
                "time": float(sample.get("time", 0.0)),
                "movement": sample.get("movement", []),
                "camera_control": sample.get("camera_control", []),
            }
        )
        _emit_channel(
            SESSION_OPTIONS.LogChannel.Buttons,
            {
                "level_id": level_id,
                "frame": int(sample.get("frame", 0)),
                "time": float(sample.get("time", 0.0)),
                "jump": bool(sample.get("jump", false)),
                "drop": bool(sample.get("drop", false)),
            }
        )


func _list_recordings() -> void:
    var recordings := RUN_RECORDING.list_recordings()
    for recording: Dictionary in recordings:
        var level_id := String(recording.get("level_id", ""))
        var level_index := int(LEVEL_MAPPING.find_level_index_by_id(level_id))
        _write_event({
            "channel": "recording",
            "level_id": level_id,
            "level_name": String(LEVEL_MAPPING.get_level_data(level_index).get(
                "name",
                level_id
            )) if level_index >= 0 else level_id,
            "modified_unix_time": int(recording.get("modified_unix_time", 0)),
            "latest": recording == recordings[0],
            "feedback_markers": _get_feedback_marker_count(level_id),
        })


func _get_feedback_marker_count(level_id: String) -> int:
    var recording := RUN_RECORDING.load_for_level(level_id)
    var metadata := recording.get("run_metadata", {}) as Dictionary
    return (metadata.get("feedback_markers", []) as Array).size()


func _emit_feedback_context(
    level_id: String,
    recording: Dictionary,
    marker: Dictionary
) -> void:
    _emit_summary("feedback", level_id, recording)
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Feedback,
        {
            "level_id": level_id,
            "frame": int(marker.get("frame", 0)),
            "time": float(marker.get("time", 0.0)),
            "note": String(marker.get("note", "")),
            "snapshot": marker.get("snapshot", {}),
        }
    )
    var metadata := recording.get("run_metadata", {}) as Dictionary
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Metadata,
        {
            "level_id": level_id,
            "metadata": {
                "level_id": metadata.get("level_id", level_id),
                "settings": metadata.get("settings", {}),
                "session": metadata.get("session", {}),
                "feedback_marker_count": (
                    metadata.get("feedback_markers", []) as Array
                ).size(),
            },
        }
    )


func _log_feedback_window(
    level_id: String,
    recording: Dictionary,
    marker: Dictionary
) -> void:
    var marker_time := float(marker.get("time", 0.0))
    var start_time := maxf(
        marker_time - float(options.get(
            "feedback_before_seconds",
            SESSION_OPTIONS.DEFAULT_FEEDBACK_BEFORE_SECONDS
        )),
        0.0
    )
    var end_time := minf(
        marker_time + float(options.get(
            "feedback_after_seconds",
            SESSION_OPTIONS.DEFAULT_FEEDBACK_AFTER_SECONDS
        )),
        float(recording.get("duration", 0.0))
    )
    var sample_seconds := float(options.get(
        "sample_seconds",
        SESSION_OPTIONS.DEFAULT_SAMPLE_SECONDS
    ))
    var sample_time := start_time
    while sample_time < end_time:
        _log_sample(level_id, recording, sample_time)
        sample_time += sample_seconds
    _log_sample(level_id, recording, end_time)


func _emit_recording_metadata(level_id: String, recording: Dictionary) -> void:
    _emit_summary("start", level_id, recording)
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Metadata,
        {
            "level_id": level_id,
            "metadata": recording.get("run_metadata", {}),
        }
    )
    if not SESSION_OPTIONS.has_log_channel(options, SESSION_OPTIONS.LogChannel.Drift):
        return
    var run_metadata := recording.get("run_metadata", {}) as Dictionary
    for checkpoint: Dictionary in run_metadata.get("drift_checkpoints", []) as Array:
        _emit_channel(
            SESSION_OPTIONS.LogChannel.Drift,
            {
                "level_id": level_id,
                "frame": int(checkpoint.get("frame", 0)),
                "time": float(checkpoint.get("time", 0.0)),
                "states": checkpoint.get("states", []),
            }
        )


func _emit_summary(event: String, level_id: String, recording: Dictionary) -> void:
    var positions := recording.get("player_positions", PackedVector3Array()) \
        as PackedVector3Array
    var distance_travelled := 0.0
    for index in range(1, positions.size()):
        distance_travelled += positions[index - 1].distance_to(positions[index])
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Summary,
        {
            "event": event,
            "level_id": level_id,
            "duration": float(recording.get("duration", 0.0)),
            "frame_count": positions.size(),
            "distance_travelled": distance_travelled,
            "start_position": _vector3_to_array(
                positions[0] if not positions.is_empty() else Vector3.ZERO
            ),
            "end_position": _vector3_to_array(
                positions[-1] if not positions.is_empty() else Vector3.ZERO
            ),
        }
    )


func _log_recording_samples(level_id: String, recording: Dictionary) -> void:
    var duration := float(recording.get("duration", 0.0))
    var sample_seconds := float(options.get(
        "sample_seconds",
        SESSION_OPTIONS.DEFAULT_SAMPLE_SECONDS
    ))
    var sample_time := 0.0
    while sample_time < duration:
        _log_sample(level_id, recording, sample_time)
        sample_time += sample_seconds
    _log_sample(level_id, recording, duration)


func _log_sample(level_id: String, recording: Dictionary, sample_time: float) -> void:
    var frame_times := recording.get("frame_times", PackedFloat32Array()) \
        as PackedFloat32Array
    if frame_times.is_empty():
        return
    var frame_index := _find_frame_index(frame_times, sample_time)
    var positions := recording.get("player_positions", PackedVector3Array()) \
        as PackedVector3Array
    var yaws := recording.get("player_yaws", PackedFloat32Array()) as PackedFloat32Array
    var movement_inputs := recording.get("movement_inputs", PackedVector2Array()) \
        as PackedVector2Array
    var camera_inputs := recording.get("camera_inputs", PackedVector2Array()) \
        as PackedVector2Array
    var camera_positions := recording.get("camera_positions", PackedVector3Array()) \
        as PackedVector3Array
    var camera_rotations := recording.get("camera_rotations", PackedVector4Array()) \
        as PackedVector4Array
    var button_states := recording.get("button_states", PackedByteArray()) as PackedByteArray
    var frame_time := frame_times[frame_index]

    _emit_channel(
        SESSION_OPTIONS.LogChannel.Position,
        {
            "level_id": level_id,
            "frame": frame_index,
            "time": frame_time,
            "position": _vector3_to_array(positions[frame_index]),
            "yaw": yaws[frame_index],
        }
    )
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Input,
        {
            "level_id": level_id,
            "frame": frame_index,
            "time": frame_time,
            "movement": _vector2_to_array(movement_inputs[frame_index]),
            "camera_control": _vector2_to_array(camera_inputs[frame_index]),
        }
    )
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Camera,
        {
            "level_id": level_id,
            "frame": frame_index,
            "time": frame_time,
            "position": _vector3_to_array(camera_positions[frame_index]),
            "rotation": _vector4_to_array(camera_rotations[frame_index]),
            "fov": float(recording.get("camera_fov", 34.0)),
        }
    )
    var flags := int(button_states[frame_index])
    _emit_channel(
        SESSION_OPTIONS.LogChannel.Buttons,
        {
            "level_id": level_id,
            "frame": frame_index,
            "time": frame_time,
            "jump": bool(flags & RUN_RECORDING.FrameFlags.JumpPressed),
            "drop": bool(flags & RUN_RECORDING.FrameFlags.DropPressed),
            "camera_available": bool(flags & RUN_RECORDING.FrameFlags.CameraAvailable),
        }
    )


func _play_visual_recording(
    level_id: String,
    recording: Dictionary,
    level_scene_path: String = ""
) -> bool:
    var level_scene: PackedScene
    if not level_scene_path.is_empty() and FileAccess.file_exists(level_scene_path):
        level_scene = ResourceLoader.load(
            level_scene_path,
            "PackedScene",
            ResourceLoader.CACHE_MODE_IGNORE
        ) as PackedScene
    else:
        var level_index := int(LEVEL_MAPPING.find_level_index_by_id(level_id))
        if level_index < 0:
            _emit_error("Visual playback requires a mapped level ID; got '%s'." % level_id)
            return false
        level_scene = load(LEVEL_MAPPING.get_level_scene_path(level_index)) as PackedScene
    if level_scene == null or not _create_visual_world(level_scene, recording):
        _emit_error("Could not construct visual playback for level '%s'." % level_id)
        return false

    var duration := float(recording.get("duration", 0.0))
    var playback_speed := float(options.get(
        "playback_speed",
        SESSION_OPTIONS.DEFAULT_PLAYBACK_SPEED
    ))
    var sample_seconds := float(options.get(
        "sample_seconds",
        SESSION_OPTIONS.DEFAULT_SAMPLE_SECONDS
    ))
    var playback_time := 0.0
    var next_log_time := 0.0
    var previous_ticks := Time.get_ticks_usec()
    while playback_time < duration:
        await process_frame
        var current_ticks := Time.get_ticks_usec()
        var delta := float(current_ticks - previous_ticks) / 1_000_000.0
        previous_ticks = current_ticks
        playback_time = minf(playback_time + delta * playback_speed, duration)
        _apply_visual_sample(recording, playback_time)
        while next_log_time <= playback_time and next_log_time < duration:
            _log_sample(level_id, recording, next_log_time)
            next_log_time += sample_seconds
    _log_sample(level_id, recording, duration)
    return true


func _create_visual_world(level_scene: PackedScene, recording: Dictionary) -> bool:
    playback_level = level_scene.instantiate() as Node3D
    if playback_level == null:
        return false
    playback_player = playback_level.get_node_or_null(^"Player") as Node3D
    if playback_player == null:
        playback_level.free()
        playback_level = null
        return false

    visual_session_root = Node3D.new()
    visual_session_root.name = "CodexReplaySession"
    visual_session_root.add_to_group(RUN_PLAYBACK_SESSION_GROUP)
    _prepare_visual_tree(playback_level)
    playback_player.set_script(PLAYBACK_PLAYER_SCRIPT)
    playback_player.set_process(false)
    playback_player.set_physics_process(false)
    var collision_body := playback_player as CollisionObject3D
    if collision_body != null:
        collision_body.collision_layer = 0
        collision_body.collision_mask = 0
    visual_session_root.add_child(playback_level)
    root.add_child(visual_session_root)

    playback_pivot = playback_player.get_node_or_null(^"Pivot") as Node3D
    playback_camera = Camera3D.new()
    playback_camera.name = "CodexReplayCamera"
    playback_camera.current = true
    playback_camera.fov = float(recording.get("camera_fov", 34.0))
    visual_session_root.add_child(playback_camera)
    _apply_visual_sample(recording, 0.0)
    return true


func _prepare_visual_tree(node: Node) -> void:
    if node is Camera3D:
        (node as Camera3D).current = false
    elif node is AudioStreamPlayer or node is AudioStreamPlayer2D \
            or node is AudioStreamPlayer3D:
        node.set("autoplay", false)
        node.call("stop")
    for child in node.get_children():
        _prepare_visual_tree(child)


func _apply_visual_sample(recording: Dictionary, playback_time: float) -> void:
    if playback_player == null or playback_camera == null:
        return
    var frame_times := recording.get("frame_times", PackedFloat32Array()) \
        as PackedFloat32Array
    var frame_deltas := recording.get("frame_deltas", PackedFloat32Array()) \
        as PackedFloat32Array
    if frame_times.is_empty() or frame_deltas.is_empty():
        return
    var frame_index := _find_frame_index(frame_times, playback_time)
    var next_index := mini(frame_index + 1, frame_times.size() - 1)
    var interpolation := clampf(
        (playback_time - frame_times[frame_index]) / frame_deltas[frame_index],
        0.0,
        1.0
    )
    var positions := recording.get("player_positions", PackedVector3Array()) \
        as PackedVector3Array
    var yaws := recording.get("player_yaws", PackedFloat32Array()) as PackedFloat32Array
    var camera_positions := recording.get("camera_positions", PackedVector3Array()) \
        as PackedVector3Array
    var camera_rotations := recording.get("camera_rotations", PackedVector4Array()) \
        as PackedVector4Array
    playback_player.global_position = positions[frame_index].lerp(
        positions[next_index],
        interpolation
    )
    if playback_pivot != null:
        playback_pivot.rotation.y = lerp_angle(
            yaws[frame_index],
            yaws[next_index],
            interpolation
        )
    playback_camera.global_position = camera_positions[frame_index].lerp(
        camera_positions[next_index],
        interpolation
    )
    var current_rotation := _vector4_to_quaternion(camera_rotations[frame_index])
    var next_rotation := _vector4_to_quaternion(camera_rotations[next_index])
    playback_camera.global_basis = Basis(current_rotation.slerp(next_rotation, interpolation))


func _find_frame_index(frame_times: PackedFloat32Array, time: float) -> int:
    var low := 0
    var high := frame_times.size() - 1
    while low <= high:
        var middle := floori(float(low + high) * 0.5)
        if frame_times[middle] <= time:
            low = middle + 1
        else:
            high = middle - 1
    return clampi(high, 0, frame_times.size() - 1)


func _open_output_file() -> bool:
    var output_path := String(options.get("log_file", "")).strip_edges()
    if output_path.is_empty():
        return true
    var output_directory := output_path.get_base_dir()
    if not output_directory.is_empty() \
            and DirAccess.make_dir_recursive_absolute(output_directory) != OK \
            and not DirAccess.dir_exists_absolute(output_directory):
        _emit_error("Could not create replay log directory '%s'." % output_directory)
        return false
    output_file = FileAccess.open(output_path, FileAccess.WRITE)
    if output_file == null:
        _emit_error("Could not create replay log '%s'." % output_path)
        return false
    return true


func _emit_channel(channel: SESSION_OPTIONS.LogChannel, payload: Dictionary) -> void:
    if not SESSION_OPTIONS.has_log_channel(options, channel):
        return
    var event := {
        "channel": SESSION_OPTIONS.get_log_channel_name(channel),
    }
    event.merge(payload, true)
    _write_event(event)


func _emit_error(message: String) -> void:
    _write_event({
        "channel": "error",
        "message": message,
    })


func _write_event(event: Dictionary) -> void:
    var line := JSON.stringify(event)
    if output_file != null:
        output_file.store_line(line)
    else:
        print("%s%s" % [OUTPUT_PREFIX, line])


func _print_help() -> void:
    _write_event({
        "channel": "help",
        "usage": (
            "--codex-replay [--codex-level latest|ID|NAME] "
            + "| --codex-new-feedback [--codex-feedback-report latest|ID] "
            + "[--codex-logs summary,metadata,feedback,position,input,camera,buttons,drift] "
            + "[--codex-sample-seconds 0.5] [--codex-speed 1.0] "
            + "[--codex-feedback-before 2.0] [--codex-feedback-after 3.0] "
            + "[--codex-visual --codex-confirmed] [--codex-log-file PATH]"
        ),
    })


func _finish(exit_code: int) -> void:
    if output_file != null:
        output_file.close()
        output_file = null
    if visual_session_root != null and is_instance_valid(visual_session_root):
        visual_session_root.queue_free()
    quit(exit_code)


func _vector2_to_array(value: Vector2) -> Array[float]:
    return [value.x, value.y]


func _vector3_to_array(value: Vector3) -> Array[float]:
    return [value.x, value.y, value.z]


func _vector4_to_array(value: Vector4) -> Array[float]:
    return [value.x, value.y, value.z, value.w]


func _vector4_to_quaternion(value: Vector4) -> Quaternion:
    return Quaternion(value.x, value.y, value.z, value.w).normalized()
