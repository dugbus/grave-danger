extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/vampire/senses/vampire_senses.gd")
const SUBJECT_PATH := "res://enemies/vampire/senses/vampire_senses.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
