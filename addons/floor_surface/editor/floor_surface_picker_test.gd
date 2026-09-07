extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_picker.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/editor/floor_surface_picker.gd")
	var surface := SURFACE_SCRIPT.new()
	var floor_map := FLOOR_MAP_SCRIPT.new()
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i.ZERO, 24)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	surface.floor_map = floor_map
	surface.elevation_profile = profile
	var top_hit: Variant = SUBJECT.pick_world_position(
		Vector3(0.5, 10.0, 0.5),
		Vector3.DOWN,
		surface
	)
	expect_equal(top_hit, Vector3(0.5, 6.0, 0.5), "Picking reaches a 24-unit top at six metres.")
	floor_map.set_floor_present(Vector2i.ZERO, false)
	var fallback_hit: Variant = SUBJECT.pick_world_position(
		Vector3(2.5, 10.0, 3.5),
		Vector3.DOWN,
		surface
	)
	expect_equal(fallback_hit, Vector3(2.5, 0.0, 3.5), "Empty space uses the default working plane.")
	surface.free()
