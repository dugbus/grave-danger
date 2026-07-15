@tool
class_name PNGToGridMapMeshCatalog
extends RefCounted

## Discovers MeshLibrary resources and exposes stable names for their items.
## The catalog keeps editor selections and saved mapping references meaningful across sessions.


## Scans the project for MeshLibrary resources.
static func find_project_mesh_libraries(editor_filesystem: Object) -> Array[String]:
	var results: Array[String] = []
	_collect_project_mesh_libraries("res://", results, editor_filesystem)
	results.sort()
	return results


## Recursively collects MeshLibrary resource paths under one directory.
static func _collect_project_mesh_libraries(
	directory_path: String,
	results: Array[String],
	editor_filesystem: Object
) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry == "":
			break
		if entry.begins_with("."):
			continue
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_project_mesh_libraries(path, results, editor_filesystem)
			continue
		var extension := entry.get_extension().to_lower()
		if extension != "tres" and extension != "res":
			continue
		# Checking the declared type avoids loading every project resource and all of
		# its dependencies merely to discover the small set of MeshLibraries.
		if String(editor_filesystem.call(&"get_file_type", path)) == "MeshLibrary":
			results.append(path)
	directory.list_dir_end()


## Builds user-facing item refs and display labels for a MeshLibrary.
static func item_ref_entries(library: MeshLibrary) -> Array[Dictionary]:
	var raw_entries: Array[Dictionary] = []
	var counts := {}
	for item_id in library.get_item_list():
		var item_name := library.get_item_name(item_id)
		var base_ref := item_base_ref(library, item_id)
		raw_entries.append({"item_id": item_id, "item_name": item_name, "base_ref": base_ref})
		counts[base_ref] = int(counts.get(base_ref, 0)) + 1
	return _deduplicate_entries(raw_entries, counts)


## Chooses the most stable item ref source for one MeshLibrary item.
static func item_base_ref(library: MeshLibrary, item_id: int) -> String:
	var mesh := library.get_item_mesh(item_id)
	if mesh != null:
		var glb_path := _extract_model_path_from_resource_path(mesh.resource_path)
		if glb_path != "":
			return glb_path.get_file().get_basename()
		var mesh_model_name := _extract_model_name_from_mesh_resource_name(mesh.resource_name)
		if mesh_model_name != "":
			return mesh_model_name
	var item_name := library.get_item_name(item_id)
	if item_name != "":
		return item_name
	return "Item %s" % item_id


## Builds a concise name for errors and warnings about one MeshLibrary item.
static func item_debug_name(library: MeshLibrary, item_id: int) -> String:
	var item_name := library.get_item_name(item_id)
	var base_ref := item_base_ref(library, item_id)
	if base_ref != "" and base_ref != item_name:
		return "%s (%s)" % [base_ref, item_name]
	if item_name != "":
		return item_name
	return "Item %s" % item_id


## Creates a lookup from item refs and aliases to MeshLibrary item ids.
static func ref_to_id(library: MeshLibrary) -> Dictionary:
	var result := {}
	for entry in item_ref_entries(library):
		var item_id := int(entry["item_id"])
		var ref := String(entry["ref"])
		var item_name := String(entry["item_name"])
		result[ref] = item_id
		if item_name != "" and not result.has(item_name):
			result[item_name] = item_id
	return result


## Converts item entries with duplicate base refs into unique selectable refs.
static func _deduplicate_entries(raw_entries: Array[Dictionary], counts: Dictionary) -> Array[Dictionary]:
	var used_refs := {}
	var entries: Array[Dictionary] = []
	for entry in raw_entries:
		var item_id := int(entry["item_id"])
		var item_name := String(entry["item_name"])
		var base_ref := String(entry["base_ref"])
		var ref := base_ref
		if used_refs.has(ref):
			ref = "%s#%s" % [base_ref, item_name]
			if used_refs.has(ref):
				ref = "%s#%s" % [base_ref, item_id]
		used_refs[ref] = true
		var display := base_ref
		if int(counts[base_ref]) > 1:
			display = "%s (%s)" % [base_ref, item_name]
		entries.append({
			"ref": ref,
			"display": display,
			"item_id": item_id,
			"item_name": item_name,
			"base_ref": base_ref,
		})
	return entries


## Extracts the owning model path from an imported mesh subresource path.
static func _extract_model_path_from_resource_path(resource_path: String) -> String:
	var glb_index := resource_path.find(".glb")
	if glb_index >= 0:
		return resource_path.substr(0, glb_index + 4)
	var gltf_index := resource_path.find(".gltf")
	if gltf_index >= 0:
		return resource_path.substr(0, gltf_index + 5)
	return ""


## Extracts a model-like name from an embedded primitive mesh resource name.
static func _extract_model_name_from_mesh_resource_name(resource_name: String) -> String:
	if resource_name == "":
		return ""
	for primitive: String in ["Cube", "Cylinder", "Sphere", "Plane", "Mesh"]:
		var suffix: String = "_" + primitive
		if resource_name.ends_with(suffix):
			return resource_name.substr(0, resource_name.length() - suffix.length())
		var numbered_suffix: String = suffix + "_"
		var numbered_index := resource_name.rfind(numbered_suffix)
		if numbered_index > 0:
			var number_part: String = resource_name.substr(numbered_index + numbered_suffix.length())
			if number_part.is_valid_int():
				return resource_name.substr(0, numbered_index)
	return ""
