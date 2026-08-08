extends RefCounted
class_name GDLevelRunPlaybackFrame


static func find_frame_index(frame_times: PackedFloat32Array, time: float) -> int:
	var low := 0
	var high := frame_times.size() - 1
	while low <= high:
		var middle := floori(float(low + high) * 0.5)
		if frame_times[middle] <= time:
			low = middle + 1
		else:
			high = middle - 1
	return clampi(high, 0, frame_times.size() - 1)


static func apply(
	recording: Dictionary,
	player: Node3D,
	pivot: Node3D,
	camera: Camera3D,
	frame_index: int,
	interpolation: float
) -> void:
	if player == null or camera == null:
		return
	var positions := recording.get("player_positions", PackedVector3Array()) \
		as PackedVector3Array
	var yaws := recording.get("player_yaws", PackedFloat32Array()) as PackedFloat32Array
	var camera_positions := recording.get("camera_positions", PackedVector3Array()) \
		as PackedVector3Array
	var camera_rotations := recording.get("camera_rotations", PackedVector4Array()) \
		as PackedVector4Array
	if frame_index < 0 or frame_index >= positions.size():
		return

	var next_index := mini(frame_index + 1, positions.size() - 1)
	player.global_position = positions[frame_index].lerp(positions[next_index], interpolation)
	if pivot != null:
		pivot.rotation.y = lerp_angle(yaws[frame_index], yaws[next_index], interpolation)
	camera.global_position = camera_positions[frame_index].lerp(
		camera_positions[next_index],
		interpolation
	)
	var current_rotation := vector_to_quaternion(camera_rotations[frame_index])
	var next_rotation := vector_to_quaternion(camera_rotations[next_index])
	camera.global_basis = Basis(current_rotation.slerp(next_rotation, interpolation))


static func vector_to_quaternion(value: Vector4) -> Quaternion:
	return Quaternion(value.x, value.y, value.z, value.w).normalized()
