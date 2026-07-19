extends RefCounted
class_name GDRunRecording

## Compact on-disk format and decoder for the most recent run of each level.

const STORAGE_DIRECTORY := "user://run_playbacks"
const FILE_EXTENSION := ".gdr"
const FILE_MAGIC := 0x47445250
const INVALID_TASK_ID := -1
const MAX_PAYLOAD_BYTES := 512 * 1024 * 1024
const MAX_METADATA_BYTES := 16 * 1024 * 1024
const NORMAL_FRAME_MINIMUM_SIZE := 35
const MIN_FRAME_DELTA := 0.000001
const POSITION_SCALE := 1000.0
const ROTATION_SCALE := 32767.0

enum FileVersion {
    PoseFrames = 2,
    RunMetadata = 3,
}

const FILE_VERSION := FileVersion.RunMetadata

enum FrameFlags {
    JumpPressed = 1 << 0,
    DropPressed = 1 << 1,
    AbsolutePosition = 1 << 2,
    CameraAvailable = 1 << 3,
}

static func save_for_level(
    level_id: String,
    frame_payload: PackedByteArray,
    frame_count: int,
    camera_fov: float,
    storage_directory: String = STORAGE_DIRECTORY,
    run_metadata: Dictionary = {},
    used_payload_size: int = -1
) -> bool:
    var payload_size := frame_payload.size() if used_payload_size < 0 else used_payload_size
    if not _is_valid_recording(level_id, frame_payload, frame_count, payload_size):
        return false
    if not _ensure_storage_directory(storage_directory):
        return false

    var payload_to_save := frame_payload.slice(0, payload_size)
    var metadata_bytes := JSON.stringify(run_metadata).to_utf8_buffer()
    if metadata_bytes.size() > MAX_METADATA_BYTES:
        return false
    var safe_id := level_id.validate_filename()
    var temporary_name := "%s%s.tmp" % [safe_id, FILE_EXTENSION]
    var final_name := "%s%s" % [safe_id, FILE_EXTENSION]
    var temporary_path := "%s/%s" % [storage_directory, temporary_name]
    var compressed_payload := payload_to_save.compress(FileAccess.COMPRESSION_ZSTD)
    if compressed_payload.is_empty():
        return false
    var recording_file := FileAccess.open(temporary_path, FileAccess.WRITE)
    if recording_file == null:
        push_warning("Could not create run recording for level '%s'." % level_id)
        return false

    recording_file.store_32(FILE_MAGIC)
    recording_file.store_16(FILE_VERSION)
    recording_file.store_32(frame_count)
    recording_file.store_float(camera_fov)
    recording_file.store_32(metadata_bytes.size())
    recording_file.store_32(payload_to_save.size())
    recording_file.store_32(compressed_payload.size())
    recording_file.store_buffer(metadata_bytes)
    recording_file.store_buffer(compressed_payload)
    recording_file.close()

    var storage := DirAccess.open(storage_directory)
    if storage == null:
        return false
    if storage.file_exists(final_name):
        var remove_error := storage.remove(final_name)
        if remove_error != OK:
            push_warning("Could not replace run recording for level '%s'." % level_id)
            return false
    var rename_error := storage.rename(temporary_name, final_name)
    if rename_error != OK:
        push_warning("Could not finish run recording for level '%s'." % level_id)
        return false
    return true


static func queue_save_for_level(
    level_id: String,
    frame_payload: PackedByteArray,
    frame_count: int,
    camera_fov: float,
    storage_directory: String = STORAGE_DIRECTORY,
    run_metadata: Dictionary = {},
    used_payload_size: int = -1
) -> int:
    var payload_size := frame_payload.size() if used_payload_size < 0 else used_payload_size
    if not _is_valid_recording(level_id, frame_payload, frame_count, payload_size):
        return INVALID_TASK_ID

    # The recorder transfers ownership of this immutable snapshot so even large metadata stays
    # off the gameplay thread rather than being deep-copied before the worker starts.
    var metadata_snapshot := run_metadata
    var save_task_id := WorkerThreadPool.add_task(
        func() -> void:
            save_for_level(
                level_id,
                frame_payload,
                frame_count,
                camera_fov,
                storage_directory,
                metadata_snapshot,
                payload_size
            ),
        false,
        "Save run recording"
    )
    if save_task_id == INVALID_TASK_ID:
        return INVALID_TASK_ID
    return save_task_id


