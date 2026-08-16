@tool
extends EditorPlugin

## Coordinates the PNG-to-GridMap editor workflow and its focused import, export, repair, and floor services.
## The plugin connects the dock to scene-safe operations, profile persistence, and undo history.

const SettingsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const DockScene := preload("res://addons/png_to_gridmap/png_to_gridmap_dock.tscn")
const ProfileStoreResource := preload("res://addons/png_to_gridmap/png_to_gridmap_profile_store.gd")
const ImporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_importer.gd")
const ExporterResource := preload("res://addons/png_to_gridmap/png_to_gridmap_exporter.gd")
const RepairerResource := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const FloorBuilderResource := preload("res://addons/png_to_gridmap/png_to_gridmap_floor_builder.gd")
const PathsResource := preload("res://addons/png_to_gridmap/png_to_gridmap_paths.gd")
const MappingCatalog := preload(
	"res://addons/png_to_gridmap/png_to_gridmap_mapping_catalog.gd"
)
const AutoRepairWatch := preload("res://addons/png_to_gridmap/png_to_gridmap_auto_repair_watch.gd")
const ResourceCatalog := preload("res://addons/png_to_gridmap/png_to_gridmap_resource_catalog.gd")

const PLUGIN_CONFIG_PATH := "res://addons/png_to_gridmap/plugin.cfg"
const EMPTY_KEY := "FFFFFFFF"
const LEVEL_PNG_FILE := "level.png"
const DIAGNOSTIC_PREFIX := "[PNGToGridMap]"

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
var _auto_repair_watch := AutoRepairWatch.new()
var _resource_refresh_pending := true
var _live_scene_refresh_pending := false
var _reload_settings_pending := false
var _level_settings_loaded := false
var _editor_dock: EditorDock
var _dock_is_open := false
var _dock_visibility_initialized := false
var _watched_mesh_library: MeshLibrary
var _watched_settings: Resource


## Creates the dock and service objects when the editor enables the addon.
func _enter_tree() -> void:
	var engine_version := String(Engine.get_version_info().get("string", "unknown"))
	_trace("Enabling on Godot %s (%s, %s)." % [
		engine_version,
		OS.get_name(),
		Engine.get_architecture_name(),
	])
	_profile_store = ProfileStoreResource.new(get_editor_interface(), SettingsResource)
	_importer = ImporterResource.new()
	_exporter = ExporterResource.new()
	_repairer = RepairerResource.new()
	_floor_builder = FloorBuilderResource.new()
	_remove_stale_editor_docks()
	var ui_state := _profile_store.load_ui_state(PNGToGridMapDock.OPERATION_IMPORT)
	_operation_id = int(ui_state["operation_id"])
	_advanced_visible = bool(ui_state["advanced_visible"])
	_dock = DockScene.instantiate() as PNGToGridMapDock
	_dock.setup(_dock_title(), _settings, ui_state)
	# Let Godot create and attach its compatibility EditorDock wrapper. Constructing
	# that wrapper directly can leave its tab detached from the content after a plugin reload.
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
	_editor_dock = _dock.get_parent() as EditorDock
	# This contextual dock is controlled by the edited scene rather than the global
	# Editor Docks menu or a saved open/closed state in Godot's editor layout.
	if _editor_dock != null:
		_editor_dock.global = false
		_editor_dock.transient = true
	_update_dock_visibility(get_editor_interface().get_edited_scene_root())
	# Connect editor callbacks only after the dock is ready because Godot can emit a
	# scene change immediately while enabling or restoring editor plugins.
	_connect_dock_signals()
	_trace("Dock UI created; waiting for an eligible level scene and project filesystem.")
	# A deferred check supports enabling the plugin after a scene is already open. During
	# editor startup, scene_changed supplies the readiness event after scenes are restored.
	_dock.set_validation_text("Waiting for Godot to finish opening the edited scene...")
	call_deferred(&"_try_complete_resource_refresh")
	set_process(true)


