extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_pit_resolver.gd")
const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_surface_pit_resolver.gd")
	_test_connected_mixed_rim_datum()
	_test_region_without_rim_has_no_bottom()


func _test_connected_mixed_rim_datum() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(5, 3)
	floor_map.default_present = true
	floor_map.presence_exceptions = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(4, 1)]
	floor_map.set_cell_elevation(Vector2i(1, 0), 4)
	floor_map.set_cell_elevation(Vector2i(2, 0), 8)
	floor_map.set_cell_style(Vector2i(2, 0), 1)
	var profile := PROFILE_SCRIPT.new()
	profile.elevation_unit = 0.25
	var shallow_style := _make_style(1.0)
	var deep_style := _make_style(3.5)
	var styles: Array[STYLE_SCRIPT] = [shallow_style, deep_style]
	var result := SUBJECT.new().resolve(floor_map, profile, styles)
	var bottoms := result["bottom_heights"] as Dictionary[Vector2i, float]
	expect_equal(result["region_count"], 2, "Disconnected bounded holes resolve independently.")
	expect(is_equal_approx(bottoms[Vector2i(1, 1)], -1.5), "The lowest rim-depth candidate sets the datum.")
	expect_equal(
		bottoms[Vector2i(1, 1)],
		bottoms[Vector2i(2, 1)],
		"Every cell in one connected hole receives exactly the same bottom height."
	)
	deep_style.pit_depth = 4.0
	result = SUBJECT.new().resolve(floor_map, profile, styles)
	bottoms = result["bottom_heights"] as Dictionary[Vector2i, float]
	expect(is_equal_approx(bottoms[Vector2i(2, 1)], -2.0), "Changing a rim style depth moves the shared datum.")


func _test_region_without_rim_has_no_bottom() -> void:
	var floor_map := MAP_SCRIPT.new()
	floor_map.dimensions = Vector2i(2, 2)
	var profile := PROFILE_SCRIPT.new()
	var styles: Array[STYLE_SCRIPT] = [_make_style(2.0)]
	var result := SUBJECT.new().resolve(floor_map, profile, styles)
	var bottoms := result["bottom_heights"] as Dictionary[Vector2i, float]
	expect_equal(result["region_count"], 0, "An all-empty authored map has no invented rim datum.")
	expect(bottoms.is_empty(), "A rimless empty region does not generate a floating pit bottom.")


func _make_style(depth: float) -> STYLE_SCRIPT:
	var style := STYLE_SCRIPT.new()
	style.top_material = StandardMaterial3D.new()
	style.edge_material = StandardMaterial3D.new()
	style.pit_depth = depth
	return style
