extends "res://tests/test_case.gd"

const SUBJECT := preload("res://tools/check_all_scenes.gd")
const SUBJECT_PATH := "res://tools/check_all_scenes.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
