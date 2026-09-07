@tool
class_name FloorSurfaceElevationPainter
extends RefCounted

## Applies integer elevation gestures independently from floor-shape painting.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

enum Operation {
	SetAbsolute,
	RaiseOne,
	LowerOne,
	Sample,
}

var _floor_map: FLOOR_MAP_SCRIPT
var _operation := Operation.SetAbsolute
var _absolute_elevation := 0
var _before_snapshot: Dictionary[Vector2i, int] = {}
var _touched_cells: Dictionary[Vector2i, bool] = {}
var _active := false


## Begins one elevation gesture and captures the exact state used by cancel and undo.
func begin(
	floor_map: FLOOR_MAP_SCRIPT,
	operation: Operation,
	absolute_elevation: int
) -> bool:
	if floor_map == null or _active:
		return false
	_floor_map = floor_map
	_operation = operation
	_absolute_elevation = absolute_elevation
	_before_snapshot = floor_map.get_elevation_snapshot()
	_touched_cells.clear()
	_active = true
	return true


## Applies the selected integer operation to present cells, once per cell per gesture.
func apply_cells(cells: Array[Vector2i]) -> int:
	if not _active or _floor_map == null:
		return 0
	var overrides := _floor_map.get_elevation_snapshot()
	var new_cell_count := 0
	for cell in cells:
		if not _floor_map.has_floor(cell) or _touched_cells.has(cell):
			continue
		_touched_cells[cell] = true
		new_cell_count += 1
		var elevation := _resolve_elevation(_floor_map.get_cell_elevation(cell))
		if elevation == _floor_map.default_elevation:
			overrides.erase(cell)
		else:
			overrides[cell] = elevation
	_floor_map.apply_elevation_snapshot(overrides)
	return new_cell_count


## Completes the gesture and returns detached before/after snapshots for one undo action.
func finish() -> Dictionary:
	if not _active or _floor_map == null:
		return {}
	var result := {
		"before": _before_snapshot.duplicate(),
		"after": _floor_map.get_elevation_snapshot(),
		"touched_count": _touched_cells.size(),
	}
	_clear()
	return result


## Cancels the complete elevation gesture and restores every prior override.
func cancel() -> bool:
	if not _active or _floor_map == null:
		return false
	_floor_map.apply_elevation_snapshot(_before_snapshot)
	_clear()
	return true


## Reports whether a gesture currently owns editable elevation state.
func is_active() -> bool:
	return _active


func _resolve_elevation(current_elevation: int) -> int:
	match _operation:
		Operation.RaiseOne:
			return current_elevation + 1
		Operation.LowerOne:
			return current_elevation - 1
		_:
			return _absolute_elevation


func _clear() -> void:
	_floor_map = null
	_before_snapshot.clear()
	_touched_cells.clear()
	_active = false
