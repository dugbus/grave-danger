extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/follow_camera.gd")
const SUBJECT_PATH := "res://game/follow_camera.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
