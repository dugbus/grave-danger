extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")
const SUBJECT_PATH := "res://addons/floor_surface/floor_surface_grid_alignment.gd"
const SURFACE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_alignment_keeps_equal_cells_on_equal_centres()
	_test_expanded_floor_cells_need_no_gridmap_resize()


func _test_alignment_keeps_equal_cells_on_equal_centres() -> void:
	var parent := Node3D.new()
	var grid_map := GridMap.new()
	grid_map.position = Vector3(-12.5, 0.0, -12.5)
	parent.add_child(grid_map)
	var surface := _surface_with_map()
	parent.add_child(surface)
	var errors := SUBJECT.align_surface_to_grid_map(surface, grid_map)
	expect(errors.is_empty(), "An ordinary square GridMap can align a FloorSurface.")
	expect(SUBJECT.is_aligned(surface, grid_map), "The aligned pair reports its shared convention.")
	var floor_centre := surface.cell_to_local(Vector2i.ZERO)
	var grid_centre := grid_map.transform * grid_map.map_to_local(Vector3i.ZERO)
	expect_equal(
		Vector2(floor_centre.x, floor_centre.z),
		Vector2(grid_centre.x, grid_centre.z),
		"Floor and GridMap cell zero share one centre."
	)
	parent.free()


func _test_expanded_floor_cells_need_no_gridmap_resize() -> void:
	var parent := Node3D.new()
	var grid_map := GridMap.new()
	parent.add_child(grid_map)
	var surface := _surface_with_map()
	parent.add_child(surface)
	SUBJECT.align_surface_to_grid_map(surface, grid_map)
	var expanded_cell := Vector2i(40, -12)
	surface.floor_map.expand_bounds_to_include([expanded_cell] as Array[Vector2i])
	surface.floor_map.set_floor_present(expanded_cell, true)
	expect_equal(
		SUBJECT.floor_cell_to_grid_cell(surface, grid_map, expanded_cell),
		expanded_cell,
		"A sparse GridMap can address a newly expanded floor cell without stored bounds."
	)
	expect_equal(
		grid_map.get_cell_item(Vector3i(expanded_cell.x, 0, expanded_cell.y)),
		GridMap.INVALID_CELL_ITEM,
		"The new placement cell stays empty and ready for a level object."
	)
	parent.free()


func _surface_with_map() -> FloorSurface:
	var surface := SURFACE_SCENE.instantiate() as FloorSurface
	var floor_map := FloorMap.new()
	floor_map.default_present = true
	surface.floor_map = floor_map
	surface.elevation_profile = FloorElevationProfile.new()
	return surface
