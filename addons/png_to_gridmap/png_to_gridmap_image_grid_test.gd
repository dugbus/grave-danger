extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_image_grid.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_image_grid.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
