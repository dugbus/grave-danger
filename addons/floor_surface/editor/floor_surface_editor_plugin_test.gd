extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/floor_surface/editor/floor_surface_editor_plugin.gd"
)


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_editor_plugin.gd"
	)
	var method_names: Array[StringName] = []
	var subject_script := SUBJECT as Script
	for method_data in subject_script.get_script_method_list():
		method_names.append(method_data.get("name", &"") as StringName)
	expect(
		method_names.has(&"_forward_3d_gui_input"),
		"The plugin implements direct 3D viewport authoring."
	)
	expect(
		method_names.has(&"_on_make_unique_requested"),
		"The plugin exposes an explicit unique-copy workflow."
	)
	expect(
		method_names.has(&"_hide_target_selection") \
			and method_names.has(&"_restore_target_selection"),
		"Painting can hide the selected node's obstructive transform gizmo and restore it later."
	)
