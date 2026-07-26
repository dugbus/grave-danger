extends ShapeCast3D
class_name GDVampireSenses


signal player_visibility_changed(visible: bool)

const GAMEPLAY_PROCESS_GROUP: StringName = &"deterministic_gameplay_process"

## Low occlusion ray used when the body-width sight sweep brushes a wall edge.
@export var visual_sight_ray_path: NodePath = ^"VisualSightRay"

var player: Node3D
var settings: Resource
var wall_grid_map: GridMap
var wall_item_ids: Dictionary = {}
var wall_grid_y := 0
var player_visible := false
var player_direct_path_clear := false
var visibility_sample_count := 0

@onready var visual_sight_ray := get_node_or_null(visual_sight_ray_path) as RayCast3D


func _ready() -> void:
	# Sample after ordinary character movement so a player crossing a sightline is
	# observed during that same physics frame, independently of the hunt state.
	add_to_group(GAMEPLAY_PROCESS_GROUP)
	process_physics_priority = 100
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	sample_player_visibility()


func configure(target_player: Node3D, vampire_settings: Resource) -> void:
	reset_runtime_state()
	player = target_player
	settings = vampire_settings
	var vampire_body := get_parent() as CollisionObject3D
	if visual_sight_ray != null and vampire_body != null:
		visual_sight_ray.add_exception(vampire_body)
	if settings != null:
		position.y = settings.sight_origin_height
		var clearance_shape := shape as SphereShape3D
		if clearance_shape != null:
			clearance_shape.radius = _get_direct_path_clearance_radius()
	enabled = player != null
	set_physics_process(enabled)
	sample_player_visibility()


## Clears retained visibility so a respawn cannot inherit a previous player's observation.
func reset_runtime_state() -> void:
	player_visible = false
	player_direct_path_clear = false
	visibility_sample_count = 0
	target_position = Vector3.ZERO


func set_wall_grid_map(grid_map: GridMap) -> void:
	wall_grid_map = grid_map
	wall_item_ids.clear()
	wall_grid_y = 0
	if wall_grid_map == null:
		return
	wall_item_ids = _get_wall_item_ids(wall_grid_map)
	wall_grid_y = _get_wall_grid_y(wall_grid_map)


## Returns cardinal passage directions clear enough for the vampire to inspect visually.
func get_clear_scan_directions(probe_distance: float) -> Array[Vector3]:
	var clear_directions: Array[Vector3] = []
	var cardinal_directions: Array[Vector3] = [
		Vector3.FORWARD,
		Vector3.RIGHT,
		Vector3.BACK,
		Vector3.LEFT,
	]
	for direction in cardinal_directions:
		var probe_target := global_position + direction * maxf(probe_distance, 0.1)
		if _grid_corridor_is_clear(probe_target):
			clear_directions.append(direction)
	return clear_directions


## Returns whether the floor-level body sweep or its wall-occluded visual ray sees the player.
func can_see_player() -> bool:
	player_direct_path_clear = false
	if player == null or settings == null or not is_instance_valid(player):
		return false

	var sight_target := Vector3(
		player.global_position.x,
		global_position.y,
		player.global_position.z
	)
	var sight_offset: Vector3 = sight_target - global_position
	if sight_offset.length() > settings.sight_distance:
		return false

	if _grid_corridor_is_clear(sight_target):
		target_position = to_local(sight_target)
		force_shapecast_update()
		player_direct_path_clear = _cast_reaches_player_without_blockers()
		if player_direct_path_clear:
			return true

	# Visual acquisition samples across the narrower player's body. Navigation
	# independently decides whether the Vampire's wider body can take the same line.
	return _visual_sight_reaches_player(sight_target)


## Returns whether current sight proves that a possible player position is unoccupied.
func can_verify_position_is_empty(world_position: Vector3) -> bool:
	if settings == null or visual_sight_ray == null:
		return false

	var sight_target := Vector3(
		world_position.x,
		global_position.y,
		world_position.z
	)
	var sight_offset := sight_target - global_position
	sight_offset.y = 0.0
	if sight_offset.length() > float(settings.sight_distance) \
			or not _grid_visual_line_is_clear(sight_target):
		return false

	visual_sight_ray.target_position = visual_sight_ray.to_local(sight_target)
	visual_sight_ray.force_raycast_update()
	if visual_sight_ray.is_colliding() \
			and _collider_belongs_to_player(visual_sight_ray.get_collider() as Node):
		return false
	return not visual_sight_ray.is_colliding()


## Samples sight immediately and emits only when continuous visibility changes.
func sample_player_visibility() -> bool:
	visibility_sample_count += 1
	var current_visibility := can_see_player()
	if current_visibility == player_visible:
		return player_visible
	player_visible = current_visibility
	player_visibility_changed.emit(player_visible)
	return player_visible


## Returns the result retained by the most recent continuous physics sample.
func is_player_visible() -> bool:
	return player_visible


## Returns whether the Vampire's full body can take the current direct line to the player.
func is_player_direct_path_clear() -> bool:
	return player_direct_path_clear


## Returns how many continuous sight samples have run for diagnostics and tests.
func get_visibility_sample_count() -> int:
	return visibility_sample_count


func _grid_corridor_is_clear(sight_target: Vector3) -> bool:
	return _grid_line_is_clear(
		sight_target,
		[-_get_direct_path_clearance_radius(), 0.0, _get_direct_path_clearance_radius()]
	)


