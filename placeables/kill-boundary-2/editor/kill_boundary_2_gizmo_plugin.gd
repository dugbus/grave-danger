@tool
class_name GDKillBoundary2GizmoPlugin
extends EditorNode3DGizmoPlugin

## Draws every pose as a pickable outline and adds shape handles to the active pose.

const INACTIVE_MATERIAL := "kill_boundary_2_inactive"
const ACTIVE_MATERIAL := "kill_boundary_2_active"
const ARROW_MATERIAL := "kill_boundary_2_arrow"
const HANDLE_MATERIAL := "kill_boundary_2_handle"

var controller := GDKillBoundary2EditorController.new()
var _editor_interface: EditorInterface
var _configured_boundary: GDKillBoundary2


func _init(editor_interface: EditorInterface = null) -> void:
	_editor_interface = editor_interface
	create_material(INACTIVE_MATERIAL, Color(0.5, 0.7, 0.9, 0.45))
	create_material(ACTIVE_MATERIAL, Color(1.0, 0.72, 0.15, 1.0))
	create_material(ARROW_MATERIAL, Color(0.85, 0.9, 1.0, 0.8))
	create_handle_material(HANDLE_MATERIAL)


func configure_undo_redo(undo_redo: EditorUndoRedoManager) -> void:
	controller.undo_redo = undo_redo


func bind_boundary(new_boundary: GDKillBoundary2) -> void:
	var previous := _configured_boundary
	_disconnect_boundary_signals()
	_configured_boundary = new_boundary
	controller.configure(_configured_boundary, controller.undo_redo)
	if _configured_boundary != null:
		if not _configured_boundary.editor_active_pose_changed.is_connected(_on_pose_display_changed):
			_configured_boundary.editor_active_pose_changed.connect(_on_pose_display_changed)
		if not _configured_boundary.sequence.sequence_changed.is_connected(_on_sequence_changed):
			_configured_boundary.sequence.sequence_changed.connect(_on_sequence_changed)
	_update_boundary_gizmos(previous)
	_update_boundary_gizmos(_configured_boundary)


func _get_gizmo_name() -> String:
	return "Kill Boundary 2 Pose"


func _get_priority() -> int:
	return 2


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is GDKillBoundary2Pose


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var pose := gizmo.get_node_3d() as GDKillBoundary2Pose
	if pose == null:
		return
	var sequence := pose.get_parent() as GDKillBoundary2Sequence
	if (
		sequence == null
		or not sequence.get_parent() is GDKillBoundary2
		or sequence.get_parent() != _configured_boundary
	):
		return
	var boundary := sequence.get_parent() as GDKillBoundary2
	var pose_index := sequence.get_pose_index(pose)
	var is_active := pose_index == boundary.editor_active_pose_index
	_draw_pose(gizmo, pose, is_active)
	if not is_active:
		return
	controller.active_pose_index = pose_index
	_draw_arrows(gizmo, pose, sequence)
	var ids := PackedInt32Array()
	for id in GDKillBoundary2EditorController.HandleKind.values():
		ids.append(id as int)
	gizmo.add_handles(
		controller.get_handle_positions(pose), get_material(HANDLE_MATERIAL, gizmo), ids
	)


func _draw_pose(
	gizmo: EditorNode3DGizmo,
	pose: GDKillBoundary2Pose,
	is_active: bool
) -> void:
	var points_2d := GDKillBoundary2Geometry.build_points(pose.size, pose.rounding, 48)
	var lines := PackedVector3Array()
	for index in points_2d.size():
		var first_point := points_2d[index]
		var second_point := points_2d[(index + 1) % points_2d.size()]
		lines.append(Vector3(first_point.x, 0.08, first_point.y))
		lines.append(Vector3(second_point.x, 0.08, second_point.y))
	var material_name := ACTIVE_MATERIAL if is_active else INACTIVE_MATERIAL
	gizmo.add_lines(lines, get_material(material_name, gizmo), false)
	# Clicking any inactive outline selects its owning Pose node without adding a centre target.
	gizmo.add_collision_segments(lines)


func _draw_arrows(
	gizmo: EditorNode3DGizmo,
	selected_pose: GDKillBoundary2Pose,
	sequence: GDKillBoundary2Sequence
) -> void:
	var lines := PackedVector3Array()
	var selected_inverse := selected_pose.global_transform.affine_inverse()
	for index in sequence.get_pose_count() - 1:
		var start := selected_inverse * (
			sequence.get_pose(index).global_position + Vector3.UP * 0.18
		)
		var finish := selected_inverse * (
			sequence.get_pose(index + 1).global_position + Vector3.UP * 0.18
		)
		lines.append(start)
		lines.append(finish)
		var direction := (finish - start).normalized()
		if direction.is_zero_approx():
			continue
		var side := direction.cross(Vector3.UP).normalized() * 0.3
		lines.append(finish)
		lines.append(finish - direction * 0.65 + side)
		lines.append(finish)
		lines.append(finish - direction * 0.65 - side)
	if not lines.is_empty():
		gizmo.add_lines(lines, get_material(ARROW_MATERIAL, gizmo), false)


