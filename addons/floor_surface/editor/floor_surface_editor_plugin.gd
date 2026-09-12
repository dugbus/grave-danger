@tool
extends EditorPlugin

## Coordinates editor selection, viewport gestures, previews, persistence and undo history.

const FLOOR_SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const SHAPE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)
const ELEVATION_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_elevation_painter.gd"
)
const STYLE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_style_painter.gd"
)
const TRANSITION_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_transition_painter.gd"
)
const FLOOD_FILL := preload(
	"res://addons/floor_surface/editor/floor_surface_flood_fill.gd"
)
const EDITOR_VISUALS := preload(
	"res://addons/floor_surface/editor/floor_surface_editor_visuals.gd"
)
const SURFACE_PICKER := preload(
	"res://addons/floor_surface/editor/floor_surface_picker.gd"
)
const DOCK_SCRIPT := preload("res://addons/floor_surface/editor/floor_surface_dock.gd")
const DOCK_SCENE := preload("res://addons/floor_surface/editor/floor_surface_dock.tscn")
const GROUNDING_EDITOR := preload(
	"res://addons/floor_surface/editor/floor_surface_grounding_editor.gd"
)
const GROUNDING_SCRIPT := preload("res://addons/floor_surface/floor_surface_grounding.gd")
const VALIDATION := preload(
	"res://addons/floor_surface/editor/floor_surface_validation.gd"
)
const APPLY_SNAPSHOT_METHOD := &"apply_shape_snapshot"
const APPLY_ELEVATION_SNAPSHOT_METHOD := &"apply_elevation_snapshot"
const APPLY_STYLE_SNAPSHOT_METHOD := &"apply_style_snapshot"
const APPLY_TRANSITION_SNAPSHOT_METHOD := &"apply_transition_snapshot"
const FLOOR_MAP_PROPERTY := &"floor_map"

var _dock: DOCK_SCRIPT
var _target: FLOOR_SURFACE_SCRIPT
var _painter := SHAPE_PAINTER.new()
var _elevation_painter := ELEVATION_PAINTER.new()
var _style_painter := STYLE_PAINTER.new()
var _transition_painter := TRANSITION_PAINTER.new()
var _rectangle_start := Vector2i.ZERO
var _last_brush_cell := Vector2i.ZERO
var _pointer_cell := Vector2i.ZERO
var _pointer_valid := false
var _preview_cells: Array[Vector2i] = []
var _visuals := EDITOR_VISUALS.new()
var _selection_hidden_for_paint := false


## Adds the contextual dock and enables 3D viewport input forwarding.
func _enter_tree() -> void:
	_dock = DOCK_SCENE.instantiate() as DOCK_SCRIPT
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, _dock)
	_dock.setup()
	_dock.editing_toggled.connect(_on_editing_toggled)
	_dock.grid_overlay_toggled.connect(_on_grid_overlay_toggled)
	_dock.edit_mode_changed.connect(_on_tool_setting_changed)
	_dock.paint_mode_changed.connect(_on_tool_setting_changed)
	_dock.elevation_operation_changed.connect(_on_tool_setting_changed)
	_dock.absolute_elevation_changed.connect(_on_tool_setting_changed)
	_dock.style_operation_changed.connect(_on_tool_setting_changed)
	_dock.style_index_changed.connect(_on_tool_setting_changed)
	_dock.transition_operation_changed.connect(_on_tool_setting_changed)
	_dock.shape_mode_changed.connect(_on_tool_setting_changed)
	_dock.brush_size_changed.connect(_on_tool_setting_changed)
	_dock.make_unique_requested.connect(_on_make_unique_requested)
	_dock.save_requested.connect(_on_save_requested)
	_dock.conform_grounded_requested.connect(_on_conform_grounded_requested)
	_dock.validate_requested.connect(_on_validate_requested)
	_dock.repair_requested.connect(_on_repair_requested)
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	set_input_event_forwarding_always_enabled()
	_on_selection_changed()


## Removes all transient editor state without touching saved scene nodes.
func _exit_tree() -> void:
	_cancel_active_edit(false)
	_restore_target_selection()
	_disconnect_target_surface()
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
		if key_event.pressed and key_event.keycode == KEY_ESCAPE and _is_gesture_active():
			_cancel_active_edit(true)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_update_pointer(viewport_camera, motion_event.position)
		if _should_capture_active_drag(_is_gesture_active()):
			if _dock.get_edit_mode() != DOCK_SCRIPT.EditMode.Transition \
					and _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Brush:
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


