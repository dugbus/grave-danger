extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/level_selection.gd")
const SUBJECT_PATH := "res://autoload/level_selection.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