func _get_handle_name(_gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> String:
	return (
		"Rounding"
		if handle_id == GDKillBoundary2EditorController.HandleKind.Rounding
		else "Resize — opposite side stays fixed"
	)


func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool) -> Variant:
	var pose := gizmo.get_node_3d() as GDKillBoundary2Pose
	return (
		pose.rounding
		if handle_id == GDKillBoundary2EditorController.HandleKind.Rounding
		else {"position": pose.position, "size": pose.size}
	)


func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	_secondary: bool,
	camera: Camera3D,
	screen_position: Vector2
) -> void:
	var pose := gizmo.get_node_3d() as GDKillBoundary2Pose
	var sequence := pose.get_parent() as GDKillBoundary2Sequence
	if sequence == null:
		return
	var normal := pose.global_basis.y.normalized()
	var intersection: Variant = Plane(normal, normal.dot(pose.global_position)).intersects_ray(
		camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position)
	)
	if intersection == null:
		return
	var local_hit := pose.global_transform.affine_inverse() * (intersection as Vector3)
	var pose_index := sequence.get_pose_index(pose)
	if handle_id == GDKillBoundary2EditorController.HandleKind.Rounding:
		sequence.set_pose_rounding(pose_index, controller.rounding_from_handle(pose, local_hit))
	else:
		var kind := handle_id as GDKillBoundary2EditorController.HandleKind
		var resized := controller.size_from_handle(pose, kind, local_hit)
		sequence.set_pose_geometry(
			pose_index, controller.position_from_handle(pose, kind, resized), resized
		)
	pose.update_gizmos()


func _commit_handle(
	gizmo: EditorNode3DGizmo, handle_id: int, _secondary: bool, restore: Variant, cancel: bool
) -> void:
	var pose := gizmo.get_node_3d() as GDKillBoundary2Pose
	var sequence := pose.get_parent() as GDKillBoundary2Sequence
	if sequence == null:
		return
	var pose_index := sequence.get_pose_index(pose)
	if handle_id == GDKillBoundary2EditorController.HandleKind.Rounding:
		_commit_rounding_handle(sequence, pose_index, pose.rounding, restore, cancel)
	else:
		_commit_size_handle(sequence, pose_index, pose, restore, cancel)
	pose.update_gizmos()


func _commit_rounding_handle(
	sequence: GDKillBoundary2Sequence,
	pose_index: int,
	current: float,
	restore: Variant,
	cancel: bool
) -> void:
	if cancel:
		sequence.set_pose_rounding(pose_index, float(restore))
	elif controller.undo_redo != null:
		controller.undo_redo.create_action("Round Kill Boundary Pose", UndoRedo.MERGE_ENDS)
		controller.undo_redo.add_do_method(sequence, &"set_pose_rounding", pose_index, current)
		controller.undo_redo.add_undo_method(sequence, &"set_pose_rounding", pose_index, restore)
		controller.undo_redo.commit_action(false)


func _commit_size_handle(
	sequence: GDKillBoundary2Sequence,
	pose_index: int,
	pose: GDKillBoundary2Pose,
	restore: Variant,
	cancel: bool
) -> void:
	var restore_values := restore as Dictionary
	var restore_position := restore_values.get("position", pose.position) as Vector3
	var restore_size := restore_values.get("size", pose.size) as Vector2
	if cancel:
		sequence.set_pose_geometry(pose_index, restore_position, restore_size)
	elif controller.undo_redo != null:
		controller.undo_redo.create_action("Resize Kill Boundary Pose", UndoRedo.MERGE_ENDS)
		controller.undo_redo.add_do_method(
			sequence, &"set_pose_geometry", pose_index, pose.position, pose.size
		)
		controller.undo_redo.add_undo_method(
			sequence, &"set_pose_geometry", pose_index, restore_position, restore_size
		)
		controller.undo_redo.commit_action(false)


func _disconnect_boundary_signals() -> void:
	if _configured_boundary == null or not is_instance_valid(_configured_boundary):
		return
	if _configured_boundary.editor_active_pose_changed.is_connected(_on_pose_display_changed):
		_configured_boundary.editor_active_pose_changed.disconnect(_on_pose_display_changed)
	if (
		_configured_boundary.sequence != null
		and _configured_boundary.sequence.sequence_changed.is_connected(_on_sequence_changed)
	):
		_configured_boundary.sequence.sequence_changed.disconnect(_on_sequence_changed)


func _on_pose_display_changed(_pose_index: int) -> void:
	_update_boundary_gizmos(_configured_boundary)


func _on_sequence_changed() -> void:
	_update_boundary_gizmos(_configured_boundary)


func _update_boundary_gizmos(boundary: GDKillBoundary2) -> void:
	if boundary == null or not is_instance_valid(boundary) or boundary.sequence == null:
		return
	for pose in boundary.sequence.get_poses():
		pose.update_gizmos()
