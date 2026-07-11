@tool
class_name PNGToGridMapRepairer
extends RefCounted

## Repairs the variants and orientations of connected GridMap pieces already present in a scene.
## It preserves cell placement and derives the intended shape from neighbouring compatible tiles.

const AutotileAlternativeResource := preload("res://addons/png_to_gridmap/png_to_gridmap_autotile_alternative.gd")

const GRID_NORTH := Vector3i(0, 0, -1)
const GRID_EAST := Vector3i(1, 0, 0)
const GRID_SOUTH := Vector3i(0, 0, 1)
const GRID_WEST := Vector3i(-1, 0, 0)


## Plans in-place autotile repairs without reading or changing a PNG image.
func build_plan(settings: Resource, grid_map: GridMap, item_aliases: Dictionary) -> Dictionary:
	if grid_map == null:
		return {"errors": ["Select an existing GridMap before repairing."], "warnings": [], "changes": []}
	if grid_map.mesh_library == null:
		return {"errors": ["Selected GridMap has no MeshLibrary."], "warnings": [], "changes": []}

	var item_to_mapping := _build_item_to_mapping(settings, grid_map.mesh_library, item_aliases)
	var cells: Array = grid_map.get_used_cells()

	var errors: Array[String] = []
	var warnings: Array[String] = []
	var changes: Array[Dictionary] = []
	var ignored_cells := 0
	var reported_conflicts := {}
	var variant_issues := {}
	var ref_to_id := PNGToGridMapMeshCatalog.ref_to_id(grid_map.mesh_library)
	var cell_to_connection := {}
	for cell: Vector3i in cells:
		var item_id := grid_map.get_cell_item(cell)
		if not item_to_mapping.has(item_id):
			ignored_cells += 1
			continue
		var mapping_data: Dictionary = item_to_mapping[item_id]
		if bool(mapping_data["conflict"]):
			if not reported_conflicts.has(item_id):
				errors.append(
					"MeshLibrary piece '%s' belongs to incompatible autotile mappings. Give those mappings distinct pieces or matching variant settings."
					% PNGToGridMapMeshCatalog.item_debug_name(grid_map.mesh_library, item_id)
				)
				reported_conflicts[item_id] = true
			continue
		cell_to_connection[cell] = String(mapping_data["connection_key"])

	for cell: Vector3i in cells:
		var item_id := grid_map.get_cell_item(cell)
		if not item_to_mapping.has(item_id):
			continue
		var mapping_data: Dictionary = item_to_mapping[item_id]
		if bool(mapping_data["conflict"]):
			continue
		var mapping: Resource = mapping_data["mapping"]
		var connection_key := String(mapping_data["connection_key"])
		var mask := _connection_neighbour_mask(cell, cell_to_connection, connection_key, true)
		var alternative := mapping_data.get("alternative") as Resource
		var previous_orientation := grid_map.get_cell_item_orientation(cell)
		if alternative != null:
			var alternative_orientation := _alternative_orientation_for_mask(
				alternative,
				mask,
				previous_orientation,
				grid_map,
				true
			)
			if alternative_orientation >= 0:
				if previous_orientation != alternative_orientation:
					changes.append({
						"cell": cell,
						"item_id": item_id,
						"orientation": alternative_orientation,
						"previous_item_id": item_id,
						"previous_orientation": previous_orientation,
					})
				continue
		var variant := PNGToGridMapAutotile.variant_for_mask(mask)
		var item_ref := _mapping_variant_ref(mapping, variant, item_aliases)
		if item_ref == "":
			_record_variant_issue(variant_issues, mapping, variant, item_ref, true)
			continue
		if not ref_to_id.has(item_ref):
			_record_variant_issue(variant_issues, mapping, variant, item_ref, false)
			continue

		var basis := PNGToGridMapAutotile.basis_for_variant(mapping, variant, mask, true)
		basis = basis.rotated(Vector3.UP, PI)
		var orientation := grid_map.get_orthogonal_index_from_basis(basis)
		var expected_item_id := int(ref_to_id[item_ref])
		if item_id != expected_item_id or previous_orientation != orientation:
			changes.append({
				"cell": cell,
				"item_id": expected_item_id,
				"orientation": orientation,
				"previous_item_id": item_id,
				"previous_orientation": previous_orientation,
			})

	_append_variant_issue_errors(errors, variant_issues)
	if ignored_cells > 0:
		warnings.append("%s cells were skipped because they do not match an enabled autotile mapping." % ignored_cells)
	return {
		"errors": errors,
		"warnings": warnings,
		"changes": changes,
		"total_cells": cells.size(),
		"configured_cells": cell_to_connection.size(),
		"skipped_cells": ignored_cells,
	}


