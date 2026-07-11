@tool
extends EditorPlugin

## Coordinates the PNG-to-GridMap editor workflow and its focused import, export, repair, and floor services.
## The plugin connects the dock to scene-safe operations, profile persistence, and undo history.

const SettingsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const ColorMappingResource := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")
const DockResource := preload("res://addons/png_to_gridmap/png_to_gridmap_dock.gd")
const ProfileStoreResource := preload("res://addons/png_to_gridmap/png_to_gridmap_profile_store.gd")
const ImporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_importer.gd")
const ExporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_exporter.gd")
const RepairerResource := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const FloorBuilderResource := preload("res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd")
const PathsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_paths.gd")

const PLUGIN_CONFIG_PATH := "res://addons/png_to_gridmap/plugin.cfg"
const EMPTY_KEY := "FFFFFFFF"
const LEVEL_PNG_FILE := "level.png"
const AUTO_REPAIR_CHECK_INTERVAL_MSEC := 200
const AUTO_REPAIR_DEBOUNCE_MSEC := 600

var _settings: Resource = SettingsResource.new()
var _image: Image
var _detected_colours := {}
var _colour_order: Array[String] = []
var _mesh_library_paths: Array[String] = []
var _floor_material_paths: Array[String] = []
var _available_item_refs: Array[String] = []
var _available_item_display_names := {}
var _available_item_ref_aliases := {}
var _operation_id := PNGToGridMapDock.OPERATION_IMPORT
var _advanced_visible := false
var _dock: PNGToGridMapDock
var _profile_store: PNGToGridMapProfileStore
var _importer: PNGToGridMapImporter
var _exporter: PNGToGridMapExporter
var _repairer: RefCounted
var _floor_builder: RefCounted
var _observed_grid_map_id := 0
var _observed_grid_map_fingerprint := 0
var _next_auto_repair_check_msec := 0
var _auto_repair_due_msec := 0


## Creates the dock and service objects when the editor enables the addon.
func _enter_tree() -> void:
	_profile_store = ProfileStoreResource.new(get_editor_interface(), SettingsResource)
	_importer = ImporterResource.new()
	_exporter = ExporterResource.new()
	_repairer = RepairerResource.new()
	_floor_builder = FloorBuilderResource.new()
	var ui_state := _profile_store.load_ui_state(PNGToGridMapDock.OPERATION_IMPORT)
	_operation_id = int(ui_state["operation_id"])
	_advanced_visible = bool(ui_state["advanced_visible"])
	_dock = DockResource.new()
	_dock.setup(_dock_title(), _settings, ui_state)
	_connect_dock_signals()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_load_level_settings()
	_load_conventional_level_png()
	_refresh_all()
	set_process(true)


## Removes the dock when the editor disables the addon.
func _exit_tree() -> void:
	set_process(false)
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


## Watches the selected GridMap at a low frequency and repairs once painting has paused.
func _process(_delta: float) -> void:
	if not _settings.auto_repair:
		_reset_auto_repair_watch()
		return
	var now := Time.get_ticks_msec()
	if now < _next_auto_repair_check_msec:
		return
	_next_auto_repair_check_msec = now + AUTO_REPAIR_CHECK_INTERVAL_MSEC
	var grid_map := _selected_gridmap()
	if grid_map == null:
		_reset_auto_repair_watch()
		return
	var instance_id := int(grid_map.get_instance_id())
	var fingerprint := _grid_map_fingerprint(grid_map)
	if instance_id != _observed_grid_map_id:
		_observed_grid_map_id = instance_id
		_observed_grid_map_fingerprint = fingerprint
		_auto_repair_due_msec = 0
		return
	if fingerprint != _observed_grid_map_fingerprint:
		_observed_grid_map_fingerprint = fingerprint
		_auto_repair_due_msec = now + AUTO_REPAIR_DEBOUNCE_MSEC
	if _auto_repair_due_msec != 0 and now >= _auto_repair_due_msec:
		_auto_repair_due_msec = 0
		_repair_grid_map(grid_map, true)
		_observed_grid_map_fingerprint = _grid_map_fingerprint(grid_map)


## Builds a compact title using plugin.cfg metadata.
func _dock_title() -> String:
	var config := ConfigFile.new()
	if config.load(PLUGIN_CONFIG_PATH) != OK:
		return "PNG to GridMap"
	var version := String(config.get_value("plugin", "version", ""))
	return "PNG to GridMap %s" % version if version != "" else "PNG to GridMap"


