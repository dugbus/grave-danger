@tool
class_name PNGToGridMapProfileStore
extends RefCounted

## Loads and saves reusable PNG-to-GridMap mapping profiles and lightweight editor preferences.
## Profiles are associated with their source assets so repeat imports use consistent intent.

const SETTINGS_DIR := "res://addons/png_to_gridmap/settings"
const UI_STATE_SECTION := "png_to_gridmap"
const UI_STATE_ADVANCED_VISIBLE := "advanced_visible"
const UI_STATE_OPERATION_ID := "operation_id"
const LEVELS_ROOT := "res://levels"
const LEVEL_SETTINGS_FILE := "png_to_gridmap_settings.tres"
const GLOBAL_PROPERTIES := [&"mesh_library_path", &"color_mappings", &"floor_materials_folder"]
const LEVEL_PROPERTIES := [
	&"png_path",
	&"export_png_path",
	&"target_gridmap_path",
	&"gridmap_name",
	&"cell_size",
	&"auto_repair",
	&"export_origin",
	&"export_size",
	&"floor_gridmap_path",
	&"floor_material_path",
]

var _editor_interface: EditorInterface
var _settings_script: Script


## Stores editor and resource dependencies needed for profile persistence.
func _init(editor_interface: EditorInterface, settings_script: Script) -> void:
	_editor_interface = editor_interface
	_settings_script = settings_script


## Loads one UI-state value from Godot editor project metadata.
func get_ui_state(key: String, default_value: Variant) -> Variant:
	return _editor_interface.get_editor_settings().get_project_metadata(UI_STATE_SECTION, key, default_value)


## Saves one UI-state value to Godot editor project metadata.
func set_ui_state(key: String, value: Variant) -> void:
	_editor_interface.get_editor_settings().set_project_metadata(UI_STATE_SECTION, key, value)


## Loads all persisted dock UI state values at once.
func load_ui_state(default_operation: int) -> Dictionary:
	return {
		"operation_id": int(get_ui_state(UI_STATE_OPERATION_ID, default_operation)),
		"advanced_visible": bool(get_ui_state(UI_STATE_ADVANCED_VISIBLE, false)),
	}


## Saves all dock UI state values at once.
func save_ui_state(operation_id: int, advanced_visible: bool) -> void:
	set_ui_state(UI_STATE_OPERATION_ID, operation_id)
	set_ui_state(UI_STATE_ADVANCED_VISIBLE, advanced_visible)


## Computes the automatic mapping profile path for a MeshLibrary.
func path_for_mesh_library(mesh_library_path: String) -> String:
	if mesh_library_path == "":
		return ""
	var key := mesh_library_path.trim_prefix("res://").get_basename().replace("/", "__").replace("\\", "__")
	return SETTINGS_DIR.path_join("%s_png_to_gridmap.tres" % key)


## Loads the automatic mapping profile for a selected MeshLibrary.
func load_for_mesh_library(current_settings: Resource) -> Resource:
	if current_settings.mesh_library_path == "":
		return current_settings
	var path := path_for_mesh_library(current_settings.mesh_library_path)
	if path == "":
		return current_settings
	if not ResourceLoader.exists(path):
		return current_settings
	var loaded := ResourceLoader.load(path)
	if loaded == null or loaded.get_script() != _settings_script:
		return current_settings
	_copy_properties(current_settings, loaded, LEVEL_PROPERTIES)
	return loaded


## Loads level-specific conversion state stored beside the edited scene.
func load_for_scene(current_settings: Resource, scene_path: String) -> Resource:
	var path := path_for_scene(scene_path)
	if path == "" or not ResourceLoader.exists(path):
		return current_settings
	var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or loaded.get_script() != _settings_script:
		return current_settings
	_copy_properties(current_settings, loaded, GLOBAL_PROPERTIES)
	return loaded


## Saves mapping and scene settings only while editing a scene below res://levels/.
func save(settings: Resource, scene_path: String) -> Error:
	var level_settings_path := path_for_scene(scene_path)
	if level_settings_path == "":
		return ERR_INVALID_PARAMETER
	if settings.mesh_library_path == "":
		return ERR_UNCONFIGURED
	_ensure_settings_dir()
	var path := path_for_mesh_library(settings.mesh_library_path)
	if path == "":
		return ERR_UNCONFIGURED
	var global_settings := _settings_script.new() as Resource
	_copy_properties(settings, global_settings, GLOBAL_PROPERTIES)
	var result := ResourceSaver.save(global_settings, path)
	if result != OK:
		return result
	var level_settings := _settings_script.new() as Resource
	_copy_properties(settings, level_settings, LEVEL_PROPERTIES)
	return ResourceSaver.save(level_settings, level_settings_path)


## Returns a settings path only for scenes inside a subfolder of res://levels/.
func path_for_scene(scene_path: String) -> String:
	if not is_scene_in_levels_subfolder(scene_path):
		return ""
	var normalized_path := scene_path.replace("\\", "/").simplify_path()
	return normalized_path.get_base_dir().path_join(LEVEL_SETTINGS_FILE)


## Reports whether a scene is inside a level-specific folder.
static func is_scene_in_levels_subfolder(scene_path: String) -> bool:
	if scene_path == "":
		return false
	var normalized_path := scene_path.replace("\\", "/").simplify_path()
	var scene_directory := normalized_path.get_base_dir()
	return scene_directory.begins_with(LEVELS_ROOT + "/")


## Copies a selected persistence partition between settings resources.
func _copy_properties(source: Resource, destination: Resource, properties: Array) -> void:
	for property_name: StringName in properties:
		destination.set(property_name, source.get(property_name))


## Ensures the automatic profile directory exists before saving.
func _ensure_settings_dir() -> void:
	if DirAccess.dir_exists_absolute(SETTINGS_DIR):
		return
	DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)
