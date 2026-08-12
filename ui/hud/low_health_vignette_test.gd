extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/low_health_vignette.gd")
const SUBJECT_PATH := "res://ui/hud/low_health_vignette.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