## Removes the dock when the editor disables the addon.
func _exit_tree() -> void:
	_trace("Disabling plugin.")
	set_process(false)
	_disconnect_editor_signals()
	_disconnect_live_resource_signals()
	_resource_refresh_pending = false
	_live_scene_refresh_pending = false
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_editor_dock = null
	_dock = null


## Watches the selected GridMap at a low frequency and repairs once painting has paused.
func _process(_delta: float) -> void:
	if not _settings.auto_repair:
		_reset_auto_repair_watch()
		return
	var grid_map := _selected_gridmap()
	var configuration_fingerprint: int = _repairer.configuration_fingerprint(
		_settings,
		_available_item_ref_aliases
	)
	if _auto_repair_watch.should_repair(
		grid_map,
		Time.get_ticks_msec(),
		configuration_fingerprint
	):
		_repair_grid_map(grid_map, true)
		_auto_repair_watch.accept_repair(grid_map, configuration_fingerprint)


## Builds a compact title using plugin.cfg metadata.
func _dock_title() -> String:
	var config := ConfigFile.new()
	if config.load(PLUGIN_CONFIG_PATH) != OK:
		return "PNG to GridMap"
	var version := String(config.get_value("plugin", "version", ""))
	return "PNG to GridMap %s" % version if version != "" else "PNG to GridMap"


## Removes wrappers orphaned when Godot hot-reloaded a previous plugin script version.
func _remove_stale_editor_docks() -> void:
	var base_control := get_editor_interface().get_base_control()
	var stale_dock_count := 0
	for node in base_control.find_children("*", "EditorDock", true, false):
		var stale_dock := node as EditorDock
		if stale_dock == null or stale_dock.title != "PNG to GridMap":
			continue
		remove_dock(stale_dock)
		stale_dock.queue_free()
		stale_dock_count += 1
	if stale_dock_count > 0:
		_trace("Removed %s stale dock wrapper(s) left by a plugin hot reload." % stale_dock_count)


## Connects dock UI actions to plugin-level orchestration handlers.
func _connect_dock_signals() -> void:
	scene_changed.connect(_on_edited_scene_changed)
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	editor_filesystem.filesystem_changed.connect(_on_editor_filesystem_activity_finished)
	editor_filesystem.resources_reimporting.connect(_on_editor_resources_reimporting)
	editor_filesystem.resources_reimported.connect(_on_editor_resources_reimported)
	editor_filesystem.resources_reload.connect(_on_editor_resources_reload)
	var undo_redo := get_undo_redo()
	undo_redo.history_changed.connect(_on_editor_history_changed)
	undo_redo.version_changed.connect(_on_editor_history_changed)
	var inspector := get_editor_interface().get_inspector()
	inspector.property_edited.connect(_on_editor_property_edited)
	var editor_tree := get_tree()
	editor_tree.node_added.connect(_on_editor_node_added)
	editor_tree.node_removed.connect(_on_editor_node_removed)
	editor_tree.node_renamed.connect(_on_editor_node_renamed)
	_dock.load_png_selected.connect(_on_load_png_selected)
	_dock.export_png_path_selected.connect(_on_export_png_path_selected)
	_dock.run_requested.connect(_on_run_requested)
	_dock.repair_gridmap_requested.connect(_on_repair_gridmap_requested)
	_dock.create_floor_requested.connect(_on_create_floor_requested)
	_dock.floor_material_selected.connect(_on_floor_material_selected)
	_dock.refresh_requested.connect(_on_refresh_requested)
	_dock.operation_changed.connect(_on_operation_changed)
	_dock.mesh_library_selected.connect(_on_mesh_library_selected)
	_dock.gridmap_selected.connect(_on_gridmap_selected)
	_dock.settings_changed.connect(_on_settings_changed)
	_dock.mapping_changed.connect(_on_mapping_changed)


