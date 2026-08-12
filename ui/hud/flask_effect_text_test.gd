extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/flask_effect_text.gd")
const SUBJECT_PATH := "res://ui/hud/flask_effect_text.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
