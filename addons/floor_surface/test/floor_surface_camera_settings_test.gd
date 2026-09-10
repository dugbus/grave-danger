extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_camera_settings.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_camera_settings.gd"
	)
	var settings := SUBJECT.new()
	expect_equal(
		settings.get_view_name(SUBJECT.CameraView.Overview),
		"2.5D overview",
		"The default camera arrangement has a human-readable name."
	)
	expect(
		settings.get_view_position(SUBJECT.CameraView.Close) \
			!= settings.get_view_position(SUBJECT.CameraView.Side),
		"Named camera arrangements retain independent positions."
	)
	expect(
		settings.get_view_size(SUBJECT.CameraView.Close) \
			< settings.get_view_size(SUBJECT.CameraView.Overview),
		"The close arrangement uses a shorter perspective follow distance."
	)
