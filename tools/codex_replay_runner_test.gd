extends "res://tests/test_case.gd"

const SUBJECT := preload("res://tools/codex_replay_runner.gd")
const SUBJECT_PATH := "res://tools/codex_replay_runner.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
