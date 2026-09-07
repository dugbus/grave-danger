@tool
class_name FloorSurfacePicker
extends RefCounted

## Picks authored elevated tops first and falls back to the default working plane.

const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const SHAPE_PAINTER := preload(
	"res://addons/floor_surface/editor/floor_surface_shape_painter.gd"
)


## Returns the nearest top beneath a viewport ray, or empty-space working-plane position.
static func pick_world_position(
	ray_origin: Vector3,
	ray_direction: Vector3,
	surface: SURFACE_SCRIPT
) -> Variant:
	if surface == null or surface.floor_map == null or surface.elevation_profile == null:
		return null
	var nearest_position: Variant = null
	var nearest_distance := INF
	for cell in surface.floor_map.get_present_cells():
		var hit: Variant = SHAPE_PAINTER.working_plane_intersection(
			ray_origin,
			ray_direction,
			surface.get_world_height_at_cell(cell)
		)
		if hit == null or surface.world_to_cell(hit as Vector3) != cell:
			continue
		var distance := ray_origin.distance_to(hit as Vector3)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_position = hit
	if nearest_position != null:
		return nearest_position
	return SHAPE_PAINTER.working_plane_intersection(
		ray_origin,
		ray_direction,
		surface.elevation_profile.elevation_to_world(surface.floor_map.default_elevation)
	)
