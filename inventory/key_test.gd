extends "res://tests/test_case.gd"

const SUBJECT := preload("res://inventory/key.gd")
const SUBJECT_PATH := "res://inventory/key.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
