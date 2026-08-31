@tool
class_name GDKillBoundary2EditorOverlay
extends Node

## Owns transient pose/time labels while a Kill Boundary 2 is selected.

var boundary: GDKillBoundary2
var _labels: Array[Label3D] = []


func bind_boundary(new_boundary: GDKillBoundary2) -> void:
	_clear_labels()
	boundary = new_boundary
	if boundary == null:
		return
	if not boundary.sequence.sequence_changed.is_connected(_rebuild):
		boundary.sequence.sequence_changed.connect(_rebuild)
	_rebuild()


func _exit_tree() -> void:
	_clear_labels()


func _rebuild() -> void:
	_clear_labels(false)
	if boundary == null or not is_instance_valid(boundary):
		return
	for index in boundary.sequence.get_pose_count():
		var pose := boundary.sequence.get_pose(index)
		_add_label(
			"Pose %d\n%.2f s" % [index + 1, pose.time_seconds],
			_get_pose_position(pose) + Vector3(0.0, 1.1, 0.0)
		)
		if index + 1 < boundary.sequence.get_pose_count():
			var next_pose := boundary.sequence.get_pose(index + 1)
			_add_label(
				"%.2f s" % (next_pose.time_seconds - pose.time_seconds),
				_get_pose_position(pose).lerp(_get_pose_position(next_pose), 0.5)
				+ Vector3(0.0, 0.55, 0.0)
			)


func _add_label(text_value: String, world_position: Vector3) -> void:
	var label := Label3D.new()
	label.name = "KillBoundary2EditorLabel"
	label.text = text_value
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color(1.0, 0.92, 0.45)
	boundary.add_child(label, false, Node.INTERNAL_MODE_FRONT)
	if label.is_inside_tree():
		label.global_position = world_position
	else:
		label.position = world_position
	_labels.append(label)


func _get_pose_position(pose: GDKillBoundary2Pose) -> Vector3:
	return pose.global_position if pose.is_inside_tree() else pose.position


func _clear_labels(disconnect := true) -> void:
	if (
		disconnect
		and boundary != null
		and is_instance_valid(boundary)
		and boundary.sequence != null
		and boundary.sequence.sequence_changed.is_connected(_rebuild)
	):
		boundary.sequence.sequence_changed.disconnect(_rebuild)
	for label in _labels:
		if is_instance_valid(label):
			if label.is_inside_tree():
				label.queue_free()
			else:
				label.free()
	_labels.clear()
	if disconnect:
		boundary = null


func get_label_count() -> int:
	return _labels.size()