## Stops editor-owned callbacks before the dock and its content begin shutting down.
func _disconnect_editor_signals() -> void:
	if scene_changed.is_connected(_on_edited_scene_changed):
		scene_changed.disconnect(_on_edited_scene_changed)
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	if editor_filesystem.filesystem_changed.is_connected(_on_editor_filesystem_activity_finished):
		editor_filesystem.filesystem_changed.disconnect(_on_editor_filesystem_activity_finished)
	if editor_filesystem.resources_reimporting.is_connected(_on_editor_resources_reimporting):
		editor_filesystem.resources_reimporting.disconnect(_on_editor_resources_reimporting)
	if editor_filesystem.resources_reimported.is_connected(_on_editor_resources_reimported):
		editor_filesystem.resources_reimported.disconnect(_on_editor_resources_reimported)
	if editor_filesystem.resources_reload.is_connected(_on_editor_resources_reload):
		editor_filesystem.resources_reload.disconnect(_on_editor_resources_reload)
	var undo_redo := get_undo_redo()
	if undo_redo.history_changed.is_connected(_on_editor_history_changed):
		undo_redo.history_changed.disconnect(_on_editor_history_changed)
	if undo_redo.version_changed.is_connected(_on_editor_history_changed):
		undo_redo.version_changed.disconnect(_on_editor_history_changed)
	var inspector := get_editor_interface().get_inspector()
	if inspector.property_edited.is_connected(_on_editor_property_edited):
		inspector.property_edited.disconnect(_on_editor_property_edited)
	var editor_tree := get_tree()
	if editor_tree.node_added.is_connected(_on_editor_node_added):
		editor_tree.node_added.disconnect(_on_editor_node_added)
	if editor_tree.node_removed.is_connected(_on_editor_node_removed):
		editor_tree.node_removed.disconnect(_on_editor_node_removed)
	if editor_tree.node_renamed.is_connected(_on_editor_node_renamed):
		editor_tree.node_renamed.disconnect(_on_editor_node_renamed)


## Shows the dock and schedules discovery only for scenes below res://levels/.
func _on_edited_scene_changed(scene_root: Node) -> void:
	if not is_instance_valid(_editor_dock):
		return
	_trace("Edited scene changed to %s." % _scene_diagnostic_name(scene_root))
	_update_dock_visibility(scene_root)
	_level_settings_loaded = false
	if not _scene_supports_dock(scene_root):
		_resource_refresh_pending = false
		return
	_resource_refresh_pending = true
	call_deferred(&"_try_complete_resource_refresh")


## Opens or closes the registered transient dock to avoid stale saved-layout tabs.
func _update_dock_visibility(scene_root: Node) -> void:
	if not is_instance_valid(_editor_dock):
		return
	var should_open := _scene_supports_dock(scene_root)
	if _dock_visibility_initialized and should_open == _dock_is_open:
		return
	_dock_visibility_initialized = true
	_dock_is_open = should_open
	if should_open:
		_editor_dock.open()
		_trace("Dock opened for %s." % _scene_diagnostic_name(scene_root))
		return
	_editor_dock.close()
	_reset_auto_repair_watch()
	_trace("Dock closed because the edited scene is outside res://levels/<subfolder>/.")


## Limits the level-building dock to saved scenes inside a subfolder of levels.
func _scene_supports_dock(scene_root: Node) -> bool:
	return scene_root != null \
		and ProfileStoreResource.is_scene_in_levels_subfolder(scene_root.scene_file_path)


## Retries queued discovery after the editor finishes a filesystem update.
func _on_editor_filesystem_activity_finished() -> void:
	_trace("Editor filesystem activity finished; refreshing project-backed choices.")
	_resource_refresh_pending = true
	call_deferred(&"_try_complete_resource_refresh")


## Suspends discovery when Godot begins replacing imported resource data.
func _on_editor_resources_reimporting(resources: PackedStringArray) -> void:
	if not is_instance_valid(_dock):
		return
	_trace("Resource reimport started for %s file(s)." % resources.size())
	_resource_refresh_pending = true
	_dock.set_validation_text("Waiting for Godot to finish importing project files...")


