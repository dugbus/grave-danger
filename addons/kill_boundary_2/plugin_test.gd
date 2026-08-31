extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/kill_boundary_2/plugin.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/kill_boundary_2/plugin.gd")
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("selection_changed.disconnect"),
		"The plugin declares selection signal cleanup."
	)
	expect(
		source.contains("get_undo_redo"),
		"The plugin registers editor UndoRedo with authoring tools."
	)
	expect(
		source.contains("configure_editor_interface(get_editor_interface())"),
		"The registration shim lets pose navigation update the Inspector."
	)
	expect(
		source.contains("_bottom_panel_button.visible = boundary != null"),
		"The bottom-panel tab is hidden when no Kill Boundary 2 selection can use it."
	)
	expect(
		source.contains("_gizmo_plugin.bind_boundary(boundary)"),
		"Boundary selection explicitly activates every pose's viewport preview gizmo."
	)
	expect(
		not source.contains("_restore_active_pose_selection")
		and not source.contains("get_editor_interface().edit_node(pose)"),
		"Selecting the boundary root leaves it selected so level editors can inspect or delete it."
	)

	var boundary := GDKillBoundary2.new()
	var implementation_child := Node3D.new()
	implementation_child.name = "BoundarySpace"
	boundary.add_child(implementation_child)
	expect_equal(
		SUBJECT._resolve_selected_boundary(implementation_child),
		boundary,
		"Selecting an implementation child keeps its owning boundary panel active."
	)

	var second_pose_index := boundary.sequence.add_default_pose()
	var second_pose := boundary.sequence.get_pose(second_pose_index)
	var pose_child := Node.new()
	second_pose.add_child(pose_child)
	boundary.set_editor_active_pose(0)
	expect(
		SUBJECT._resolve_selected_boundary(pose_child) == boundary
		and boundary.editor_active_pose_index == second_pose_index,
		"Selecting a pose descendant activates that pose and keeps its boundary bound."
	)

	var unrelated := Node.new()
	expect(
		SUBJECT._resolve_selected_boundary(unrelated) == null,
		"Nodes outside Kill Boundary 2 do not activate its editor panel."
	)
	unrelated.free()
	boundary.free()
