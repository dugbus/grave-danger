extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/frontend_audio.gd")
const SUBJECT_PATH := "res://autoload/frontend_audio.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
