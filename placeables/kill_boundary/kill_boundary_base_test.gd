extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill_boundary/kill_boundary_base.gd")
const SUBJECT_PATH := "res://placeables/kill_boundary/kill_boundary_base.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
