extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/stairs/procedural_staircase.gd")
const SUBJECT_PATH := "res://placeables/stairs/procedural_staircase.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
