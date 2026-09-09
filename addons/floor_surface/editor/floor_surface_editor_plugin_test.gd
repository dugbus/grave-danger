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
	expect(
		method_names.has(&"_sample_elevation") \
			and method_names.has(&"_update_elevation_overlay"),
		"M4 exposes cursor sampling and a temporary muted elevation overlay."
	)
	expect(
		method_names.has(&"_sample_style") and method_names.has(&"_get_style_name"),
		"M5 exposes named palette sampling independently from elevation editing."
	)
	expect(
		method_names.has(&"_on_grid_overlay_toggled") \
			and method_names.has(&"_update_grid_overlay"),
		"The optional editor grid can be toggled independently of real floor materials."
	)
	expect(
		method_names.has(&"_gesture_action_name") \
			and method_names.has(&"_update_preview_footprint"),
		"M6 routes inferred ramp gestures through the existing preview and undo workflow."
	)
	var ramp_preview: Array[Vector2i] = SUBJECT._make_single_cell_preview(Vector2i(-2, 3), true)
	expect_equal(
		ramp_preview,
		[Vector2i(-2, 3)] as Array[Vector2i],
		"Ramp hover builds a typed preview accepted by the plugin's Array[Vector2i] state."
	)
	expect_equal(
		SUBJECT._make_single_cell_preview(Vector2i.ZERO, false),
		[] as Array[Vector2i],
		"An absent ramp hover produces an empty typed preview without an assignment error."
	)
	expect(
		SUBJECT._should_capture_active_drag(true),
		"Every motion event in an active drag is consumed before the 3D viewport can move."
	)
	expect(
		not SUBJECT._should_capture_active_drag(false),
		"Motion remains available to viewport navigation when no paint gesture is active."
	)
