extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/active_flask_hud.gd")
const SUBJECT_PATH := "res://ui/hud/active_flask_hud.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
