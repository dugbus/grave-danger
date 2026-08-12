extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/player_feedback/player_feedback_report_store.gd")
const SUBJECT_PATH := "res://ui/hud/player_feedback/player_feedback_report_store.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
