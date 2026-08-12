extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/result_stats.gd")
const SUBJECT_PATH := "res://autoload/result_stats.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
