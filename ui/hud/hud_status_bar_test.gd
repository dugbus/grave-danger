extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/hud_status_bar.gd")
const SUBJECT_PATH := "res://ui/hud/hud_status_bar.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
