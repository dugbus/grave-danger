extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_tile_placement.gd")
const COMPATIBILITY := preload("res://placeables/traps/crumbling_floor/editor/crumbling_floor_placement.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/editor/floor_surface_tile_placement.gd")
	var root := Node3D.new()
	var tile := Node3D.new()
	var surface := FloorSurface.new()
	root.add_child(tile)
	root.add_child(surface)
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(3, 3)
	surface.floor_map.default_present = true
	surface.elevation_profile = FloorElevationProfile.new()
	surface.floor_map.set_cell_elevation(Vector2i(2, 1), 8)
	surface.floor_map.set_floor_present(Vector2i.ONE, false)
	tile.position = Vector3(1.7, 12.0, 1.8)
	var before := surface.floor_map.get_presence_snapshot()
	var placement := SUBJECT.calculate_auto_transform(tile, surface)
	expect(placement["valid"] as bool, "Shared placement resolves a retained hole.")
	expect_equal(
		(placement["transform"] as Transform3D).origin,
		Vector3(1.5, 0.0, 1.5),
		"Tiles centre at the lowest surrounding landing."
	)
	expect_equal(
		COMPATIBILITY.calculate_auto_transform(tile, surface),
		placement,
		"The crumbling-floor entrypoint retains identical placement results."
	)
	expect_equal(surface.floor_map.get_presence_snapshot(), before, "Placement never opens or fills a floor cell.")
	root.free()
