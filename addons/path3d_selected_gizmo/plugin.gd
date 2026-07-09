@tool
extends EditorPlugin

const SelectedPath3DGizmoPlugin := preload("res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd")
const UPDATE_INTERVAL_SECONDS := 0.1

var _gizmo_plugin: EditorNode3DGizmoPlugin
var _previous_selected_paths: Array[Path3D] = []
var _update_elapsed := 0.0


## Registers the selected Path3D visibility gizmo while this addon is enabled.
func _enter_tree() -> void:
    _gizmo_plugin = SelectedPath3DGizmoPlugin.new(get_editor_interface())
    add_node_3d_gizmo_plugin(_gizmo_plugin)
    get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
    _previous_selected_paths = _selected_paths()
    set_process(true)


## Removes the selected Path3D visibility gizmo while this addon is disabled.
func _exit_tree() -> void:
    var selection := get_editor_interface().get_selection()
    if selection.selection_changed.is_connected(_on_selection_changed):
        selection.selection_changed.disconnect(_on_selection_changed)

    if _gizmo_plugin != null:
        remove_node_3d_gizmo_plugin(_gizmo_plugin)
        _gizmo_plugin = null

    _update_path_gizmos(_previous_selected_paths)
    _previous_selected_paths = []
    set_process(false)


func _process(delta: float) -> void:
    if _previous_selected_paths.is_empty():
        return

    _update_elapsed += delta
    if _update_elapsed < UPDATE_INTERVAL_SECONDS:
        return

    _update_elapsed = 0.0
    _update_path_gizmos(_previous_selected_paths)


func _on_selection_changed() -> void:
    var current_selected_paths := _selected_paths()
    _update_path_gizmos(_previous_selected_paths)
    _update_path_gizmos(current_selected_paths)
    _previous_selected_paths = current_selected_paths


func _selected_paths() -> Array[Path3D]:
    var paths: Array[Path3D] = []
    for node in get_editor_interface().get_selection().get_selected_nodes():
        if node is Path3D:
            paths.append(node as Path3D)
    return paths


func _update_path_gizmos(paths: Array[Path3D]) -> void:
    for path in paths:
        if path != null and path.has_method("update_gizmos"):
            path.update_gizmos()
