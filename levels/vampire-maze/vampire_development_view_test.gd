extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/vampire_development_view.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/vampire_development_view.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
