@tool
extends EditorPlugin

## Coordinates editor selection, viewport gestures, previews, persistence and undo history.

const FLOOR_SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const SHAPE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)
const DOCK_SCRIPT := preload("res://addons/floor_surface/editor/floor_surface_dock.gd")
const DOCK_SCENE := preload("res://addons/floor_surface/editor/floor_surface_dock.tscn")
const APPLY_SNAPSHOT_METHOD := &"apply_shape_snapshot"
const FLOOR_MAP_PROPERTY := &"floor_map"

var _dock: DOCK_SCRIPT
var _target: FLOOR_SURFACE_SCRIPT
var _painter := SHAPE_PAINTER.new()
var _rectangle_start := Vector2i.ZERO
var _last_brush_cell := Vector2i.ZERO
var _pointer_cell := Vector2i.ZERO
var _pointer_valid := false
var _preview_cells: Array[Vector2i] = []
var _preview_mesh: MeshInstance3D
var _preview_box: BoxMesh
var _preview_material: StandardMaterial3D
var _selection_hidden_for_paint := false


## Adds the contextual dock and enables 3D viewport input forwarding.
func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate() as DOCK_SCRIPT
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)
	_dock.setup()
	_dock.editing_toggled.connect(_on_editing_toggled)
	_dock.paint_mode_changed.connect(_on_tool_setting_changed)
	_dock.shape_mode_changed.connect(_on_tool_setting_changed)
	_dock.brush_size_changed.connect(_on_tool_setting_changed)
	_dock.make_unique_requested.connect(_on_make_unique_requested)
	_dock.save_requested.connect(_on_save_requested)
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	set_input_event_forwarding_always_enabled()
	_on_selection_changed()


## Removes all transient editor state without touching saved scene nodes.
func _exit_tree() -> void:
	_cancel_active_edit(false)
	_restore_target_selection()
	_remove_preview()
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	_dock = null
	_target = null


## Advertises the FloorSurface node type to the editor selection system.
func _handles(object: Object) -> bool:
	return object is FloorSurface


