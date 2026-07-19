@tool
extends EditorPlugin

const SelectedPath3DGizmoPlugin := preload("res://addons/path3d_selected_gizmo/path3d_selected_gizmo_plugin.gd")
const UPDATE_INTERVAL_SECONDS := 0.1
const PATH_POINT_SELECTION_RADIUS_PIXELS := 18.0

var _gizmo_plugin: EditorNode3DGizmoPlugin
var _previous_selected_paths: Array[Path3D] = []
var _update_elapsed := 0.0


## Registers the selected Path3D visibility gizmo while this addon is enabled.
func _enter_tree() -> void:
	set_input_event_forwarding_always_enabled()
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


## Previews the animation time associated with a clicked point on supported paths.
func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> EditorPlugin.AfterGUIInput:
	var mouse_event := event as InputEventMouseButton
	if (
		mouse_event == null
		or mouse_event.button_index != MOUSE_BUTTON_LEFT
		or not mouse_event.pressed
	):
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	var selected_point := _closest_clicked_path_point(camera, mouse_event.position)
	if selected_point.is_empty():
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	var path := selected_point.get("path") as Path3D
	var point_index := int(selected_point.get("point_index", -1))
	if path == null or point_index < 0:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if path.has_method("preview_path_point_in_animation"):
		var point_time := float(path.call("preview_path_point_in_animation", point_index))
		if point_time >= 0.0:
			_center_animation_timeline.call_deferred(point_time)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


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


func _closest_clicked_path_point(camera: Camera3D, screen_position: Vector2) -> Dictionary:
	var closest: Dictionary = {}
	var closest_screen_distance := PATH_POINT_SELECTION_RADIUS_PIXELS
	for path in _selected_paths():
		if path.curve == null or not path.has_method("preview_path_point_in_animation"):
			continue
		for point_index in path.curve.point_count:
			var global_position := path.to_global(path.curve.get_point_position(point_index))
			if camera.is_position_behind(global_position):
				continue
			var point_screen_position := camera.unproject_position(global_position)
			var screen_distance := screen_position.distance_to(point_screen_position)
			if screen_distance <= closest_screen_distance:
				closest_screen_distance = screen_distance
				closest = {
					"path": path,
					"point_index": point_index,
				}
	return closest


func _center_animation_timeline(point_time: float) -> void:
	var timeline := _find_animation_timeline(get_editor_interface().get_base_control())
	if timeline == null:
		return

	var centered_offset := point_time - timeline.page * 0.5
	var maximum_offset := maxf(timeline.max_value - timeline.page, timeline.min_value)
	timeline.value = clampf(centered_offset, timeline.min_value, maximum_offset)


func _find_animation_timeline(node: Node) -> Range:
	if node is Range and node.get_class() == "AnimationTimelineEdit":
		return node as Range
	for child in node.get_children():
		var timeline := _find_animation_timeline(child)
		if timeline != null:
			return timeline
	return null


func _update_path_gizmos(paths: Array[Path3D]) -> void:
	for path in paths:
		if path != null and path.has_method("update_gizmos"):
			path.update_gizmos()
