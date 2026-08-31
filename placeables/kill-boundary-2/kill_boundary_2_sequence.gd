@tool
class_name GDKillBoundary2Sequence
extends Node

## Owns ordered pose nodes and validates every authored sequence mutation.

signal sequence_changed
signal pose_changed(pose_index: int)

enum RetimingMode {
	ShiftFollowing,
	MoveThisPoseOnly,
}

const MINIMUM_INTERVAL_SECONDS := 0.01
const DEFAULT_NEW_POSE_SECONDS := 1.0

var _is_sanitizing := false


func _ready() -> void:
	if not child_order_changed.is_connected(_on_child_order_changed):
		child_order_changed.connect(_on_child_order_changed)
	ensure_default_pose()
	_connect_pose_signals()
	_sanitize_all_poses()


## Ensures a newly authored boundary contains Pose 1 at zero seconds.
func ensure_default_pose() -> void:
	if get_pose_count() > 0:
		return
	_is_sanitizing = true
	var pose := GDKillBoundary2Pose.new()
	pose.name = "Pose 1"
	_add_pose_node(pose)
	_is_sanitizing = false
	_sanitize_all_poses()


func get_pose_count() -> int:
	return get_poses().size()


func get_poses() -> Array[GDKillBoundary2Pose]:
	var result: Array[GDKillBoundary2Pose] = []
	for child in get_children():
		if child is GDKillBoundary2Pose:
			result.append(child as GDKillBoundary2Pose)
	return result


func get_pose(index: int) -> GDKillBoundary2Pose:
	var poses := get_poses()
	return poses[index] if index >= 0 and index < poses.size() else null


func get_pose_index(pose: GDKillBoundary2Pose) -> int:
	return get_poses().find(pose)


func get_duration() -> float:
	var poses := get_poses()
	return poses.back().time_seconds if poses.size() > 1 else 0.0


## Appends a new default pose one second after the sequence endpoint.
func add_default_pose() -> int:
	ensure_default_pose()
	var poses := get_poses()
	var pose := GDKillBoundary2Pose.new()
	_is_sanitizing = true
	pose.time_seconds = poses.back().time_seconds + DEFAULT_NEW_POSE_SECONDS
	_add_pose_node(pose)
	_is_sanitizing = false
	_notify_sequence_changed(get_pose_count() - 1)
	return get_pose_count() - 1


## Inserts an exact selected-pose copy and shifts all later authored times.
func duplicate_pose(index: int) -> int:
	var poses := get_poses()
	if index < 0 or index >= poses.size():
		return -1
	_is_sanitizing = true
	for later_index in range(index + 1, poses.size()):
		poses[later_index].time_seconds += DEFAULT_NEW_POSE_SECONDS
	var copy := GDKillBoundary2Pose.new()
	copy.copy_values_from(poses[index])
	copy.time_seconds += DEFAULT_NEW_POSE_SECONDS
	_add_pose_node(copy, index + 1)
	_is_sanitizing = false
	_notify_sequence_changed(index + 1)
	return index + 1


## Deletes a pose while retaining absolute times, except when establishing a new Pose 1.
func delete_pose(index: int) -> int:
	var poses := get_poses()
	if poses.size() <= 1 or index < 0 or index >= poses.size():
		return clampi(index, 0, maxi(poses.size() - 1, 0))
	_is_sanitizing = true
	var removed := poses[index]
	_disconnect_pose_signal(removed)
	remove_child(removed)
	removed.free()
	poses = get_poses()
	if index == 0:
		var offset := poses[0].time_seconds
		for pose in poses:
			pose.time_seconds -= offset
	_is_sanitizing = false
	_notify_sequence_changed(mini(index, poses.size() - 1))
	return mini(index, poses.size() - 1)


## Applies an absolute-time edit using the selected retiming policy.
func set_pose_time(index: int, requested_time: float, mode: RetimingMode) -> float:
	var poses := get_poses()
	if index <= 0 or index >= poses.size():
		return 0.0 if index == 0 else requested_time
	var minimum_time := poses[index - 1].time_seconds + MINIMUM_INTERVAL_SECONDS
	var target_time := maxf(requested_time, minimum_time)
	if mode == RetimingMode.MoveThisPoseOnly and index + 1 < poses.size():
		target_time = minf(target_time, poses[index + 1].time_seconds - MINIMUM_INTERVAL_SECONDS)
	var delta := target_time - poses[index].time_seconds
	_is_sanitizing = true
	poses[index].time_seconds = target_time
	if mode == RetimingMode.ShiftFollowing:
		for later_index in range(index + 1, poses.size()):
			poses[later_index].time_seconds += delta
	_is_sanitizing = false
	_notify_sequence_changed(index)
	return target_time


func set_pose_transform(index: int, pose_position: Vector3, yaw_radians: float) -> void:
	var pose := get_pose(index)
	if pose == null:
		return
	_is_sanitizing = true
	pose.set_authored_transform(pose_position, yaw_radians)
	_is_sanitizing = false
	_notify_pose_changed(index)


func set_pose_size(index: int, size: Vector2) -> void:
	var pose := get_pose(index)
	if pose == null:
		return
	_is_sanitizing = true
	pose.size = size
	_is_sanitizing = false
	_notify_pose_changed(index)


