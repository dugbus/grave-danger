extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/level_selection.gd")
const SUBJECT_PATH := "res://autoload/level_selection.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var selection := SUBJECT.new() as GDLevelSelection
	expect_equal(
		selection.get_selected_level_scene_path(),
		"res://levels/tutorial-1/level.tscn",
		"The selected level path can be requested without synchronously loading its scene."
	)
	selection.free()
