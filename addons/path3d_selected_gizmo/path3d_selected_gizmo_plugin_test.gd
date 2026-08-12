extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd")
const SUBJECT_PATH := "res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