static func load_for_level(
    level_id: String,
    storage_directory: String = STORAGE_DIRECTORY
) -> Dictionary:
    if level_id.is_empty():
        return {}

    var recording_file := FileAccess.open(
        get_path_for_level(level_id, storage_directory),
        FileAccess.READ
    )
    if recording_file == null:
        return {}
    if recording_file.get_32() != FILE_MAGIC:
        return {}
    var file_version := recording_file.get_16()
    if file_version != FileVersion.PoseFrames and file_version != FileVersion.RunMetadata:
        return {}

    var frame_count := recording_file.get_32()
    var camera_fov := recording_file.get_float()
    var metadata_size := recording_file.get_32() if file_version >= FileVersion.RunMetadata else 0
    var payload_size := recording_file.get_32()
    var compressed_size := recording_file.get_32()
    if frame_count <= 0 or metadata_size < 0 or metadata_size > MAX_METADATA_BYTES \
            or payload_size <= 0 or payload_size > MAX_PAYLOAD_BYTES \
            or compressed_size <= 0 \
            or metadata_size + compressed_size > recording_file.get_length() - recording_file.get_position() \
            or frame_count > floori(
                float(payload_size) / float(NORMAL_FRAME_MINIMUM_SIZE)
            ) + 1:
        return {}
    var run_metadata: Dictionary = {}
    if metadata_size > 0:
        var metadata_bytes := recording_file.get_buffer(metadata_size)
        if metadata_bytes.size() != metadata_size:
            return {}
        var parsed_metadata: Variant = JSON.parse_string(metadata_bytes.get_string_from_utf8())
        if parsed_metadata is Dictionary:
            run_metadata = parsed_metadata
        else:
            return {}
    var compressed_payload := recording_file.get_buffer(compressed_size)
    if compressed_payload.size() != compressed_size:
        return {}
    var payload := compressed_payload.decompress(payload_size, FileAccess.COMPRESSION_ZSTD)
    if payload.size() != payload_size:
        return {}
    var decoded := decode_payload(payload, frame_count, camera_fov)
    if not decoded.is_empty():
        decoded["run_metadata"] = run_metadata
    return decoded


static func load_for_level_after_task(
    level_id: String,
    save_task_id: int,
    storage_directory: String = STORAGE_DIRECTORY
) -> Dictionary:
    if save_task_id != INVALID_TASK_ID:
        WorkerThreadPool.wait_for_task_completion(save_task_id)
    return load_for_level(level_id, storage_directory)


