extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/run_recording.gd")
const SUBJECT_PATH := "res://game/run_recording.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