func _grid_visual_line_is_clear(sight_target: Vector3) -> bool:
	if wall_grid_map == null:
		return true
	var ignored_cells: Array[Vector3i] = [
		_world_position_to_wall_cell(global_position),
		_world_position_to_wall_cell(sight_target),
	]
	return _grid_line_is_clear(sight_target, [0.0], ignored_cells)


func _grid_line_is_clear(
		sight_target: Vector3,
		clearance_offsets: Array[float],
		ignored_cells: Array[Vector3i] = []
) -> bool:
	if wall_grid_map == null:
		return true

	var sight_offset := sight_target - global_position
	sight_offset.y = 0.0
	var sight_distance := sight_offset.length()
	if sight_distance <= 0.001:
		return true

	var direction := sight_offset / sight_distance
	var perpendicular := Vector3(-direction.z, 0.0, direction.x)
	var minimum_cell_size := minf(
		wall_grid_map.cell_size.x,
		wall_grid_map.cell_size.z
	)
	var sample_spacing := maxf(minimum_cell_size * 0.2, 0.05)
	var sample_count := maxi(ceili(sight_distance / sample_spacing), 1)
	for sample_index in range(sample_count + 1):
		var progress := float(sample_index) / float(sample_count)
		var centre := global_position.lerp(sight_target, progress)
		for clearance_offset in clearance_offsets:
			var sample_position: Vector3 = centre + perpendicular * clearance_offset
			if ignored_cells.has(_world_position_to_wall_cell(sample_position)):
				continue
			if _world_position_is_wall(sample_position):
				return false
	return true


func _cast_reaches_player_without_blockers() -> bool:
	if not is_colliding():
		return false
	var hits_player := false
	for collision_index in get_collision_count():
		if _collider_belongs_to_player(get_collider(collision_index) as Node):
			hits_player = true
			continue
		# The sweep intentionally overlaps walkable ground on uneven floor tiles;
		# only predominantly horizontal surfaces can catch the Vampire's body.
		if absf(get_collision_normal(collision_index).y) < 0.5:
			return false
	return hits_player


func _get_direct_path_clearance_radius() -> float:
	if settings == null:
		return 0.0
	return maxf(
		float(settings.sight_clearance_radius) \
			+ float(settings.direct_path_clearance_margin),
		0.0
	)


func _visual_sight_reaches_player(sight_target: Vector3) -> bool:
	var sight_offset := sight_target - global_position
	sight_offset.y = 0.0
	if sight_offset.is_zero_approx():
		return _sight_ray_hits_player(sight_target)

	var perpendicular := Vector3(
		-sight_offset.z,
		0.0,
		sight_offset.x
	).normalized()
	var sample_half_width := maxf(
		float(settings.visual_sight_sample_half_width),
		0.0
	)
	var sight_targets: Array[Vector3] = [
		sight_target,
		sight_target + perpendicular * sample_half_width,
		sight_target - perpendicular * sample_half_width,
	]
	for sample_target in sight_targets:
		if not _grid_visual_line_is_clear(sample_target):
			continue
		if _sight_ray_hits_player(sample_target):
			return true
	return false


func _sight_ray_hits_player(sight_target: Vector3) -> bool:
	if visual_sight_ray == null:
		return false
	var ray_offset := sight_target - global_position
	var ray_target := sight_target
	if not ray_offset.is_zero_approx():
		# Side samples end inside the player's rounded capsule. Extending through it
		# ensures the ray crosses the visible body instead of stopping at its edge.
		ray_target += ray_offset.normalized() * maxf(
			float(settings.visual_sight_sample_half_width),
			0.0
		)
	visual_sight_ray.target_position = visual_sight_ray.to_local(ray_target)
	visual_sight_ray.force_raycast_update()
	return visual_sight_ray.is_colliding() \
		and _collider_belongs_to_player(visual_sight_ray.get_collider() as Node)


func _collider_belongs_to_player(collider: Node) -> bool:
	while collider != null:
		if collider == player:
			return true
		collider = collider.get_parent()
	return false


func _world_position_is_wall(world_position: Vector3) -> bool:
	var cell := _world_position_to_wall_cell(world_position)
	var item_id := wall_grid_map.get_cell_item(cell)
	return wall_item_ids.has(item_id)


func _world_position_to_wall_cell(world_position: Vector3) -> Vector3i:
	var cell := wall_grid_map.local_to_map(wall_grid_map.to_local(world_position))
	cell.y = wall_grid_y
	return cell


func _get_wall_item_ids(grid_map: GridMap) -> Dictionary:
	var item_ids := {}
	if grid_map == null or grid_map.mesh_library == null:
		return item_ids
	for item_id in grid_map.mesh_library.get_item_list():
		if _is_wall_item(grid_map, item_id):
			item_ids[item_id] = true
	return item_ids


func _get_wall_grid_y(grid_map: GridMap) -> int:
	for cell in grid_map.get_used_cells():
		if _is_wall_item(grid_map, grid_map.get_cell_item(cell)):
			return cell.y
	return 0


func _is_wall_item(grid_map: GridMap, item_id: int) -> bool:
	return item_id != GridMap.INVALID_CELL_ITEM \
		and grid_map.mesh_library != null \
		and grid_map.mesh_library.get_item_name(item_id).to_lower().contains("wall")
