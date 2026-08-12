extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/lockables/lockable_hinged_leaf.gd")
const SUBJECT_PATH := "res://placeables/lockables/lockable_hinged_leaf.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
