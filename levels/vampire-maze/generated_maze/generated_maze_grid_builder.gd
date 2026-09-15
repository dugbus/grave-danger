extends RefCounted
class_name GDGeneratedMazeGridBuilder

const REPAIRER_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const MESH_CATALOG_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_mesh_catalog.gd")
const FLOOR_SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const GRID_ALIGNMENT_SCRIPT := preload("res://addons/floor_surface/floor_surface_grid_alignment.gd")
const BASE_WALL_ITEM_REF := "Wall"


func populate(
	wall_grid_map: GridMap,
	floor_surface: FLOOR_SURFACE_SCRIPT,
	floor_cells: Dictionary,
	width: int,
	height: int,
	_floor_texture_tiles: Vector2i,
	wall_repair_settings: Resource
) -> Array[String]:
	var errors: Array[String] = []
	if wall_grid_map.mesh_library == null:
		return ["GeneratedMaze wall GridMap requires a MeshLibrary."]
	if floor_surface == null or floor_surface.floor_map == null:
		return ["GeneratedMaze requires an editable FloorSurface map."]

	var wall_refs: Dictionary = MESH_CATALOG_SCRIPT.ref_to_id(wall_grid_map.mesh_library)
	if not wall_refs.has(BASE_WALL_ITEM_REF):
		return ["GeneratedMaze wall MeshLibrary has no '%s' item." % BASE_WALL_ITEM_REF]
	var wall_item_id := int(wall_refs[BASE_WALL_ITEM_REF])
	var map_offset := Vector3(-float(width) * 0.5, 0.0, -float(height) * 0.5)
	wall_grid_map.clear()
	wall_grid_map.position = map_offset
	wall_grid_map.cell_size = Vector3.ONE
	wall_grid_map.cell_center_x = true
	wall_grid_map.cell_center_y = false
	wall_grid_map.cell_center_z = true
	errors.append_array(GRID_ALIGNMENT_SCRIPT.align_surface_to_grid_map(floor_surface, wall_grid_map))
	if not errors.is_empty():
		return errors
	var floor_map := floor_surface.floor_map
	floor_map.minimum_cell = Vector2i.ZERO
	floor_map.dimensions = Vector2i(width, height)
	floor_map.default_present = true
	floor_map.presence_exceptions.clear()
	floor_map.default_elevation = 0
	floor_map.elevation_overrides.clear()
	floor_map.default_style_index = 0
	floor_map.style_overrides.clear()
	floor_map.transition_overrides.clear()
	floor_map.low_edge_overrides.clear()
	floor_map.emit_changed()
	for z_coordinate in height:
		for x_coordinate in width:
			var cell := Vector3i(x_coordinate, 0, z_coordinate)
			if not floor_cells.has(Vector2i(x_coordinate, z_coordinate)):
				wall_grid_map.set_cell_item(cell, wall_item_id)
	errors.append_array(repair(wall_grid_map, wall_repair_settings))
	return errors


func repair(wall_grid_map: GridMap, wall_repair_settings: Resource) -> Array[String]:
	if wall_repair_settings == null:
		return ["GeneratedMaze requires PNG-to-GridMap wall repair settings."]
	var repairer: RefCounted = REPAIRER_SCRIPT.new()
	var plan: Dictionary = repairer.call(&"build_plan", wall_repair_settings, wall_grid_map, {})
	var errors: Array[String] = []
	for error in plan.get("errors", []):
		errors.append(String(error))
	if not errors.is_empty():
		return errors
	for change in plan.get("changes", []):
		var cell := change["cell"] as Vector3i
		wall_grid_map.set_cell_item(cell, int(change["item_id"]), int(change["orientation"]))
	return errors
