extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/text_trigger/text_trigger.gd")
const SUBJECT_PATH := "res://placeables/text_trigger/text_trigger.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