## Builds a lookup from every configured autotile item to its owning mapping.
func _build_item_to_mapping(settings: Resource, library: MeshLibrary, item_aliases: Dictionary) -> Dictionary:
	var result := {}
	var ref_to_id := PNGToGridMapMeshCatalog.ref_to_id(library)
	for mapping: Resource in settings.color_mappings:
		if not mapping.autotile_enabled:
			continue
		var mapping_signature := _mapping_signature(mapping, item_aliases)
		var connection_key := _connection_key_for_mapping(mapping, mapping_signature)
		for variant in PNGToGridMapAutotile.VARIANTS:
			var ref := _mapping_variant_ref(mapping, variant, item_aliases)
			if ref == "" or not ref_to_id.has(ref):
				continue
			var item_id := int(ref_to_id[ref])
			_add_item_mapping(result, item_id, mapping, mapping_signature, connection_key, null)
		for alternative: Resource in mapping.autotile_alternatives:
			var alternative_ref := _alternative_item_ref(alternative, item_aliases)
			if alternative_ref == "" or not ref_to_id.has(alternative_ref):
				continue
			_add_item_mapping(
				result,
				int(ref_to_id[alternative_ref]),
				mapping,
				mapping_signature,
				connection_key,
				alternative
			)
	return result


## Adds one canonical or preserved-alternative MeshLibrary item to the repair lookup.
func _add_item_mapping(
	result: Dictionary,
	item_id: int,
	mapping: Resource,
	mapping_signature: String,
	connection_key: String,
	alternative: Resource
) -> void:
	if result.has(item_id):
		if String(result[item_id]["mapping_signature"]) != mapping_signature:
			result[item_id]["conflict"] = true
		return
	result[item_id] = {
		"mapping": mapping,
		"mapping_signature": mapping_signature,
		"connection_key": connection_key,
		"alternative": alternative,
		"conflict": false,
	}


## Builds the source-image neighbour mask for cells in the same configured connection group.
func _connection_neighbour_mask(
	cell: Vector3i,
	cell_to_connection: Dictionary,
	connection_key: String,
	flip_y_to_world_negative_z: bool
) -> int:
	var mask := 0
	if flip_y_to_world_negative_z:
		if _cell_has_connection(cell + GRID_SOUTH, cell_to_connection, connection_key):
			mask |= PNGToGridMapAutotile.NORTH
		if _cell_has_connection(cell + GRID_WEST, cell_to_connection, connection_key):
			mask |= PNGToGridMapAutotile.EAST
		if _cell_has_connection(cell + GRID_NORTH, cell_to_connection, connection_key):
			mask |= PNGToGridMapAutotile.SOUTH
		if _cell_has_connection(cell + GRID_EAST, cell_to_connection, connection_key):
			mask |= PNGToGridMapAutotile.WEST
		return mask
	if _cell_has_connection(cell + GRID_NORTH, cell_to_connection, connection_key):
		mask |= PNGToGridMapAutotile.NORTH
	if _cell_has_connection(cell + GRID_EAST, cell_to_connection, connection_key):
		mask |= PNGToGridMapAutotile.EAST
	if _cell_has_connection(cell + GRID_SOUTH, cell_to_connection, connection_key):
		mask |= PNGToGridMapAutotile.SOUTH
	if _cell_has_connection(cell + GRID_WEST, cell_to_connection, connection_key):
		mask |= PNGToGridMapAutotile.WEST
	return mask


## Reports whether a cell belongs to the target configured connection group.
func _cell_has_connection(cell: Vector3i, cell_to_connection: Dictionary, connection_key: String) -> bool:
	return String(cell_to_connection.get(cell, "")) == connection_key


## Uses an explicit shared group, or connects equivalent configured variant sets.
func _connection_key_for_mapping(mapping: Resource, mapping_signature: String) -> String:
	var group: String = String(mapping.autotile_connectivity_group).strip_edges()
	if group != "":
		return "group:%s" % group
	return "mapping:%s" % mapping_signature


