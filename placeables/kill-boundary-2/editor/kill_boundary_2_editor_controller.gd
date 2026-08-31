@tool
class_name GDKillBoundary2EditorController
extends RefCounted

## Coordinates editor mutations so every authoring path shares snapshots and UndoRedo.

signal active_pose_changed(pose_index: int)
signal boundary_changed

enum HandleKind {
	WidthPositive,
	WidthNegative,
	DepthPositive,
	DepthNegative,
	CornerPositivePositive,
	CornerNegativePositive,
	CornerNegativeNegative,
	CornerPositiveNegative,
	Rounding,
}

var boundary: GDKillBoundary2
var undo_redo: EditorUndoRedoManager
var active_pose_index := 0


func configure(new_boundary: GDKillBoundary2, new_undo_redo: EditorUndoRedoManager = null) -> void:
	boundary = new_boundary
	undo_redo = new_undo_redo
	active_pose_index = (
		0
		if boundary == null
		else clampi(
			boundary.editor_active_pose_index, 0, maxi(boundary.sequence.get_pose_count() - 1, 0)
		)
	)


func select_pose(index: int) -> void:
	if boundary == null:
		return
	active_pose_index = clampi(index, 0, maxi(boundary.sequence.get_pose_count() - 1, 0))
	boundary.set_editor_active_pose(active_pose_index)
	boundary.preview_seek(boundary.sequence.get_pose(active_pose_index).time_seconds)
	active_pose_changed.emit(active_pose_index)


func add_pose() -> void:
	_commit_sequence_change(
		&"Add Kill Boundary Pose",
		func() -> void: active_pose_index = boundary.sequence.add_default_pose()
	)
	select_pose(active_pose_index)


func duplicate_pose() -> void:
	_commit_sequence_change(
		&"Duplicate Kill Boundary Pose",
		func() -> void: active_pose_index = boundary.sequence.duplicate_pose(active_pose_index)
	)
	select_pose(active_pose_index)


func delete_pose() -> void:
	if boundary == null or boundary.sequence.get_pose_count() <= 1:
		return
	_commit_sequence_change(
		&"Delete Kill Boundary Pose",
		func() -> void: active_pose_index = boundary.sequence.delete_pose(active_pose_index)
	)
	select_pose(active_pose_index)


func set_pose_time(value: float) -> void:
	_commit_sequence_change(
		&"Set Kill Boundary Pose Time",
		func() -> void:
			boundary.sequence.set_pose_time(active_pose_index, value, boundary.retiming_mode)
	)
	select_pose(active_pose_index)


func set_pose_easing(value: GDKillBoundary2Pose.TransitionEasing) -> void:
	_commit_sequence_change(
		&"Set Kill Boundary Pose Easing",
		func() -> void: boundary.sequence.set_pose_easing(active_pose_index, value)
	)
	select_pose(active_pose_index)


func set_retiming_mode(value: GDKillBoundary2Sequence.RetimingMode) -> void:
	_commit_boundary_property(
		&"Set Kill Boundary Retiming Mode", &"retiming_mode", boundary.retiming_mode, value
	)


func set_playback_speed(value: float) -> void:
	_commit_boundary_property(
		&"Set Kill Boundary Preview Speed", &"playback_speed", boundary.playback_speed, value
	)


func set_loop_return_seconds(value: float) -> void:
	_commit_boundary_property(
		&"Set Kill Boundary Loop Return Duration",
		&"loop_return_seconds",
		boundary.loop_return_seconds,
		value
	)


func set_pose_transform(index: int, transform: Transform3D) -> void:
	var yaw := transform.basis.get_euler(EULER_ORDER_YXZ).y
	_commit_sequence_change(
		&"Transform Kill Boundary Pose",
		func() -> void: boundary.sequence.set_pose_transform(index, transform.origin, yaw)
	)
	select_pose(index)


func set_pose_size(index: int, size: Vector2) -> void:
	_commit_sequence_change(
		&"Resize Kill Boundary Pose", func() -> void: boundary.sequence.set_pose_size(index, size)
	)
	select_pose(index)


func set_pose_rounding(index: int, rounding: float) -> void:
	_commit_sequence_change(
		&"Round Kill Boundary Pose",
		func() -> void: boundary.sequence.set_pose_rounding(index, rounding)
	)
	select_pose(index)