## Routes only armed left-button painting and Escape cancellation away from viewport navigation.
func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not _can_paint():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and _painter.is_active():
			_cancel_active_edit(true)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_update_pointer(viewport_camera, motion_event.position)
		if _painter.is_active() \
				and _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Brush \
				and (motion_event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_apply_brush_segment()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return EditorPlugin.AFTER_GUI_INPUT_PASS
		_update_pointer(viewport_camera, button_event.position)
		if button_event.pressed:
			return _begin_gesture()
		return _finish_gesture()
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _on_selection_changed() -> void:
	var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.is_empty() and _selection_hidden_for_paint:
		return
	_selection_hidden_for_paint = false
	var selected_surface: FLOOR_SURFACE_SCRIPT
	for selected_node in selected_nodes:
		selected_surface = _find_surface_ancestor(selected_node as Node)
		if selected_surface != null:
			break
	_set_target(selected_surface)


func _find_surface_ancestor(node: Node) -> FLOOR_SURFACE_SCRIPT:
	var candidate := node
	while candidate != null:
		if candidate is FloorSurface:
			return candidate as FLOOR_SURFACE_SCRIPT
		candidate = candidate.get_parent()
	return null


func _set_target(surface: FLOOR_SURFACE_SCRIPT) -> void:
	if surface == _target:
		_refresh_dock_target()
		return
	_cancel_active_edit(false)
	_remove_preview()
	_target = surface
	_pointer_valid = false
	if _target != null:
		_create_preview()
	_refresh_dock_target()


func _refresh_dock_target() -> void:
	if not is_instance_valid(_dock):
		return
	_dock.set_target(_target, _target.floor_map if _target != null else null)
	if _target == null:
		_dock.set_status("Select a FloorSurface to begin.")


func _on_editing_toggled(enabled: bool) -> void:
	if not enabled:
		_cancel_active_edit(false)
		_pointer_valid = false
		_preview_cells.clear()
		_update_preview()
		_restore_target_selection()
		_dock.set_status("Viewport painting disabled; selection clicks are available.")
		return
	_hide_target_selection()
	_dock.set_status(
		"Viewport painting enabled; the transform gizmo is hidden. Left-drag to edit."
	)


func _on_tool_setting_changed(_value: int) -> void:
	_cancel_active_edit(false)
	_update_preview_footprint()


func _update_pointer(viewport_camera: Camera3D, pointer_position: Vector2) -> void:
	var ray_origin := viewport_camera.project_ray_origin(pointer_position)
	var ray_direction := viewport_camera.project_ray_normal(pointer_position)
	var intersection: Variant = SHAPE_PAINTER.working_plane_intersection(
		ray_origin,
		ray_direction,
		_working_world_height()
	)
	if intersection == null:
		_pointer_valid = false
		_preview_cells.clear()
		_dock.clear_hover()
		_update_preview()
		return
	_pointer_valid = true
	_pointer_cell = _target.world_to_cell(intersection as Vector3)
	_update_preview_footprint()


func _update_preview_footprint() -> void:
	if not _can_paint() or not _pointer_valid:
		_preview_cells.clear()
		_update_preview()
		return
	if _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Rectangle:
		if _painter.is_active():
			_preview_cells = SHAPE_PAINTER.rectangle_footprint(
				_rectangle_start,
				_pointer_cell,
				_target.floor_map,
				_should_clip_to_bounds()
			)
		else:
			_preview_cells = SHAPE_PAINTER.brush_footprint(
				_pointer_cell,
				1,
				_target.floor_map,
				_should_clip_to_bounds()
			)
	else:
		_preview_cells = SHAPE_PAINTER.brush_footprint(
			_pointer_cell,
			_dock.get_brush_size(),
			_target.floor_map,
			_should_clip_to_bounds()
		)
	if _preview_cells.is_empty():
		_dock.clear_hover()
	else:
		_dock.set_hover(_pointer_cell, _preview_cells.size())
	_update_preview()


func _begin_gesture() -> int:
	if _preview_cells.is_empty() or not _painter.begin(
		_target.floor_map,
		_dock.get_paint_mode() as SHAPE_PAINTER.PaintMode
	):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	_rectangle_start = _pointer_cell
	_last_brush_cell = _pointer_cell
	if _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Brush:
		_painter.apply_cells(_preview_cells)
	else:
		_update_preview_footprint()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _apply_brush_segment() -> void:
	for brush_centre in SHAPE_PAINTER.stroke_centres(_last_brush_cell, _pointer_cell):
		_painter.apply_cells(SHAPE_PAINTER.brush_footprint(
			brush_centre,
			_dock.get_brush_size(),
			_target.floor_map,
			_should_clip_to_bounds()
		))
	_last_brush_cell = _pointer_cell


func _finish_gesture() -> int:
	if not _painter.is_active():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Rectangle:
		_painter.apply_cells(_preview_cells)
	var edit := _painter.finish()
	var before := edit.get("before", {}) as Dictionary
	var after := edit.get("after", {}) as Dictionary
	var touched_count := edit.get("touched_count", 0) as int
	if before != after:
		var action_name := _gesture_action_name()
		var undo_redo := get_undo_redo()
		undo_redo.create_action(action_name)
		undo_redo.add_do_method(_target.floor_map, APPLY_SNAPSHOT_METHOD, after)
		undo_redo.add_undo_method(_target.floor_map, APPLY_SNAPSHOT_METHOD, before)
		# The live gesture already applied the final state; register it without executing twice.
		undo_redo.commit_action(false)
		_dock.set_status("%s: %d cell%s. Save Map when ready." % [
			action_name,
			touched_count,
			"" if touched_count == 1 else "s",
		])
	else:
		_dock.set_status("Gesture made no occupancy change.")
	_update_preview_footprint()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _gesture_action_name() -> String:
	var operation := (
		"Paint Floor"
		if _dock.get_paint_mode() == SHAPE_PAINTER.PaintMode.Paint
		else "Erase Floor"
	)
	return "%s Rectangle" % operation \
		if _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Rectangle \
		else "%s Stroke" % operation


func _should_clip_to_bounds() -> bool:
	return _dock.get_paint_mode() == SHAPE_PAINTER.PaintMode.Erase


func _hide_target_selection() -> void:
	if _target == null:
		return
	_selection_hidden_for_paint = true
	get_editor_interface().get_selection().clear()


func _restore_target_selection() -> void:
	if not _selection_hidden_for_paint:
		return
	_selection_hidden_for_paint = false
	var selection := get_editor_interface().get_selection()
	selection.clear()
	if is_instance_valid(_target):
		selection.add_node(_target)


func _cancel_active_edit(show_status: bool) -> void:
	if not _painter.cancel():
		return
	if show_status and is_instance_valid(_dock):
		_dock.set_status("Gesture cancelled; the map was restored.")
	_update_preview_footprint()


func _on_make_unique_requested() -> void:
	if _target == null or _target.floor_map == null:
		return
	_cancel_active_edit(false)
	var shared_map := _target.floor_map
	var unique_map := shared_map.create_unique_copy() as FLOOR_MAP_SCRIPT
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Make FloorMap Unique")
	undo_redo.add_do_property(_target, FLOOR_MAP_PROPERTY, unique_map)
	undo_redo.add_undo_property(_target, FLOOR_MAP_PROPERTY, shared_map)
	undo_redo.commit_action()
	_refresh_dock_target()
	_dock.set_status("Independent copy created for this scene. Save the scene to retain it.")


func _on_save_requested() -> void:
	if _target == null or _target.floor_map == null:
		return
	var floor_map := _target.floor_map
	if floor_map.resource_local_to_scene or floor_map.resource_path.is_empty():
		get_editor_interface().save_scene()
		_dock.set_status("Scene saved with its unique FloorMap.")
		return
	var save_error := ResourceSaver.save(floor_map, floor_map.resource_path)
	if save_error == OK:
		_dock.set_status("Saved shared FloorMap: %s" % floor_map.resource_path)
	else:
		_dock.set_status("Could not save FloorMap (error %d)." % save_error)


func _working_world_height() -> float:
	if _target == null or _target.floor_map == null or _target.elevation_profile == null:
		return 0.0
	return _target.elevation_profile.elevation_to_world(_target.floor_map.default_elevation)


func _can_paint() -> bool:
	return is_instance_valid(_dock) \
		and is_instance_valid(_target) \
		and _target.floor_map != null \
		and _dock.is_editing_enabled()


func _create_preview() -> void:
	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "_FloorSurfacePaintPreview"
	_preview_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_preview_box = BoxMesh.new()
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_material.no_depth_test = true
	_preview_box.material = _preview_material
	_preview_mesh.mesh = _preview_box
	_preview_mesh.visible = false
	_target.add_child(_preview_mesh)
	_preview_mesh.owner = null


func _remove_preview() -> void:
	if is_instance_valid(_preview_mesh):
		_preview_mesh.free()
	_preview_mesh = null
	_preview_box = null
	_preview_material = null


func _update_preview() -> void:
	if not is_instance_valid(_preview_mesh) or _preview_cells.is_empty() or not _can_paint():
		if is_instance_valid(_preview_mesh):
			_preview_mesh.visible = false
		return
	var minimum := _preview_cells[0]
	var maximum := _preview_cells[0]
	for cell in _preview_cells:
		minimum.x = mini(minimum.x, cell.x)
		minimum.y = mini(minimum.y, cell.y)
		maximum.x = maxi(maximum.x, cell.x)
		maximum.y = maxi(maximum.y, cell.y)
	var width := maximum.x - minimum.x + 1
	var depth := maximum.y - minimum.y + 1
	_preview_box.size = Vector3(
		float(width) * _target.cell_size,
		0.04,
		float(depth) * _target.cell_size
	)
	_preview_mesh.position = Vector3(
		_target.world_origin_xz.x + (float(minimum.x) + float(width) * 0.5) * _target.cell_size,
		_working_world_height() + 0.04,
		_target.world_origin_xz.y + (float(minimum.y) + float(depth) * 0.5) * _target.cell_size
	)
	_preview_material.albedo_color = (
		Color(0.2, 0.95, 0.45, 0.38)
		if _dock.get_paint_mode() == SHAPE_PAINTER.PaintMode.Paint
		else Color(1.0, 0.2, 0.25, 0.38)
	)
	_preview_mesh.visible = true