## Retries queued discovery after imported resource data becomes available.
func _on_editor_resources_reimported(resources: PackedStringArray) -> void:
	_trace("Resource reimport finished for %s file(s)." % resources.size())
	if ResourceCatalog.resources_include_path(resources, _settings.png_path):
		_image = null
	_resource_refresh_pending = true
	call_deferred(&"_try_complete_resource_refresh")


## Reloads persisted settings and image state when Godot replaces their cached resources.
func _on_editor_resources_reload(resources: PackedStringArray) -> void:
	if ResourceCatalog.resources_include_path(resources, _settings.png_path):
		_image = null
	if _resources_include_current_settings(resources):
		_reload_settings_pending = true
	_resource_refresh_pending = true
	call_deferred(&"_try_complete_resource_refresh")


## Queues a scene-derived UI refresh after any committed editor property change.
func _on_editor_history_changed() -> void:
	_queue_live_scene_refresh()


## Queues immediately after Inspector edits, including edits to external MeshLibraries.
func _on_editor_property_edited(_property: String) -> void:
	_queue_live_scene_refresh()


## Refreshes when a GridMap enters the edited scene.
func _on_editor_node_added(node: Node) -> void:
	if node is GridMap and _node_belongs_to_edited_scene(node):
		_queue_live_scene_refresh()


## Refreshes when a GridMap leaves any edited scene hierarchy.
func _on_editor_node_removed(node: Node) -> void:
	if node is GridMap:
		_queue_live_scene_refresh()


## Refreshes scene-relative GridMap paths when a GridMap or one of its parents is renamed.
func _on_editor_node_renamed(node: Node) -> void:
	if _node_belongs_to_edited_scene(node):
		_queue_live_scene_refresh()


## Coalesces noisy editor callbacks into one current-scene refresh on the next idle turn.
func _queue_live_scene_refresh() -> void:
	if _live_scene_refresh_pending or _resource_refresh_pending:
		return
	var root := get_editor_interface().get_edited_scene_root()
	if not _scene_supports_dock(root):
		return
	_live_scene_refresh_pending = true
	call_deferred(&"_refresh_live_scene_state")


## Rebuilds every control derived from unsaved scene or resource state.
func _refresh_live_scene_state() -> void:
	_live_scene_refresh_pending = false
	if _resource_refresh_pending or not is_instance_valid(_dock):
		return
	var root := get_editor_interface().get_edited_scene_root()
	if not _scene_supports_dock(root):
		return
	_resolve_scene_grid_map_settings()
	_refresh_gridmap_paths()
	_dock.set_mesh_library_paths(_mesh_library_paths)
	_dock.set_floor_material_paths(_floor_material_paths)
	_refresh_available_items()
	_watch_live_resources()
	_update_dock_state()


## Reports whether a changed editor node is inside the scene represented by this dock.
func _node_belongs_to_edited_scene(node: Node) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	return root != null and (node == root or root.is_ancestor_of(node))


## Runs discovery only when an edited scene exists and the project filesystem is idle.
func _try_complete_resource_refresh() -> void:
	# A refresh may already be queued when Godot disables or reloads the plugin.
	if not _resource_refresh_pending \
			or not is_instance_valid(_editor_dock) or not is_instance_valid(_dock):
		return
	var root := get_editor_interface().get_edited_scene_root()
	_update_dock_visibility(root)
	if not _scene_supports_dock(root):
		_trace("Resource refresh skipped: the edited scene is not an eligible level scene.")
		_resource_refresh_pending = false
		return
	if not _editor_filesystem_is_ready():
		var editor_filesystem := get_editor_interface().get_resource_filesystem()
		_trace("Resource refresh paused: filesystem scanning=%s, importing=%s." % [
			editor_filesystem.is_scanning(),
			editor_filesystem.is_importing(),
		])
		_dock.set_validation_text("Waiting for Godot to finish scanning project files...")
		return
	_trace("Edited scene and project filesystem are ready; starting discovery.")
	_resource_refresh_pending = false
	_live_scene_refresh_pending = false
	if _reload_settings_pending:
		_reload_current_settings()
		_reload_settings_pending = false
		_level_settings_loaded = true
	elif not _level_settings_loaded:
		_load_level_settings()
		_level_settings_loaded = true
	_refresh_all(true)


