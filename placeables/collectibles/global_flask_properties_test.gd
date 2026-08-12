extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/collectibles/global_flask_properties.gd")
const SUBJECT_PATH := "res://placeables/collectibles/global_flask_properties.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
