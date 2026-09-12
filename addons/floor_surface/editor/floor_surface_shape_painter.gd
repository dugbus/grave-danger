@tool
class_name FloorSurfaceShapePainter
extends RefCounted

## Builds bounded shape footprints and aggregates live occupancy edits into one gesture.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

enum PaintMode {
	Paint,
	Erase,
}

enum ShapeMode {
	Brush,
	Rectangle,
	Fill,
}


## Intersects a viewport ray with the authored elevation plane, including over empty cells.
static func working_plane_intersection(
	ray_origin: Vector3,
	ray_direction: Vector3,
	world_height: float
) -> Variant:
	if is_zero_approx(ray_direction.y):
		return null
	var distance := (world_height - ray_origin.y) / ray_direction.y
	if distance < 0.0:
		return null
	return ray_origin + ray_direction * distance

var _floor_map: FLOOR_MAP_SCRIPT
var _paint_mode := PaintMode.Paint
var _before_snapshot: Dictionary = {}
var _touched_cells: Dictionary[Vector2i, bool] = {}
var _active := false


## Returns a square, odd-width brush footprint clipped to the map bounds.
static func brush_footprint(
	center: Vector2i,
	brush_size: int,
	floor_map: FLOOR_MAP_SCRIPT,
	clip_to_bounds := true
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if floor_map == null:
		return cells
	var safe_size := maxi(brush_size, 1)
	var radius := safe_size / 2
	for z_coordinate in range(center.y - radius, center.y + radius + 1):
		for x_coordinate in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x_coordinate, z_coordinate)
			if not clip_to_bounds or floor_map.is_in_bounds(cell):
				cells.append(cell)
	return cells


## Returns an inclusive rectangle footprint clipped to the map bounds.
static func rectangle_footprint(
	first_corner: Vector2i,
	second_corner: Vector2i,
	floor_map: FLOOR_MAP_SCRIPT,
	clip_to_bounds := true
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if floor_map == null:
		return cells
	var minimum := Vector2i(
		mini(first_corner.x, second_corner.x),
		mini(first_corner.y, second_corner.y)
	)
	var maximum := Vector2i(
		maxi(first_corner.x, second_corner.x),
		maxi(first_corner.y, second_corner.y)
	)
	for z_coordinate in range(minimum.y, maximum.y + 1):
		for x_coordinate in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(x_coordinate, z_coordinate)
			if not clip_to_bounds or floor_map.is_in_bounds(cell):
				cells.append(cell)
	return cells


## Returns every cell centre crossed by a brush drag so fast pointer motion cannot leave gaps.
static func stroke_centres(first_cell: Vector2i, last_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var current := first_cell
	var delta_x := absi(last_cell.x - first_cell.x)
	var step_x := 1 if first_cell.x < last_cell.x else -1
	var delta_z := -absi(last_cell.y - first_cell.y)
	var step_z := 1 if first_cell.y < last_cell.y else -1
	var error := delta_x + delta_z
	while true:
		cells.append(current)
		if current == last_cell:
			break
		var doubled_error := error * 2
		if doubled_error >= delta_z:
			error += delta_z
			current.x += step_x
		if doubled_error <= delta_x:
			error += delta_x
			current.y += step_z
	return cells


## Begins a gesture and captures the exact state used by cancel and undo.
func begin(floor_map: FLOOR_MAP_SCRIPT, paint_mode: PaintMode) -> bool:
	if floor_map == null or _active:
		return false
	_floor_map = floor_map
	_paint_mode = paint_mode
	_before_snapshot = floor_map.get_shape_snapshot()
	_touched_cells.clear()
	_active = true
	return true


## Applies another portion of the active gesture while deduplicating self-crossings.
func apply_cells(cells: Array[Vector2i]) -> int:
	if not _active or _floor_map == null:
		return 0
	if _paint_mode == PaintMode.Paint:
		_floor_map.expand_bounds_to_include(cells)
	var new_cell_count := 0
	var exception_lookup: Dictionary[Vector2i, bool] = {}
	for exception_cell in _floor_map.get_presence_snapshot():
		exception_lookup[exception_cell] = true
	var desired_present := _paint_mode == PaintMode.Paint
	for cell in cells:
		if not _floor_map.is_in_bounds(cell) or _touched_cells.has(cell):
			continue
		_touched_cells[cell] = true
		new_cell_count += 1
		if desired_present == _floor_map.default_present:
			exception_lookup.erase(cell)
		else:
			exception_lookup[cell] = true
	_floor_map.apply_presence_snapshot(_cells_from_lookup(exception_lookup))
	return new_cell_count


## Completes the gesture and returns detached before/after snapshots for one undo action.
func finish() -> Dictionary:
	if not _active or _floor_map == null:
		return {}
	_floor_map.compact_storage()
	var result := {
		"before": _before_snapshot.duplicate(true),
		"after": _floor_map.get_shape_snapshot(),
		"touched_count": _touched_cells.size(),
	}
	_clear()
	return result


## Cancels the complete gesture, restoring the state captured by begin.
func cancel() -> bool:
	if not _active or _floor_map == null:
		return false
	_floor_map.apply_shape_snapshot(_before_snapshot)
	_clear()
	return true


## Reports whether a gesture currently owns editable map state.
func is_active() -> bool:
	return _active


func _cells_from_lookup(lookup: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell_value in lookup.keys():
		cells.append(cell_value as Vector2i)
	return cells


func _clear() -> void:
	_floor_map = null
	_before_snapshot.clear()
	_touched_cells.clear()
	_active = false
