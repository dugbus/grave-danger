extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/codex_test_instruction/codex_test_instruction.gd")
const SUBJECT_PATH := "res://ui/hud/codex_test_instruction/codex_test_instruction.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
