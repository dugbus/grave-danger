extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
