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
		var description := surface.get_cell_surface_description(cell)
		var corner_heights := description.get("corner_heights", []) as Array[float]
		if corner_heights.size() != 4:
			continue
		var candidate_height := (
			corner_heights[0] + corner_heights[1] + corner_heights[2] + corner_heights[3]
		) * 0.25
		var hit: Variant = SHAPE_PAINTER.working_plane_intersection(
			ray_origin,
			ray_direction,
			candidate_height
		)
		if hit == null or surface.world_to_cell(hit as Vector3) != cell:
			continue
		var refined_hit_valid := true
		for _iteration in 3:
			var sample := surface.sample_surface(hit as Vector3)
			if not sample.valid:
				refined_hit_valid = false
				break
			hit = SHAPE_PAINTER.working_plane_intersection(
				ray_origin, ray_direction, sample.world_height
			)
			if hit == null or surface.world_to_cell(hit as Vector3) != cell:
				refined_hit_valid = false
				break
		if not refined_hit_valid:
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
