extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/path3d_selected_gizmo/plugin.gd")
const SUBJECT_PATH := "res://addons/path3d_selected_gizmo/plugin.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var method_names: Array[StringName] = []
	var subject_script := SUBJECT as Script
	for method_data in subject_script.get_script_method_list():
		method_names.append(method_data.get("name", &"") as StringName)
	expect(
		not method_names.has(&"_forward_3d_gui_input") and not method_names.has(&"_process"),
		"The Path3D overlay neither intercepts point clicks nor polls gizmo redraws."
	)
