extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://placeables/kill-boundary-2/editor/kill_boundary_2_editor_controller.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT, "res://placeables/kill-boundary-2/editor/kill_boundary_2_editor_controller.gd"
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("commit_action(false)"),
		"Editor changes register their already-applied state without replaying it and losing selection."
	)
	var boundary := GDKillBoundary2.new()
	var controller := GDKillBoundary2EditorController.new()
	controller.configure(boundary)
	controller.add_pose()
	expect_equal(
		boundary.sequence.get_pose_count(),
		2,
		"The editor controller adds through the sequence API."
	)
	controller.duplicate_pose()
	expect_equal(
		boundary.sequence.get_pose_count(), 3, "The editor controller duplicates the active pose."
	)
	controller.set_pose_easing(GDKillBoundary2Pose.TransitionEasing.Accelerate)
	expect_equal(
		boundary.sequence.get_pose(controller.active_pose_index).outgoing_easing,
		GDKillBoundary2Pose.TransitionEasing.Accelerate,
		"Changing easing retains the active pose while applying the authored value."
	)
	var pose := boundary.sequence.get_pose(controller.active_pose_index)
	pose.set_authored_transform(Vector3(10.0, 0.0, 5.0), deg_to_rad(90.0))
	var fixed_corner_before := pose.transform * Vector3(-4.0, 0.0, -4.0)
	var resized := controller.size_from_handle(
		pose,
		GDKillBoundary2EditorController.HandleKind.CornerPositivePositive,
		Vector3(6.0, 0.0, 3.0)
	)
	var repositioned := controller.position_from_handle(
		pose, GDKillBoundary2EditorController.HandleKind.CornerPositivePositive, resized
	)
	var resized_transform := Transform3D(pose.basis, repositioned)
	var fixed_corner_after := resized_transform * Vector3(-resized.x * 0.5, 0.0, -resized.y * 0.5)
	expect(
		resized.is_equal_approx(Vector2(10.0, 7.0))
		and fixed_corner_after.is_equal_approx(fixed_corner_before),
		"Dragging a rotated corner changes size and origin while its opposite corner stays fixed."
	)
	var edge_resized := controller.size_from_handle(
		pose,
		GDKillBoundary2EditorController.HandleKind.WidthNegative,
		Vector3(-6.0, 0.0, 0.0)
	)
	var edge_repositioned := controller.position_from_handle(
		pose, GDKillBoundary2EditorController.HandleKind.WidthNegative, edge_resized
	)
	var fixed_edge_before := pose.transform * Vector3(4.0, 0.0, 0.0)
	var fixed_edge_after := Transform3D(pose.basis, edge_repositioned) * Vector3(
		edge_resized.x * 0.5, 0.0, 0.0
	)
	expect(
		edge_resized.is_equal_approx(Vector2(10.0, 8.0))
		and fixed_edge_after.is_equal_approx(fixed_edge_before),
		"Dragging an edge moves only that edge and preserves the opposite edge in world space."
	)
	var clamped_size := controller.size_from_handle(
		pose,
		GDKillBoundary2EditorController.HandleKind.WidthPositive,
		Vector3(-100.0, 0.0, 0.0)
	)
	var clamped_position := controller.position_from_handle(
		pose, GDKillBoundary2EditorController.HandleKind.WidthPositive, clamped_size
	)
	var clamped_fixed_after := Transform3D(pose.basis, clamped_position) * Vector3(
		-clamped_size.x * 0.5, 0.0, 0.0
	)
	expect(
		is_equal_approx(clamped_size.x, GDKillBoundary2Pose.MINIMUM_SIZE)
		and clamped_fixed_after.is_equal_approx(pose.transform * Vector3(-4.0, 0.0, 0.0)),
		"Minimum-size clamping does not move the fixed edge."
	)
	controller.delete_pose()
	expect_equal(
		boundary.sequence.get_pose_count(),
		2,
		"The editor controller deletes through the sequence API."
	)
	controller.set_retiming_mode(GDKillBoundary2Sequence.RetimingMode.MoveThisPoseOnly)
	controller.set_playback_speed(1.5)
	controller.set_loop_return_seconds(2.25)
	expect(
		(
			boundary.retiming_mode == GDKillBoundary2Sequence.RetimingMode.MoveThisPoseOnly
			and is_equal_approx(boundary.playback_speed, 1.5)
			and is_equal_approx(boundary.loop_return_seconds, 2.25)
		),
		"Per-boundary timing properties use the shared editor mutation controller."
	)
	boundary.free()
