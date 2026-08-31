extends "res://tests/test_case.gd"

const DEMO_SCENE := preload("res://levels/kill-boundary-2-demo/level.tscn")


func run(_tree: SceneTree) -> void:
	var demo := DEMO_SCENE.instantiate()
	var boundary := demo.get_node(^"KillBoundary2") as GDKillBoundary2
	expect(boundary != null, "The demo loads one Kill Boundary 2 provider.")
	expect_equal(boundary.sequence.get_pose_count(), 5, "The demo authors five approval poses.")
	expect(
		boundary.sequence.get_pose(4).get_parent() == boundary.sequence,
		"The demo exposes all five poses as selectable scene-tree nodes."
	)
	expect(
		is_equal_approx(boundary.loop_return_seconds, 3.0)
		and boundary.sequence.get_pose(4).outgoing_easing
		== GDKillBoundary2Pose.TransitionEasing.Smooth,
		"The demo authors a visible smooth three-second Loop return to Pose 1."
	)
	expect_equal(
		boundary.sequence.get_pose(0).outgoing_easing,
		GDKillBoundary2Pose.TransitionEasing.Constant,
		"Transition 1 demonstrates Constant easing."
	)
	expect_equal(
		boundary.sequence.get_pose(1).outgoing_easing,
		GDKillBoundary2Pose.TransitionEasing.Smooth,
		"Transition 2 demonstrates Smooth easing."
	)
	expect_equal(
		boundary.sequence.get_pose(2).outgoing_easing,
		GDKillBoundary2Pose.TransitionEasing.Accelerate,
		"Transition 3 demonstrates Accelerate easing."
	)
	expect_equal(
		boundary.sequence.get_pose(3).outgoing_easing,
		GDKillBoundary2Pose.TransitionEasing.Decelerate,
		"Transition 4 demonstrates Decelerate easing."
	)
	expect(
		boundary.find_children("*", "Path3D", true, false).is_empty(),
		"The demo boundary contains no Path3D."
	)
	expect(
		boundary.find_children("*", "AnimationPlayer", true, false).is_empty(),
		"The demo boundary contains no AnimationPlayer."
	)
	expect(
		demo.get_node_or_null(^"DemoHUD/Controls") != null,
		"The demo includes its runtime validation HUD."
	)
	expect(
		(
			demo.get_node_or_null(^"PauseBoundaryFlask") != null
			and demo.get_node_or_null(^"BreathingSpaceFlask") != null
			and demo.get_node_or_null(^"NoBoundaryFlask") != null
		),
		"The demo includes all three boundary-effect flasks."
	)
	demo.free()