## Keeps every motion event in an active paint gesture away from 3D viewport navigation.
static func _should_capture_active_drag(active: bool) -> bool:
	return active


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
	_disconnect_target_surface()
	_remove_preview()
	_target = surface
	_pointer_valid = false
	if _target != null:
		_create_preview()
		_connect_target_surface()
	_refresh_dock_target()


func _refresh_dock_target() -> void:
	if not is_instance_valid(_dock):
		return
	var available_styles: Array[STYLE_SCRIPT] = []
	if _target != null:
		available_styles = _target.styles
	_dock.set_styles(available_styles)
	_dock.set_target(_target, _target.floor_map if _target != null else null)
	if _target != null and _target.elevation_profile != null:
		_dock.set_elevation_unit(_target.elevation_profile.elevation_unit)
	if _target == null:
		_dock.set_status("Select a FloorSurface to begin.")
	_update_grid_overlay()


func _on_editing_toggled(enabled: bool) -> void:
	if not enabled:
		_cancel_active_edit(false)
		_pointer_valid = false
		_preview_cells.clear()
		_update_preview()
		_update_elevation_overlay()
		_restore_target_selection()
		_dock.set_status("Viewport painting disabled; selection clicks are available.")
		return
	_hide_target_selection()
	_update_elevation_overlay()
	_dock.set_status(
		"Viewport painting enabled; the transform gizmo is hidden. Left-drag to edit."
	)


func _on_tool_setting_changed(_value: int) -> void:
	_cancel_active_edit(false)
	_update_preview_footprint()
	_update_elevation_overlay()
	_update_grid_overlay()


func _on_grid_overlay_toggled(_visible: bool) -> void:
	_update_grid_overlay()


