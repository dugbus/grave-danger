@tool
class_name FloorMap
extends Resource

## Authoritative finite grid data for a FloorSurface.

const INVALID_ELEVATION := -2147483648
const INVALID_STYLE_INDEX := -1

enum Transition {
	Flat,
	Ramp,
}

enum LowEdge {
	None,
	North,
	East,
	South,
	West,
}

## Lowest inclusive authored cell coordinate.
@export var minimum_cell := Vector2i.ZERO
## Number of authored cells along X and Z; values must be positive.
@export var dimensions := Vector2i(1, 1)
## Baseline occupancy used by every in-bounds cell without an exception.
@export var default_present := false
## Sorted cells whose occupancy is the opposite of the baseline.
@export var presence_exceptions: Array[Vector2i] = []
## Baseline absolute elevation, measured in FloorElevationProfile units.
@export var default_elevation := 0
## Sparse absolute-elevation overrides, retained even for absent cells.
@export var elevation_overrides: Dictionary[Vector2i, int] = {}
## Baseline index into the owning FloorSurface style palette.
@export_range(0, 1024, 1, "or_greater") var default_style_index := 0
## Sparse style overrides, including optional appearance intent for absent cells.
@export var style_overrides: Dictionary[Vector2i, int] = {}
## Sparse named transition overrides reserved for authored ramps.
@export var transition_overrides: Dictionary[Vector2i, int] = {}
## Sparse named low-edge orientations reserved for authored transitions.
@export var low_edge_overrides: Dictionary[Vector2i, int] = {}


## Returns whether a cell is inside the finite authored rectangle.
func is_in_bounds(cell: Vector2i) -> bool:
	if dimensions.x <= 0 or dimensions.y <= 0:
		return false
	return (
		cell.x >= minimum_cell.x
		and cell.y >= minimum_cell.y
		and cell.x < minimum_cell.x + dimensions.x
		and cell.y < minimum_cell.y + dimensions.y
	)