## Connects dock UI actions to plugin-level orchestration handlers.
func _connect_dock_signals() -> void:
	_dock.load_png_selected.connect(_on_load_png_selected)
	_dock.export_png_path_selected.connect(_on_export_png_path_selected)
	_dock.run_requested.connect(_on_run_requested)
	_dock.repair_gridmap_requested.connect(_on_repair_gridmap_requested)
	_dock.create_floor_requested.connect(_on_create_floor_requested)
	_dock.floor_material_selected.connect(_on_floor_material_selected)
	_dock.refresh_requested.connect(_refresh_all)
	_dock.operation_changed.connect(_on_operation_changed)
	_dock.mesh_library_selected.connect(_on_mesh_library_selected)
	_dock.gridmap_selected.connect(_on_gridmap_selected)
	_dock.settings_changed.connect(_on_settings_changed)
	_dock.mapping_changed.connect(_on_mapping_changed)


## Refreshes project-driven dropdowns and reloads any saved PNG state.
func _refresh_all() -> void:
	_refresh_mesh_libraries()
	_refresh_floor_materials()
	_refresh_gridmap_paths()
	_refresh_available_items()
	var conventional_png := _conventional_level_png_path()
	if conventional_png != "" and ResourceLoader.exists(conventional_png) \
			and _settings.png_path != conventional_png:
		_load_png(conventional_png, false)
	elif _settings.png_path != "" and _image == null:
		_load_png(_settings.png_path, false)
	else:
		_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_update_dock_state()


## Rebuilds the MeshLibrary dropdown from project resources.
func _refresh_mesh_libraries() -> void:
	_mesh_library_paths = PNGToGridMapMeshCatalog.find_project_mesh_libraries()
	if _settings.mesh_library_path == "" and _mesh_library_paths.size() == 1:
		_settings.mesh_library_path = _mesh_library_paths[0]
		_load_profile_for_current_mesh_library()
	_dock.set_settings(_settings)
	_dock.set_mesh_library_paths(_mesh_library_paths)


## Rebuilds the floor material choices from the globally configured folder.
func _refresh_floor_materials() -> void:
	_floor_material_paths.clear()
	_collect_material_paths(_settings.floor_materials_folder, _floor_material_paths)
	_floor_material_paths.sort()
	_dock.set_floor_material_paths(_floor_material_paths)


