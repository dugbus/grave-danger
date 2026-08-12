extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/run_frame_encoder.gd")
const SUBJECT_PATH := "res://game/run_frame_encoder.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
