@tool
extends RefCounted
class_name PNGToGridMapResourceCatalog


static func collect_material_paths(
	editor_filesystem: EditorFileSystem,
	folder: String
) -> Array[String]:
	var paths: Array[String] = []
	_collect_material_paths_recursive(editor_filesystem, folder, paths)
	paths.sort()
	return paths


static func collect_grid_map_paths(root: Node) -> Array[String]:
	var paths: Array[String] = []
	if root != null:
		_collect_grid_map_paths_recursive(root, root, paths)
	return paths


## Keeps a valid configured GridMap, or selects the scene's only GridMap when unambiguous.
static func preferred_grid_map_path(root: Node, configured_path: NodePath) -> NodePath:
	if root == null:
		return NodePath()
	if not configured_path.is_empty() and root.get_node_or_null(configured_path) is GridMap:
		return configured_path
	var paths := collect_grid_map_paths(root)
	return NodePath(paths[0]) if paths.size() == 1 else NodePath()


static func _collect_material_paths_recursive(
	editor_filesystem: EditorFileSystem,
	folder: String,
	paths: Array[String]
) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var path := folder.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_material_paths_recursive(editor_filesystem, path, paths)
		elif entry.get_extension().to_lower() in ["material", "tres"]:
			var resource_type := editor_filesystem.get_file_type(path)
			if resource_type != "" and ClassDB.is_parent_class(resource_type, &"Material"):
				paths.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


static func _collect_grid_map_paths_recursive(
	root: Node,
	node: Node,
	paths: Array[String]
) -> void:
	if node is GridMap:
		paths.append(String(root.get_path_to(node)))
	for child in node.get_children():
		_collect_grid_map_paths_recursive(root, child, paths)
