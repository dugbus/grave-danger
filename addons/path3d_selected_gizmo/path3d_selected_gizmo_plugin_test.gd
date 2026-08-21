extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd")
const SUBJECT_PATH := "res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var source_code := (SUBJECT as Script).source_code
	var redraw_start := source_code.find("func _redraw(")
	var interaction_guard := source_code.find(
		"if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):",
		redraw_start
	)
	var clear_call := source_code.find("gizmo.clear()", redraw_start)
	expect(
		redraw_start >= 0 \
			and interaction_guard > redraw_start \
			and clear_call > interaction_guard,
		"The selected Path3D overlay does not mutate its gizmo during native handle input."
	)
