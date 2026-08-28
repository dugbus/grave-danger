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
	boundary.loop_boundary_path = false
	expect(
		animation.loop_mode == Animation.LOOP_NONE,
		"Disabling path looping makes non-ping-pong animation playback one-shot."
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
	var linear_animation := Animation.new()
	linear_animation.length = 10.0
	linear_animation.loop_mode = Animation.LOOP_LINEAR
	var linear_speed_track := linear_animation.add_track(Animation.TYPE_VALUE)
	linear_animation.track_set_path(linear_speed_track, boundary.MOVEMENT_SPEED_TRACK_PATH)
	linear_animation.track_insert_key(linear_speed_track, 0.0, 1.0)
	boundary.movement_cycle_distance = 0.0
	boundary.last_animation_position = 9.5
	boundary._update_movement_cycle_distance(linear_animation, 0.5, true)
	expect(
		is_equal_approx(boundary.movement_cycle_distance, 10.0),
		"Linear editor playback preserves travelled distance when its timeline wraps."
	)
	linear_animation.loop_mode = Animation.LOOP_NONE
	boundary.movement_cycle_distance = 10.0
	boundary.last_animation_position = 9.5
	boundary._update_movement_cycle_distance(linear_animation, 0.0, true)
	expect(
		is_zero_approx(boundary.movement_cycle_distance),
		"A playing one-shot editor preview clears stale loop travel and starts at the path start."
	)
	tree.root.add_child(boundary)
	expect(
		animation_player.has_animation(&"RESET") \
			and animation_player.has_animation(boundary.DEFAULT_ANIMATION_NAME) \
			and animation_player.get_animation_library("") == authored_library \
			and animation.find_track(boundary.MOVEMENT_SPEED_TRACK_PATH, Animation.TYPE_VALUE) >= 0,
		"Boundary updates preserve authored libraries and add a track-driven movement fallback."
	)
	animation_player.pause()
	animation_player.seek(0.5, true)
	boundary.editor_preview_animation = animation
	boundary.editor_preview_initialized = true
	boundary.editor_preview_time = 0.0
	expect(
		is_equal_approx(boundary._get_editor_preview_time(animation_player, animation), 0.5),
		"A paused Animation panel scrub uses the assigned animation's current timeline position."
	)
	boundary.autoplay_boundary_animation = false
	boundary.curve = Curve3D.new()
	boundary.curve.add_point(Vector3.ZERO)
	boundary.curve.add_point(Vector3(10.0, 0.0, 0.0))
	var track_driven_animation := Animation.new()
	track_driven_animation.length = 10.0
	var track_driven_speed_track := track_driven_animation.add_track(Animation.TYPE_VALUE)
	track_driven_animation.track_set_path(
		track_driven_speed_track,
		boundary.MOVEMENT_SPEED_TRACK_PATH
	)
	track_driven_animation.track_insert_key(track_driven_speed_track, 0.0, 1.0)
	boundary.boundary_animation = track_driven_animation
	boundary.set_process(false)
	boundary.set_physics_process(false)
	var track_driven_center := boundary.get_node(boundary.BOUNDARY_CENTER_NAME) as PathFollow3D
	animation_player.play(boundary.DEFAULT_ANIMATION_NAME)
	animation_player.advance(2.0)
	expect(
		is_equal_approx(track_driven_center.progress, 2.0),
		"The animated speed track drives path progress without relying on boundary process order."
	)
	animation_player.stop()
	animation_player.clear_caches()
	boundary.free()

	var timed_boundary := GDKillBoundary3D.new()
	timed_boundary.curve = Curve3D.new()
	timed_boundary.curve.add_point(Vector3.ZERO)
	timed_boundary.curve.add_point(Vector3(10.0, 0.0, 0.0))
	timed_boundary.ping_pong_boundary_animation = true
	var timed_animation := Animation.new()
	timed_animation.length = 20.0
	var speed_track := timed_animation.add_track(Animation.TYPE_VALUE)
	timed_animation.track_set_path(speed_track, timed_boundary.MOVEMENT_SPEED_TRACK_PATH)
	timed_animation.track_set_interpolation_loop_wrap(speed_track, false)
	timed_animation.track_insert_key(speed_track, 0.0, 1.0)
	timed_animation.track_insert_key(speed_track, 2.0, 1.0)
	timed_animation.track_insert_key(speed_track, 4.0, 3.0)
	timed_animation.track_insert_key(speed_track, 6.0, 2.0)
	timed_boundary.boundary_animation = timed_animation
	timed_boundary._sync_path_point_animation_markers()
	expect(
		is_equal_approx(timed_boundary.derived_ping_pong_end_time, 10.0 - 2.0 * sqrt(5.0)) \
			and is_equal_approx(timed_animation.length, 20.0) \
			and timed_animation.track_get_key_count(speed_track) == 4,
		"Boundary duration finds the path-end time across multiple interpolated speed keys (got %f)." \
			% timed_boundary.derived_ping_pong_end_time
	)
	timed_boundary.curve.set_point_position(1, Vector3(20.0, 0.0, 0.0))
	timed_boundary._sync_path_point_animation_markers()
	expect(
		is_equal_approx(timed_boundary.derived_ping_pong_end_time, 10.5) \
			and is_equal_approx(timed_animation.length, 20.0) \
			and timed_animation.track_get_key_count(speed_track) == 4,
		"Boundary duration extends when the path needs more travel time at the keyed speeds (got %f)." \
			% timed_boundary.derived_ping_pong_end_time
	)
	var timed_player := AnimationPlayer.new()
	timed_player.name = timed_boundary.ANIMATION_PLAYER_NAME
	timed_boundary.add_child(timed_player)
	var timed_library := AnimationLibrary.new()
	timed_library.add_animation(timed_boundary.DEFAULT_ANIMATION_NAME, timed_animation)
	timed_player.add_animation_library(&"", timed_library)
	timed_boundary._play_boundary_animation(timed_player)
	expect(
		timed_player.has_section() \
			and is_zero_approx(timed_player.get_section_start_time()) \
			and is_equal_approx(
				timed_player.get_section_end_time(),
				timed_boundary.derived_ping_pong_end_time
			),
		"Ping-pong playback uses the derived path-end section without truncating authored keys."
	)
	timed_player.advance(timed_boundary.derived_ping_pong_end_time + 0.5)
	var reversed_position := timed_player.current_animation_position
	timed_boundary.ping_pong_boundary_animation = false
	timed_player.advance(0.25)
	expect(
		timed_animation.loop_mode == Animation.LOOP_LINEAR \
			and not timed_player.has_section() \
			and timed_player.current_animation_position > reversed_position,
		"Disabling ping-pong restarts an active editor preview in the forward direction."
	)
	timed_boundary.free()
