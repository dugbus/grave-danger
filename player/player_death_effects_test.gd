extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_death_effects.gd")
const SUBJECT_PATH := "res://player/player_death_effects.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
