extends "res://tests/test_case.gd"

const BOUNDARY_SCENE := preload("res://placeables/kill-boundary-2/kill_boundary_2.tscn")


func run(tree: SceneTree) -> void:
	if not Engine.is_editor_hint():
		expect(true, "The editor preview smoke test is reserved for an editor-hint run.")
		return
	var boundary := BOUNDARY_SCENE.instantiate() as GDKillBoundary2
	var second_pose := boundary.sequence.add_default_pose()
	boundary.sequence.set_pose_transform(second_pose, Vector3(4.0, 0.0, 0.0), 0.0)
	tree.root.add_child(boundary)
	await tree.process_frame
	expect_equal(
		boundary.geometry.points.size(),
		boundary.settings.boundary_segments,
		"Opening an edited boundary immediately builds its canonical preview perimeter."
	)
	var distinct_positions: Dictionary[Vector3, bool] = {}
	for segment in boundary.presentation.segments:
		distinct_positions[segment.position] = true
	expect(
		distinct_positions.size() > 8,
		"Generated preview segments occupy the perimeter instead of stacking at the origin."
	)
	boundary.preview_play()
	boundary.advance_editor_preview(0.5)
	expect(
		is_equal_approx(boundary.state_root.position.x, 2.0),
		"Editor transport advances the complete evaluated boundary state."
	)
	boundary.free()
