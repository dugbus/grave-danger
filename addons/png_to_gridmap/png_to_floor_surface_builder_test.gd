extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_floor_surface_builder.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_floor_surface_builder.gd"
const SETTINGS := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const GridAlignment := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_png_alpha_creates_editable_floor_surface()
	_test_floor_cells_align_with_selected_wall_gridmap()
	_test_rebuild_retains_height_authored_on_remaining_cells()


func _test_png_alpha_creates_editable_floor_surface() -> void:
	var image := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.set_pixel(0, 0, Color.WHITE)
	image.set_pixel(2, 1, Color.WHITE)
	var root := Node3D.new()
	var settings := SETTINGS.new()
	settings.cell_size = 2.0
	var result: Dictionary = SUBJECT.new().run(settings, image, root, null)
	var surface := result.get("floor_surface") as FloorSurface
	expect(result.get("errors", []).is_empty(), "Valid PNG alpha imports without errors.")
	expect(surface != null, "Floor import creates the reusable FloorSurface scene type.")
	expect(surface.floor_map.resource_local_to_scene, "A new map remains independently editable in its level scene.")
	expect_equal(surface.floor_map.minimum_cell, Vector2i.ZERO, "Storage fits the painted PNG extent.")
	expect_equal(surface.floor_map.dimensions, Vector2i(3, 2), "Storage includes both painted edge cells.")
	expect(surface.has_floor(Vector2i(2, 1)), "The upper-left PNG pixel follows wall-import axis flipping.")
	expect(surface.has_floor(Vector2i.ZERO), "The lower-right PNG pixel follows wall-import axis flipping.")
	expect_equal(surface.cell_size, 2.0, "A standalone surface uses the configured cell size.")
	expect_equal(surface.world_origin_xz, Vector2(-3.0, -2.0), "A standalone PNG floor is centred on world zero.")
	root.free()


func _test_floor_cells_align_with_selected_wall_gridmap() -> void:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var root := Node3D.new()
	var grid_map := GridMap.new()
	grid_map.position = Vector3(3.0, 0.0, 4.0)
	grid_map.cell_size = Vector3(2.0, 1.0, 2.0)
	root.add_child(grid_map)
	var settings := SETTINGS.new()
	var result: Dictionary = SUBJECT.new().run(settings, image, root, grid_map)
	var surface := result["floor_surface"] as FloorSurface
	var floor_centre := surface.cell_to_local(Vector2i.ZERO)
	var wall_centre := grid_map.position + grid_map.map_to_local(Vector3i.ZERO)
	expect_equal(surface.cell_size, 2.0, "Floor import adopts the selected wall GridMap cell size.")
	expect(
		surface.get_placement_grid_map() == grid_map \
			and GridAlignment.is_aligned(surface, grid_map),
		"PNG floor import records and aligns its sparse object-placement GridMap."
	)
	expect_equal(
		Vector2(floor_centre.x, floor_centre.z),
		Vector2(wall_centre.x, wall_centre.z),
		"Imported floor and wall cell centres share the same world alignment."
	)
	root.free()


func _test_rebuild_retains_height_authored_on_remaining_cells() -> void:
	var image := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var root := Node3D.new()
	var settings := SETTINGS.new()
	var builder := SUBJECT.new()
	var first_result: Dictionary = builder.run(settings, image, root, null)
	var surface := first_result["floor_surface"] as FloorSurface
	surface.floor_map.set_cell_elevation(Vector2i.ZERO, 4)
	image.set_pixel(0, 0, Color.TRANSPARENT)
	var second_result: Dictionary = builder.run(settings, image, root, null)
	expect(not second_result["created"], "A later import rebuilds the conventional FloorSurface node.")
	expect(second_result["floor_surface"] == surface, "Rebuild keeps the existing editable surface instance.")
	expect_equal(
		surface.floor_map.get_cell_elevation(Vector2i.ZERO),
		4,
		"Height painting survives when its floor cell remains present after PNG rebuild."
	)
	expect(
		not surface.has_floor(Vector2i(1, 0)),
		"Transparent PNG pixels remove prior floor occupancy."
	)
	root.free()
