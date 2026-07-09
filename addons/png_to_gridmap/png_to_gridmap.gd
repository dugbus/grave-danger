@tool
extends EditorPlugin

const SettingsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const ColorMappingResource := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")
const DockResource := preload("res://addons/png_to_gridmap/png_to_gridmap_dock.gd")
const ProfileStoreResource := preload("res://addons/png_to_gridmap/png_to_gridmap_profile_store.gd")
const ImporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_importer.gd")
const ExporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_exporter.gd")
const PathsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_paths.gd")

const PLUGIN_CONFIG_PATH := "res://addons/png_to_gridmap/plugin.cfg"
const EMPTY_KEY := "FFFFFFFF"

var _settings: Resource = SettingsResource.new()
var _image: Image
var _detected_colours := {}
var _colour_order: Array[String] = []
var _mesh_library_paths: Array[String] = []
var _available_item_refs: Array[String] = []
var _available_item_display_names := {}
var _available_item_ref_aliases := {}
var _operation_id := PNGToGridMapDock.OPERATION_IMPORT
var _advanced_visible := false
var _dock: PNGToGridMapDock
var _profile_store: PNGToGridMapProfileStore
var _importer: PNGToGridMapImporter
var _exporter: PNGToGridMapExporter


## Creates the dock and service objects when the editor enables the addon.
func _enter_tree() -> void:
	_profile_store = ProfileStoreResource.new(get_editor_interface(), SettingsResource)
	_importer = ImporterResource.new()
	_exporter = ExporterResource.new()
	var ui_state := _profile_store.load_ui_state(PNGToGridMapDock.OPERATION_IMPORT)
	_operation_id = int(ui_state["operation_id"])
	_advanced_visible = bool(ui_state["advanced_visible"])
	_dock = DockResource.new()
	_dock.setup(_dock_title(), _settings, ui_state)
	_connect_dock_signals()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_refresh_all()


## Removes the dock when the editor disables the addon.
func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


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
	_dock.refresh_requested.connect(_refresh_all)
	_dock.new_settings_requested.connect(_on_new_settings_requested)
	_dock.operation_changed.connect(_on_operation_changed)
	_dock.mesh_library_selected.connect(_on_mesh_library_selected)
	_dock.gridmap_selected.connect(_on_gridmap_selected)
	_dock.settings_changed.connect(_on_settings_changed)
	_dock.mapping_changed.connect(_on_mapping_changed)


## Refreshes project-driven dropdowns and reloads any saved PNG state.
func _refresh_all() -> void:
	_refresh_mesh_libraries()
	_refresh_gridmap_paths()
	_refresh_available_items()
	if _settings.png_path != "" and _image == null:
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


## Replaces mappings with a fresh profile while keeping current editor inputs.
func _on_new_settings_requested() -> void:
	var previous := _settings
	_settings = SettingsResource.new()
	_settings.png_path = previous.png_path
	_settings.export_png_path = previous.export_png_path
	_settings.target_gridmap_path = previous.target_gridmap_path
	_settings.mesh_library_path = previous.mesh_library_path
	_settings.gridmap_name = previous.gridmap_name
	if _image != null:
		_scan_colours()
	_dock.set_settings(_settings)
	_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_save_profile()
	_update_dock_state("Started a fresh automatic mapping profile.")


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
	_save_profile()
	_update_dock_state()


## Saves non-mapping settings and refreshes derived colour state when needed.
func _on_settings_changed() -> void:
	_settings.cell_size = round(float(_settings.cell_size) * 1000.0) / 1000.0
	if _image != null:
		_scan_colours()
		_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_save_profile()
	_update_dock_state()


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
	var scan := PNGToGridMapImageGrid.scan_image_colours(_image, _settings.ignore_fully_transparent)
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
	_profile_store.save(_settings)


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
		errors.append("Load a PNG before importing.")
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
