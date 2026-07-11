@tool
class_name PNGToGridMapExporter
extends RefCounted

## Converts an existing GridMap into a PNG representation using the active colour-mapping profile.
## Exported images preserve the grid footprint so they can be edited and imported again.

const PathsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_paths.gd")


## Exports a selected GridMap to a PNG file.
func run(settings: Resource, grid_map: GridMap, path: String, item_aliases: Dictionary, item_display_names: Dictionary) -> Dictionary:
	if grid_map == null:
		return {"errors": ["Select an existing GridMap before exporting."]}
	if grid_map.mesh_library == null:
		return {"errors": ["Selected GridMap has no MeshLibrary."]}
	var export_model := _build_export_model(settings, grid_map, item_aliases, item_display_names)
	var errors := _to_string_array(export_model.get("errors", []))
	if not errors.is_empty():
		return {"errors": errors}
	var image: Image = export_model["image"]
	var normalized_path := PathsResource.normalize_png_output_path(path)
	var result := image.save_png(normalized_path)
	if result != OK:
		return {"errors": ["Could not save PNG to %s. Error: %s" % [normalized_path, result]]}
	settings.png_path = normalized_path
	settings.export_origin = export_model["origin"]
	settings.export_size = export_model["size"]
	return {
		"path": normalized_path,
		"origin": export_model["origin"],
		"size": export_model["size"],
		"warnings": _to_string_array(export_model.get("warnings", [])),
		"errors": [],
	}


## Builds the exported image and warning list without writing to disk.
func _build_export_model(
	settings: Resource,
	grid_map: GridMap,
	item_aliases: Dictionary,
	item_display_names: Dictionary
) -> Dictionary:
	var cells: Array = grid_map.get_used_cells()
	var errors: Array[String] = []
	if cells.is_empty():
		return {"image": Image.create(1, 1, false, Image.FORMAT_RGBA8), "origin": Vector2i.ZERO, "size": Vector2i(1, 1), "errors": []}
	var item_to_mapping := _build_item_to_mapping(settings, grid_map.mesh_library, item_aliases)
	var bounds := _collect_cell_bounds(settings, grid_map, cells, item_to_mapping)
	errors.append_array(_to_string_array(bounds.get("errors", [])))
	if not errors.is_empty():
		return {"errors": errors}
	var origin: Vector2i = bounds["origin"]
	var size: Vector2i = bounds["size"]
	var cell_to_key: Dictionary = bounds["cell_to_key"]
	var colour_grid := PNGToGridMapImageGrid.grid_from_cells(cell_to_key, origin, size, true)
	errors.append_array(_validate_mapping_conflicts(grid_map, item_to_mapping))
	if not errors.is_empty():
		return {"errors": errors}
	var warnings := _validate_cells(settings, grid_map, cell_to_key, item_to_mapping, colour_grid, origin, size, item_aliases, item_display_names)
	var image := _build_image_from_cells(settings, cell_to_key, origin, size)
	return {"image": image, "origin": origin, "size": size, "errors": [], "warnings": warnings}


## Builds a lookup from MeshLibrary item id to mapping resource.
func _build_item_to_mapping(settings: Resource, library: MeshLibrary, item_aliases: Dictionary) -> Dictionary:
	var item_to_mapping := {}
	var ref_to_id := PNGToGridMapMeshCatalog.ref_to_id(library)
	for mapping in settings.color_mappings:
		for variant in PNGToGridMapAutotile.VARIANTS:
			if variant != PNGToGridMapAutotile.VARIANT_BASE and not mapping.autotile_enabled:
				continue
			var ref := _mapping_variant_ref(mapping, variant, item_aliases)
			if ref == "" or not ref_to_id.has(ref):
				continue
			var item_id := int(ref_to_id[ref])
			if item_to_mapping.has(item_id) and item_to_mapping[item_id]["mapping"] != mapping:
				item_to_mapping[item_id]["conflict"] = true
			else:
				item_to_mapping[item_id] = {"mapping": mapping, "ref": ref, "conflict": false}
	return item_to_mapping


