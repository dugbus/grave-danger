extends RefCounted
class_name GDGroundSpawn

## Shared spawn correction for placing ground enemies on a nearby walkable surface.

const SETTINGS := preload("res://enemies/ground_spawn_settings.tres")


static func snap_to_nearby_floor(
	world_node: Node3D,
	floor_sample_node: Node3D,
	placement_node: Node3D,
	collision_mask: int,
	minimum_floor_normal_y: float,
	excluded_bodies: Array[RID] = []
) -> bool:
	if world_node == null or floor_sample_node == null or placement_node == null:
		return false
	var world := world_node.get_world_3d()
	if world == null:
		return false

	var sample_position := floor_sample_node.global_position
	var query := PhysicsRayQueryParameters3D.create(
		sample_position + Vector3.UP * SETTINGS.below_floor_search_distance,
		sample_position + Vector3.DOWN * (
			SETTINGS.above_floor_search_distance + SETTINGS.floor_contact_epsilon
		),
		collision_mask,
		excluded_bodies
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false

	var floor_normal := hit.get("normal", Vector3.ZERO) as Vector3
	var floor_position := hit.get("position", sample_position) as Vector3
	var vertical_correction := floor_position.y - sample_position.y
	if floor_normal.y < minimum_floor_normal_y \
			or vertical_correction > SETTINGS.below_floor_search_distance \
			or vertical_correction < -SETTINGS.above_floor_search_distance:
		return false

	placement_node.global_position += Vector3.UP * vertical_correction
	return true
