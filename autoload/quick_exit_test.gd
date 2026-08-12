extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/quick_exit.gd")
const SUBJECT_PATH := "res://autoload/quick_exit.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
