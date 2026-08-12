extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/follow_camera_profile.gd")
const SUBJECT_PATH := "res://game/follow_camera_profile.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
