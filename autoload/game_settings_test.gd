extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/game_settings.gd")
const SUBJECT_PATH := "res://autoload/game_settings.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
