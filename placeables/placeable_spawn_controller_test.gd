extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/placeable_spawn_controller.gd")
const SUBJECT_PATH := "res://placeables/placeable_spawn_controller.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