func _update_pointer(viewport_camera: Camera3D, pointer_position: Vector2) -> void:
	var ray_origin := viewport_camera.project_ray_origin(pointer_position)
	var ray_direction := viewport_camera.project_ray_normal(pointer_position)
	var intersection: Variant = SURFACE_PICKER.pick_world_position(
		ray_origin,
		ray_direction,
		_target
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
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		var ramp_cell := _transition_painter.get_start_cell() \
			if _transition_painter.is_active() else _pointer_cell
		_preview_cells = _transition_painter.get_preview_cells(_pointer_cell) \
			if _transition_painter.is_active() \
			else _make_single_cell_preview(ramp_cell, _target.has_floor(ramp_cell))
		var transition := _target.floor_map.get_cell_transition(ramp_cell)
		var low_edge := _target.floor_map.get_cell_low_edge(ramp_cell)
		var transition_name := _target.floor_map.get_transition_name(transition)
		var transition_error := _target.get_transition_error(ramp_cell)
		if _transition_painter.is_active() \
				and _dock.get_transition_operation() == TRANSITION_PAINTER.Operation.PaintRamp:
			low_edge = _transition_painter.get_preview_low_edge(_pointer_cell)
			var ramp_cell_count := _transition_painter.get_preview_ramp_cells(
				_pointer_cell
			).size()
			transition_name = "Ramp run preview — %d ramp tiles" % ramp_cell_count
			# Live validation text resized the dock and therefore the 3D viewport during a drag.
			transition_error = ""
		if _preview_cells.is_empty():
			_dock.clear_hover()
		else:
			_dock.set_transition_hover(
				ramp_cell,
				transition_name,
				_target.floor_map.get_low_edge_name(low_edge),
				transition_error
			)
		_update_preview()
		return
	var clip_to_bounds := _should_clip_to_bounds()
	if _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Fill:
		var fill_seed := _rectangle_start if _is_gesture_active() else _pointer_cell
		_preview_cells = FLOOD_FILL.footprint(
			_target.floor_map,
			fill_seed,
			_get_fill_match_property()
		)
	elif _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Rectangle:
		if _is_gesture_active():
			_preview_cells = SHAPE_PAINTER.rectangle_footprint(
				_rectangle_start,
				_pointer_cell,
				_target.floor_map,
				clip_to_bounds
			)
		else:
			_preview_cells = SHAPE_PAINTER.brush_footprint(
				_pointer_cell,
				1,
				_target.floor_map,
				clip_to_bounds
			)
	else:
		_preview_cells = SHAPE_PAINTER.brush_footprint(
			_pointer_cell,
			_dock.get_brush_size(),
			_target.floor_map,
			clip_to_bounds
		)
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation:
		_preview_cells = _present_cells_only(_preview_cells)
	if _preview_cells.is_empty():
		_dock.clear_hover()
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation \
			and _target.has_floor(_pointer_cell):
		_dock.set_elevation_hover(
			_pointer_cell,
			_preview_cells.size(),
			_target.get_cell_elevation(_pointer_cell)
		)
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Style \
			and _target.floor_map.is_in_bounds(_pointer_cell):
		var style_index := _target.floor_map.get_cell_style(_pointer_cell)
		_dock.set_style_hover(
			_pointer_cell,
			_preview_cells.size(),
			_get_style_name(style_index)
		)
	else:
		_dock.set_hover(_pointer_cell, _preview_cells.size())
	_update_preview()


## Builds typed transition feedback without assigning an untyped array literal at runtime.
static func _make_single_cell_preview(cell: Vector2i, include_cell: bool) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if include_cell:
		cells.append(cell)
	return cells


func _begin_gesture() -> int:
	if _preview_cells.is_empty():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		if not _transition_painter.begin(
			_target.floor_map,
			_target.elevation_profile,
			_target.cell_size,
			_dock.get_transition_operation(),
			_pointer_cell
		):
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation:
		var operation := _dock.get_elevation_operation() as ELEVATION_PAINTER.Operation
		if operation == ELEVATION_PAINTER.Operation.Sample:
			_sample_elevation()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if not _elevation_painter.begin(
			_target.floor_map,
			operation,
			_dock.get_absolute_elevation()
		):
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Style:
		if _dock.get_style_operation() == STYLE_PAINTER.Operation.Sample:
			_sample_style()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		if not _style_painter.begin(_target.floor_map, _dock.get_style_index()):
			return EditorPlugin.AFTER_GUI_INPUT_PASS
	elif not _painter.begin(
		_target.floor_map,
		_dock.get_paint_mode() as SHAPE_PAINTER.PaintMode
	):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	_rectangle_start = _pointer_cell
	_last_brush_cell = _pointer_cell
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		_update_preview_footprint()
	elif _dock.get_shape_mode() in [
		SHAPE_PAINTER.ShapeMode.Brush,
		SHAPE_PAINTER.ShapeMode.Fill,
	]:
		_apply_active_cells(_preview_cells)
	else:
		_update_preview_footprint()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _apply_brush_segment() -> void:
	for brush_centre in SHAPE_PAINTER.stroke_centres(_last_brush_cell, _pointer_cell):
		_apply_active_cells(SHAPE_PAINTER.brush_footprint(
			brush_centre,
			_dock.get_brush_size(),
			_target.floor_map,
			_should_clip_to_bounds()
		))
	_last_brush_cell = _pointer_cell


func _finish_gesture() -> int:
	if not _is_gesture_active():
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _dock.get_edit_mode() != DOCK_SCRIPT.EditMode.Transition \
			and _dock.get_shape_mode() == SHAPE_PAINTER.ShapeMode.Rectangle:
		_apply_active_cells(_preview_cells)
	var edit_mode := _dock.get_edit_mode()
	var edit: Dictionary
	var apply_method := APPLY_SNAPSHOT_METHOD
	match edit_mode:
		DOCK_SCRIPT.EditMode.Transition:
			edit = _transition_painter.finish(_pointer_cell)
			apply_method = APPLY_TRANSITION_SNAPSHOT_METHOD
		DOCK_SCRIPT.EditMode.Elevation:
			edit = _elevation_painter.finish()
			apply_method = APPLY_ELEVATION_SNAPSHOT_METHOD
		DOCK_SCRIPT.EditMode.Style:
			edit = _style_painter.finish()
			apply_method = APPLY_STYLE_SNAPSHOT_METHOD
		_:
			edit = _painter.finish()
	var before := edit.get("before", {}) as Dictionary
	var after := edit.get("after", {}) as Dictionary
	var touched_count := edit.get("touched_count", 0) as int
	var edit_error := edit.get("error", "") as String
	if before != after:
		var action_name := _gesture_action_name()
		var undo_redo := get_undo_redo()
		undo_redo.create_action(action_name)
		undo_redo.add_do_method(_target.floor_map, apply_method, after)
		undo_redo.add_undo_method(_target.floor_map, apply_method, before)
		# The live gesture already applied the final state; register it without executing twice.
		undo_redo.commit_action(false)
		_dock.set_status("%s: %d cell%s. Save Map when ready." % [
			action_name,
			touched_count,
			"" if touched_count == 1 else "s",
		])
	elif not edit_error.is_empty():
		_dock.set_status("Ramp not placed.")
	else:
		_dock.set_status("Gesture made no floor change.")
	_update_preview_footprint()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


func _gesture_action_name() -> String:
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		match _dock.get_transition_operation() as TRANSITION_PAINTER.Operation:
			TRANSITION_PAINTER.Operation.EraseRamp:
				return "Make Ramp Cell Flat"
			TRANSITION_PAINTER.Operation.RotateRamp:
				return "Rotate Ramp"
			_:
				return "Paint Ramp"
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation:
		var operation_name := "Set Elevation %d" % _dock.get_absolute_elevation()
		match _dock.get_elevation_operation() as ELEVATION_PAINTER.Operation:
			ELEVATION_PAINTER.Operation.RaiseOne:
				operation_name = "Raise Elevation"
			ELEVATION_PAINTER.Operation.LowerOne:
				operation_name = "Lower Elevation"
		return _shaped_action_name(operation_name)
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Style:
		var style_operation := "Paint Style: %s" % _get_style_name(_dock.get_style_index())
		return _shaped_action_name(style_operation)
	var operation := (
		"Paint Floor"
		if _dock.get_paint_mode() == SHAPE_PAINTER.PaintMode.Paint
		else "Erase Floor"
	)
	return _shaped_action_name(operation)


func _shaped_action_name(operation: String) -> String:
	match _dock.get_shape_mode() as SHAPE_PAINTER.ShapeMode:
		SHAPE_PAINTER.ShapeMode.Rectangle:
			return "%s Rectangle" % operation
		SHAPE_PAINTER.ShapeMode.Fill:
			return "%s Fill" % operation
		_:
			return "%s Stroke" % operation


func _get_fill_match_property() -> FLOOD_FILL.MatchProperty:
	match _dock.get_edit_mode() as DOCK_SCRIPT.EditMode:
		DOCK_SCRIPT.EditMode.Elevation:
			return FLOOD_FILL.MatchProperty.Elevation
		DOCK_SCRIPT.EditMode.Style:
			return FLOOD_FILL.MatchProperty.Style
		_:
			return FLOOD_FILL.MatchProperty.Shape


func _should_clip_to_bounds() -> bool:
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		return true
	if _dock.get_edit_mode() != DOCK_SCRIPT.EditMode.FloorShape:
		return true
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
	var cancelled := _painter.cancel()
	cancelled = _elevation_painter.cancel() or cancelled
	cancelled = _style_painter.cancel() or cancelled
	cancelled = _transition_painter.cancel() or cancelled
	if not cancelled:
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


func _on_validate_requested() -> void:
	if _target == null:
		return
	var scene_root := get_editor_interface().get_edited_scene_root()
	var diagnostics: Array[String] = VALIDATION.collect(scene_root, _target)
	_dock.set_diagnostics(VALIDATION.format_report(diagnostics))
	_dock.set_status("Validation complete: %d issue%s." % [
		diagnostics.size(),
		"" if diagnostics.size() == 1 else "s",
	])


func _on_repair_requested() -> void:
	if _target == null or _target.floor_map == null:
		return
	var repair := VALIDATION.plan_safe_ramp_repair(_target)
	var repaired_cells := repair["repaired_cells"] as Array[Vector2i]
	if repaired_cells.is_empty():
		var current_diagnostics: Array[String] = VALIDATION.collect(
			get_editor_interface().get_edited_scene_root(),
			_target
		)
		_dock.set_diagnostics(VALIDATION.format_report(current_diagnostics))
		_dock.set_status("No invalid ramps were safe to repair.")
		return
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Repair Invalid Floor Ramps")
	undo_redo.add_do_method(
		_target.floor_map,
		APPLY_TRANSITION_SNAPSHOT_METHOD,
		repair["after"] as Dictionary
	)
	undo_redo.add_undo_method(
		_target.floor_map,
		APPLY_TRANSITION_SNAPSHOT_METHOD,
		repair["before"] as Dictionary
	)
	undo_redo.commit_action()
	_dock.set_status("Repaired %d invalid ramp%s; undo is available." % [
		repaired_cells.size(),
		"" if repaired_cells.size() == 1 else "s",
	])
	var remaining_diagnostics: Array[String] = VALIDATION.collect(
		get_editor_interface().get_edited_scene_root(),
		_target
	)
	_dock.set_diagnostics(VALIDATION.format_report(remaining_diagnostics))


func _on_conform_grounded_requested() -> void:
	if _target == null:
		return
	var scene_root := get_editor_interface().get_edited_scene_root()
	var plan := GROUNDING_EDITOR.plan_conform(scene_root, _target)
	var changes := plan.get("changes", []) as Array[Dictionary]
	var errors := plan.get("errors", []) as Array[String]
	if changes.is_empty():
		_dock.set_status(
			"No grounded objects conformed.%s" % _format_grounding_errors(errors)
		)
		return
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Conform Grounded Objects")
	for change in changes:
		var grounding := change["grounding"] as GROUNDING_SCRIPT
		undo_redo.add_do_method(
			grounding,
			&"apply_grounding_state",
			change["after_transform"] as Transform3D,
			change["after_stale"] as bool
		)
		undo_redo.add_undo_method(
			grounding,
			&"apply_grounding_state",
			change["before_transform"] as Transform3D,
			change["before_stale"] as bool
		)
	undo_redo.commit_action()
	_dock.set_status(
		"Conformed %d grounded object%s.%s" % [
			changes.size(),
			"" if changes.size() == 1 else "s",
			_format_grounding_errors(errors),
		]
	)


func _format_grounding_errors(errors: Array[String]) -> String:
	if errors.is_empty():
		return ""
	return " %d skipped: %s" % [errors.size(), errors[0]]


func _working_world_height() -> float:
	if _target == null or _target.floor_map == null or _target.elevation_profile == null:
		return 0.0
	return _target.elevation_profile.elevation_to_world(_target.floor_map.default_elevation)


func _preview_world_height() -> float:
	if _target == null or _target.elevation_profile == null:
		return 0.0
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.FloorShape:
		return _working_world_height()
	var preview_cell := _transition_painter.get_start_cell() \
		if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition \
			and _transition_painter.is_active() \
		else _pointer_cell
	var elevation := _target.get_cell_elevation(preview_cell)
	if elevation == FLOOR_MAP_SCRIPT.INVALID_ELEVATION:
		return _working_world_height()
	if _dock.get_edit_mode() in [DOCK_SCRIPT.EditMode.Style, DOCK_SCRIPT.EditMode.Transition]:
		return _target.elevation_profile.elevation_to_world(elevation)
	match _dock.get_elevation_operation() as ELEVATION_PAINTER.Operation:
		ELEVATION_PAINTER.Operation.SetAbsolute:
			elevation = _dock.get_absolute_elevation()
		ELEVATION_PAINTER.Operation.RaiseOne:
			elevation += 1
		ELEVATION_PAINTER.Operation.LowerOne:
			elevation -= 1
	return _target.elevation_profile.elevation_to_world(elevation)


func _can_paint() -> bool:
	return is_instance_valid(_dock) \
		and is_instance_valid(_target) \
		and _target.floor_map != null \
		and _dock.is_editing_enabled()


func _create_preview() -> void:
	_visuals.attach(_target)
	_update_elevation_overlay()
	_update_grid_overlay()


func _remove_preview() -> void:
	_visuals.detach()


func _update_preview() -> void:
	var colour := Color(1.0, 0.95, 0.2, 0.48)
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation:
		colour = Color(0.55, 0.45, 0.18, 0.32)
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Style:
		colour = Color(0.3, 0.55, 0.72, 0.32)
	elif _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		colour = Color(0.28, 0.68, 0.82, 0.42)
	else:
		colour = (
			Color(0.2, 0.95, 0.45, 0.38)
			if _dock.get_paint_mode() == SHAPE_PAINTER.PaintMode.Paint
			else Color(1.0, 0.2, 0.25, 0.38)
		)
	if _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition:
		_visuals.update_surface_footprint(
			_preview_cells,
			_target.cell_size if _target != null else 1.0,
			_target.world_origin_xz if _target != null else Vector2.ZERO,
			_get_transition_preview_descriptions(),
			colour,
			_can_paint()
		)
		return
	_visuals.update_footprint(
		_preview_cells,
		_target.cell_size if _target != null else 1.0,
		_target.world_origin_xz if _target != null else Vector2.ZERO,
		_preview_world_height(),
		colour,
		_can_paint()
	)


func _get_transition_preview_descriptions() -> Dictionary:
	var descriptions: Dictionary = {}
	if _target == null:
		return descriptions
	if _transition_painter.is_active() \
			and _dock.get_transition_operation() == TRANSITION_PAINTER.Operation.PaintRamp:
		descriptions = _transition_painter.get_preview_surface_descriptions(_pointer_cell)
		if not descriptions.is_empty():
			return descriptions
	for cell in _preview_cells:
		if _target.has_floor(cell):
			descriptions[cell] = _target.get_cell_surface_description(cell)
	return descriptions


func _is_gesture_active() -> bool:
	return _painter.is_active() \
		or _elevation_painter.is_active() \
		or _style_painter.is_active() \
		or _transition_painter.is_active()


func _apply_active_cells(cells: Array[Vector2i]) -> void:
	if _elevation_painter.is_active():
		_elevation_painter.apply_cells(_present_cells_only(cells))
	elif _style_painter.is_active():
		_style_painter.apply_cells(cells)
	else:
		_painter.apply_cells(cells)


func _present_cells_only(cells: Array[Vector2i]) -> Array[Vector2i]:
	var present: Array[Vector2i] = []
	for cell in cells:
		if _target.has_floor(cell):
			present.append(cell)
	return present


func _sample_elevation() -> void:
	var elevation := _target.get_cell_elevation(_pointer_cell)
	if elevation == FLOOR_MAP_SCRIPT.INVALID_ELEVATION:
		_dock.set_status("No floor tile to sample at %s." % _pointer_cell)
		return
	_dock.set_sampled_elevation(elevation)
	_dock.set_status("Sampled elevation %d — %.2f m." % [
		elevation,
		_target.elevation_profile.elevation_to_world(elevation),
	])
	_update_preview_footprint()


func _sample_style() -> void:
	if not _target.floor_map.is_in_bounds(_pointer_cell):
		_dock.set_status("No bounded floor cell to sample at %s." % _pointer_cell)
		return
	var style_index := _target.floor_map.get_cell_style(_pointer_cell)
	_dock.set_sampled_style(style_index)
	_dock.set_status("Sampled style %s." % _get_style_name(style_index))
	_update_preview_footprint()


func _get_style_name(style_index: int) -> String:
	if _target == null or style_index < 0 or style_index >= _target.styles.size():
		return "Invalid style %d" % style_index
	return _target.styles[style_index].display_name


func _connect_target_surface() -> void:
	if _target == null:
		return
	if not _target.surface_rebuilt.is_connected(_on_target_surface_rebuilt):
		_target.surface_rebuilt.connect(_on_target_surface_rebuilt)


func _disconnect_target_surface() -> void:
	if _target == null:
		return
	if _target.surface_rebuilt.is_connected(_on_target_surface_rebuilt):
		_target.surface_rebuilt.disconnect(_on_target_surface_rebuilt)


func _on_target_surface_rebuilt(_cell_count: int) -> void:
	_update_elevation_overlay()
	_update_grid_overlay()
	_update_preview_footprint()


func _update_elevation_overlay() -> void:
	if _target == null:
		return
	var should_show := _can_paint() \
		and _dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Elevation
	_visuals.update_elevation_overlay(
		_target.floor_map,
		_target.elevation_profile,
		_target.cell_size,
		_target.world_origin_xz,
		should_show
	)


func _update_grid_overlay() -> void:
	if _target == null or not is_instance_valid(_dock):
		return
	_visuals.update_grid_overlay(
		_target.floor_map,
		_target.elevation_profile,
		_target.cell_size,
		_target.world_origin_xz,
		_dock.is_grid_overlay_visible(),
		_dock.get_edit_mode() == DOCK_SCRIPT.EditMode.Transition
	)
