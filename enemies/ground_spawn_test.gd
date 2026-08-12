extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/ground_spawn.gd")
const SUBJECT_PATH := "res://enemies/ground_spawn.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
