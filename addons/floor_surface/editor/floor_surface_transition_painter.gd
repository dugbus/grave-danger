@tool
class_name FloorSurfaceTransitionPainter
extends RefCounted

## Applies one inferred ramp, erase or orientation correction as an undoable gesture.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const RAMP_RESOLVER := preload("res://addons/floor_surface/floor_surface_ramp_resolver.gd")

enum Operation {
	PaintRamp,
	EraseRamp,
	RotateRamp,
}

var _floor_map: FLOOR_MAP_SCRIPT
var _profile: PROFILE_SCRIPT
var _cell_size := 1.0
var _operation := Operation.PaintRamp
var _start_cell := Vector2i.ZERO
var _before_snapshot: Dictionary = {}
var _active := false


## Begins a transition gesture without changing the map until release.
func begin(
	floor_map: FLOOR_MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float,
	operation: Operation,
	start_cell: Vector2i
) -> bool:
	if floor_map == null or profile == null or _active or not floor_map.has_floor(start_cell):
		return false
	_floor_map = floor_map
	_profile = profile
	_cell_size = maxf(cell_size, 0.01)
	_operation = operation
	_start_cell = _resolve_start_landing(start_cell)
	_before_snapshot = floor_map.get_transition_snapshot()
	_active = true
	return true


func _resolve_start_landing(start_cell: Vector2i) -> Vector2i:
	if _operation != Operation.PaintRamp \
			or _floor_map.get_cell_transition(start_cell) != FLOOR_MAP_SCRIPT.Transition.Ramp:
		return start_cell
	var description := RAMP_RESOLVER.new().resolve_cell(
		_floor_map,
		_profile,
		start_cell,
		_cell_size
	)
	if not description.get("valid", false) as bool:
		return start_cell
	return description.get("high_cell", start_cell) as Vector2i


## Applies the inferred or corrected transition and returns one complete undo snapshot.
func finish(end_cell: Vector2i) -> Dictionary:
	if not _active or _floor_map == null:
		return {}
	var preview_cells := get_preview_cells(end_cell)
	var gesture_cells := _get_ramp_cells(preview_cells) \
		if _operation == Operation.PaintRamp else preview_cells
	var error := ""
	match _operation:
		Operation.PaintRamp:
			error = _paint_ramps(preview_cells, gesture_cells)
		Operation.EraseRamp:
			for cell in gesture_cells:
				_floor_map.set_cell_transition(cell, FLOOR_MAP_SCRIPT.Transition.Flat)
		Operation.RotateRamp:
			for cell in gesture_cells:
				error = _rotate_ramp(cell)
				if not error.is_empty():
					_floor_map.apply_transition_snapshot(_before_snapshot)
					break
	var after := _floor_map.get_transition_snapshot()
	var result := {
		"after": after,
		"before": _before_snapshot.duplicate(true),
		"error": error,
		"touched_count": _count_changed_cells(_before_snapshot, after, gesture_cells),
	}
	_clear()
	return result


## Cancels the pending gesture and restores any captured transition state.
func cancel() -> bool:
	if not _active or _floor_map == null:
		return false
	_floor_map.apply_transition_snapshot(_before_snapshot)
	_clear()
	return true


## Reports whether this painter currently owns a pending viewport gesture.
func is_active() -> bool:
	return _active


## Returns the cell where the current boundary drag began.
func get_start_cell() -> Vector2i:
	return _start_cell


