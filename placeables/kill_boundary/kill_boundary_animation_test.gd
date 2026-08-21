extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill_boundary/kill_boundary_animation.gd")
const SUBJECT_PATH := "res://placeables/kill_boundary/kill_boundary_animation.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var boundary := GDKillBoundary3D.new()
	var animation_player := AnimationPlayer.new()
	animation_player.name = boundary.ANIMATION_PLAYER_NAME
	var authored_library := AnimationLibrary.new()
	authored_library.add_animation(&"RESET", Animation.new())
	animation_player.add_animation_library("", authored_library)
	boundary.add_child(animation_player)
	var animation := Animation.new()
	boundary.boundary_animation = animation
	boundary.ping_pong_boundary_animation = true
	expect(
		animation.loop_mode == Animation.LOOP_PINGPONG,
		"Ping-pong playback can be enabled for the boundary animation."
	)
	boundary.ping_pong_boundary_animation = false
	expect(
		animation.loop_mode == Animation.LOOP_LINEAR,
		"Linear looping is restored when ping-pong playback is disabled."
	)

	boundary.curve = Curve3D.new()
	boundary.curve.add_point(Vector3.ZERO)
	expect(
		not boundary._has_previewable_editor_path(),
		"A one-point path does not drive the editor boundary preview."
	)

	boundary.curve.add_point(Vector3.ZERO)
	expect(
		not boundary._has_previewable_editor_path(),
		"A zero-length path does not drive the editor boundary preview."
	)

	boundary.curve.set_point_position(1, Vector3.RIGHT)
	expect(
		boundary._has_previewable_editor_path(),
		"A path with two distinct points can drive the editor boundary preview."
	)

	boundary.ping_pong_boundary_animation = true
	boundary.movement_cycle_distance = 10.0
	boundary.last_animation_position = 1.0
	boundary._update_movement_cycle_distance(animation, 0.75, true)
	expect(
		is_zero_approx(boundary.movement_cycle_distance),
		"Ping-pong playback retraces the boundary path without accumulating forward cycles."
	)
	tree.root.add_child(boundary)
	expect(
		animation_player.has_animation(&"RESET") \
			and animation_player.has_animation(boundary.DEFAULT_ANIMATION_NAME) \
			and animation_player.get_animation_library("") == authored_library,
		"Boundary animation updates preserve authored RESET animations and their library."
	)
	boundary.free()
