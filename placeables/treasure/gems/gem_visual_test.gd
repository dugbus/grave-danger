extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/gems/gem_visual.gd")
const SUBJECT_PATH := "res://placeables/treasure/gems/gem_visual.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