## Collects occupied cells into export bounds and colour-key lookup.
func _collect_cell_bounds(settings: Resource, grid_map: GridMap, cells: Array, item_to_mapping: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var initialized := false
	var min_x := 0
	var max_x := 0
	var min_z := 0
	var max_z := 0
	var cell_to_key := {}
	for cell in cells:
		if cell.y != 0:
			errors.append("Cell %s is not on Y=0; PNG export supports one GridMap layer." % cell)
			continue
		var item_id := grid_map.get_cell_item(cell)
		if not item_to_mapping.has(item_id):
			errors.append("No colour mapping for GridMap item: %s" % PNGToGridMapMeshCatalog.item_debug_name(grid_map.mesh_library, item_id))
			continue
		var mapping = item_to_mapping[item_id]["mapping"]
		cell_to_key[cell] = PNGToGridMapImageGrid.colour_key(mapping.colour)
		if not initialized:
			min_x = cell.x
			max_x = cell.x
			min_z = cell.z
			max_z = cell.z
			initialized = true
		else:
			min_x = mini(min_x, cell.x)
			max_x = maxi(max_x, cell.x)
			min_z = mini(min_z, cell.z)
			max_z = maxi(max_z, cell.z)
	if not errors.is_empty():
		return {"errors": errors}
	return {
		"origin": Vector2i(min_x, min_z),
		"size": Vector2i(max_x - min_x + 1, max_z - min_z + 1),
		"cell_to_key": cell_to_key,
		"errors": [],
	}


## Reports items that cannot be exported because they map to multiple colours.
func _validate_mapping_conflicts(grid_map: GridMap, item_to_mapping: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var reported := {}
	for item_id in item_to_mapping.keys():
		if bool(item_to_mapping[item_id]["conflict"]) and not reported.has(item_id):
			errors.append("Item %s is mapped to multiple colours." % PNGToGridMapMeshCatalog.item_debug_name(grid_map.mesh_library, int(item_id)))
			reported[item_id] = true
	return errors


## Validates exported cells against deterministic import expectations.
func _validate_cells(
	settings: Resource,
	grid_map: GridMap,
	cell_to_key: Dictionary,
	item_to_mapping: Dictionary,
	colour_grid: Array,
	origin: Vector2i,
	size: Vector2i,
	item_aliases: Dictionary,
	item_display_names: Dictionary
) -> Array[String]:
	var errors: Array[String] = []
	var ref_to_id := PNGToGridMapMeshCatalog.ref_to_id(grid_map.mesh_library)
	for cell in cell_to_key.keys():
		var key: String = cell_to_key[cell]
		var mapping := _mapping_for_key(settings, key)
		if mapping == null:
			errors.append("No mapping found for exported colour #%s." % key)
			continue
		_append_cell_validation(errors, grid_map, cell, mapping, colour_grid, origin, size, true, ref_to_id, item_aliases, item_display_names)
	return errors


## Adds validation messages for one exported cell when item or orientation differs.
func _append_cell_validation(
	errors: Array[String],
	grid_map: GridMap,
	cell: Vector3i,
	mapping: Resource,
	colour_grid: Array,
	origin: Vector2i,
	size: Vector2i,
	flip_y_to_world_negative_z: bool,
	ref_to_id: Dictionary,
	item_aliases: Dictionary,
	item_display_names: Dictionary
) -> void:
	var key := PNGToGridMapImageGrid.colour_key(mapping.colour)
	var pixel := PNGToGridMapImageGrid.cell_to_pixel(cell, origin, size, flip_y_to_world_negative_z)
	var item_id := grid_map.get_cell_item(cell)
	var orientation := grid_map.get_cell_item_orientation(cell)
	var mask := PNGToGridMapImageGrid.get_same_colour_mask(colour_grid, pixel.x, pixel.y, key)
	var variant := PNGToGridMapAutotile.variant_for_mask(mask) if mapping.autotile_enabled else PNGToGridMapAutotile.VARIANT_BASE
	var expected_ref := _mapping_variant_ref(mapping, variant, item_aliases)
	var expected_id := int(ref_to_id.get(expected_ref, -1))
	var expected_basis := PNGToGridMapAutotile.basis_for_variant(mapping, variant, mask, mapping.autotile_enabled)
	if flip_y_to_world_negative_z:
		expected_basis = expected_basis.rotated(Vector3.UP, PI)
	var expected_orientation := grid_map.get_orthogonal_index_from_basis(expected_basis)
	if item_id != expected_id:
		errors.append("Cell %s uses %s, expected %s." % [cell, PNGToGridMapMeshCatalog.item_debug_name(grid_map.mesh_library, item_id), _item_display_name(expected_ref, item_display_names)])
	if orientation != expected_orientation:
		errors.append("Cell %s uses orientation %s, expected %s." % [cell, orientation, expected_orientation])


## Builds a PNG image from exported cell colour keys.
func _build_image_from_cells(settings: Resource, cell_to_key: Dictionary, origin: Vector2i, size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for cell in cell_to_key.keys():
		var mapping := _mapping_for_key(settings, String(cell_to_key[cell]))
		var pixel := PNGToGridMapImageGrid.cell_to_pixel(cell, origin, size, true)
		image.set_pixel(pixel.x, pixel.y, mapping.colour)
	return image


## Finds the mapping resource for a colour key.
func _mapping_for_key(settings: Resource, key: String) -> Resource:
	for mapping in settings.color_mappings:
		if PNGToGridMapImageGrid.colour_key(mapping.colour) == key:
			return mapping
	return null


## Resolves a mapping variant ref through MeshLibrary aliases.
func _mapping_variant_ref(mapping: Resource, variant: String, item_aliases: Dictionary) -> String:
	var ref := PNGToGridMapAutotile.variant_ref_for_mapping(mapping, variant)
	return String(item_aliases.get(ref, ref))


## Looks up a display label for an item ref.
func _item_display_name(item_ref: String, item_display_names: Dictionary) -> String:
	return String(item_display_names.get(item_ref, item_ref))


## Converts an arbitrary variant into a typed string array.
func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
