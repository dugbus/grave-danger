extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton.gd")
const SUBJECT_PATH := "res://enemies/skeleton.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
