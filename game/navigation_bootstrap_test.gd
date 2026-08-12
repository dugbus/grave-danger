extends "res://tests/test_case.gd"

const SUBJECT := preload("res://game/navigation_bootstrap.gd")
const SUBJECT_PATH := "res://game/navigation_bootstrap.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