## Returns whether an in-bounds cell owns a walkable top; outside is always absent.
func has_floor(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and (default_present != presence_exceptions.has(cell))


## Changes occupancy while keeping the serialized exception list deterministic.
func set_floor_present(cell: Vector2i, present: bool) -> bool:
	if not is_in_bounds(cell) or has_floor(cell) == present:
		return false
	if present == default_present:
		presence_exceptions.erase(cell)
	else:
		presence_exceptions.append(cell)
	presence_exceptions.sort_custom(_is_cell_before)
	emit_changed()
	return true


## Returns a detached, deterministically ordered occupancy snapshot for editor undo.
func get_presence_snapshot() -> Array[Vector2i]:
	return presence_exceptions.duplicate()


## Returns detached occupancy and bounds state for a complete editor gesture.
func get_shape_snapshot() -> Dictionary:
	return {
		"minimum_cell": minimum_cell,
		"dimensions": dimensions,
		"default_present": default_present,
		"presence_exceptions": get_presence_snapshot(),
	}


## Restores occupancy and bounds together so expansion participates in undo and cancellation.
func apply_shape_snapshot(snapshot: Dictionary) -> bool:
	var restored_minimum := snapshot.get("minimum_cell", minimum_cell) as Vector2i
	var restored_dimensions := snapshot.get("dimensions", dimensions) as Vector2i
	restored_dimensions.x = maxi(restored_dimensions.x, 1)
	restored_dimensions.y = maxi(restored_dimensions.y, 1)
	var restored_default := snapshot.get("default_present", default_present) as bool
	var restored_cells := snapshot.get(
		"presence_exceptions",
		presence_exceptions
	) as Array[Vector2i]
	var bounds_changed := restored_minimum != minimum_cell or restored_dimensions != dimensions
	var baseline_changed := restored_default != default_present
	minimum_cell = restored_minimum
	dimensions = restored_dimensions
	default_present = restored_default
	var unique_cells: Dictionary[Vector2i, bool] = {}
	for cell in restored_cells:
		if is_in_bounds(cell):
			unique_cells[cell] = true
	var sanitized_cells := _cells_from_lookup(unique_cells)
	if not bounds_changed and not baseline_changed and sanitized_cells == presence_exceptions:
		return false
	presence_exceptions = sanitized_cells
	emit_changed()
	return true


## Restores an occupancy snapshot, discarding duplicates and cells outside the authored bounds.
func apply_presence_snapshot(cells: Array[Vector2i]) -> bool:
	var unique_cells: Dictionary[Vector2i, bool] = {}
	for cell in cells:
		if is_in_bounds(cell):
			unique_cells[cell] = true
	var sanitized_cells := _cells_from_lookup(unique_cells)
	if sanitized_cells == presence_exceptions:
		return false
	presence_exceptions = sanitized_cells
	emit_changed()
	return true


## Grows the finite storage rectangle while keeping every formerly outside cell absent.
func expand_bounds_to_include(cells: Array[Vector2i]) -> bool:
	if cells.is_empty():
		return false
	var old_minimum := minimum_cell
	var old_dimensions := dimensions
	var old_maximum := minimum_cell + dimensions - Vector2i.ONE
	var expanded_minimum := old_minimum
	var expanded_maximum := old_maximum
	for cell in cells:
		expanded_minimum.x = mini(expanded_minimum.x, cell.x)
		expanded_minimum.y = mini(expanded_minimum.y, cell.y)
		expanded_maximum.x = maxi(expanded_maximum.x, cell.x)
		expanded_maximum.y = maxi(expanded_maximum.y, cell.y)
	if expanded_minimum == old_minimum and expanded_maximum == old_maximum:
		return false
	# Convert a dense default-present map before expansion. This avoids serializing every
	# untouched cell in a potentially enormous rectangle when a designer paints far away.
	var retained_cells := get_present_cells() if default_present else get_presence_snapshot()
	minimum_cell = expanded_minimum
	dimensions = expanded_maximum - expanded_minimum + Vector2i.ONE
	if default_present:
		default_present = false
	presence_exceptions = retained_cells
	emit_changed()
	return true


## Removes unused exterior bounds and selects the smaller equivalent occupancy representation.
func compact_storage() -> bool:
	var present_cells := get_present_cells()
	var extent_lookup: Dictionary[Vector2i, bool] = {}
	for cell in present_cells:
		extent_lookup[cell] = true

	var compact_minimum := Vector2i.ZERO
	var compact_dimensions := Vector2i.ONE
	if not extent_lookup.is_empty():
		var extent_cells := _cells_from_lookup(extent_lookup)
		var compact_maximum := extent_cells[0]
		compact_minimum = compact_maximum
		for cell in extent_cells:
			compact_minimum.x = mini(compact_minimum.x, cell.x)
			compact_minimum.y = mini(compact_minimum.y, cell.y)
			compact_maximum.x = maxi(compact_maximum.x, cell.x)
			compact_maximum.y = maxi(compact_maximum.y, cell.y)
		compact_dimensions = compact_maximum - compact_minimum + Vector2i.ONE

	var cell_count := compact_dimensions.x * compact_dimensions.y
	var compact_default := present_cells.size() * 2 > cell_count
	var present_lookup: Dictionary[Vector2i, bool] = {}
	for cell in present_cells:
		present_lookup[cell] = true
	var compact_exceptions: Array[Vector2i] = []
	if compact_default:
		for z_coordinate in range(compact_minimum.y, compact_minimum.y + compact_dimensions.y):
			for x_coordinate in range(compact_minimum.x, compact_minimum.x + compact_dimensions.x):
				var cell := Vector2i(x_coordinate, z_coordinate)
				if not present_lookup.has(cell):
					compact_exceptions.append(cell)
	else:
		compact_exceptions = present_cells

	if minimum_cell == compact_minimum \
		and dimensions == compact_dimensions \
		and default_present == compact_default \
		and presence_exceptions == compact_exceptions:
		return false
	minimum_cell = compact_minimum
	dimensions = compact_dimensions
	default_present = compact_default
	presence_exceptions = compact_exceptions
	elevation_overrides = _bounded_integer_overrides(elevation_overrides)
	style_overrides = _bounded_integer_overrides(style_overrides)
	transition_overrides = _bounded_integer_overrides(transition_overrides)
	low_edge_overrides = _bounded_integer_overrides(low_edge_overrides)
	emit_changed()
	return true


## Creates an independent scene-local map suitable for an explicit Make Unique workflow.
func create_unique_copy() -> Resource:
	var unique_map := duplicate(true)
	unique_map.resource_local_to_scene = true
	return unique_map


## Returns a present cell's authored elevation or INVALID_ELEVATION when no top exists.
func get_cell_elevation(cell: Vector2i) -> int:
	if not has_floor(cell):
		return INVALID_ELEVATION
	return elevation_overrides.get(cell, default_elevation) as int


## Stores absolute elevation intent for any in-bounds cell, including an absent one.
func set_cell_elevation(cell: Vector2i, elevation: int) -> bool:
	if not is_in_bounds(cell):
		return false
	if elevation == default_elevation:
		elevation_overrides.erase(cell)
	else:
		elevation_overrides[cell] = elevation
	elevation_overrides = _sort_integer_overrides(elevation_overrides)
	emit_changed()
	return true


## Returns detached, deterministically ordered elevation overrides for editor undo.
func get_elevation_snapshot() -> Dictionary[Vector2i, int]:
	return elevation_overrides.duplicate()


## Restores elevation overrides while rejecting entries outside current tile storage.
func apply_elevation_snapshot(overrides: Dictionary[Vector2i, int]) -> bool:
	var sanitized: Dictionary[Vector2i, int] = {}
	for cell_value in overrides.keys():
		var cell := cell_value as Vector2i
		if not is_in_bounds(cell):
			continue
		var elevation := overrides[cell] as int
		if elevation != default_elevation:
			sanitized[cell] = elevation
	sanitized = _sort_integer_overrides(sanitized)
	if sanitized == elevation_overrides:
		return false
	elevation_overrides = sanitized
	emit_changed()
	return true


## Returns an in-bounds cell's style intent, whether or not a top is present.
func get_cell_style(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return INVALID_STYLE_INDEX
	return style_overrides.get(cell, default_style_index) as int


## Stores style intent for any in-bounds cell, including an absent one.
func set_cell_style(cell: Vector2i, style_index: int) -> bool:
	if not is_in_bounds(cell):
		return false
	if style_index == default_style_index:
		style_overrides.erase(cell)
	else:
		style_overrides[cell] = style_index
	style_overrides = _sort_integer_overrides(style_overrides)
	emit_changed()
	return true


## Returns detached, deterministically ordered style overrides for editor undo.
func get_style_snapshot() -> Dictionary[Vector2i, int]:
	return style_overrides.duplicate()


## Restores style intent while rejecting entries outside current tile storage.
func apply_style_snapshot(overrides: Dictionary[Vector2i, int]) -> bool:
	var sanitized: Dictionary[Vector2i, int] = {}
	for cell_value in overrides.keys():
		var cell := cell_value as Vector2i
		if not is_in_bounds(cell):
			continue
		var style_index := overrides[cell] as int
		if style_index != default_style_index:
			sanitized[cell] = style_index
	sanitized = _sort_integer_overrides(sanitized)
	if sanitized == style_overrides:
		return false
	style_overrides = sanitized
	emit_changed()
	return true


## Returns the named transition authored for a present cell; absent cells are flat.
func get_cell_transition(cell: Vector2i) -> Transition:
	if not has_floor(cell):
		return Transition.Flat
	return int(transition_overrides.get(cell, Transition.Flat)) as Transition


## Returns the named low edge authored for a present cell; absent cells have none.
func get_cell_low_edge(cell: Vector2i) -> LowEdge:
	if not has_floor(cell):
		return LowEdge.None
	return int(low_edge_overrides.get(cell, LowEdge.None)) as LowEdge


## Returns present cells in stable Z-major then X-major order.
func get_present_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for z_coordinate in range(minimum_cell.y, minimum_cell.y + maxi(dimensions.y, 0)):
		for x_coordinate in range(minimum_cell.x, minimum_cell.x + maxi(dimensions.x, 0)):
			var cell := Vector2i(x_coordinate, z_coordinate)
			if has_floor(cell):
				cells.append(cell)
	return cells


## Reports style references that do not resolve against the owning palette.
func validate_palette_size(palette_size: int) -> Array[String]:
	var errors: Array[String] = []
	if palette_size <= 0:
		errors.append("FloorSurface needs at least one FloorStyle.")
		return errors
	if default_style_index < 0 or default_style_index >= palette_size:
		errors.append(
			"Default style index %d is outside the palette of %d styles."
			% [default_style_index, palette_size]
		)
	for cell in _sorted_override_cells(style_overrides):
		var style_index := style_overrides[cell] as int
		if not is_in_bounds(cell):
			errors.append("Style override %s is outside the authored bounds." % cell)
		elif style_index < 0 or style_index >= palette_size:
			errors.append(
				"Cell %s uses style index %d outside the palette of %d styles."
				% [cell, style_index, palette_size]
			)
	return errors


## Returns a stable display name for authored transition data.
func get_transition_name(transition: Transition) -> String:
	match transition:
		Transition.Ramp:
			return "Ramp"
		_:
			return "Flat"


func _sort_integer_overrides(
	overrides: Dictionary[Vector2i, int]
) -> Dictionary[Vector2i, int]:
	var sorted: Dictionary[Vector2i, int] = {}
	for cell in _sorted_override_cells(overrides):
		sorted[cell] = overrides[cell]
	return sorted


func _sorted_override_cells(overrides: Dictionary[Vector2i, int]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell_value in overrides.keys():
		cells.append(cell_value as Vector2i)
	cells.sort_custom(_is_cell_before)
	return cells


func _cells_from_lookup(lookup: Dictionary[Vector2i, bool]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell_value in lookup.keys():
		cells.append(cell_value as Vector2i)
	cells.sort_custom(_is_cell_before)
	return cells


func _bounded_integer_overrides(
	overrides: Dictionary[Vector2i, int]
) -> Dictionary[Vector2i, int]:
	var bounded: Dictionary[Vector2i, int] = {}
	for cell in _sorted_override_cells(overrides):
		if is_in_bounds(cell):
			bounded[cell] = overrides[cell]
	return bounded


func _is_cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)