## Refreshes immediately when safe, or queues the request behind an active editor scan.
func _on_refresh_requested() -> void:
	if not _editor_filesystem_is_ready():
		_resource_refresh_pending = true
		_dock.set_validation_text("Waiting for Godot to finish scanning project files...")
		return
	_resource_refresh_pending = false
	_refresh_all(true)


## Reports readiness only while the editor has an indexed and idle project filesystem.
func _editor_filesystem_is_ready() -> bool:
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	return editor_filesystem.get_filesystem() != null \
		and not editor_filesystem.is_scanning() \
		and not editor_filesystem.is_importing()


## Refreshes every project-driven choice and optionally reloads image data from disk.
func _refresh_all(reload_png: bool = false) -> void:
	_resolve_scene_grid_map_settings()
	_trace("Refreshing MeshLibrary catalogue.")
	_refresh_mesh_libraries()
	_trace("Found %s MeshLibrary resource(s)." % _mesh_library_paths.size())
	_trace("Refreshing floor material catalogue.")
	_refresh_floor_materials()
	_trace("Found %s floor material resource(s)." % _floor_material_paths.size())
	_trace("Refreshing edited-scene GridMap paths.")
	_refresh_gridmap_paths()
	_trace("Refreshing MeshLibrary item references.")
	_refresh_available_items()
	_trace("Found %s selectable MeshLibrary item(s)." % _available_item_refs.size())
	var conventional_png := _conventional_level_png_path()
	if reload_png:
		_reload_png_state()
	elif conventional_png != "" and ResourceLoader.exists(conventional_png) \
			and _settings.png_path != conventional_png:
		_load_png(conventional_png, false)
	elif _settings.png_path != "" and _image == null:
		_load_png(_settings.png_path, false)
	else:
		_dock.set_png_state(_settings.png_path, _detected_colours, _colour_order)
	_watch_live_resources()
	_update_dock_state()
	_trace("Resource refresh completed.")


## Selects an unambiguous scene GridMap and uses its library to load the shared tile profile.
func _resolve_scene_grid_map_settings() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	var target_path := ResourceCatalog.preferred_grid_map_path(
		root,
		_settings.target_gridmap_path
	)
	_settings.target_gridmap_path = target_path
	_sync_selected_grid_map_library()


## Uses the selected scene GridMap's current external MeshLibrary and mapping profile.
func _sync_selected_grid_map_library() -> void:
	var grid_map := _selected_gridmap()
	if grid_map == null or grid_map.mesh_library == null:
		return
	var scene_mesh_library_path := grid_map.mesh_library.resource_path
	if scene_mesh_library_path == "" or scene_mesh_library_path == _settings.mesh_library_path:
		return
	_settings.mesh_library_path = scene_mesh_library_path
	_load_profile_for_current_mesh_library()


## Rebuilds the MeshLibrary dropdown from project resources.
func _refresh_mesh_libraries() -> void:
	var editor_filesystem := get_editor_interface().get_resource_filesystem()
	_mesh_library_paths = PNGToGridMapMeshCatalog.find_project_mesh_libraries(editor_filesystem)
	if _settings.mesh_library_path == "" and _mesh_library_paths.size() == 1:
		_settings.mesh_library_path = _mesh_library_paths[0]
		_load_profile_for_current_mesh_library()
	_dock.set_settings(_settings)
	_dock.set_mesh_library_paths(_mesh_library_paths)


