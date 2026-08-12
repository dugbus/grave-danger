extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie.gd")
const SUBJECT_PATH := "res://enemies/zombie.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
