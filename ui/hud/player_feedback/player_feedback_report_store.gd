class_name GDPlayerFeedbackReportStore
extends RefCounted

## Stores bounded, repository-backed bug reports and their compact run playbacks.

const RUN_RECORDING := preload("res://game/run_recording.gd")
const REPORT_EXTENSION := ".json"
const PLAYBACK_EXTENSION := ".gdr"
const LEVEL_SCENE_EXTENSION := ".tscn"

enum PlaybackStatus {
    Pending,
    Ready,
    OmittedSizeLimit,
    SaveFailed,
}


static func create_report(
    report_directory: String,
    archive_directory: String,
    level_id: String,
    marker: Dictionary,
    maximum_report_count: int,
    maximum_total_bytes: int,
    level_scene_path: String = ""
) -> String:
    if not _ensure_directory(report_directory) or not _ensure_directory(archive_directory):
        return ""
    enforce_retention(
        report_directory,
        archive_directory,
        maxi(maximum_report_count - 1, 0),
        maximum_total_bytes
    )
    if _get_report_paths(report_directory, archive_directory).size() \
            >= maximum_report_count:
        push_warning(
            "Player feedback report limit reached; resolve an open report before adding another."
        )
        return ""

    var report_id := _create_report_id(level_id, report_directory)
    var level_scene_snapshot := _save_level_scene_snapshot(
        report_directory,
        report_id,
        level_scene_path
    )
    var report := {
        "format_version": 2,
        "report_id": report_id,
        "status": "open",
        "level_id": level_id,
        "created_unix_time": int(marker.get(
            "created_unix_time",
            Time.get_unix_time_from_system()
        )),
        "marker": marker.duplicate(true),
        "playback_file": "%s%s" % [report_id, PLAYBACK_EXTENSION],
        "playback_status": _get_playback_status_name(PlaybackStatus.Pending),
        "playback_bytes": 0,
        "level_scene_file": level_scene_snapshot.get("file", ""),
        "level_scene_status": level_scene_snapshot.get("status", "unavailable"),
        "level_scene_bytes": level_scene_snapshot.get("bytes", 0),
        "level_scene_sha256": level_scene_snapshot.get("sha256", ""),
    }
    if not _write_report(report_directory, report_id, report):
        _remove_level_scene_snapshot(report_directory, report_id)
        return ""
    return report_id


static func update_report_note(
    report_directory: String,
    report_id: String,
    note: String
) -> bool:
    var report := load_report(report_directory, report_id)
    if report.is_empty():
        return false
    var marker := report.get("marker", {}) as Dictionary
    marker["note"] = note.strip_edges()
    report["marker"] = marker
    return _write_report(report_directory, report_id, report)


static func save_report_playback(
    report_directory: String,
    archive_directory: String,
    report_id: String,
    frame_payload: PackedByteArray,
    frame_count: int,
    camera_fov: float,
    run_metadata: Dictionary,
    used_payload_size: int,
    maximum_playback_bytes: int,
    maximum_report_count: int,
    maximum_total_bytes: int
) -> bool:
    var report := load_report(report_directory, report_id)
    if report.is_empty():
        return false
    var saved := RUN_RECORDING.save_for_level(
        report_id,
        frame_payload,
        frame_count,
        camera_fov,
        report_directory,
        run_metadata,
        used_payload_size
    )
    var playback_path := RUN_RECORDING.get_path_for_level(report_id, report_directory)
    var playback_bytes := _get_file_size(playback_path) if saved else 0
    if saved and playback_bytes > maximum_playback_bytes:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(playback_path))
        saved = false
        report["playback_status"] = _get_playback_status_name(
            PlaybackStatus.OmittedSizeLimit
        )
        push_warning(
            "Player feedback playback '%s' exceeded its %d byte limit."
            % [report_id, maximum_playback_bytes]
        )
    elif saved:
        report["playback_status"] = _get_playback_status_name(PlaybackStatus.Ready)
    else:
        report["playback_status"] = _get_playback_status_name(PlaybackStatus.SaveFailed)
    report["playback_bytes"] = playback_bytes if saved else 0
    report["captured_frame_count"] = frame_count
    var marker := report.get("marker", {}) as Dictionary
    report["captured_duration"] = float(run_metadata.get(
        "report_capture_time",
        marker.get("time", 0.0)
    ))
    _write_report(report_directory, report_id, report)

    enforce_retention(
        report_directory,
        archive_directory,
        maximum_report_count,
        maximum_total_bytes
    )
    if saved and _get_total_playback_bytes(report_directory, archive_directory) \
            > maximum_total_bytes:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(playback_path))
        report["playback_status"] = _get_playback_status_name(
            PlaybackStatus.OmittedSizeLimit
        )
        report["playback_bytes"] = 0
        _write_report(report_directory, report_id, report)
        push_warning("Player feedback playback omitted because the repository limit is full.")
        return false
    return saved


