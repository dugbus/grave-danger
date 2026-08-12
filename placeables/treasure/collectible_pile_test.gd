extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/collectible_pile.gd")
const SUBJECT_PATH := "res://placeables/treasure/collectible_pile.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
