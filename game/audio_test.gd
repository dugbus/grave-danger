extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/audio.gd")
const SUBJECT_PATH := "res://game/audio.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