static func load_report(report_directory: String, report_id: String) -> Dictionary:
    var report_path := _get_report_path(report_directory, report_id)
    if not FileAccess.file_exists(report_path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
    return parsed as Dictionary if parsed is Dictionary else {}


static func enforce_retention(
    report_directory: String,
    archive_directory: String,
    maximum_report_count: int,
    maximum_total_bytes: int
) -> void:
    var archived_reports := _get_json_paths_recursive(archive_directory)
    archived_reports.sort_custom(
        func(left: String, right: String) -> bool:
            return FileAccess.get_modified_time(left) < FileAccess.get_modified_time(right)
    )
    while not archived_reports.is_empty() \
            and (
                _get_report_paths(report_directory, archive_directory).size() \
                    > maximum_report_count
                or _get_total_playback_bytes(report_directory, archive_directory) \
                    > maximum_total_bytes
            ):
        _remove_report_pair(archived_reports.pop_front())


static func _create_report_id(level_id: String, report_directory: String) -> String:
    var date_time := Time.get_datetime_dict_from_system(true)
    var timestamp := "%04d%02d%02dT%02d%02d%02dZ" % [
        int(date_time.get("year", 0)),
        int(date_time.get("month", 0)),
        int(date_time.get("day", 0)),
        int(date_time.get("hour", 0)),
        int(date_time.get("minute", 0)),
        int(date_time.get("second", 0)),
    ]
    var base_id := "%s-%s" % [timestamp, level_id.validate_filename()]
    var report_id := base_id
    var suffix := 2
    while FileAccess.file_exists(_get_report_path(report_directory, report_id)):
        report_id = "%s-%d" % [base_id, suffix]
        suffix += 1
    return report_id


static func _write_report(
    report_directory: String,
    report_id: String,
    report: Dictionary
) -> bool:
    if not _ensure_directory(report_directory):
        return false
    var report_file := FileAccess.open(
        _get_report_path(report_directory, report_id),
        FileAccess.WRITE
    )
    if report_file == null:
        push_warning("Could not write player feedback report '%s'." % report_id)
        return false
    report_file.store_string(JSON.stringify(report, "  ") + "\n")
    return true


static func _get_report_path(report_directory: String, report_id: String) -> String:
    return report_directory.path_join(
        "%s%s" % [report_id.validate_filename(), REPORT_EXTENSION]
    )


static func _get_report_paths(
    report_directory: String,
    archive_directory: String
) -> Array[String]:
    var paths := _get_json_paths_recursive(report_directory)
    paths.append_array(_get_json_paths_recursive(archive_directory))
    return paths


static func _get_total_playback_bytes(
    report_directory: String,
    archive_directory: String
) -> int:
    var total := 0
    for playback_path in _get_playback_paths_recursive(report_directory):
        total += _get_file_size(playback_path)
    for playback_path in _get_playback_paths_recursive(archive_directory):
        total += _get_file_size(playback_path)
    return total


static func _get_json_paths_recursive(directory: String) -> Array[String]:
    return _get_paths_recursive(directory, REPORT_EXTENSION)


static func _get_playback_paths_recursive(directory: String) -> Array[String]:
    return _get_paths_recursive(directory, PLAYBACK_EXTENSION)


static func _get_paths_recursive(directory: String, extension: String) -> Array[String]:
    var paths: Array[String] = []
    var access := DirAccess.open(directory)
    if access == null:
        return paths
    for file_name in access.get_files():
        if file_name.ends_with(extension):
            paths.append(directory.path_join(file_name))
    for child_directory in access.get_directories():
        paths.append_array(_get_paths_recursive(
            directory.path_join(child_directory),
            extension
        ))
    return paths


static func _remove_report_pair(report_path: String) -> void:
    var playback_path := report_path.trim_suffix(REPORT_EXTENSION) + PLAYBACK_EXTENSION
    var level_scene_path := report_path.trim_suffix(REPORT_EXTENSION) \
        + LEVEL_SCENE_EXTENSION
    if FileAccess.file_exists(playback_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(playback_path))
    if FileAccess.file_exists(level_scene_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(level_scene_path))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(report_path))


