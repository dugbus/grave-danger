extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/editor_debugger.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/editor_debugger.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
