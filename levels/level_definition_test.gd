extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/level_definition.gd")
const SUBJECT_PATH := "res://levels/level_definition.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
