extends "res://tests/test_case.gd"

const SUBJECT := preload("res://lighting/gd_indoor_lighting.gd")
const SUBJECT_PATH := "res://lighting/gd_indoor_lighting.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
