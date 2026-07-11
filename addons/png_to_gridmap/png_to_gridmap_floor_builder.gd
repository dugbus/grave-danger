@tool
class_name PNGToGridMapFloorBuilder
extends RefCounted

## Builds a batched, collision-backed floor beneath the non-transparent area of a source PNG.
## The generated GridMap follows the imported layout while keeping floor rendering economical.

const FLOOR_GRIDMAP_NAME := "PNGFloorGridMap"
const FLOOR_ITEM_ID := 0
const FLOOR_ITEM_NAME := "PNG Floor Tile"
const FLOOR_OCTANT_SIZE := 16
const FLOOR_TILE_SCENE := preload("res://addons/png_to_gridmap/floor/png_floor_tile.tscn")


## Creates or rebuilds a collision-backed floor GridMap from non-transparent PNG pixels.
func run(
	settings: Resource,
	image: Image,
	root: Node,
	source_grid_map: GridMap
) -> Dictionary:
	var errors := _validate(settings, image, root)
	if not errors.is_empty():
		return {"errors": errors}

	var floor_material := ResourceLoader.load(settings.floor_material_path) as Material
	var floor_grid_map := _find_floor_grid_map(settings, root)
	var created := floor_grid_map == null
	if created:
		floor_grid_map = GridMap.new()
		floor_grid_map.name = FLOOR_GRIDMAP_NAME
		root.add_child(floor_grid_map)
		floor_grid_map.owner = root
		settings.floor_gridmap_path = root.get_path_to(floor_grid_map)

	_configure_grid_map(floor_grid_map, settings, source_grid_map)
	var library_result := _build_floor_library(floor_grid_map.cell_size, floor_material)
	var library_errors: Array = library_result["errors"]
	if not library_errors.is_empty():
		if created:
			floor_grid_map.queue_free()
		return {"errors": library_errors}
	floor_grid_map.mesh_library = library_result["library"]
	floor_grid_map.clear()

	var import_size := Vector2i(image.get_width(), image.get_height())
	var import_origin := PNGToGridMapImageGrid.get_import_origin(
		image.get_width(),
		image.get_height(),
		settings.export_origin,
		settings.export_size,
		true,
		true
	)
	if created and source_grid_map == null and settings.export_size == Vector2i.ZERO:
		import_origin = Vector2i.ZERO
		PNGToGridMapImageGrid.offset_created_gridmap_for_rect(floor_grid_map, import_size)

	var placed := 0
	for y in image.get_height():
		for x in image.get_width():
			if is_zero_approx(image.get_pixel(x, y).a):
				continue
			var cell := PNGToGridMapImageGrid.pixel_to_cell(
				Vector2i(x, y),
				import_origin,
				import_size,
				true
			)
			floor_grid_map.set_cell_item(cell, FLOOR_ITEM_ID)
			placed += 1

	return {
		"created": created,
		"errors": [],
		"grid_map": floor_grid_map,
		"placed": placed,
	}


## Validates floor inputs before changing the edited scene.
func _validate(settings: Resource, image: Image, root: Node) -> Array[String]:
	var errors: Array[String] = []
	if root == null:
		errors.append("Open a scene before creating a floor.")
	if image == null or image.is_empty():
		errors.append("Load a PNG before creating a floor.")
	if settings.floor_material_path == "":
		errors.append("Select a floor material.")
	elif not ResourceLoader.exists(settings.floor_material_path):
		errors.append("Floor material not found: %s" % settings.floor_material_path)
	elif not ResourceLoader.load(settings.floor_material_path) is Material:
		errors.append("Selected floor resource is not a Material: %s" % settings.floor_material_path)
	return errors


## Finds the previously generated floor without confusing it with the wall GridMap.
func _find_floor_grid_map(settings: Resource, root: Node) -> GridMap:
	if String(settings.floor_gridmap_path) != "":
		var configured := root.get_node_or_null(settings.floor_gridmap_path) as GridMap
		if configured != null:
			return configured
	return root.get_node_or_null(FLOOR_GRIDMAP_NAME) as GridMap


## Copies grid alignment from the selected wall map and applies performant collision defaults.
func _configure_grid_map(floor_grid_map: GridMap, settings: Resource, source_grid_map: GridMap) -> void:
	if source_grid_map != null and source_grid_map != floor_grid_map:
		floor_grid_map.transform = source_grid_map.transform
		floor_grid_map.cell_size = source_grid_map.cell_size
		floor_grid_map.cell_center_x = source_grid_map.cell_center_x
		floor_grid_map.cell_center_z = source_grid_map.cell_center_z
	else:
		floor_grid_map.cell_size = Vector3.ONE * maxf(float(settings.cell_size), 0.01)
	floor_grid_map.cell_center_y = false
	floor_grid_map.cell_octant_size = FLOOR_OCTANT_SIZE
	floor_grid_map.collision_layer = 1
	floor_grid_map.collision_mask = 0


## Builds one shared mesh/collision item so GridMap can batch all visible floor cells.
func _build_floor_library(cell_size: Vector3, floor_material: Material) -> Dictionary:
	var tile := FLOOR_TILE_SCENE.instantiate()
	var mesh_instance := tile.get_node_or_null("MeshInstance3D") as MeshInstance3D
	var collision_shape := tile.get_node_or_null("StaticBody3D/CollisionShape3D") as CollisionShape3D
	if mesh_instance == null or not mesh_instance.mesh is PlaneMesh:
		tile.free()
		return {"errors": ["Floor tile scene needs a PlaneMesh at MeshInstance3D."]}
	if collision_shape == null or not collision_shape.shape is BoxShape3D:
		tile.free()
		return {"errors": ["Floor tile scene needs a BoxShape3D collision shape."]}

	var mesh := mesh_instance.mesh.duplicate() as PlaneMesh
	mesh.size = Vector2(cell_size.x, cell_size.z)
	mesh.material = floor_material

	var shape := collision_shape.shape.duplicate() as BoxShape3D
	shape.size = Vector3(cell_size.x, shape.size.y, cell_size.z)
	var shape_transform := collision_shape.transform
	shape_transform.origin.y = -shape.size.y * 0.5
	var library := MeshLibrary.new()
	library.create_item(FLOOR_ITEM_ID)
	library.set_item_name(FLOOR_ITEM_ID, FLOOR_ITEM_NAME)
	library.set_item_mesh(FLOOR_ITEM_ID, mesh)
	library.set_item_shapes(FLOOR_ITEM_ID, [shape, shape_transform])
	tile.free()
	return {"errors": [], "library": library}