## Rebuilds the floor material choices from the globally configured folder.
func _refresh_floor_materials() -> void:
	_floor_material_paths = ResourceCatalog.collect_material_paths(
		get_editor_interface().get_resource_filesystem(),
		_settings.floor_materials_folder
	)
	_dock.set_floor_material_paths(_floor_material_paths)


## Rebuilds the GridMap dropdown from the currently edited scene.
func _refresh_gridmap_paths() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	_dock.set_gridmap_paths(ResourceCatalog.collect_grid_map_paths(root))


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


## Reconnects change notifications whenever profile loading replaces a watched resource.
func _watch_live_resources() -> void:
	if _watched_settings != _settings:
		if _watched_settings != null \
				and _watched_settings.changed.is_connected(_on_live_resource_changed):
			_watched_settings.changed.disconnect(_on_live_resource_changed)
		_watched_settings = _settings
		if _watched_settings != null \
				and not _watched_settings.changed.is_connected(_on_live_resource_changed):
			_watched_settings.changed.connect(_on_live_resource_changed)
	var active := _active_mesh_library()
	var active_library := active.get("library") as MeshLibrary
	if _watched_mesh_library == active_library:
		return
	if _watched_mesh_library != null \
			and _watched_mesh_library.changed.is_connected(_on_live_resource_changed):
		_watched_mesh_library.changed.disconnect(_on_live_resource_changed)
	_watched_mesh_library = active_library
	if _watched_mesh_library != null \
			and not _watched_mesh_library.changed.is_connected(_on_live_resource_changed):
		_watched_mesh_library.changed.connect(_on_live_resource_changed)


## Stops resource callbacks before the plugin and editor-owned resources are released.
func _disconnect_live_resource_signals() -> void:
	if _watched_settings != null \
			and _watched_settings.changed.is_connected(_on_live_resource_changed):
		_watched_settings.changed.disconnect(_on_live_resource_changed)
	if _watched_mesh_library != null \
			and _watched_mesh_library.changed.is_connected(_on_live_resource_changed):
		_watched_mesh_library.changed.disconnect(_on_live_resource_changed)
	_watched_settings = null
	_watched_mesh_library = null


## Rebuilds resource-derived controls after a watched settings file or MeshLibrary changes.
func _on_live_resource_changed() -> void:
	_queue_live_scene_refresh()


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
		undo_redo.add_do_method(
			grid_map,
			&"set_cell_item",
			change["cell"],
			int(change["item_id"]),
			int(change["orientation"])
		)
		undo_redo.add_undo_method(
			grid_map,
			&"set_cell_item",
			change["cell"],
			int(change["previous_item_id"]),
			int(change["previous_orientation"])
		)
	undo_redo.commit_action()
	get_editor_interface().edit_node(grid_map)
	get_editor_interface().mark_scene_as_unsaved()
	_save_profile()
	var message := "Repaired %s autotile cells in %s.\n%s" % [
		changes.size(),
		grid_map.name,
		_repair_result_summary(result),
	]
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
	_watch_live_resources()
	_update_dock_state()


## Records the scene GridMap target chosen in the dock.
func _on_gridmap_selected(path: String) -> void:
	_settings.target_gridmap_path = NodePath(path)
	_sync_selected_grid_map_library()
	_dock.set_mesh_library_paths(_mesh_library_paths)
	_refresh_available_items()
	_watch_live_resources()
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
	_auto_repair_watch.reset()


## Saves mapping changes and updates validation with current assignments.
func _on_mapping_changed() -> void:
	_save_profile()
	_update_dock_state()


