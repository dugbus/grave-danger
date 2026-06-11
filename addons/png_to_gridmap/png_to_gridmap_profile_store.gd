@tool
class_name PNGToGridMapProfileStore
extends RefCounted

const SETTINGS_DIR := "res://addons/png_to_gridmap/settings"
const UI_STATE_SECTION := "png_to_gridmap"
const UI_STATE_ADVANCED_VISIBLE := "advanced_visible"
const UI_STATE_OPERATION_ID := "operation_id"

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
	var mesh_library_path: String = current_settings.mesh_library_path
	var png_path: String = current_settings.png_path
	var export_png_path: String = current_settings.export_png_path
	var target_gridmap_path: NodePath = current_settings.target_gridmap_path
	loaded.mesh_library_path = mesh_library_path
	if png_path != "":
		loaded.png_path = png_path
	if export_png_path != "":
		loaded.export_png_path = export_png_path
	if String(target_gridmap_path) != "":
		loaded.target_gridmap_path = target_gridmap_path
	return loaded


## Saves the automatic mapping profile for the selected MeshLibrary.
func save(settings: Resource) -> Error:
	if settings.mesh_library_path == "":
		return ERR_UNCONFIGURED
	_ensure_settings_dir()
	var path := path_for_mesh_library(settings.mesh_library_path)
	if path == "":
		return ERR_UNCONFIGURED
	var result := ResourceSaver.save(settings, path)
	return result


## Ensures the automatic profile directory exists before saving.
func _ensure_settings_dir() -> void:
	if DirAccess.dir_exists_absolute(SETTINGS_DIR):
		return
	DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)
