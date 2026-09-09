@tool
class_name FloorSurfaceRampResolver
extends RefCounted

## Resolves authored transition intent into one shared top-surface description.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


## Builds flat fallback geometry plus validation details for one present cell.
func resolve_cell(
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell: Vector2i,
	cell_size: float
) -> Dictionary:
	if floor_map == null or profile == null or not floor_map.has_floor(cell):
		return {"valid": false, "error": "Cell has no floor surface."}
	var anchor_height := profile.elevation_to_world(floor_map.get_cell_elevation(cell))
	var flat_heights: Array[float] = [
		anchor_height,
		anchor_height,
		anchor_height,
		anchor_height,
	]
	var transition := floor_map.get_cell_transition(cell)
	if transition == MAP_SCRIPT.Transition.Flat:
		return _make_result(true, "", transition, MAP_SCRIPT.LowEdge.None, flat_heights, cell_size)
	if transition != MAP_SCRIPT.Transition.Ramp:
		return _make_result(
			false,
			"Unsupported transition value.",
			transition,
			MAP_SCRIPT.LowEdge.None,
			flat_heights,
			cell_size
		)
	var low_edge := floor_map.get_cell_low_edge(cell)
	if not _is_cardinal_edge(low_edge):
		return _make_result(false, "Ramp needs a named low edge.", transition, low_edge, flat_heights, cell_size)
	var run_result := _resolve_run(floor_map, cell, low_edge)
	if not run_result.get("valid", false) as bool:
		return _make_result(
			false,
			run_result.get("error", "Ramp run is invalid.") as String,
			transition,
			low_edge,
			flat_heights,
			cell_size
		)
	var low_cell := run_result["low_landing"] as Vector2i
	var high_cell := run_result["high_landing"] as Vector2i
	var ramp_cells := run_result["ramp_cells"] as Array[Vector2i]
	var low_elevation := floor_map.get_cell_elevation(low_cell)
	var high_elevation := floor_map.get_cell_elevation(high_cell)
	if high_elevation <= low_elevation:
		return _make_result(
			false,
			"Ramp low edge does not face the lower landing.",
			transition,
			low_edge,
			flat_heights,
			cell_size
		)
	var low_height := profile.elevation_to_world(low_elevation)
	var high_height := profile.elevation_to_world(high_elevation)
	var run_index := ramp_cells.find(cell)
	var run_length := ramp_cells.size()
	var height_delta := high_height - low_height
	var cell_low_height := low_height + height_delta * float(run_index) / float(run_length)
	var cell_high_height := low_height + height_delta * float(run_index + 1) / float(run_length)
	var ramp_heights := _ramp_corner_heights(low_edge, cell_low_height, cell_high_height)
	var result := _make_result(true, "", transition, low_edge, ramp_heights, cell_size)
	result["low_cell"] = low_cell
	result["high_cell"] = high_cell
	result["low_elevation"] = low_elevation
	result["high_elevation"] = high_elevation
	result["ramp_cells"] = ramp_cells
	result["run_index"] = run_index
	result["run_length"] = run_length
	return result


## Reports whether an edge belongs to a valid continuous ramp run instead of a ledge.
func is_continuous_connection(
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	from_cell: Vector2i,
	to_cell: Vector2i,
	cell_size: float
) -> bool:
	var offset := to_cell - from_cell
	if absi(offset.x) + absi(offset.y) != 1:
		return false
	var from_transition := floor_map.get_cell_transition(from_cell)
	var to_transition := floor_map.get_cell_transition(to_cell)
	if from_transition != MAP_SCRIPT.Transition.Ramp \
			and to_transition != MAP_SCRIPT.Transition.Ramp:
		return false
	if from_transition == MAP_SCRIPT.Transition.Ramp:
		var from_slope_axis := edge_offset(floor_map.get_cell_low_edge(from_cell))
		if offset != from_slope_axis and offset != -from_slope_axis:
			return false
	if to_transition == MAP_SCRIPT.Transition.Ramp:
		var to_slope_axis := edge_offset(floor_map.get_cell_low_edge(to_cell))
		if offset != to_slope_axis and offset != -to_slope_axis:
			return false
	var from_result := resolve_cell(floor_map, profile, from_cell, cell_size)
	var to_result := resolve_cell(floor_map, profile, to_cell, cell_size)
	if not from_result.get("valid", false) as bool or not to_result.get("valid", false) as bool:
		return false
	var from_local := Vector2(0.5 + float(offset.x) * 0.5, 0.5 + float(offset.y) * 0.5)
	var to_local := Vector2.ONE - from_local
	return is_equal_approx(sample_height(from_result, from_local), sample_height(to_result, to_local))


