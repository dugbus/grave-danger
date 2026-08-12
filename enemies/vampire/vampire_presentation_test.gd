extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/vampire/vampire_presentation.gd")
const SUBJECT_PATH := "res://enemies/vampire/vampire_presentation.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
