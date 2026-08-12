extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/minimap_route_overlay.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/minimap_route_overlay.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
