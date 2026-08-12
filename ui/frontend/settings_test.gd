extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/frontend/settings.gd")
const SUBJECT_PATH := "res://ui/frontend/settings.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
