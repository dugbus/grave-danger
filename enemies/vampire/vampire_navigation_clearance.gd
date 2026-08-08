extends RefCounted
class_name GDVampireNavigationClearance

const TARGET_WALL_CLEARANCE_MARGIN := 0.02
const DIRECTION_EPSILON_CELL_FRACTION := 0.01

var body: CharacterBody3D
var settings: Resource
var wall_grid_map: GridMap
var wall_item_ids: Dictionary = {}


func configure(
	vampire_body: CharacterBody3D,
	vampire_settings: Resource,
	grid_map: GridMap,
	wall_ids: Dictionary
) -> void:
	body = vampire_body
	settings = vampire_settings
	wall_grid_map = grid_map
	wall_item_ids = wall_ids


func get_direction_epsilon() -> float:
	return maxf(
		get_minimum_world_cell_edge_length() * DIRECTION_EPSILON_CELL_FRACTION,
		0.0001
	)


func get_minimum_world_cell_edge_length() -> float:
	return minf(get_world_cell_edge_length(Vector3i.RIGHT), get_world_cell_edge_length(Vector3i.BACK))


func get_maximum_world_cell_edge_length() -> float:
	return maxf(get_world_cell_edge_length(Vector3i.RIGHT), get_world_cell_edge_length(Vector3i.BACK))


func get_world_cell_edge_length(direction: Vector3i) -> float:
	if wall_grid_map == null:
		return 1.0
	var origin_point := wall_grid_map.to_global(wall_grid_map.map_to_local(Vector3i.ZERO))
	var neighbour_point := wall_grid_map.to_global(wall_grid_map.map_to_local(direction))
	return maxf(origin_point.distance_to(neighbour_point), 0.0001)


func get_wall_clearance_offset(cell: Vector3i) -> Vector3:
	if wall_grid_map == null:
		return Vector3.ZERO
	var offset := Vector3.ZERO
	var required_x_offset := maxf(
		_get_local_body_clearance_x() - wall_grid_map.cell_size.x * 0.5,
		0.0
	)
	var required_z_offset := maxf(
		_get_local_body_clearance_z() - wall_grid_map.cell_size.z * 0.5,
		0.0
	)
	if _is_wall(cell + Vector3i(1, 0, 0)):
		offset.x -= required_x_offset
	if _is_wall(cell + Vector3i(-1, 0, 0)):
		offset.x += required_x_offset
	if _is_wall(cell + Vector3i(0, 0, 1)):
		offset.z -= required_z_offset
	if _is_wall(cell + Vector3i(0, 0, -1)):
		offset.z += required_z_offset
	return offset


func get_body_clear_target_point(cell: Vector3i, world_target: Vector3) -> Vector3:
	if wall_grid_map == null or settings == null:
		return world_target
	var cell_centre := wall_grid_map.map_to_local(cell)
	var local_target := wall_grid_map.to_local(world_target)
	var half_width := wall_grid_map.cell_size.x * 0.5
	var half_depth := wall_grid_map.cell_size.z * 0.5
	var body_clearance_x := _get_local_body_clearance_x()
	var body_clearance_z := _get_local_body_clearance_z()
	var minimum_x := cell_centre.x - half_width
	var maximum_x := cell_centre.x + half_width
	var minimum_z := cell_centre.z - half_depth
	var maximum_z := cell_centre.z + half_depth
	if _is_wall(cell + Vector3i(1, 0, 0)):
		maximum_x -= body_clearance_x
	if _is_wall(cell + Vector3i(-1, 0, 0)):
		minimum_x += body_clearance_x
	if _is_wall(cell + Vector3i(0, 0, 1)):
		maximum_z -= body_clearance_z
	if _is_wall(cell + Vector3i(0, 0, -1)):
		minimum_z += body_clearance_z
	local_target.x = clampf(local_target.x, minimum_x, maximum_x) \
		if minimum_x <= maximum_x else cell_centre.x
	local_target.z = clampf(local_target.z, minimum_z, maximum_z) \
		if minimum_z <= maximum_z else cell_centre.z
	return wall_grid_map.to_global(local_target)


func _get_local_body_clearance_x() -> float:
	return _get_body_clearance_world() / maxf(
		wall_grid_map.global_transform.basis.x.length(), 0.0001
	)


func _get_local_body_clearance_z() -> float:
	return _get_body_clearance_world() / maxf(
		wall_grid_map.global_transform.basis.z.length(), 0.0001
	)


func _get_body_clearance_world() -> float:
	var fallback_radius := float(settings.sight_clearance_radius) if settings != null else 0.0
	if body == null:
		return fallback_radius + TARGET_WALL_CLEARANCE_MARGIN
	var collision_shape := body.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if collision_shape == null or collision_shape.shape == null:
		return fallback_radius + TARGET_WALL_CLEARANCE_MARGIN
	var shape_radius := fallback_radius
	if collision_shape.shape is CapsuleShape3D:
		shape_radius = (collision_shape.shape as CapsuleShape3D).radius
	elif collision_shape.shape is SphereShape3D:
		shape_radius = (collision_shape.shape as SphereShape3D).radius
	elif collision_shape.shape is CylinderShape3D:
		shape_radius = (collision_shape.shape as CylinderShape3D).radius
	var horizontal_scale := maxf(
		collision_shape.global_transform.basis.x.length(),
		collision_shape.global_transform.basis.z.length()
	)
	return shape_radius * horizontal_scale + TARGET_WALL_CLEARANCE_MARGIN


func _is_wall(cell: Vector3i) -> bool:
	return wall_grid_map != null and wall_item_ids.has(wall_grid_map.get_cell_item(cell))
