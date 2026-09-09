class_name FloorSurfaceSample
extends RefCounted

## Typed result returned by FloorSurface.sample_surface().

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

var valid := false
var world_height := -INF
var surface_normal := Vector3.ZERO
var cell := Vector2i.ZERO
var style_index := MAP_SCRIPT.INVALID_STYLE_INDEX
var transition := MAP_SCRIPT.Transition.Flat


## Configures a valid flat sample and returns this result for concise consumers.
func set_flat(
	sampled_cell: Vector2i,
	sampled_height: float,
	sampled_style_index: int,
	sampled_transition: MAP_SCRIPT.Transition
) -> FloorSurfaceSample:
	return set_surface(
		sampled_cell,
		sampled_height,
		Vector3.UP,
		sampled_style_index,
		sampled_transition
	)


## Configures a valid flat or sloped sample from the shared generated-surface description.
func set_surface(
	sampled_cell: Vector2i,
	sampled_height: float,
	sampled_normal: Vector3,
	sampled_style_index: int,
	sampled_transition: MAP_SCRIPT.Transition
) -> FloorSurfaceSample:
	valid = true
	cell = sampled_cell
	world_height = sampled_height
	surface_normal = sampled_normal
	style_index = sampled_style_index
	transition = sampled_transition
	return self


## Configures an invalid sample while retaining the inspected grid cell.
func set_invalid(sampled_cell: Vector2i) -> FloorSurfaceSample:
	valid = false
	cell = sampled_cell
	world_height = -INF
	surface_normal = Vector3.ZERO
	style_index = MAP_SCRIPT.INVALID_STYLE_INDEX
	transition = MAP_SCRIPT.Transition.Flat
	return self