static func decode_payload(
    payload: PackedByteArray,
    frame_count: int,
    camera_fov: float
) -> Dictionary:
    var frame_deltas := PackedFloat32Array()
    var frame_times := PackedFloat32Array()
    var movement_inputs := PackedVector2Array()
    var camera_inputs := PackedVector2Array()
    var button_states := PackedByteArray()
    var player_positions := PackedVector3Array()
    var player_yaws := PackedFloat32Array()
    var camera_positions := PackedVector3Array()
    var camera_rotations := PackedVector4Array()
    frame_deltas.resize(frame_count)
    frame_times.resize(frame_count)
    movement_inputs.resize(frame_count)
    camera_inputs.resize(frame_count)
    button_states.resize(frame_count)
    player_positions.resize(frame_count)
    player_yaws.resize(frame_count)
    camera_positions.resize(frame_count)
    camera_rotations.resize(frame_count)

    var offset := 0
    var elapsed := 0.0
    var previous_player_position := Vector3.ZERO
    var previous_camera_position := Vector3.ZERO
    for frame_index in frame_count:
        if offset + 23 > payload.size():
            return {}
        var delta := maxf(payload.decode_float(offset), MIN_FRAME_DELTA)
        offset += 4
        var movement := Vector2(
            _decode_normalized(payload.decode_u16(offset)),
            _decode_normalized(payload.decode_u16(offset + 2))
        )
        offset += 4
        var camera_control := Vector2(
            _decode_normalized(payload.decode_u16(offset)),
            _decode_normalized(payload.decode_u16(offset + 2))
        )
        offset += 4
        var flags := payload.decode_u8(offset)
        offset += 1
        var player_yaw := _decode_angle(payload.decode_u16(offset))
        offset += 2
        var camera_rotation := Quaternion(
            _decode_normalized(payload.decode_u16(offset)),
            _decode_normalized(payload.decode_u16(offset + 2)),
            _decode_normalized(payload.decode_u16(offset + 4)),
            _decode_normalized(payload.decode_u16(offset + 6))
        ).normalized()
        offset += 8

        var player_position := Vector3.ZERO
        var camera_position := Vector3.ZERO
        if flags & FrameFlags.AbsolutePosition:
            if offset + 24 > payload.size():
                return {}
            player_position = Vector3(
                payload.decode_float(offset),
                payload.decode_float(offset + 4),
                payload.decode_float(offset + 8)
            )
            camera_position = Vector3(
                payload.decode_float(offset + 12),
                payload.decode_float(offset + 16),
                payload.decode_float(offset + 20)
            )
            offset += 24
        else:
            if offset + 12 > payload.size():
                return {}
            player_position = previous_player_position + Vector3(
                float(_decode_signed(payload.decode_u16(offset))),
                float(_decode_signed(payload.decode_u16(offset + 2))),
                float(_decode_signed(payload.decode_u16(offset + 4)))
            ) / POSITION_SCALE
            camera_position = previous_camera_position + Vector3(
                float(_decode_signed(payload.decode_u16(offset + 6))),
                float(_decode_signed(payload.decode_u16(offset + 8))),
                float(_decode_signed(payload.decode_u16(offset + 10)))
            ) / POSITION_SCALE
            offset += 12

        frame_deltas[frame_index] = delta
        frame_times[frame_index] = elapsed
        movement_inputs[frame_index] = movement
        camera_inputs[frame_index] = camera_control
        button_states[frame_index] = flags & (
            FrameFlags.JumpPressed | FrameFlags.DropPressed | FrameFlags.CameraAvailable
        )
        player_positions[frame_index] = player_position
        player_yaws[frame_index] = player_yaw
        camera_positions[frame_index] = camera_position
        camera_rotations[frame_index] = Vector4(
            camera_rotation.x,
            camera_rotation.y,
            camera_rotation.z,
            camera_rotation.w
        )
        previous_player_position = player_position
        previous_camera_position = camera_position
        elapsed += delta

    if offset != payload.size():
        return {}
    return {
        "frame_deltas": frame_deltas,
        "frame_times": frame_times,
        "movement_inputs": movement_inputs,
        "camera_inputs": camera_inputs,
        "button_states": button_states,
        "player_positions": player_positions,
        "player_yaws": player_yaws,
        "camera_positions": camera_positions,
        "camera_rotations": camera_rotations,
        "camera_fov": camera_fov,
        "duration": elapsed,
    }


static func get_path_for_level(
    level_id: String,
    storage_directory: String = STORAGE_DIRECTORY
) -> String:
    return "%s/%s%s" % [storage_directory, level_id.validate_filename(), FILE_EXTENSION]


static func remove_for_level(
    level_id: String,
    storage_directory: String = STORAGE_DIRECTORY
) -> void:
    var storage := DirAccess.open(storage_directory)
    if storage == null:
        return
    storage.remove("%s%s" % [level_id.validate_filename(), FILE_EXTENSION])


static func clear_all(storage_directory: String = STORAGE_DIRECTORY) -> void:
    var storage := DirAccess.open(storage_directory)
    if storage == null:
        return
    for file_name in storage.get_files():
        if file_name.ends_with(FILE_EXTENSION) or file_name.ends_with("%s.tmp" % FILE_EXTENSION):
            storage.remove(file_name)


static func _ensure_storage_directory(storage_directory: String) -> bool:
    var global_storage_path := ProjectSettings.globalize_path(storage_directory)
    if DirAccess.dir_exists_absolute(global_storage_path):
        return true
    return DirAccess.make_dir_recursive_absolute(global_storage_path) == OK


static func _is_valid_recording(
    level_id: String,
    frame_payload: PackedByteArray,
    frame_count: int,
    used_payload_size: int = -1
) -> bool:
    var payload_size := frame_payload.size() if used_payload_size < 0 else used_payload_size
    return not level_id.is_empty() \
        and frame_count > 0 \
        and not frame_payload.is_empty() \
        and payload_size > 0 \
        and payload_size <= frame_payload.size() \
        and payload_size <= MAX_PAYLOAD_BYTES


static func _decode_signed(encoded: int) -> int:
    return encoded - 65536 if encoded >= 32768 else encoded


static func _decode_normalized(encoded: int) -> float:
    return clampf(float(_decode_signed(encoded)) / ROTATION_SCALE, -1.0, 1.0)


static func _decode_angle(encoded: int) -> float:
    return _decode_normalized(encoded) * PI
