extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/wall_breakable/wall_breakable.gd")
const SUBJECT_PATH := "res://placeables/wall_breakable/wall_breakable.gd"
const WALL_SCENE := preload("res://placeables/wall_breakable/wall_breakable.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_collapse_requires_meaningful_displacement_and_speed()
	await _test_wall_scene_plays_spatial_audio_once_blocks_are_displaced(tree)


func _test_collapse_requires_meaningful_displacement_and_speed() -> void:
	var wall := SUBJECT.new() as BreakableWall

	expect(
		not wall.is_collapse_motion(
			wall.minimum_collapse_displacement * 0.5,
			wall.minimum_collapse_speed * 2.0
		),
		"Fast brick jitter does not count as a wall collapse."
	)
	expect(
		not wall.is_collapse_motion(
			wall.minimum_collapse_displacement * 2.0,
			wall.minimum_collapse_speed * 0.5
		),
		"A slowly nudged brick does not trigger collapse audio."
	)
	expect(
		wall.is_collapse_motion(
			wall.minimum_collapse_displacement,
			wall.minimum_collapse_speed
		),
		"A brick that is displaced at collapse speed triggers the wall response."
	)

	wall.free()


func _test_wall_scene_plays_spatial_audio_once_blocks_are_displaced(tree: SceneTree) -> void:
	var wall := WALL_SCENE.instantiate() as BreakableWall
	tree.root.add_child(wall)
	await tree.process_frame

	var rigid_brick_count := 0
	for child: Node in wall.get_children():
		if child is RigidBody3D:
			rigid_brick_count += 1

	expect_equal(rigid_brick_count, 7, "The breakable wall tracks all seven rigid bricks.")
	var collapse_audio_player := (
		wall.get_node_or_null(^"CollapseAudioPlayer") as AudioStreamPlayer3D
	)
	expect(
		collapse_audio_player != null,
		"The breakable wall owns a spatial collapse audio player."
	)

	wall.settling_time_remaining = 0.0
	var displaced_brick := wall.tracked_bricks[0]
	displaced_brick.position += Vector3.RIGHT * wall.minimum_collapse_displacement
	displaced_brick.linear_velocity = Vector3.RIGHT * wall.minimum_collapse_speed
	wall._physics_process(0.016)
	expect(wall.has_played_collapse_audio, "Dislodged wall bricks trigger collapse audio once.")
	expect(
		collapse_audio_player != null and collapse_audio_player.playing,
		"The wall starts spatial collapse playback when it breaks."
	)

	if collapse_audio_player != null:
		collapse_audio_player.stop()
	wall.queue_free()
	for _frame_index in 3:
		await tree.process_frame
