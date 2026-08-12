extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/frontend/focus_scroll_list.gd")
const SUBJECT_PATH := "res://ui/frontend/focus_scroll_list.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
