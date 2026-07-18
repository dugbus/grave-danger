extends Node
class_name GDRunRecorder

## Captures one compact sample after every gameplay physics frame and saves it per level.

const RUN_RECORDING := preload("res://game/run_recording.gd")
const INITIAL_BUFFER_SIZE := 64 * 1024
const NORMAL_FRAME_SIZE := 35
const ABSOLUTE_FRAME_SIZE := 47
const POSITION_SCALE := RUN_RECORDING.POSITION_SCALE
const NORMALIZED_SCALE := RUN_RECORDING.ROTATION_SCALE
const SIGNED_16_MIN := -32768
const SIGNED_16_MAX := 32767

var level_id := ""
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


func begin_recording(
    recorded_level_id: String,
    player_node: Node3D,
    camera_node: Camera3D
) -> bool:
    if recorded_level_id.is_empty() or player_node == null:
        return false

    level_id = recorded_level_id
    player = player_node
    pivot = player.get_node_or_null(^"Pivot") as Node3D
    camera = camera_node
    camera_fov = camera.fov if camera != null else camera_fov
    frame_payload.resize(INITIAL_BUFFER_SIZE)
    recording_enabled = true
    set_physics_process(true)
    return true


func _physics_process(delta: float) -> void:
    if not recording_enabled or player == null:
        return

    var active_camera := get_viewport().get_camera_3d()
    if active_camera != null:
        camera = active_camera
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
    var camera_position := camera_transform.origin
    var player_delta := (player_position - previous_player_position) * POSITION_SCALE
    var camera_delta := (camera_position - previous_camera_position) * POSITION_SCALE
    var requires_absolute_position := frame_count == 0 \
        or not _fits_signed_16(player_delta) or not _fits_signed_16(camera_delta)
    _ensure_capacity(ABSOLUTE_FRAME_SIZE if requires_absolute_position else NORMAL_FRAME_SIZE)

    _encode_float(delta)
    _encode_normalized(movement_input.x)
    _encode_normalized(movement_input.y)
    _encode_normalized(camera_input.x)
    _encode_normalized(camera_input.y)
    var flags := 0
    if jump_pressed:
        flags |= RUN_RECORDING.FrameFlags.JumpPressed
    if drop_pressed:
        flags |= RUN_RECORDING.FrameFlags.DropPressed
    if requires_absolute_position:
        flags |= RUN_RECORDING.FrameFlags.AbsolutePosition
    if camera_available:
        flags |= RUN_RECORDING.FrameFlags.CameraAvailable
    _encode_u8(flags)
    _encode_angle(player_yaw)

    var camera_rotation := camera_transform.basis.get_rotation_quaternion().normalized()
    _encode_normalized(camera_rotation.x)
    _encode_normalized(camera_rotation.y)
    _encode_normalized(camera_rotation.z)
    _encode_normalized(camera_rotation.w)
    if requires_absolute_position:
        _encode_vector3_float(player_position)
        _encode_vector3_float(camera_position)
    else:
        _encode_vector3_delta(player_delta)
        _encode_vector3_delta(camera_delta)

    if requires_absolute_position:
        previous_player_position = player_position
        previous_camera_position = camera_position
    else:
        previous_player_position += Vector3(
            roundi(player_delta.x),
            roundi(player_delta.y),
            roundi(player_delta.z)
        ) / POSITION_SCALE
        previous_camera_position += Vector3(
            roundi(camera_delta.x),
            roundi(camera_delta.y),
            roundi(camera_delta.z)
        ) / POSITION_SCALE
    frame_count += 1


func finish_recording(save_to_disk: bool = true) -> PackedByteArray:
    if recording_saved:
        return frame_payload
    recording_enabled = false
    set_physics_process(false)
    frame_payload.resize(bytes_used)
    if save_to_disk and frame_count > 0:
        RUN_RECORDING.save_for_level(level_id, frame_payload, frame_count, camera_fov)
    recording_saved = true
    return frame_payload


func _exit_tree() -> void:
    finish_recording()


func _ensure_capacity(additional_bytes: int) -> void:
    var required_size := bytes_used + additional_bytes
    if required_size <= frame_payload.size():
        return
    var expanded_size := maxi(frame_payload.size(), INITIAL_BUFFER_SIZE)
    while expanded_size < required_size:
        expanded_size *= 2
    frame_payload.resize(expanded_size)


func _fits_signed_16(value: Vector3) -> bool:
    return value.x >= SIGNED_16_MIN and value.x <= SIGNED_16_MAX \
        and value.y >= SIGNED_16_MIN and value.y <= SIGNED_16_MAX \
        and value.z >= SIGNED_16_MIN and value.z <= SIGNED_16_MAX


func _encode_u8(value: int) -> void:
    frame_payload.encode_u8(bytes_used, value)
    bytes_used += 1


func _encode_u16(value: int) -> void:
    frame_payload.encode_u16(bytes_used, value & 0xffff)
    bytes_used += 2


func _encode_float(value: float) -> void:
    frame_payload.encode_float(bytes_used, value)
    bytes_used += 4


func _encode_normalized(value: float) -> void:
    _encode_u16(roundi(clampf(value, -1.0, 1.0) * NORMALIZED_SCALE))


func _encode_angle(value: float) -> void:
    _encode_normalized(wrapf(value, -PI, PI) / PI)


func _encode_vector3_float(value: Vector3) -> void:
    _encode_float(value.x)
    _encode_float(value.y)
    _encode_float(value.z)


func _encode_vector3_delta(value: Vector3) -> void:
    _encode_u16(roundi(value.x))
    _encode_u16(roundi(value.y))
    _encode_u16(roundi(value.z))
