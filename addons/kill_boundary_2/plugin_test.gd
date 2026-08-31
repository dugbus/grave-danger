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
		source.contains("node is GDKillBoundary2Pose") and source.contains("get_pose_index(pose)"),
		"Selecting an authored pose keeps the boundary panel and preview synchronized."
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
