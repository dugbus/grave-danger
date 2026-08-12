extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/game_font.gd")
const SUBJECT_PATH := "res://ui/game_font.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
