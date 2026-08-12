extends "res://tests/test_case.gd"

const SUBJECT := preload("res://tools/editor_preview_lighting.gd")
const SUBJECT_PATH := "res://tools/editor_preview_lighting.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
