extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/editor/kill_boundary_2_gizmo_plugin.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT, "res://placeables/kill-boundary-2/editor/kill_boundary_2_gizmo_plugin.gd"
	)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("gizmo.add_collision_segments(lines)"),
		"Every pose perimeter is visible and directly selectable in the viewport."
	)
	expect(
		source.contains("return for_node_3d is GDKillBoundary2Pose"),
		"The custom gizmo belongs to actual authored pose nodes."
	)
	expect(
		not source.contains("_subgizmo") and not source.contains("CENTRE_MARKER"),
		"No synthetic picking cross or sub-gizmo obscures the native transform widget."
	)
	expect(
		source.contains("if not is_active:")
		and source.contains("controller.get_handle_positions(pose)"),
		"The active pose keeps its complete edge, corner, and rounding controls."
	)
	expect(
		source.contains("controller.position_from_handle")
		and source.contains("set_pose_geometry")
		and source.contains("opposite side stays fixed"),
		"Size handles move the pose origin so the opposite edge or corner remains fixed."
	)
	expect(
		source.contains("_draw_arrows(gizmo, pose, sequence)"),
		"The active pose preview retains direction arrows for the full sequence layout."
	)
	expect(source.contains("_commit_handle"), "The gizmo registers shape handle UndoRedo commits.")
