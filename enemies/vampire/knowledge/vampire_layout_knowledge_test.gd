extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/vampire/knowledge/vampire_layout_knowledge.gd")
const SUBJECT_PATH := "res://enemies/vampire/knowledge/vampire_layout_knowledge.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