func get_handle_positions(pose: GDKillBoundary2Pose) -> PackedVector3Array:
	var half := pose.size * 0.5
	var local_positions := PackedVector2Array(
		[
			Vector2(half.x, 0.0),
			Vector2(-half.x, 0.0),
			Vector2(0.0, half.y),
			Vector2(0.0, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y) * (1.0 - pose.rounding * 0.5),
		]
	)
	var result := PackedVector3Array()
	for local_position in local_positions:
		result.append(Vector3(local_position.x, 0.0, local_position.y))
	return result


func size_from_handle(
	pose: GDKillBoundary2Pose, kind: HandleKind, pose_local_hit: Vector3
) -> Vector2:
	var offset := Vector2(pose_local_hit.x, pose_local_hit.z)
	var signs := _get_handle_axis_signs(kind)
	var half := pose.size * 0.5
	var result := pose.size
	if signs.x != 0:
		result.x = maxf(float(signs.x) * offset.x + half.x, GDKillBoundary2Pose.MINIMUM_SIZE)
	if signs.y != 0:
		result.y = maxf(float(signs.y) * offset.y + half.y, GDKillBoundary2Pose.MINIMUM_SIZE)
	return result


## Moves the pose centre so the edge or corner opposite the dragged handle stays fixed.
func position_from_handle(
	pose: GDKillBoundary2Pose, kind: HandleKind, resized: Vector2
) -> Vector3:
	var signs := _get_handle_axis_signs(kind)
	var local_shift := Vector3(
		float(signs.x) * (resized.x - pose.size.x) * 0.5,
		0.0,
		float(signs.y) * (resized.y - pose.size.y) * 0.5
	)
	return pose.position + pose.basis * local_shift


func rounding_from_handle(pose: GDKillBoundary2Pose, pose_local_hit: Vector3) -> float:
	var offset := Vector2(pose_local_hit.x, pose_local_hit.z).abs()
	var half := pose.size * 0.5
	var normalized_inset := maxf(
		1.0 - offset.x / maxf(half.x, 0.05), 1.0 - offset.y / maxf(half.y, 0.05)
	)
	return clampf(normalized_inset * 2.0, 0.0, 1.0)


func _get_handle_axis_signs(kind: HandleKind) -> Vector2i:
	match kind:
		HandleKind.WidthPositive:
			return Vector2i(1, 0)
		HandleKind.WidthNegative:
			return Vector2i(-1, 0)
		HandleKind.DepthPositive:
			return Vector2i(0, 1)
		HandleKind.DepthNegative:
			return Vector2i(0, -1)
		HandleKind.CornerPositivePositive:
			return Vector2i(1, 1)
		HandleKind.CornerNegativePositive:
			return Vector2i(-1, 1)
		HandleKind.CornerNegativeNegative:
			return Vector2i(-1, -1)
		HandleKind.CornerPositiveNegative:
			return Vector2i(1, -1)
	return Vector2i.ZERO


func _commit_sequence_change(action_name: StringName, mutation: Callable) -> void:
	if boundary == null or boundary.sequence == null:
		return
	var before := boundary.sequence.create_snapshot()
	mutation.call()
	var after := boundary.sequence.create_snapshot()
	if before == after:
		return
	if undo_redo != null:
		undo_redo.create_action(String(action_name), UndoRedo.MERGE_ENDS)
		undo_redo.add_do_method(boundary.sequence, &"restore_snapshot", after)
		undo_redo.add_undo_method(boundary.sequence, &"restore_snapshot", before)
		# The mutation is already live. Register it without replaying the do method so
		# Godot keeps the selected pose and the focused editor control intact.
		undo_redo.commit_action(false)
	boundary_changed.emit()


func _commit_boundary_property(
	action_name: StringName, property_name: StringName, before: Variant, after: Variant
) -> void:
	if boundary == null or before == after:
		return
	if undo_redo == null:
		boundary.set(property_name, after)
	else:
		undo_redo.create_action(String(action_name), UndoRedo.MERGE_ENDS)
		undo_redo.add_do_property(boundary, property_name, after)
		undo_redo.add_undo_property(boundary, property_name, before)
		undo_redo.commit_action()
	boundary_changed.emit()
