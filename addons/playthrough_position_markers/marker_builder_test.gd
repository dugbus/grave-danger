extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/marker_builder.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/marker_builder.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var builder := SUBJECT.new() as RefCounted
	var scene_root := Node3D.new()
	var first_samples: Array[Dictionary] = [
		{
			"start_time": 2.0,
			"end_time": 6.0,
			"position": Vector3(1.0, 0.0, 3.0),
		},
		{
			"start_time": 8.0,
			"end_time": 8.0,
			"position": Vector3(2.0, 0.0, 3.0),
		},
	]
	var first_container := builder.replace_markers(scene_root, first_samples) as Node3D
	var first_marker := first_container.get_node("Sample_000") as Node3D
	var first_label := first_marker.get_node("Time") as Label3D
	expect_equal(first_label.text, "0:02–0:06", "Stationary markers show an occupied time range.")
	expect_equal(first_marker.position, Vector3(1.0, 0.0, 3.0), "Markers retain level-local position.")
	expect(
		not first_label.fixed_size and is_equal_approx(first_label.pixel_size, 0.01),
		"Time labels stay compact and scale naturally with the editor's world view."
	)
	expect(
		first_container.get_node_or_null("WalkedPath") is Path3D,
		"A Path3D connects samples through the prominent selected-path editor overlay."
	)
	var walked_path := builder.find_walked_path(first_container) as Path3D
	expect_equal(walked_path.curve.point_count, 2, "The walked path retains every sampled point.")
	expect_equal(
		walked_path.curve.get_point_position(1),
		Vector3(2.0, 0.0, 3.0),
		"The walked path uses the same level-local coordinates as its timed markers."
	)

	var second_samples: Array[Dictionary] = [{
		"start_time": 65.0,
		"end_time": 65.0,
		"position": Vector3(-2.0, 0.5, 4.0),
	}]
	var second_container := builder.replace_markers(scene_root, second_samples) as Node3D
	expect(first_container != second_container, "A new playthrough replaces the previous group.")
	expect_equal(scene_root.get_child_count(), 1, "Only the newest marker group remains in the level.")
	var second_label := second_container.get_node("Sample_000/Time") as Label3D
	expect_equal(second_label.text, "1:05", "Moving samples show their single arrival time.")
	scene_root.free()
