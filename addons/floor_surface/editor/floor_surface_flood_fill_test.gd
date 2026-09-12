extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_flood_fill.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/editor/floor_surface_flood_fill.gd"
	)
	_test_shape_fill_is_bounded()
	_test_elevation_and_style_matching()


func _test_shape_fill_is_bounded() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.minimum_cell = Vector2i(-1, -1)
	floor_map.dimensions = Vector2i(4, 3)
	floor_map.default_present = false
	floor_map.presence_exceptions = [Vector2i.ZERO, Vector2i(1, 0)]
	var absent := SUBJECT.footprint(floor_map, Vector2i(-1, -1), SUBJECT.MatchProperty.Shape)
	expect_equal(absent.size(), 10, "An absent-cell fill remains bounded and stops at present cells.")
	for cell in absent:
		expect(floor_map.is_in_bounds(cell), "Flood fill never escapes finite authored bounds.")
	var present := SUBJECT.footprint(floor_map, Vector2i.ZERO, SUBJECT.MatchProperty.Shape)
	expect_equal(
		present,
		[Vector2i.ZERO, Vector2i(1, 0)] as Array[Vector2i],
		"Shape fill matches four-connected occupancy."
	)


func _test_elevation_and_style_matching() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(3, 2)
	floor_map.default_present = true
	floor_map.set_cell_elevation(Vector2i(2, 0), 4)
	floor_map.set_cell_elevation(Vector2i(2, 1), 4)
	var low_region := SUBJECT.footprint(floor_map, Vector2i.ZERO, SUBJECT.MatchProperty.Elevation)
	expect_equal(low_region.size(), 4, "Elevation fill matches the seed's exact connected height.")
	floor_map.set_floor_present(Vector2i(1, 0), false)
	floor_map.set_cell_style(Vector2i.ZERO, 2)
	floor_map.set_cell_style(Vector2i(1, 0), 2)
	var style_region := SUBJECT.footprint(floor_map, Vector2i.ZERO, SUBJECT.MatchProperty.Style)
	expect_equal(style_region.size(), 1, "Style fill does not cross between floor and hole cells.")
	expect(
		SUBJECT.describe_match(SUBJECT.MatchProperty.Shape).contains("within current bounds"),
		"Shape fill describes its absent-cell safety boundary."
	)
