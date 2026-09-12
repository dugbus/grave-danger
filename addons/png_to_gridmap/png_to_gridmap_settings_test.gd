extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_settings.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var settings := SUBJECT.new()
	expect(
		is_zero_approx(settings.autotile_vertical_connection_metres),
		"GridMap repair preserves exact-height connectivity unless a profile opts into slopes."
	)
