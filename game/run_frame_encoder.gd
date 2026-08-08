extends RefCounted
class_name GDRunFrameEncoder

const RUN_RECORDING := preload("res://game/run_recording.gd")
const INITIAL_BUFFER_SIZE := 1024 * 1024
const NORMAL_FRAME_SIZE := 35
const ABSOLUTE_FRAME_SIZE := 47
const POSITION_SCALE := RUN_RECORDING.POSITION_SCALE
const NORMALIZED_SCALE := RUN_RECORDING.ROTATION_SCALE
const SIGNED_16_MIN := -32768
const SIGNED_16_MAX := 32767

var payload := PackedByteArray()
var bytes_used := 0
var previous_player_position := Vector3.ZERO
var previous_camera_position := Vector3.ZERO


func reset() -> void:
	payload = PackedByteArray()
	payload.resize(INITIAL_BUFFER_SIZE)
	bytes_used = 0
	previous_player_position = Vector3.ZERO
	previous_camera_position = Vector3.ZERO


func encode_frame(
	is_first_frame: bool,
	delta: float,
	movement_input: Vector2,
	camera_input: Vector2,
	jump_pressed: bool,
	drop_pressed: bool,
	player_position: Vector3,
	player_yaw: float,
	camera_transform: Transform3D,
	camera_available: bool
) -> void:
	var camera_position := camera_transform.origin
	var player_delta := (player_position - previous_player_position) * POSITION_SCALE
	var camera_delta := (camera_position - previous_camera_position) * POSITION_SCALE
	var requires_absolute_position := is_first_frame \
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
		previous_player_position = player_position
		previous_camera_position = camera_position
	else:
		_encode_vector3_delta(player_delta)
		_encode_vector3_delta(camera_delta)
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


func take_payload() -> PackedByteArray:
	var completed_payload := payload
	payload = PackedByteArray()
	return completed_payload


func _ensure_capacity(additional_bytes: int) -> void:
	var required_size := bytes_used + additional_bytes
	if required_size <= payload.size():
		return
	var expanded_size := maxi(payload.size(), INITIAL_BUFFER_SIZE)
	while expanded_size < required_size:
		expanded_size *= 2
	payload.resize(expanded_size)


func _fits_signed_16(value: Vector3) -> bool:
	return value.x >= SIGNED_16_MIN and value.x <= SIGNED_16_MAX \
		and value.y >= SIGNED_16_MIN and value.y <= SIGNED_16_MAX \
		and value.z >= SIGNED_16_MIN and value.z <= SIGNED_16_MAX


func _encode_u8(value: int) -> void:
	payload.encode_u8(bytes_used, value)
	bytes_used += 1


func _encode_u16(value: int) -> void:
	payload.encode_u16(bytes_used, value & 0xffff)
	bytes_used += 2


func _encode_float(value: float) -> void:
	payload.encode_float(bytes_used, value)
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