## Loads a PNG image and rebuilds colour mappings from its palette.
func _load_png(path: String, save_profile: bool) -> void:
	var localized_path := PathsResource.localize_project_path(path)
	_trace("Loading PNG resource: %s." % localized_path)
	var texture := ResourceLoader.load(localized_path) as Texture2D
	if texture == null:
		_trace("PNG load failed: the resource did not produce a Texture2D.")
		_clear_png_state(localized_path)
		_update_dock_state("Could not load PNG: %s." % localized_path)
		return

	var image := texture.get_image()
	if image == null:
		_trace("PNG load failed: the Texture2D did not provide image data.")
		_clear_png_state(localized_path)
		_update_dock_state("Could not read image data from PNG: %s." % localized_path)
		return
	_image = image
	_settings.png_path = localized_path
	_scan_colours()
	_trace("PNG loaded at %sx%s with %s mapped colour(s)." % [
		_image.get_width(),
		_image.get_height(),
		_colour_order.size(),
	])
	_dock.set_settings(_settings)
	_dock.set_png_state(localized_path, _detected_colours, _colour_order)
	if save_profile:
		_save_profile()
	_update_dock_state()


## Reloads the current level image, preferring the conventional level.png when present.
func _reload_png_state() -> void:
	var conventional_png := _conventional_level_png_path()
	if conventional_png != "" and ResourceLoader.exists(conventional_png):
		_load_png(conventional_png, false)
		return
	if _settings.png_path != "" and ResourceLoader.exists(_settings.png_path):
		_load_png(_settings.png_path, false)
		return
	_clear_png_state(_settings.png_path)


## Clears cached image-derived UI while preserving the missing configured path for diagnosis.
func _clear_png_state(path: String) -> void:
	_image = null
	_detected_colours.clear()
	_colour_order.clear()
	_settings.png_path = path
	_dock.set_png_state(path, _detected_colours, _colour_order, path == "")


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
	var result := _importer.run(
		_settings,
		_image,
		root,
		_selected_gridmap(),
		active["library"],
		active["ref_to_id"],
		_available_item_ref_aliases,
		EMPTY_KEY
	)
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
	var result := _exporter.run(
		_settings,
		_selected_gridmap(),
		normalized_path,
		_available_item_ref_aliases,
		_available_item_display_names
	)
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
	var empty_colour := Color.from_string("#" + EMPTY_KEY, Color.WHITE)
	var configured_colours := MappingCatalog.configured_colours(
		_settings,
		[empty_colour] as Array[Color]
	)
	var scan := PNGToGridMapImageGrid.scan_image_colours(
		_image,
		true,
		configured_colours,
		_settings.colour_match_tolerance
	)
	_detected_colours = scan["data"]
	_colour_order.clear()
	_colour_order.assign(scan["order"])
	_detected_colours.erase(EMPTY_KEY)
	_colour_order.erase(EMPTY_KEY)
	for key in _colour_order:
		MappingCatalog.ensure_detected_mapping(
			_settings,
			key,
			_detected_colours[key]["colour"] as Color
		)

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


## Reloads both level-specific and shared MeshLibrary settings after an external resource edit.
func _reload_current_settings() -> void:
	_load_level_settings()
	_settings = _profile_store.load_for_mesh_library(_settings)
	if _image != null:
		_scan_colours()


## Reports whether a reload batch contains either settings resource represented by the dock.
func _resources_include_current_settings(resources: PackedStringArray) -> bool:
	var root := get_editor_interface().get_edited_scene_root()
	var scene_path := root.scene_file_path if root != null else ""
	var level_settings_path := _profile_store.path_for_scene(scene_path)
	var shared_settings_path := _profile_store.path_for_mesh_library(_settings.mesh_library_path)
	return ResourceCatalog.resources_include_path(resources, level_settings_path) \
		or ResourceCatalog.resources_include_path(resources, shared_settings_path)


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


## Prints low-noise lifecycle detail only when Godot is launched with --verbose.
func _trace(message: String) -> void:
	print_verbose("%s %s" % [DIAGNOSTIC_PREFIX, message])


## Names an edited scene safely for startup diagnostics.
func _scene_diagnostic_name(scene_root: Node) -> String:
	if scene_root == null:
		return "<none>"
	return scene_root.scene_file_path if scene_root.scene_file_path != "" \
		else "%s (unsaved)" % scene_root.name


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
