extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_content_cell_selector.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_content_cell_selector.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
