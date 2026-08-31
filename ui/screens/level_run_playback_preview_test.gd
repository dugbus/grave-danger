extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_run_playback_preview.gd")
const SUBJECT_PATH := "res://ui/screens/level_run_playback_preview.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var root := Node.new()
	var boundary := BoundaryStub.new()
	boundary.add_to_group(&"kill_boundary")
	root.add_child(boundary)
	SUBJECT.start_runtime(root)
	expect_equal(
		boundary.begin_count,
		1,
		"Replay startup begins any grouped boundary exposing the compatibility method."
	)
	root.free()


class BoundaryStub:
	extends Node

	var begin_count := 0

	func begin_runtime_animation() -> void:
		begin_count += 1
