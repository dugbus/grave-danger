@tool
class_name FloorSurfaceStylePainter
extends RefCounted

## Applies palette-index gestures independently from topology and elevation painting.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

enum Operation {
	Paint,
	Sample,
}

var _floor_map: FLOOR_MAP_SCRIPT
var _style_index := 0
var _before_snapshot: Dictionary[Vector2i, int] = {}
var _touched_cells: Dictionary[Vector2i, bool] = {}
var _active := false


## Begins one style gesture and captures the exact state used by cancel and undo.
func begin(floor_map: FLOOR_MAP_SCRIPT, style_index: int) -> bool:
	if floor_map == null or _active or style_index < 0:
		return false
	_floor_map = floor_map
	_style_index = style_index
	_before_snapshot = floor_map.get_style_snapshot()
	_touched_cells.clear()
	_active = true
	return true


## Paints style intent on in-bounds tops or holes, once per cell per gesture.
func apply_cells(cells: Array[Vector2i]) -> int:
	if not _active or _floor_map == null:
		return 0
	var overrides := _floor_map.get_style_snapshot()
	var new_cell_count := 0
	for cell in cells:
		if not _floor_map.is_in_bounds(cell) or _touched_cells.has(cell):
			continue
		_touched_cells[cell] = true
		new_cell_count += 1
		if _style_index == _floor_map.default_style_index:
			overrides.erase(cell)
		else:
			overrides[cell] = _style_index
	_floor_map.apply_style_snapshot(overrides)
	return new_cell_count


## Completes the gesture and returns detached before/after snapshots for one undo action.
func finish() -> Dictionary:
	if not _active or _floor_map == null:
		return {}
	var result := {
		"before": _before_snapshot.duplicate(),
		"after": _floor_map.get_style_snapshot(),
		"touched_count": _touched_cells.size(),
	}
	_clear()
	return result


## Cancels the complete style gesture and restores every prior override.
func cancel() -> bool:
	if not _active or _floor_map == null:
		return false
	_floor_map.apply_style_snapshot(_before_snapshot)
	_clear()
	return true


## Reports whether a gesture currently owns editable style state.
func is_active() -> bool:
	return _active


func _clear() -> void:
	_floor_map = null
	_before_snapshot.clear()
	_touched_cells.clear()
	_active = false