## Infers which side of a candidate ramp cell faces the lower of two opposite landings.
func infer_low_edge(
	floor_map: MAP_SCRIPT,
	ramp_cell: Vector2i,
	axis_neighbour: Vector2i
) -> MAP_SCRIPT.LowEdge:
	if floor_map == null or not floor_map.has_floor(ramp_cell):
		return MAP_SCRIPT.LowEdge.None
	var offset := axis_neighbour - ramp_cell
	if absi(offset.x) + absi(offset.y) != 1:
		return MAP_SCRIPT.LowEdge.None
	var opposite_neighbour := ramp_cell - offset
	if not floor_map.has_floor(axis_neighbour) or not floor_map.has_floor(opposite_neighbour):
		return MAP_SCRIPT.LowEdge.None
	var target_elevation := floor_map.get_cell_elevation(axis_neighbour)
	var opposite_elevation := floor_map.get_cell_elevation(opposite_neighbour)
	if target_elevation == opposite_elevation:
		return MAP_SCRIPT.LowEdge.None
	return offset_to_edge(offset) \
		if target_elevation < opposite_elevation else offset_to_edge(-offset)


## Returns all invalid authored transitions as stable cell-prefixed editor messages.
func validate_map(
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	cell_size: float
) -> Array[String]:
	var errors: Array[String] = []
	if floor_map == null or profile == null:
		return errors
	for cell in floor_map.get_present_cells():
		if floor_map.get_cell_transition(cell) == MAP_SCRIPT.Transition.Flat:
			continue
		var result := resolve_cell(floor_map, profile, cell, cell_size)
		if not result.get("valid", false) as bool:
			errors.append("Ramp %s: %s" % [cell, result.get("error", "Invalid ramp.")])
	return errors


## Samples the planar top description at cell-local X/Z coordinates from zero to one.
func sample_height(result: Dictionary, local_xz: Vector2) -> float:
	var heights := result.get("corner_heights", []) as Array[float]
	if heights.size() != 4:
		return -INF
	var u := clampf(local_xz.x, 0.0, 1.0)
	var v := clampf(local_xz.y, 0.0, 1.0)
	return (
		heights[0] * (1.0 - u) * (1.0 - v)
		+ heights[1] * (1.0 - u) * v
		+ heights[2] * u * v
		+ heights[3] * u * (1.0 - v)
	)


## Returns the world-horizontal offset associated with a named cell edge.
func edge_offset(edge: MAP_SCRIPT.LowEdge) -> Vector2i:
	match edge:
		MAP_SCRIPT.LowEdge.North:
			return Vector2i.UP
		MAP_SCRIPT.LowEdge.East:
			return Vector2i.RIGHT
		MAP_SCRIPT.LowEdge.South:
			return Vector2i.DOWN
		MAP_SCRIPT.LowEdge.West:
			return Vector2i.LEFT
		_:
			return Vector2i.ZERO


## Returns the named edge reached by one cardinal grid offset.
func offset_to_edge(offset: Vector2i) -> MAP_SCRIPT.LowEdge:
	match offset:
		Vector2i.UP:
			return MAP_SCRIPT.LowEdge.North
		Vector2i.RIGHT:
			return MAP_SCRIPT.LowEdge.East
		Vector2i.DOWN:
			return MAP_SCRIPT.LowEdge.South
		Vector2i.LEFT:
			return MAP_SCRIPT.LowEdge.West
		_:
			return MAP_SCRIPT.LowEdge.None


