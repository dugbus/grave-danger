extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/copy_all_errors/plugin.gd")
const SUBJECT_PATH := "res://addons/copy_all_errors/plugin.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
