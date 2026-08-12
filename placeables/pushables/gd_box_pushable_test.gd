extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/pushables/gd_box_pushable.gd")
const SUBJECT_PATH := "res://placeables/pushables/gd_box_pushable.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
