extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_run_playback_player.gd")
const SUBJECT_PATH := "res://ui/screens/level_run_playback_player.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
