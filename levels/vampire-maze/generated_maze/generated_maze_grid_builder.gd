extends RefCounted
class_name GDGeneratedMazeGridBuilder

const REPAIRER_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const MESH_CATALOG_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_mesh_catalog.gd")
const BASE_WALL_ITEM_REF := "Wall"


func populate(
	wall_grid_map: GridMap,
	floor_grid_map: GridMap,
	floor_cells: Dictionary,
	width: int,
	height: int,
	floor_texture_tiles: Vector2i,
	wall_repair_settings: Resource
) -> Array[String]:
	var errors: Array[String] = []
	if wall_grid_map.mesh_library == null:
		return ["GeneratedMaze wall GridMap requires a MeshLibrary."]
	if floor_grid_map.mesh_library == null or floor_grid_map.mesh_library.get_item_list().is_empty():
		return ["GeneratedMaze floor GridMap requires at least one MeshLibrary item."]

	var wall_refs: Dictionary = MESH_CATALOG_SCRIPT.ref_to_id(wall_grid_map.mesh_library)
	if not wall_refs.has(BASE_WALL_ITEM_REF):
		return ["GeneratedMaze wall MeshLibrary has no '%s' item." % BASE_WALL_ITEM_REF]
	var wall_item_id := int(wall_refs[BASE_WALL_ITEM_REF])
	var map_offset := Vector3(-float(width) * 0.5, 0.0, -float(height) * 0.5)
	wall_grid_map.clear()
	floor_grid_map.clear()
	wall_grid_map.position = map_offset
	floor_grid_map.position = map_offset
	wall_grid_map.cell_size = Vector3.ONE
	floor_grid_map.cell_size = Vector3.ONE
	wall_grid_map.cell_center_y = false
	floor_grid_map.cell_center_y = false
	for z_coordinate in height:
		for x_coordinate in width:
			var cell := Vector3i(x_coordinate, 0, z_coordinate)
			var floor_item_id := GDGeneratedFloorSettings.item_id_for_cell(
				floor_grid_map,
				Vector2i(x_coordinate, z_coordinate),
				floor_texture_tiles
			)
			floor_grid_map.set_cell_item(cell, floor_item_id)
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