func _resolve_run(
	floor_map: MAP_SCRIPT,
	cell: Vector2i,
	low_edge: MAP_SCRIPT.LowEdge
) -> Dictionary:
	var low_direction := edge_offset(low_edge)
	var low_ramp_cell := cell
	var cursor := cell + low_direction
	while floor_map.has_floor(cursor) \
			and floor_map.get_cell_transition(cursor) == MAP_SCRIPT.Transition.Ramp:
		if floor_map.get_cell_low_edge(cursor) != low_edge:
			return {"valid": false, "error": "Connected ramp cells must share one low edge."}
		low_ramp_cell = cursor
		cursor += low_direction
	var low_landing := cursor
	var high_ramp_cell := cell
	cursor = cell - low_direction
	while floor_map.has_floor(cursor) \
			and floor_map.get_cell_transition(cursor) == MAP_SCRIPT.Transition.Ramp:
		if floor_map.get_cell_low_edge(cursor) != low_edge:
			return {"valid": false, "error": "Connected ramp cells must share one low edge."}
		high_ramp_cell = cursor
		cursor -= low_direction
	var high_landing := cursor
	if not floor_map.has_floor(low_landing) or not floor_map.has_floor(high_landing):
		return {"valid": false, "error": "Ramp run needs present low and high landing cells."}
	if floor_map.get_cell_transition(low_landing) != MAP_SCRIPT.Transition.Flat \
			or floor_map.get_cell_transition(high_landing) != MAP_SCRIPT.Transition.Flat:
		return {"valid": false, "error": "Ramp run endpoints must be flat landing cells."}
	var ramp_cells: Array[Vector2i] = []
	cursor = low_ramp_cell
	while true:
		ramp_cells.append(cursor)
		if cursor == high_ramp_cell:
			break
		cursor -= low_direction
		if ramp_cells.size() > floor_map.dimensions.x * floor_map.dimensions.y:
			return {"valid": false, "error": "Ramp run could not resolve its endpoints."}
	return {
		"high_landing": high_landing,
		"low_landing": low_landing,
		"ramp_cells": ramp_cells,
		"valid": true,
	}


func _make_result(
	valid: bool,
	error: String,
	transition: MAP_SCRIPT.Transition,
	low_edge: MAP_SCRIPT.LowEdge,
	corner_heights: Array[float],
	cell_size: float
) -> Dictionary:
	var safe_size := maxf(cell_size, 0.01)
	var corner_positions: Array[Vector3] = [
		Vector3(0.0, corner_heights[0], 0.0),
		Vector3(0.0, corner_heights[1], safe_size),
		Vector3(safe_size, corner_heights[2], safe_size),
		Vector3(safe_size, corner_heights[3], 0.0),
	]
	var surface_normal := (corner_positions[1] - corner_positions[0]).cross(
		corner_positions[2] - corner_positions[0]
	).normalized()
	return {
		"corner_heights": corner_heights,
		"error": error,
		"low_edge": low_edge,
		"normal": surface_normal,
		"transition": transition,
		"valid": valid,
	}


func _ramp_corner_heights(
	low_edge: MAP_SCRIPT.LowEdge,
	low_height: float,
	high_height: float
) -> Array[float]:
	match low_edge:
		MAP_SCRIPT.LowEdge.North:
			return [low_height, high_height, high_height, low_height]
		MAP_SCRIPT.LowEdge.East:
			return [high_height, high_height, low_height, low_height]
		MAP_SCRIPT.LowEdge.South:
			return [high_height, low_height, low_height, high_height]
		_:
			return [low_height, low_height, high_height, high_height]


func _is_cardinal_edge(edge: MAP_SCRIPT.LowEdge) -> bool:
	return edge in [
		MAP_SCRIPT.LowEdge.North,
		MAP_SCRIPT.LowEdge.East,
		MAP_SCRIPT.LowEdge.South,
		MAP_SCRIPT.LowEdge.West,
	]
