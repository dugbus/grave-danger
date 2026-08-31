extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_animator.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_animator.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var sequence := GDKillBoundary2Sequence.new()
	var second_index := sequence.add_default_pose()
	sequence.set_pose_transform(second_index, Vector3(10.0, 0.0, 0.0), deg_to_rad(-170.0))
	sequence.set_pose_size(second_index, Vector2(4.0, 6.0))
	sequence.set_pose_rounding(second_index, 1.0)
	sequence.get_pose(0).yaw_radians = deg_to_rad(170.0)
	var animator := GDKillBoundary2Animator.new()
	animator.configure(sequence, GDKillBoundary2Animator.PlaybackMode.SingleShot, 1.0)
	var state := animator.evaluate_at(0.5)
	expect(
		is_equal_approx(state.position.x, 5.0) and state.size == Vector2(6.0, 7.0),
		"All pose values interpolate together."
	)
	expect(absf(rad_to_deg(state.yaw_radians)) > 179.0, "Yaw takes the shortest angular route.")
	sequence.get_pose(0).outgoing_easing = GDKillBoundary2Pose.TransitionEasing.Accelerate
	state = animator.evaluate_at(0.5)
	expect(is_equal_approx(state.position.x, 2.5), "Accelerate uses quadratic ease-in.")
	sequence.get_pose(0).outgoing_easing = GDKillBoundary2Pose.TransitionEasing.Decelerate
	state = animator.evaluate_at(0.5)
	expect(is_equal_approx(state.position.x, 7.5), "Decelerate uses quadratic ease-out.")
	sequence.get_pose(0).outgoing_easing = GDKillBoundary2Pose.TransitionEasing.Smooth
	state = animator.evaluate_at(0.25)
	expect(is_equal_approx(state.position.x, 1.5625), "Smooth uses exact smoothstep easing.")
	sequence.get_pose(0).outgoing_easing = GDKillBoundary2Pose.TransitionEasing.Constant
	state = animator.evaluate_at(0.25)
	expect(is_equal_approx(state.position.x, 2.5), "Constant is linear interpolation.")
	var completion_count: Array[int] = [0]
	animator.playback_finished.connect(func() -> void: completion_count[0] += 1)
	animator.playback_mode = GDKillBoundary2Animator.PlaybackMode.SingleShot
	animator.restart()
	animator.advance(2.0)
	animator.advance(2.0)
	expect(
		(
			is_equal_approx(animator.authored_position, 1.0)
			and not animator.playing
			and completion_count[0] == 1
		),
		"Single Shot clamps at the end and completes exactly once."
	)
	animator.playback_mode = GDKillBoundary2Animator.PlaybackMode.Loop
	animator.loop_return_seconds = 1.0
	sequence.get_pose(1).outgoing_easing = GDKillBoundary2Pose.TransitionEasing.Smooth
	animator.restart()
	animator.advance(1.0)
	expect(
		is_equal_approx(animator.authored_position, 1.0)
		and is_equal_approx(animator.state.position.x, 10.0),
		"Loop reaches and evaluates the final authored pose before returning."
	)
	animator.advance(0.25)
	expect(
		is_equal_approx(animator.authored_position, 1.25)
		and is_equal_approx(animator.state.position.x, 8.4375),
		"The final pose's outgoing easing controls the closing Loop transition."
	)
	animator.advance(0.25)
	expect(
		is_equal_approx(animator.authored_position, 1.5)
		and is_equal_approx(animator.state.position.x, 5.0)
		and animator.state.size.is_equal_approx(Vector2(6.0, 7.0))
		and is_equal_approx(animator.state.rounding, 0.5),
		"Loop return duration and the final pose's easing tween every state value to Pose 1."
	)
	animator.advance(0.5)
	expect(
		is_zero_approx(animator.authored_position)
		and is_zero_approx(animator.state.position.x),
		"Loop crosses its cycle boundary continuously at Pose 1."
	)
	animator.playback_mode = GDKillBoundary2Animator.PlaybackMode.PingPong
	animator.restart()
	animator.advance(1.5)
	expect(
		is_equal_approx(animator.authored_position, 0.5),
		"Ping Pong reverses authored time cleanly."
	)
	animator.playback_speed = 0.5
	animator.restart()
	animator.advance(1.0)
	expect(
		is_equal_approx(animator.authored_position, 0.5),
		"Playback speed scales clock advancement only."
	)
	animator.set_paused(true)
	animator.advance(1.0)
	expect(
		is_equal_approx(animator.authored_position, 0.5), "Pausing freezes authored sequence time."
	)
	animator.seek(0.75)
	expect(is_equal_approx(animator.authored_position, 0.75), "Seeking evaluates exact time.")
	var static_animator := GDKillBoundary2Animator.new()
	var static_sequence := GDKillBoundary2Sequence.new()
	static_sequence.ensure_default_pose()
	static_animator.configure(
		static_sequence, GDKillBoundary2Animator.PlaybackMode.Loop, 2.0, 3.0
	)
	static_animator.restart()
	static_animator.advance(10.0)
	expect(
		is_zero_approx(static_animator.authored_position), "A single-pose sequence remains static."
	)
	static_animator.free()
	animator.free()
	static_sequence.free()
	sequence.free()
