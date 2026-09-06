extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_map.gd")
const ROUND_TRIP_PATH := "res://.godot/floor_surface_map_round_trip_test.tres"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_map.gd")
	_test_bounds_occupancy_and_negative_cells()
	_test_sparse_authored_values_and_palette_validation()
	_test_text_resource_round_trip()


func _test_bounds_occupancy_and_negative_cells() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-2, -1)
	floor_map.dimensions = Vector2i(4, 3)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i(-1, 0)]
	expect(floor_map.has_floor(Vector2i(-2, -1)), "Negative in-bounds cells can own floor.")
	expect(not floor_map.has_floor(Vector2i(-1, 0)), "An occupancy exception creates a hole.")
	expect(not floor_map.has_floor(Vector2i(2, 0)), "The exclusive maximum bound is absent.")
	expect_equal(floor_map.get_present_cells().size(), 11, "The finite map lists every top except its hole.")
	expect(floor_map.set_floor_present(Vector2i(-1, 0), true), "A hole can be restored.")
	expect(not floor_map.set_floor_present(Vector2i(8, 8), true), "Outside occupancy cannot be authored.")


func _test_sparse_authored_values_and_palette_validation() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-1, -1)
	floor_map.dimensions = Vector2i(2, 2)
	floor_map.default_present = true
	expect(floor_map.set_cell_elevation(Vector2i(-1, -1), -4), "Negative absolute elevation is stored.")
	expect_equal(floor_map.get_cell_elevation(Vector2i(-1, -1)), -4, "Elevation remains an integer.")
	floor_map.set_floor_present(Vector2i(0, 0), false)
	floor_map.set_cell_style(Vector2i(0, 0), 2)
	expect_equal(floor_map.get_cell_style(Vector2i(0, 0)), 2, "Absent cells retain style intent.")
	expect_equal(
		floor_map.get_cell_elevation(Vector2i(0, 0)),
		SUBJECT.INVALID_ELEVATION,
		"A hole never exposes an implicit world height."
	)
	expect_equal(floor_map.validate_palette_size(3), [], "Valid absent-cell styles pass validation.")
	expect_equal(floor_map.validate_palette_size(2).size(), 1, "Out-of-range style intent is reported.")


func _test_text_resource_round_trip() -> void:
	var floor_map := SUBJECT.new()
	floor_map.minimum_cell = Vector2i(-3, 2)
	floor_map.dimensions = Vector2i(5, 4)
	floor_map.default_present = true
	floor_map.set_floor_present(Vector2i(-1, 3), false)
	floor_map.set_cell_elevation(Vector2i(-2, 2), 7)
	floor_map.set_cell_style(Vector2i(-1, 3), 1)
	var save_error := ResourceSaver.save(floor_map, ROUND_TRIP_PATH)
	expect_equal(save_error, OK, "FloorMap saves as a text resource.")
	var restored := ResourceLoader.load(
		ROUND_TRIP_PATH,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	expect(restored != null, "A saved FloorMap reloads.")
	if restored != null:
		expect_equal(restored.minimum_cell, floor_map.minimum_cell, "Minimum cell survives reload.")
		expect_equal(restored.dimensions, floor_map.dimensions, "Dimensions survive reload.")
		expect(not restored.has_floor(Vector2i(-1, 3)), "A saved hole survives reload.")
		expect_equal(restored.get_cell_elevation(Vector2i(-2, 2)), 7, "Elevation survives reload.")
		expect_equal(restored.get_cell_style(Vector2i(-1, 3)), 1, "Absent style survives reload.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROUND_TRIP_PATH))
