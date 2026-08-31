extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_sequence.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_sequence.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var sequence := GDKillBoundary2Sequence.new()
	sequence.ensure_default_pose()
	expect(
		sequence.get_pose_count() == 1 and is_zero_approx(sequence.get_duration()),
		"A sequence creates Pose 1 at zero."
	)
	expect(
		sequence.get_pose(0) is Node3D and sequence.get_pose(0).get_parent() == sequence,
		"The sequence owns each authored pose as a scene-tree node."
	)
	sequence.add_default_pose()
	sequence.add_default_pose()
	sequence.set_pose_time(1, 2.0, GDKillBoundary2Sequence.RetimingMode.ShiftFollowing)
	expect(
		sequence.get_pose(1).time_seconds == 2.0 and sequence.get_pose(2).time_seconds == 3.0,
		"Shift-following retiming preserves later durations."
	)
	sequence.set_pose_time(1, 2.5, GDKillBoundary2Sequence.RetimingMode.MoveThisPoseOnly)
	expect(sequence.get_pose(2).time_seconds == 3.0, "Move-only retiming leaves later poses fixed.")
	sequence.set_pose_time(1, 99.0, GDKillBoundary2Sequence.RetimingMode.MoveThisPoseOnly)
	expect(
		is_equal_approx(sequence.get_pose(1).time_seconds, 2.99),
		"Move-only retiming clamps below the following pose by the minimum interval."
	)
	sequence.set_pose_time(1, -10.0, GDKillBoundary2Sequence.RetimingMode.MoveThisPoseOnly)
	expect(
		is_equal_approx(sequence.get_pose(1).time_seconds, 0.01),
		"Move-only retiming clamps above the preceding pose by the minimum interval."
	)
	var duplicate_index := sequence.duplicate_pose(1)
	expect(
		duplicate_index == 2
		and is_equal_approx(sequence.get_pose(duplicate_index).time_seconds, 5.01)
		and is_equal_approx(sequence.get_pose(3).time_seconds, 8.0),
		"Duplicating inserts five seconds later and shifts every later pose by five seconds."
	)
	sequence.delete_pose(0)
	expect(
		is_zero_approx(sequence.get_pose(0).time_seconds),
		"Deleting Pose 1 rebases the remaining sequence."
	)
	var first_time_before_delete := sequence.get_pose(0).time_seconds
	sequence.delete_pose(1)
	expect(
		is_equal_approx(sequence.get_pose(0).time_seconds, first_time_before_delete),
		"Deleting a non-first pose leaves other absolute times unchanged."
	)
	var snapshot := sequence.create_snapshot()
	sequence.add_default_pose()
	sequence.restore_snapshot(snapshot)
	expect(
		sequence.get_pose_count() == snapshot.size(), "Snapshots restore the complete pose list."
	)
	var retained_source_pose := sequence.get_pose(0)
	var before_duplicate := sequence.create_snapshot()
	sequence.duplicate_pose(0)
	var after_duplicate := sequence.create_snapshot()
	sequence.restore_snapshot(before_duplicate)
	sequence.restore_snapshot(after_duplicate)
	expect(
		sequence.get_pose(0) == retained_source_pose,
		"Snapshot UndoRedo preserves pose node identity instead of invalidating editor selection."
	)
	var timed_pose := sequence.get_pose(1)
	var before_time_edit := sequence.create_snapshot()
	sequence.set_pose_time(
		1, timed_pose.time_seconds + 0.5, GDKillBoundary2Sequence.RetimingMode.ShiftFollowing
	)
	var after_time_edit := sequence.create_snapshot()
	sequence.restore_snapshot(before_time_edit)
	sequence.restore_snapshot(after_time_edit)
	expect(
		sequence.get_pose(1) == timed_pose,
		"Committing Absolute Time keeps the edited pose selected through snapshot UndoRedo."
	)
	var easing_pose := sequence.get_pose(1)
	var before_easing_edit := sequence.create_snapshot()
	sequence.set_pose_easing(1, GDKillBoundary2Pose.TransitionEasing.Decelerate)
	var after_easing_edit := sequence.create_snapshot()
	sequence.restore_snapshot(before_easing_edit)
	sequence.restore_snapshot(after_easing_edit)
	expect(
		sequence.get_pose(1) == easing_pose,
		"Committing outgoing easing keeps the edited pose selected through snapshot UndoRedo."
	)
	var geometry_pose := sequence.get_pose(1)
	var geometry_yaw := geometry_pose.yaw_radians
	sequence.set_pose_geometry(1, Vector3(3.0, 0.0, -2.0), Vector2(5.0, 7.0))
	expect(
		geometry_pose.position.is_equal_approx(Vector3(3.0, 0.0, -2.0))
		and geometry_pose.size.is_equal_approx(Vector2(5.0, 7.0))
		and is_equal_approx(geometry_pose.yaw_radians, geometry_yaw),
		"Anchored resizing applies position and size together without changing yaw."
	)
	sequence.free()
