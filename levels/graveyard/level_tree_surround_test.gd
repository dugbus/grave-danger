extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/graveyard/level_tree_surround.gd")
const SUBJECT_PATH := "res://levels/graveyard/level_tree_surround.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
