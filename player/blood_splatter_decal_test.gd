extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/blood_splatter_decal.gd")
const SUBJECT_PATH := "res://player/blood_splatter_decal.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