static func _save_level_scene_snapshot(
    report_directory: String,
    report_id: String,
    level_scene_path: String
) -> Dictionary:
    if level_scene_path.is_empty() or not FileAccess.file_exists(level_scene_path):
        return {"status": "unavailable"}
    if level_scene_path.get_extension().to_lower() != "tscn":
        push_warning(
            "Player feedback level snapshot requires a text .tscn source; got '%s'."
            % level_scene_path
        )
        return {"status": "unavailable"}
    var scene_source := FileAccess.get_file_as_string(level_scene_path)
    if scene_source.is_empty():
        return {"status": "save_failed"}
    scene_source = _remove_root_scene_uid(scene_source)
    var file_name := "%s%s" % [report_id, LEVEL_SCENE_EXTENSION]
    var snapshot_path := report_directory.path_join(file_name)
    var snapshot_file := FileAccess.open(snapshot_path, FileAccess.WRITE)
    if snapshot_file == null:
        push_warning("Could not save the player feedback level snapshot.")
        return {"status": "save_failed"}
    snapshot_file.store_string(scene_source)
    snapshot_file.close()
    return {
        "file": file_name,
        "status": "ready",
        "bytes": _get_file_size(snapshot_path),
        "sha256": FileAccess.get_sha256(snapshot_path),
    }


## Removes the source identity so an immutable report copy cannot collide with the live scene.
static func _remove_root_scene_uid(scene_source: String) -> String:
    var header_end := scene_source.find("\n")
    if header_end < 0:
        header_end = scene_source.length()
    var header := scene_source.left(header_end)
    if not header.begins_with("[gd_scene "):
        return scene_source
    var uid_start := header.find(" uid=\"")
    if uid_start < 0:
        return scene_source
    var uid_end := header.find("\"", uid_start + 6)
    if uid_end < 0:
        return scene_source
    return scene_source.left(uid_start) + scene_source.substr(uid_end + 1)


static func _remove_level_scene_snapshot(
    report_directory: String,
    report_id: String
) -> void:
    var snapshot_path := report_directory.path_join(
        "%s%s" % [report_id, LEVEL_SCENE_EXTENSION]
    )
    if FileAccess.file_exists(snapshot_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(snapshot_path))


static func _ensure_directory(directory: String) -> bool:
    var global_directory := ProjectSettings.globalize_path(directory)
    if DirAccess.dir_exists_absolute(global_directory):
        return true
    return DirAccess.make_dir_recursive_absolute(global_directory) == OK


static func _get_file_size(path: String) -> int:
    var file := FileAccess.open(path, FileAccess.READ)
    return file.get_length() if file != null else 0


static func _get_playback_status_name(status: PlaybackStatus) -> String:
    return String(PlaybackStatus.keys()[status]).to_snake_case()