## Builds a stable identity from all configured variants and their rotation offsets.
func _mapping_signature(mapping: Resource, item_aliases: Dictionary) -> String:
	var parts: Array[String] = []
	for variant: String in PNGToGridMapAutotile.VARIANTS:
		parts.append("%s=%s@%s" % [
			variant,
			_mapping_variant_ref(mapping, variant, item_aliases),
			PNGToGridMapAutotile.rotation_offset_for_mapping(mapping, variant),
		])
	var alternative_parts: Array[String] = []
	for alternative: Resource in mapping.autotile_alternatives:
		alternative_parts.append("%s@%s:%s" % [
			_alternative_item_ref(alternative, item_aliases),
			int(alternative.rotation_offset),
			int(alternative.connection_shape),
		])
	alternative_parts.sort()
	parts.append_array(alternative_parts)
	return "|".join(parts)


## Finds a valid orientation for an alternative whose configured joins match its neighbours.
func _alternative_orientation_for_mask(
	alternative: Resource,
	neighbour_mask: int,
	current_orientation: int,
	grid_map: GridMap,
	flip_y_to_world_negative_z: bool
) -> int:
	var shape := int(alternative.connection_shape) as AutotileAlternativeResource.ConnectionShape
	var variant := AutotileAlternativeResource.variant_for_connection_shape(shape)
	var default_mask := PNGToGridMapAutotile.default_mask_for_variant(variant)
	var offset := int(alternative.rotation_offset)
	var first_matching_orientation := -1
	for turns in 4:
		if PNGToGridMapAutotile.rotate_mask_clockwise(default_mask, turns) != neighbour_mask:
			continue
		var basis := Basis.IDENTITY.rotated(
			Vector3.UP,
			-(float(turns) * PI * 0.5) + (float(offset) * PI * 0.5)
		)
		if flip_y_to_world_negative_z:
			basis = basis.rotated(Vector3.UP, PI)
		var matching_orientation := grid_map.get_orthogonal_index_from_basis(basis)
		if matching_orientation == current_orientation:
			return current_orientation
		if first_matching_orientation < 0:
			first_matching_orientation = matching_orientation
	return first_matching_orientation


## Counts cells blocked by one missing or unknown configured variant.
func _record_variant_issue(
	issues: Dictionary,
	mapping: Resource,
	variant: String,
	item_ref: String,
	missing_assignment: bool
) -> void:
	var issue_type := "unassigned" if missing_assignment else "missing_item"
	var key := "%s:%s:%s:%s" % [mapping.get_instance_id(), variant, item_ref, issue_type]
	if not issues.has(key):
		issues[key] = {
			"count": 0,
			"item_ref": item_ref,
			"mapping_label": _mapping_label(mapping),
			"missing_assignment": missing_assignment,
			"variant": variant,
		}
	issues[key]["count"] = int(issues[key]["count"]) + 1


## Converts aggregated configuration issues into concise guidance for the dock.
func _append_variant_issue_errors(errors: Array[String], issues: Dictionary) -> void:
	for issue: Dictionary in issues.values():
		var count := int(issue["count"])
		var mapping_label := String(issue["mapping_label"])
		var variant := String(issue["variant"]).capitalize()
		if bool(issue["missing_assignment"]):
			errors.append(
				"Autotile mapping '%s' needs a %s piece for %s cells. Assign it under Colour Mappings."
				% [mapping_label, variant, count]
			)
		else:
			errors.append(
				"Autotile mapping '%s' references missing %s piece '%s' for %s cells. Select a valid MeshLibrary piece."
				% [mapping_label, variant, String(issue["item_ref"]), count]
			)


## Returns the name shown for one configured colour mapping.
func _mapping_label(mapping: Resource) -> String:
	var display_name := String(mapping.display_name).strip_edges()
	return display_name if display_name != "" else "Unnamed mapping"


## Resolves a mapping variant through MeshLibrary aliases.
func _mapping_variant_ref(mapping: Resource, variant: String, item_aliases: Dictionary) -> String:
	var ref := PNGToGridMapAutotile.variant_ref_for_mapping(mapping, variant)
	return String(item_aliases.get(ref, ref))


## Resolves a preserved alternative item through MeshLibrary aliases.
func _alternative_item_ref(alternative: Resource, item_aliases: Dictionary) -> String:
	var ref := String(alternative.item_ref)
	return String(item_aliases.get(ref, ref))
