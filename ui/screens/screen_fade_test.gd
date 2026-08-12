extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/screen_fade.gd")
const SUBJECT_PATH := "res://ui/screens/screen_fade.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
