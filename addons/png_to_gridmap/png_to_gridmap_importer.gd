@tool
class_name PNGToGridMapImporter
extends RefCounted

const CELL_SIZE_PRECISION := 1000.0


## Validates that the current PNG and mappings can be imported.
func validate(
	settings: Resource,
	image: Image,
	ref_to_id: Dictionary,
	item_aliases: Dictionary,
	empty_key: String
) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	if image == null:
		errors.append("No PNG loaded.")
		return {"errors": errors, "warnings": warnings}
	var colour_grid := PNGToGridMapImageGrid.grid_from_image(image, settings.ignore_fully_transparent, empty_key)
	for key in _mapping_keys_for_image(image, settings.ignore_fully_transparent, empty_key):
		var mapping := _mapping_for_key(settings, key)
		if mapping == null:
			warnings.append("No mapping for colour #%s." % key)
			continue
		if mapping.base_item_ref == "":
			warnings.append("Colour #%s has no base item." % key)
			continue
		var base_ref := _mapping_variant_ref(mapping, PNGToGridMapAutotile.VARIANT_BASE, item_aliases)
		if not ref_to_id.has(base_ref):
			errors.append("Base item not found for colour #%s: %s" % [key, base_ref])
		if mapping.autotile_enabled:
			for variant in PNGToGridMapImageGrid.required_variants_for_colour(colour_grid, key):
				var ref := _mapping_variant_ref(mapping, variant, item_aliases)
				if ref == "":
					errors.append("Colour #%s needs %s item for this PNG." % [key, variant])
				elif not ref_to_id.has(ref):
					errors.append("%s item not found for colour #%s: %s" % [variant.capitalize(), key, ref])
	return {"errors": errors, "warnings": warnings}


## Imports an image into an existing or newly created GridMap.
func run(
	settings: Resource,
	image: Image,
	root: Node,
	grid_map: GridMap,
	library: MeshLibrary,
	ref_to_id: Dictionary,
	item_aliases: Dictionary,
	empty_key: String
) -> Dictionary:
	if root == null:
		return {"errors": ["Open a scene before importing."]}
	var created_gridmap := false
	if grid_map == null:
		grid_map = GridMap.new()
		grid_map.name = settings.gridmap_name if settings.gridmap_name != "" else "PNGGridMap"
		root.add_child(grid_map)
		grid_map.owner = root
		created_gridmap = true
		settings.target_gridmap_path = root.get_path_to(grid_map)
	grid_map.mesh_library = library
	grid_map.cell_size = Vector3.ONE * _normalize_cell_size(settings.cell_size)
	var import_origin := PNGToGridMapImageGrid.get_import_origin(
		image.get_width(),
		image.get_height(),
		settings.export_origin,
		settings.export_size,
		settings.center_cells,
		settings.flip_y_to_world_negative_z
	)
	var import_size := Vector2i(image.get_width(), image.get_height())
	if created_gridmap and settings.center_cells:
		import_origin = Vector2i.ZERO
		PNGToGridMapImageGrid.offset_created_gridmap_for_rect(grid_map, import_size)
	PNGToGridMapImageGrid.clear_gridmap_rect(grid_map, import_origin, import_size)
	var placed := _place_cells(settings, image, grid_map, ref_to_id, item_aliases, empty_key, import_origin, import_size)
	settings.export_origin = import_origin
	settings.export_size = import_size
	return {"grid_map": grid_map, "placed": placed, "created": created_gridmap, "errors": []}


## Places all mapped non-empty PNG pixels into the target GridMap.
func _place_cells(
	settings: Resource,
	image: Image,
	grid_map: GridMap,
	ref_to_id: Dictionary,
	item_aliases: Dictionary,
	empty_key: String,
	import_origin: Vector2i,
	import_size: Vector2i
) -> int:
	var colour_grid := PNGToGridMapImageGrid.grid_from_image(image, settings.ignore_fully_transparent, empty_key)
	var placed := 0
	for y in image.get_height():
		for x in image.get_width():
			var key := String(colour_grid[y][x])
			if key == "":
				continue
			var mapping := _mapping_for_key(settings, key)
			if mapping == null or mapping.base_item_ref == "":
				continue
			var mask := PNGToGridMapImageGrid.get_same_colour_mask(colour_grid, x, y, key)
			var variant := PNGToGridMapAutotile.variant_for_mask(mask) if mapping.autotile_enabled else PNGToGridMapAutotile.VARIANT_BASE
			var item_ref := _mapping_variant_ref(mapping, variant, item_aliases)
			var item_id := int(ref_to_id[item_ref])
			var basis := PNGToGridMapAutotile.basis_for_variant(mapping, variant, mask, mapping.autotile_enabled)
			if settings.flip_y_to_world_negative_z:
				basis = basis.rotated(Vector3.UP, PI)
			var orientation := grid_map.get_orthogonal_index_from_basis(basis)
			var cell := PNGToGridMapImageGrid.pixel_to_cell(Vector2i(x, y), import_origin, import_size, settings.flip_y_to_world_negative_z)
			grid_map.set_cell_item(cell, item_id, orientation)
			placed += 1
	return placed


## Returns every non-empty colour key currently present in an image.
func _mapping_keys_for_image(image: Image, ignore_fully_transparent: bool, empty_key: String) -> Array[String]:
	var scan := PNGToGridMapImageGrid.scan_image_colours(image, ignore_fully_transparent)
	var keys: Array[String] = []
	keys.assign(scan["order"])
	keys.erase(empty_key)
	return keys


## Finds the colour mapping for one colour key.
func _mapping_for_key(settings: Resource, key: String) -> Resource:
	for mapping in settings.color_mappings:
		if PNGToGridMapImageGrid.colour_key(mapping.colour) == key:
			return mapping
	return null


## Resolves a mapping variant through MeshLibrary aliases.
func _mapping_variant_ref(mapping: Resource, variant: String, item_aliases: Dictionary) -> String:
	var ref := PNGToGridMapAutotile.variant_ref_for_mapping(mapping, variant)
	return String(item_aliases.get(ref, ref))


## Normalizes user-entered cell sizes before assigning them to GridMaps.
func _normalize_cell_size(value: float) -> float:
	return round(value * CELL_SIZE_PRECISION) / CELL_SIZE_PRECISION