## Recursively collects loadable Material resources without relying on file extensions alone.
func _collect_material_paths(folder: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(folder)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		var path := folder.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_collect_material_paths(path, paths)
		elif entry.get_extension().to_lower() in ["material", "tres"]:
			if ResourceLoader.load(path) is Material:
				paths.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


## Rebuilds the GridMap dropdown from the currently edited scene.
func _refresh_gridmap_paths() -> void:
	var paths: Array[String] = []
	var root := get_editor_interface().get_edited_scene_root()
	if root != null:
		_collect_gridmap_paths(root, root, paths)
	_dock.set_gridmap_paths(paths)


## Collects scene-relative NodePaths for GridMaps in one scene subtree.
func _collect_gridmap_paths(root: Node, node: Node, paths: Array[String]) -> void:
	if node is GridMap:
		paths.append(String(root.get_path_to(node)))
	for child in node.get_children():
		_collect_gridmap_paths(root, child, paths)


## Rebuilds selectable MeshLibrary item refs for mapping rows.
func _refresh_available_items() -> void:
	_available_item_refs.clear()
	_available_item_display_names.clear()
	_available_item_ref_aliases.clear()
	var active := _active_mesh_library()
	if active.has("library"):
		for entry in PNGToGridMapMeshCatalog.item_ref_entries(active["library"]):
			var ref := String(entry["ref"])
			var base_ref := String(entry["base_ref"])
			var item_name := String(entry["item_name"])
			_available_item_refs.append(ref)
			_available_item_display_names[ref] = String(entry["display"])
			if base_ref != "" and not _available_item_ref_aliases.has(base_ref):
				_available_item_ref_aliases[base_ref] = ref
			if item_name != "" and not _available_item_ref_aliases.has(item_name):
				_available_item_ref_aliases[item_name] = ref
	_dock.set_available_items(_available_item_refs, _available_item_display_names, _available_item_ref_aliases)


## Loads the automatic mapping profile for the selected MeshLibrary.
func _load_profile_for_current_mesh_library() -> void:
	_settings = _profile_store.load_for_mesh_library(_settings)
	if _image != null:
		_scan_colours()


## Loads a PNG from disk and updates colour mapping rows.
func _on_load_png_selected(path: String) -> void:
	_load_png(path, true)


## Records the user-selected export PNG path without writing a file.
func _on_export_png_path_selected(path: String) -> void:
	_settings.export_png_path = PathsResource.normalize_png_output_path(path)
	_save_profile()
	_update_dock_state()


## Dispatches the fixed Run button to the selected operation.
func _on_run_requested(operation_id: int) -> void:
	if operation_id == PNGToGridMapDock.OPERATION_EXPORT:
		_request_export(_export_output_path())
	else:
		_run_import()


## Stores the floor material selected for the current level.
func _on_floor_material_selected(path: String) -> void:
	_settings.floor_material_path = PathsResource.localize_project_path(path)
	_save_profile()
	_update_dock_state("Floor material selected: %s" % _settings.floor_material_path)


## Creates or rebuilds the generated floor from every non-transparent PNG pixel.
func _on_create_floor_requested() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	var result: Dictionary = _floor_builder.run(_settings, _image, root, _selected_gridmap())
	var errors := _to_string_array(result.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("Create Floor could not run:\n- %s" % "\n- ".join(errors))
		return
	var floor_grid_map: GridMap = result["grid_map"]
	get_editor_interface().edit_node(floor_grid_map)
	get_editor_interface().mark_scene_as_unsaved()
	_refresh_gridmap_paths()
	_save_profile()
	var action := "Created" if bool(result["created"]) else "Rebuilt"
	_update_dock_state("%s %s collision-backed floor cells in %s." % [
		action,
		int(result["placed"]),
		floor_grid_map.name,
	])


## Repairs enabled autotile variants using the occupied cells in the selected GridMap.
func _on_repair_gridmap_requested() -> void:
	var grid_map := _selected_gridmap()
	_repair_grid_map(grid_map, false)


## Repairs one GridMap, optionally keeping quiet when an automatic pass has nothing to change.
func _repair_grid_map(grid_map: GridMap, automatic: bool) -> void:
	var result: Dictionary = _repairer.build_plan(_settings, grid_map, _available_item_ref_aliases)
	var errors := _to_string_array(result.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("Repair GridMap could not run:\n- %s" % "\n- ".join(errors))
		return

	var changes: Array = result.get("changes", [])
	var warnings := _to_string_array(result.get("warnings", []))
	if changes.is_empty():
		if automatic:
			return
		var message := "No autotile changes were needed in %s.\n%s" % [grid_map.name, _repair_result_summary(result)]
		if not warnings.is_empty():
			message += "\n" + "\n".join(warnings)
		_update_dock_state(message)
		return

	var undo_redo := get_undo_redo()
	undo_redo.create_action("Auto Repair GridMap" if automatic else "Repair GridMap")
	for change: Dictionary in changes:
		undo_redo.add_do_method(grid_map, &"set_cell_item", change["cell"], int(change["item_id"]), int(change["orientation"]))
		undo_redo.add_undo_method(grid_map, &"set_cell_item", change["cell"], int(change["previous_item_id"]), int(change["previous_orientation"]))
	undo_redo.commit_action()
	get_editor_interface().edit_node(grid_map)
	get_editor_interface().mark_scene_as_unsaved()
	_save_profile()
	var message := "Repaired %s autotile cells in %s.\n%s" % [changes.size(), grid_map.name, _repair_result_summary(result)]
	if not warnings.is_empty():
		message += "\n" + "\n".join(warnings)
	_update_dock_state(message)


## Formats repair coverage without exposing internal cell coordinates or IDs.
func _repair_result_summary(result: Dictionary) -> String:
	return "Checked %s cells: %s matched enabled mappings, %s skipped." % [
		int(result.get("total_cells", 0)),
		int(result.get("configured_cells", 0)),
		int(result.get("skipped_cells", 0)),
	]


## Persists the operation selector and Advanced visibility as editor UI state.
func _on_operation_changed(operation_id: int, advanced_visible: bool) -> void:
	_operation_id = operation_id
	_advanced_visible = advanced_visible
	_profile_store.save_ui_state(operation_id, advanced_visible)
	_update_dock_state()


## Loads mappings and item refs for the selected MeshLibrary.
func _on_mesh_library_selected(path: String) -> void:
	_settings.mesh_library_path = path
	_load_profile_for_current_mesh_library()
	_dock.set_settings(_settings)
	_refresh_available_items()
	if _settings.png_path != "" and _image == null:
		_load_png(_settings.png_path, false)
	else:
		_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_update_dock_state()


## Records the scene GridMap target chosen in the dock.
func _on_gridmap_selected(path: String) -> void:
	_settings.target_gridmap_path = NodePath(path)
	_reset_auto_repair_watch()
	_save_profile()
	_update_dock_state()


## Saves non-mapping settings and refreshes derived colour state when needed.
func _on_settings_changed() -> void:
	_settings.cell_size = round(float(_settings.cell_size) * 1000.0) / 1000.0
	if _image != null:
		_scan_colours()
		_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_save_profile()
	_refresh_floor_materials()
	if not _settings.auto_repair:
		_reset_auto_repair_watch()
	_update_dock_state()


## Clears pending change detection when the target or setting changes.
func _reset_auto_repair_watch() -> void:
	_observed_grid_map_id = 0
	_observed_grid_map_fingerprint = 0
	_next_auto_repair_check_msec = 0
	_auto_repair_due_msec = 0


## Summarises GridMap contents so painting changes can be detected without editor input hooks.
func _grid_map_fingerprint(grid_map: GridMap) -> int:
	var cells := grid_map.get_used_cells()
	cells.sort()
	var fingerprint := cells.size()
	for cell: Vector3i in cells:
		fingerprint = hash([
			fingerprint,
			cell,
			grid_map.get_cell_item(cell),
			grid_map.get_cell_item_orientation(cell),
		])
	return fingerprint


## Saves mapping changes and updates validation with current assignments.
func _on_mapping_changed() -> void:
	_save_profile()
	_update_dock_state()


## Loads a PNG image and rebuilds colour mappings from its palette.
func _load_png(path: String, save_profile: bool) -> void:
	var localized_path := PathsResource.localize_project_path(path)
	var texture := ResourceLoader.load(localized_path) as Texture2D
	if texture == null:
		_update_dock_state("Could not load PNG: %s." % localized_path)
		return

	var image := texture.get_image()
	if image == null:
		_update_dock_state("Could not read image data from PNG: %s." % localized_path)
		return
	_image = image
	_settings.png_path = localized_path
	_scan_colours()
	_dock.set_settings(_settings)
	_dock.set_png_state(localized_path, _detected_colours, _colour_order)
	if save_profile:
		_save_profile()
	_update_dock_state()


## Imports the current PNG after validating mappings and warnings.
func _run_import() -> void:
	var active := _active_mesh_library()
	var errors := _to_string_array(active.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("\n".join(errors))
		return
	var validation := _importer.validate(_settings, _image, active["ref_to_id"], _available_item_ref_aliases, EMPTY_KEY)
	errors = _to_string_array(validation.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("\n".join(errors))
		return
	var warnings := _to_string_array(validation.get("warnings", []))
	if not warnings.is_empty():
		_dock.show_import_warning(warnings, func() -> void: _continue_import(active))
		return
	_continue_import(active)


## Performs the import once the user has accepted any non-blocking warnings.
func _continue_import(active: Dictionary) -> void:
	var root := get_editor_interface().get_edited_scene_root()
	var result := _importer.run(_settings, _image, root, _selected_gridmap(), active["library"], active["ref_to_id"], _available_item_ref_aliases, EMPTY_KEY)
	var errors := _to_string_array(result.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("\n".join(errors))
		return
	var grid_map: GridMap = result["grid_map"]
	get_editor_interface().edit_node(grid_map)
	get_editor_interface().mark_scene_as_unsaved()
	_refresh_gridmap_paths()
	_save_profile()
	_update_dock_state("Imported %s cells into %s." % [int(result["placed"]), grid_map.name])


## Confirms overwrite when needed before exporting the selected GridMap.
func _request_export(path: String) -> void:
	var normalized_path := PathsResource.normalize_png_output_path(path)
	if FileAccess.file_exists(normalized_path):
		_dock.show_overwrite_warning(normalized_path, func() -> void: _run_export(normalized_path))
		return
	_run_export(normalized_path)


## Exports the selected GridMap to a PNG path.
func _run_export(path: String) -> void:
	var active := _active_mesh_library()
	var errors := _to_string_array(active.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("\n".join(errors))
		return
	var normalized_path := PathsResource.normalize_png_output_path(path)
	var result := _exporter.run(_settings, _selected_gridmap(), normalized_path, _available_item_ref_aliases, _available_item_display_names)
	errors = _to_string_array(result.get("errors", []))
	if not errors.is_empty():
		_update_dock_state("\n".join(errors))
		return
	_settings.export_png_path = String(result["path"])
	_load_png(String(result["path"]), false)
	_save_profile()
	var warnings := _to_string_array(result.get("warnings", []))
	var message := "Exported PNG: %s" % String(result["path"])
	if not warnings.is_empty():
		message += "\n" + "\n".join(warnings)
	_update_dock_state(message)


## Scans the current image and creates missing colour mappings.
func _scan_colours() -> void:
	var scan := PNGToGridMapImageGrid.scan_image_colours(_image, true)
	_detected_colours = scan["data"]
	_colour_order.clear()
	_colour_order.assign(scan["order"])
	_detected_colours.erase(EMPTY_KEY)
	_colour_order.erase(EMPTY_KEY)
	for key in _colour_order:
		_get_or_create_mapping(key, _detected_colours[key]["colour"])


## Finds or creates the serialized mapping for one PNG colour.
func _get_or_create_mapping(key: String, colour: Color) -> Resource:
	for mapping in _settings.color_mappings:
		if PNGToGridMapImageGrid.colour_key(mapping.colour) == key:
			return mapping
	var mapping := ColorMappingResource.new()
	mapping.colour = colour
	mapping.display_name = "#" + key
	_settings.color_mappings.append(mapping)
	return mapping


## Loads the selected MeshLibrary and its item lookup for service calls.
func _active_mesh_library() -> Dictionary:
	if _settings.mesh_library_path == "":
		return {"errors": ["Select a MeshLibrary before running the converter."]}
	if not ResourceLoader.exists(_settings.mesh_library_path):
		return {"errors": ["MeshLibrary file not found: %s" % _settings.mesh_library_path]}
	var library := ResourceLoader.load(_settings.mesh_library_path)
	if not library is MeshLibrary:
		return {"errors": ["Selected resource is not a MeshLibrary: %s" % _settings.mesh_library_path]}
	return {"library": library, "ref_to_id": PNGToGridMapMeshCatalog.ref_to_id(library), "errors": []}


## Returns the existing GridMap selected in the scene dropdown.
func _selected_gridmap() -> GridMap:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null or String(_settings.target_gridmap_path) == "":
		return null
	var node := root.get_node_or_null(_settings.target_gridmap_path)
	return node as GridMap


## Computes the selected export path, defaulting to overwriting the loaded PNG.
func _export_output_path() -> String:
	if _settings.export_png_path != "":
		return _settings.export_png_path
	if _settings.png_path != "":
		return _settings.png_path
	var root := get_editor_interface().get_edited_scene_root()
	if root != null and root.scene_file_path != "":
		return root.scene_file_path.get_basename() + "_gridmap.png"
	return "res://gridmap_export.png"


## Saves the selected MeshLibrary's automatic mapping profile when configured.
func _save_profile() -> void:
	if _settings.mesh_library_path == "":
		return
	var root := get_editor_interface().get_edited_scene_root()
	var scene_path := root.scene_file_path if root != null else ""
	_profile_store.save(_settings, scene_path)


## Loads conversion state from the settings resource beside the edited level scene.
func _load_level_settings() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		return
	_settings = _profile_store.load_for_scene(_settings, root.scene_file_path)


## Loads level.png beside the edited level scene using the add-on's file convention.
func _load_conventional_level_png() -> void:
	var path := _conventional_level_png_path()
	if path != "" and ResourceLoader.exists(path):
		_load_png(path, false)


## Returns the conventional PNG path beside the currently edited level scene.
func _conventional_level_png_path() -> String:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null or root.scene_file_path == "":
		return ""
	return root.scene_file_path.get_base_dir().path_join(LEVEL_PNG_FILE)


## Updates shared dock labels and validation status.
func _update_dock_state(message: String = "") -> void:
	_dock.set_settings(_settings)
	_dock.set_output_path(_export_output_path())
	_dock.set_validation_text(message if message != "" else _validation_text())


## Builds the current validation summary shown above Run.
func _validation_text() -> String:
	var errors: Array[String] = []
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		errors.append("Open a scene before running the converter.")
	var active := _active_mesh_library()
	errors.append_array(_to_string_array(active.get("errors", [])))
	if _operation_id == PNGToGridMapDock.OPERATION_IMPORT and _image == null:
		var expected_path := _conventional_level_png_path()
		if expected_path == "":
			errors.append("Open a saved level scene so its level.png can be loaded automatically.")
		else:
			errors.append(
				"Create the level layout PNG at %s, then press Refresh. Each pixel represents one GridMap cell."
				% expected_path
			)
	if _operation_id == PNGToGridMapDock.OPERATION_EXPORT and _selected_gridmap() == null:
		errors.append("Select an existing GridMap before exporting.")
	return "\n".join(errors) if not errors.is_empty() else "Ready."


## Converts an arbitrary array-like value into typed strings.
func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result
