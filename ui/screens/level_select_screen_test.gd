extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_select_screen.gd")
const SUBJECT_PATH := "res://ui/screens/level_select_screen.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("required_dependency_path"),
		"Gameplay transitions wait for both the shell and selected level dependency graph."
	)
