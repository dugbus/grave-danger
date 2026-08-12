extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/graveyard/level_select_crypt.gd")
const SUBJECT_PATH := "res://levels/graveyard/level_select_crypt.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
