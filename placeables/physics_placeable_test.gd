extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/physics_placeable.gd")
const SUBJECT_PATH := "res://placeables/physics_placeable.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
