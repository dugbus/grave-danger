extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/collectibles/flask_breathing_space.gd")
const SUBJECT_PATH := "res://placeables/collectibles/flask_breathing_space.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
