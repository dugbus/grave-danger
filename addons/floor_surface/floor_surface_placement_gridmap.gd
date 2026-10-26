@tool
extends GridMap

## Grounds native GridMap brush strokes and reseats scenery after completed floor edits.

const PAINT := preload("res://addons/floor_surface/editor/floor_surface_gridmap_paint.gd")
const SHAPE := preload("res://addons/floor_surface/editor/floor_surface_shape_painter.gd")

## FloorSurface that supplies the height below each newly painted grid cell.
@export_node_path("FloorSurface") var floor_surface_path: NodePath
## Seat new brush placements and update grounded scenery after floor edits; disable for fixed-height placement.
@export var follow_floor := true
## Only painting on this vertical GridMap layer follows the floor; other layers retain manual heights.
@export var floor_paint_layer := 0

var _manager: Object
var _history_versions: Dictionary[int, int] = {}
var _floor_before: FloorSurface
var _floor_state: Dictionary = {}
var _before: Dictionary[Vector3i, Vector2i] = {}
var _applying := false
var _placement_errors := PackedStringArray()
var _stroke_cells: Array[Vector3i] = []
var _observing_stroke := false


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		_ensure_editor_history()


func _exit_tree() -> void:
	_disconnect_history()


func _process(_delta: float) -> void:
	# Recover connections after tool-script reloads; steady-state placement does no per-frame scanning.
	if not is_instance_valid(_manager) or _history_versions.is_empty():
		_ensure_editor_history()


func _ensure_editor_history() -> void:
	if not Engine.has_singleton(&"EditorInterface"):
		return
	var editor := Engine.get_singleton(&"EditorInterface")
	bind_editor_history(editor.get_editor_undo_redo() as Object)


## Binds one editor history service and establishes the saved-cell baseline without moving anything.
func bind_editor_history(manager: Object) -> void:
	if not is_instance_valid(manager):
		return
	if manager == _manager and not _history_versions.is_empty():
		return
	_disconnect_history()
	_manager = manager
	_before = PAINT.snapshot(self)
	var surface := get_node_or_null(floor_surface_path) as FloorSurface
	_capture_floor(surface)
	_remember_history_versions(_history_sources(surface))
	_manager.history_changed.connect(_on_history_changed)
	_manager.version_changed.connect(_on_version_changed)


func _disconnect_history() -> void:
	if is_instance_valid(_manager):
		if _manager.history_changed.is_connected(_on_history_changed):
			_manager.history_changed.disconnect(_on_history_changed)
		if _manager.version_changed.is_connected(_on_version_changed):
			_manager.version_changed.disconnect(_on_version_changed)
	_manager = null
	_history_versions.clear()
	if is_instance_valid(_floor_before):
		_floor_before.free()
	_floor_before = null
	_floor_state.clear()
	_stroke_cells.clear()
	_observing_stroke = false


## Observes native brush coordinates without consuming input or replacing its palette and tools.
## Tracking empty cells lets the native eraser remove an automatically raised piece as well.
func observe_pointer(camera: Camera3D, event: InputEvent) -> void:
	if Engine.is_editor_hint() and _history_versions.is_empty():
		_ensure_editor_history()
	if event is InputEventKey and (event as InputEventKey).keycode == KEY_ESCAPE:
		_stroke_cells.clear()
		_observing_stroke = false
		return
	var position: Vector2
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		_observing_stroke = button.pressed
		if not button.pressed:
			return
		_stroke_cells.clear()
		position = button.position
	elif event is InputEventMouseMotion and _observing_stroke:
		position = (event as InputEventMouseMotion).position
	else:
		return
	var editor_floor := get_meta(&"_editor_floor_", Vector3.ZERO) as Vector3
	if not follow_floor or roundi(editor_floor.y) != floor_paint_layer:
		return
	var inverse := global_transform.affine_inverse() if is_inside_tree() else transform.affine_inverse()
	var hit: Variant = SHAPE.working_plane_intersection(
		inverse * camera.project_ray_origin(position),
		inverse.basis * camera.project_ray_normal(position),
		float(floor_paint_layer) * cell_size.y
	)
	if hit != null:
		var cell := local_to_map(hit as Vector3)
		cell.y = floor_paint_layer
		if not _stroke_cells.has(cell):
			_stroke_cells.append(cell)