## Returns the full straight drag including both flat landing endpoints for viewport feedback.
func get_preview_cells(end_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not _active or _floor_map == null:
		return cells
	var delta := end_cell - _start_cell
	if absi(delta.x) >= absi(delta.y):
		var step_x := 1 if delta.x >= 0 else -1
		for x_coordinate in range(_start_cell.x, end_cell.x + step_x, step_x):
			cells.append(Vector2i(x_coordinate, _start_cell.y))
	else:
		var step_y := 1 if delta.y >= 0 else -1
		for y_coordinate in range(_start_cell.y, end_cell.y + step_y, step_y):
			cells.append(Vector2i(_start_cell.x, y_coordinate))
	return cells


## Returns only the cells that would become ramps, excluding both flat landings.
func get_preview_ramp_cells(end_cell: Vector2i) -> Array[Vector2i]:
	return _get_ramp_cells(get_preview_cells(end_cell))


## Resolves the intended sloped and landing tops without changing the authored map.
func get_preview_surface_descriptions(end_cell: Vector2i) -> Dictionary:
	var descriptions: Dictionary = {}
	if not _active or _floor_map == null or _profile == null:
		return descriptions
	var preview_cells := get_preview_cells(end_cell)
	var intent := _resolve_run_intent(preview_cells)
	if not intent.get("valid", false) as bool:
		return descriptions
	var ramp_cells := _get_ramp_cells(preview_cells)
	var preview_map := _floor_map.duplicate(true) as FLOOR_MAP_SCRIPT
	var low_edge := intent["low_edge"] as FLOOR_MAP_SCRIPT.LowEdge
	for cell in ramp_cells:
		if not preview_map.has_floor(cell):
			return {}
		preview_map.set_cell_transition(cell, FLOOR_MAP_SCRIPT.Transition.Ramp, low_edge)
	var resolver := RAMP_RESOLVER.new()
	for cell in preview_cells:
		var description := resolver.resolve_cell(preview_map, _profile, cell, _cell_size)
		if not description.get("valid", false) as bool:
			return {}
		descriptions[cell] = description
	return descriptions


## Infers the low edge from whichever drag endpoint has the lower authored elevation.
func get_preview_low_edge(end_cell: Vector2i) -> FLOOR_MAP_SCRIPT.LowEdge:
	if not _active or _floor_map == null or _operation != Operation.PaintRamp:
		return FLOOR_MAP_SCRIPT.LowEdge.None
	var cells := get_preview_cells(end_cell)
	var intent := _resolve_run_intent(cells)
	if not intent.get("valid", false) as bool:
		return FLOOR_MAP_SCRIPT.LowEdge.None
	return intent["low_edge"] as FLOOR_MAP_SCRIPT.LowEdge


func _paint_ramps(preview_cells: Array[Vector2i], ramp_cells: Array[Vector2i]) -> String:
	var intent := _resolve_run_intent(preview_cells)
	if not intent.get("valid", false) as bool:
		return intent.get("error", "Ramp drag is invalid.") as String
	var low_edge := intent["low_edge"] as FLOOR_MAP_SCRIPT.LowEdge
	var low_landing := intent["low_landing"] as Vector2i
	var high_landing := intent["high_landing"] as Vector2i
	if not _floor_map.has_floor(low_landing) or not _floor_map.has_floor(high_landing):
		return "Ramp run needs present low and high landing cells."
	if _floor_map.get_cell_transition(low_landing) != FLOOR_MAP_SCRIPT.Transition.Flat \
			or _floor_map.get_cell_transition(high_landing) != FLOOR_MAP_SCRIPT.Transition.Flat:
		return "Ramp run endpoints must be flat landing cells."
	for cell in ramp_cells:
		if not _floor_map.has_floor(cell):
			return "Ramp line crosses missing floor at cell %s." % cell
	var resolver := RAMP_RESOLVER.new()
	for cell in ramp_cells:
		_floor_map.set_cell_transition(
			cell,
			FLOOR_MAP_SCRIPT.Transition.Ramp,
			low_edge
		)
	for cell in ramp_cells:
		var description := resolver.resolve_cell(_floor_map, _profile, cell, _cell_size)
		if not description.get("valid", false) as bool:
			_floor_map.apply_transition_snapshot(_before_snapshot)
			return "Cell %s: %s" % [cell, description.get("error", "Invalid ramp.")]
	return ""


func _rotate_ramp(cell: Vector2i) -> String:
	if _floor_map.get_cell_transition(cell) != FLOOR_MAP_SCRIPT.Transition.Ramp:
		return "Rotate Ramp needs an existing ramp at cell %s." % cell
	var current_edge := _floor_map.get_cell_low_edge(cell)
	var next_edge := _next_edge(current_edge)
	_floor_map.set_cell_transition(
		cell,
		FLOOR_MAP_SCRIPT.Transition.Ramp,
		next_edge
	)
	return ""


func _resolve_run_intent(preview_cells: Array[Vector2i]) -> Dictionary:
	if preview_cells.size() < 3:
		return {
			"valid": false,
			"error": "Leave at least one tile between the high and low flat landings.",
		}
	var first_cell := preview_cells[0]
	var last_cell := preview_cells[-1]
	if not _floor_map.has_floor(first_cell) or not _floor_map.has_floor(last_cell):
		return {"valid": false, "error": "Both drag endpoints must contain floor."}
	if _floor_map.get_cell_transition(first_cell) != FLOOR_MAP_SCRIPT.Transition.Flat \
			or _floor_map.get_cell_transition(last_cell) != FLOOR_MAP_SCRIPT.Transition.Flat:
		return {"valid": false, "error": "Both drag endpoints must be flat landing tiles."}
	var first_elevation := _floor_map.get_cell_elevation(first_cell)
	var last_elevation := _floor_map.get_cell_elevation(last_cell)
	if first_elevation == last_elevation:
		return {"valid": false, "error": "Ramp endpoints must have different elevations."}
	var high_to_low: Array[Vector2i] = preview_cells.duplicate()
	if first_elevation < last_elevation:
		high_to_low.reverse()
	var low_direction := (high_to_low[1] as Vector2i) - (high_to_low[0] as Vector2i)
	return {
		"high_landing": high_to_low[0],
		"low_edge": RAMP_RESOLVER.new().offset_to_edge(low_direction),
		"low_landing": high_to_low[-1],
		"valid": true,
	}


func _get_ramp_cells(preview_cells: Array[Vector2i]) -> Array[Vector2i]:
	var ramp_cells: Array[Vector2i] = []
	var intent := _resolve_run_intent(preview_cells)
	if not intent.get("valid", false) as bool:
		return ramp_cells
	var low_landing := intent["low_landing"] as Vector2i
	var high_landing := intent["high_landing"] as Vector2i
	for cell in preview_cells:
		if cell != low_landing and cell != high_landing:
			ramp_cells.append(cell)
	return ramp_cells


func _count_changed_cells(
	before: Dictionary,
	after: Dictionary,
	cells: Array[Vector2i]
) -> int:
	var before_elevations := before.get("elevation_overrides", {}) as Dictionary
	var after_elevations := after.get("elevation_overrides", {}) as Dictionary
	var before_transitions := before.get("transition_overrides", {}) as Dictionary
	var after_transitions := after.get("transition_overrides", {}) as Dictionary
	var before_edges := before.get("low_edge_overrides", {}) as Dictionary
	var after_edges := after.get("low_edge_overrides", {}) as Dictionary
	var changed_count := 0
	for cell in cells:
		if before_elevations.get(cell, _floor_map.default_elevation) \
				!= after_elevations.get(cell, _floor_map.default_elevation) \
				or before_transitions.get(cell, FLOOR_MAP_SCRIPT.Transition.Flat) \
				!= after_transitions.get(cell, FLOOR_MAP_SCRIPT.Transition.Flat) \
				or before_edges.get(cell, FLOOR_MAP_SCRIPT.LowEdge.None) \
				!= after_edges.get(cell, FLOOR_MAP_SCRIPT.LowEdge.None):
			changed_count += 1
	return changed_count


func _next_edge(edge: FLOOR_MAP_SCRIPT.LowEdge) -> FLOOR_MAP_SCRIPT.LowEdge:
	match edge:
		FLOOR_MAP_SCRIPT.LowEdge.North:
			return FLOOR_MAP_SCRIPT.LowEdge.East
		FLOOR_MAP_SCRIPT.LowEdge.East:
			return FLOOR_MAP_SCRIPT.LowEdge.South
		FLOOR_MAP_SCRIPT.LowEdge.South:
			return FLOOR_MAP_SCRIPT.LowEdge.West
		_:
			return FLOOR_MAP_SCRIPT.LowEdge.North


func _clear() -> void:
	_floor_map = null
	_profile = null
	_before_snapshot.clear()
	_active = false
