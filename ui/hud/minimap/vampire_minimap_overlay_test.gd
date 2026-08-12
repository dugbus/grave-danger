extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/hud/minimap/vampire_minimap_overlay.gd")
const SUBJECT_PATH := "res://ui/hud/minimap/vampire_minimap_overlay.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
