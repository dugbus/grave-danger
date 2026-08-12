extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/vampire/behaviour/vampire_hunt.gd")
const SUBJECT_PATH := "res://enemies/vampire/behaviour/vampire_hunt.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
