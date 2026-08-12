extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/player_progress.gd")
const SUBJECT_PATH := "res://autoload/player_progress.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