func _on_history_changed() -> void:
	if _applying or not is_instance_valid(_manager):
		return
	if _history_versions.is_empty():
		# A notification arriving during script reload must not reinterpret saved cells as a new stroke.
		bind_editor_history(_manager)
		return
	var surface := get_node_or_null(floor_surface_path) as FloorSurface
	var sources := _history_sources(surface)
	var changed: Array[int] = []
	for history_id in sources:
		var candidate := _manager.get_history_undo_redo(history_id) as UndoRedo
		if _history_versions.has(history_id) and _history_versions[history_id] != candidate.get_version():
			changed.append(history_id)
	if changed.is_empty():
		return
	var own_id := _manager.get_object_history_id(self) as int
	var own_changed := changed.has(own_id)
	var floor_changed := _floor_before != null and PAINT.height_state(surface) != _floor_state
	if not own_changed and not floor_changed:
		# An unrelated resource commit must not capture a still-live native brush as the new baseline.
		_remember_history_versions(sources)
		return
	var changed_id := own_id if own_changed else changed[0]
	var history := _manager.get_history_undo_redo(changed_id) as UndoRedo
	var action_name := history.get_current_action_name()
	_placement_errors.clear()
	_applying = true
	if follow_floor and not history.has_redo():
		if own_changed and action_name == PAINT.paint_action_name():
			_apply_plan(PAINT.plan(self, surface, _before, floor_paint_layer, _stroke_cells), action_name, self)
		if floor_changed:
			_apply_plan(PAINT.plan_floor_change(self, _floor_before, surface), action_name, sources[changed_id])
	_applying = false
	_before = PAINT.snapshot(self)
	_capture_floor(surface)
	_remember_history_versions(sources)
	_stroke_cells.clear()
	update_configuration_warnings()


func _on_version_changed() -> void:
	# Floor and scenery undo/redo already includes the correction; refresh query state without moving anything.
	var cells := PAINT.snapshot(self)
	var own_id := _manager.get_object_history_id(self) as int
	var history := _manager.get_history_undo_redo(own_id) as UndoRedo
	_applying = true
	if cells != _before and _history_versions.get(own_id) == history.get_version():
		_mark_scene_unsaved()
	_before = cells
	_stroke_cells.clear()
	var surface := get_node_or_null(floor_surface_path) as FloorSurface
	_capture_floor(surface)
	_remember_history_versions(_history_sources(surface))
	_applying = false


func _apply_plan(result: Dictionary, action_name: String, context: Object) -> void:
	_placement_errors.append_array(PackedStringArray(result["errors"]))
	var changes := result["changes"] as Array[Dictionary]
	PAINT.apply_with_history(self, changes, _manager, action_name, context)
	if not changes.is_empty() and _manager.get_object_history_id(context) != _manager.get_object_history_id(self):
		# Resource-history actions do not mark the scene's native history dirty by themselves.
		_mark_scene_unsaved()


func _mark_scene_unsaved() -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton(&"EditorInterface"):
		return
	var editor := Engine.get_singleton(&"EditorInterface")
	var root := editor.get_edited_scene_root() as Node
	if root != null and root.is_ancestor_of(self):
		editor.mark_scene_as_unsaved()


## Floor resources can belong to the global history while their GridMap belongs to the scene history.
func _history_sources(surface: FloorSurface) -> Dictionary[int, Object]:
	var sources: Dictionary[int, Object] = {}
	var objects: Array[Object] = [self]
	if surface != null:
		if surface.floor_map != null:
			objects.append(surface.floor_map)
		if surface.elevation_profile != null:
			objects.append(surface.elevation_profile)
	for object in objects:
		var history_id := _manager.get_object_history_id(object) as int
		if not sources.has(history_id):
			sources[history_id] = object
	return sources


func _remember_history_versions(sources: Dictionary[int, Object]) -> void:
	_history_versions.clear()
	for history_id in sources:
		var history := _manager.get_history_undo_redo(history_id) as UndoRedo
		_history_versions[history_id] = history.get_version()


func _capture_floor(surface: FloorSurface) -> void:
	var state := PAINT.height_state(surface)
	if state == _floor_state:
		return
	if is_instance_valid(_floor_before):
		_floor_before.free()
	_floor_before = PAINT.capture_surface(surface)
	_floor_state = state


func _get_configuration_warnings() -> PackedStringArray:
	return _placement_errors