## Applies an anchored gizmo resize as one position-and-size authoring change.
func set_pose_geometry(index: int, pose_position: Vector3, size: Vector2) -> void:
	var pose := get_pose(index)
	if pose == null:
		return
	_is_sanitizing = true
	pose.set_authored_transform(pose_position, pose.yaw_radians)
	pose.size = size
	_is_sanitizing = false
	_notify_pose_changed(index)


func set_pose_rounding(index: int, rounding: float) -> void:
	var pose := get_pose(index)
	if pose == null:
		return
	_is_sanitizing = true
	pose.rounding = rounding
	_is_sanitizing = false
	_notify_pose_changed(index)


func set_pose_easing(index: int, easing: GDKillBoundary2Pose.TransitionEasing) -> void:
	var pose := get_pose(index)
	if pose == null:
		return
	_is_sanitizing = true
	pose.outgoing_easing = easing
	_is_sanitizing = false
	_notify_pose_changed(index)


## Captures primitive pose values for editor UndoRedo operations.
func create_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for pose in get_poses():
		snapshot.append(
			{
				"position": pose.position,
				"yaw_radians": pose.yaw_radians,
				"size": pose.size,
				"rounding": pose.rounding,
				"time_seconds": pose.time_seconds,
				"outgoing_easing": pose.outgoing_easing,
			}
		)
	return snapshot


## Restores values in place so editor selection survives UndoRedo whenever the index remains.
func restore_snapshot(snapshot: Array[Dictionary]) -> void:
	_is_sanitizing = true
	var poses := get_poses()
	while poses.size() > snapshot.size():
		var removed: GDKillBoundary2Pose = poses.pop_back()
		_disconnect_pose_signal(removed)
		remove_child(removed)
		removed.free()
	while poses.size() < snapshot.size():
		var pose := GDKillBoundary2Pose.new()
		_add_pose_node(pose)
		poses.append(pose)
	for index in snapshot.size():
		_apply_snapshot_values(poses[index], snapshot[index])
	_is_sanitizing = false
	ensure_default_pose()
	_sanitize_all_poses()
	_notify_sequence_changed(0)


func _apply_snapshot_values(pose: GDKillBoundary2Pose, values: Dictionary) -> void:
	pose.set_authored_transform(
		values.get("position", Vector3.ZERO) as Vector3,
		float(values.get("yaw_radians", 0.0))
	)
	pose.size = values.get("size", Vector2(8.0, 8.0)) as Vector2
	pose.rounding = float(values.get("rounding", 0.0))
	pose.time_seconds = float(values.get("time_seconds", 0.0))
	pose.outgoing_easing = (
		int(values.get("outgoing_easing", GDKillBoundary2Pose.TransitionEasing.Constant))
		as GDKillBoundary2Pose.TransitionEasing
	)


func _add_pose_node(pose: GDKillBoundary2Pose, pose_index := -1) -> void:
	add_child(pose)
	if pose_index >= 0:
		move_child(pose, pose_index)
	_assign_editor_owner(pose)
	_connect_pose_signal(pose)
	_rename_poses()


func _assign_editor_owner(pose: GDKillBoundary2Pose) -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var edited_root := get_tree().edited_scene_root
	# Poses placed in a level belong to that level, not to the reusable boundary scene.
	# This keeps every pose structurally editable, including Pose 1.
	if edited_root != null and edited_root != get_parent() and edited_root.is_ancestor_of(pose):
		pose.owner = edited_root


func _sanitize_all_poses() -> void:
	var poses := get_poses()
	if poses.is_empty() or _is_sanitizing:
		return
	_is_sanitizing = true
	for index in poses.size():
		if index == 0:
			poses[index].time_seconds = 0.0
		else:
			poses[index].time_seconds = maxf(
				poses[index].time_seconds,
				poses[index - 1].time_seconds + MINIMUM_INTERVAL_SECONDS
			)
	_is_sanitizing = false
	_rename_poses()


func _rename_poses() -> void:
	var poses := get_poses()
	for index in poses.size():
		poses[index].name = "Pose %d" % (index + 1)


func _connect_pose_signals() -> void:
	for pose in get_poses():
		_connect_pose_signal(pose)


func _connect_pose_signal(pose: GDKillBoundary2Pose) -> void:
	if pose != null and not pose.pose_changed.is_connected(_on_pose_node_changed):
		pose.pose_changed.connect(_on_pose_node_changed)


func _disconnect_pose_signal(pose: GDKillBoundary2Pose) -> void:
	if pose != null and pose.pose_changed.is_connected(_on_pose_node_changed):
		pose.pose_changed.disconnect(_on_pose_node_changed)


func _on_pose_node_changed(pose: GDKillBoundary2Pose) -> void:
	if _is_sanitizing:
		return
	_sanitize_all_poses()
	var index := get_pose_index(pose)
	if index >= 0:
		_notify_pose_changed(index)


func _on_child_order_changed() -> void:
	if _is_sanitizing:
		return
	_connect_pose_signals()
	_sanitize_all_poses()
	sequence_changed.emit()


func _notify_pose_changed(index: int) -> void:
	pose_changed.emit(index)
	sequence_changed.emit()


func _notify_sequence_changed(index: int) -> void:
	pose_changed.emit(index)
	sequence_changed.emit()
