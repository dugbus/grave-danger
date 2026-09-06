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


func _is_cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)
