extends Node
class_name GDVampireNavigation

const INVALID_CELL := Vector3i(2147483647, 2147483647, 2147483647)
const RouteSearch := preload("res://enemies/vampire/vampire_route_search.gd")
const NavigationClearance := preload(
	"res://enemies/vampire/vampire_navigation_clearance.gd"
)
const FORWARD_DIRECTION_ALIGNMENT := 0.5
const PREDICTION_FRONTIER_FRACTION := 0.7

enum SearchDirectionMatch {
	None,
	NonBacktracking,
	Forward,
}

enum RouteSearchStatus {
	Complete,
	AlreadyAtTarget,
	Unreachable,
	SearchBudgetExhausted,
	NoGridMap,
}

enum RouteTraversalStatus {
	Idle,
	Following,
	Arrived,
	Failed,
}

var body: CharacterBody3D
var pivot: Node3D
var settings: Resource
var wall_grid_map: GridMap
var wall_item_ids: Dictionary = {}
var grid_bounds := Rect2i()
var wall_grid_y := 0
var route_points: Array[Vector3] = []
var route_index := 0
var target_position := Vector3.ZERO
var has_target := false
var current_horizontal_velocity := Vector3.ZERO
var wall_stall_elapsed := 0.0
var wall_stall_recovery_count := 0
var direct_shortcut_recovery_count := 0
var route_rebuild_count := 0
var movement_start_waypoint_distance := 0.0
var last_movement_direction := Vector3.ZERO
var last_completed_route_direction := Vector3.ZERO
var last_search_direction_match := SearchDirectionMatch.None
var visible_player_position := Vector3.ZERO
var has_visible_player_position := false
var visible_player_direct_path_clear := false
var using_visible_player_shortcut := false
var wall_stall_progress_distance := 0.0
var last_route_search_status := RouteSearchStatus.NoGridMap
var route_traversal_status := RouteTraversalStatus.Idle
var last_frontier_search_was_truncated := false
var _route_search := RouteSearch.new()
var _navigation_clearance := NavigationClearance.new()


func configure(
		vampire_body: CharacterBody3D,
		visual_pivot: Node3D,
		vampire_settings: Resource
) -> void:
	body = vampire_body
	pivot = visual_pivot
	settings = vampire_settings
	_configure_route_search()
	reset_runtime_state()


## Clears every active route and movement observation before this component is reused.
func reset_runtime_state() -> void:
	has_target = false
	route_points.clear()
	route_index = 0
	target_position = Vector3.ZERO
	current_horizontal_velocity = Vector3.ZERO
	wall_stall_elapsed = 0.0
	wall_stall_progress_distance = 0.0
	movement_start_waypoint_distance = 0.0
	last_movement_direction = Vector3.ZERO
	last_completed_route_direction = Vector3.ZERO
	last_search_direction_match = SearchDirectionMatch.None
	last_route_search_status = RouteSearchStatus.NoGridMap
	route_traversal_status = RouteTraversalStatus.Idle
	last_frontier_search_was_truncated = false
	clear_visible_player_position()
	if body != null:
		body.velocity.x = 0.0
		body.velocity.z = 0.0


func set_wall_grid_map(grid_map: GridMap) -> void:
	wall_grid_map = grid_map
	wall_item_ids.clear()
	grid_bounds = Rect2i()
	wall_grid_y = 0
	if wall_grid_map != null:
		wall_item_ids = _get_wall_item_ids(wall_grid_map)
		wall_grid_y = _get_wall_grid_y(wall_grid_map)
		grid_bounds = _get_used_wall_bounds(wall_grid_map, wall_grid_y)
	_configure_route_search()

	if has_target:
		_rebuild_route()


func _configure_route_search() -> void:
	_route_search.configure(settings, wall_grid_map, wall_item_ids, grid_bounds, wall_grid_y)
	_navigation_clearance.configure(body, settings, wall_grid_map, wall_item_ids)


func select_target(noise_position: Vector3) -> bool:
	clear_visible_player_position()
	target_position = noise_position
	has_target = true
	_rebuild_route()
	return route_traversal_status == RouteTraversalStatus.Following


## Builds a safe tile route while retaining a body-clear player line for close interception.
func select_visible_target(
		route_target: Vector3,
		confirmed_player_position: Vector3,
		direct_path_clear: bool
) -> bool:
	target_position = route_target
	visible_player_position = confirmed_player_position
	has_visible_player_position = true
	visible_player_direct_path_clear = direct_path_clear
	has_target = true
	_rebuild_route()
	return route_traversal_status == RouteTraversalStatus.Following


## Refreshes the confirmed player and body-clear line without rebuilding the tile route.
func update_visible_player_position(
		confirmed_player_position: Vector3,
		direct_path_clear: bool
) -> void:
	visible_player_position = confirmed_player_position
	has_visible_player_position = true
	visible_player_direct_path_clear = direct_path_clear


## Moves or extends a visible route endpoint without restarting a straight corridor chase.
func refresh_visible_route_target(confirmed_player_position: Vector3) -> bool:
	if body == null or wall_grid_map == null or not has_target or route_points.is_empty():
		return false

	var current_target_cell := wall_grid_map.local_to_map(
		wall_grid_map.to_local(route_points[-1])
	)
	var confirmed_target_cell := wall_grid_map.local_to_map(
		wall_grid_map.to_local(confirmed_player_position)
	)
	current_target_cell.y = wall_grid_y
	confirmed_target_cell.y = wall_grid_y
	if not _cell_is_in_bounds(confirmed_target_cell) or _is_wall(confirmed_target_cell):
		return false

	if confirmed_target_cell == current_target_cell:
		target_position = confirmed_player_position
		route_points[route_points.size() - 1] = _get_body_clear_target_point(
			confirmed_target_cell,
			confirmed_player_position
		)
		return true

	var cell_step := confirmed_target_cell - current_target_cell
	if absi(cell_step.x) + absi(cell_step.z) != 1:
		return false
	var route_arrival_direction := last_movement_direction
	if route_points.size() >= 2:
		route_arrival_direction = route_points[-1] - route_points[-2]
	route_arrival_direction.y = 0.0
	var step_direction := wall_grid_map.to_global(
		wall_grid_map.map_to_local(confirmed_target_cell)
	) - wall_grid_map.to_global(wall_grid_map.map_to_local(current_target_cell))
	step_direction.y = 0.0
	if route_arrival_direction.is_zero_approx() \
			or route_arrival_direction.normalized().dot(step_direction.normalized()) < 0.5:
		return false

	# The previous destination becomes an ordinary body-clear lane waypoint, while
	# the new endpoint follows the player. No route index or velocity is reset.
	route_points[route_points.size() - 1] = wall_grid_map.to_global(
		wall_grid_map.map_to_local(current_target_cell) \
			+ _get_wall_clearance_offset(current_target_cell)
	)
	route_points.append(
		_get_body_clear_target_point(confirmed_target_cell, confirmed_player_position)
	)
	target_position = confirmed_player_position
	return true


## Removes the close interception exception as soon as the player is no longer visible.
func clear_visible_player_position() -> void:
	has_visible_player_position = false
	visible_player_direct_path_clear = false
	using_visible_player_shortcut = false


func update_velocity(delta: float) -> float:
	if body == null or settings == null:
		return 0.0

	if not has_target:
		using_visible_player_shortcut = false
		_stop_horizontal(delta)
		return current_horizontal_velocity.length()

	_advance_reached_route_points()
	if not has_target:
		using_visible_player_shortcut = false
		_stop_horizontal(delta)
		return current_horizontal_velocity.length()

	var next_position := target_position
	if route_index < route_points.size():
		next_position = route_points[route_index]
	using_visible_player_shortcut = _visible_player_is_closer_than(next_position)
	if using_visible_player_shortcut:
		next_position = visible_player_position

	var direction := next_position - body.global_position
	direction.y = 0.0
	movement_start_waypoint_distance = direction.length()
	if direction.length_squared() <= _get_direction_epsilon_squared():
		_stop_horizontal(delta)
		return current_horizontal_velocity.length()

	direction = direction.normalized()
	last_movement_direction = direction
	# Preserve speed but never lateral momentum when a tile waypoint changes. Blending
	# velocity vectors here cuts inside maze corners even though the route itself is safe.
	var next_speed := move_toward(
		current_horizontal_velocity.length(),
		float(settings.max_speed),
		float(settings.acceleration) * delta
	)
	current_horizontal_velocity = direction * next_speed
	body.velocity.x = current_horizontal_velocity.x
	body.velocity.z = current_horizontal_velocity.z
	_face_direction(direction, delta)
	return current_horizontal_velocity.length()


## Checks completed movement and rebuilds the detailed route after any sustained stall.
func update_after_movement(delta: float) -> void:
	if body == null or settings == null or not has_target:
		wall_stall_elapsed = 0.0
		return

	var collided_with_wall := false
	for collision_index in body.get_slide_collision_count():
		var collision := body.get_slide_collision(collision_index)
		if absf(collision.get_normal().y) < 0.5:
			collided_with_wall = true
			break
	if collided_with_wall and using_visible_player_shortcut:
		_abandon_blocked_visible_shortcut()
		return

	var waypoint := target_position
	if route_index < route_points.size():
		waypoint = route_points[route_index]
	var remaining_offset := waypoint - body.global_position
	remaining_offset.y = 0.0
	var progress_speed := (movement_start_waypoint_distance - remaining_offset.length()) \
		/ maxf(delta, 0.0001)
	_update_wall_stall_recovery(
		delta,
		collided_with_wall,
		progress_speed,
		current_horizontal_velocity.length()
	)


func get_route_points() -> Array[Vector3]:
	return route_points.duplicate()


## Returns the next meaningful movement direction on the active cell-by-cell route.
func get_active_route_direction() -> Vector3:
	if body == null or not has_target:
		return Vector3.ZERO
	var next_route_index := route_index
	while next_route_index < route_points.size():
		var waypoint := route_points[next_route_index]
		var horizontal_offset := waypoint - body.global_position
		horizontal_offset.y = 0.0
		var reached_distance := _get_route_point_reached_distance(next_route_index)
		if horizontal_offset.length() > reached_distance:
			return horizontal_offset.normalized()
		next_route_index += 1

	var target_offset := target_position - body.global_position
	target_offset.y = 0.0
	return target_offset.normalized()


## Reports whether the retained route still ends close enough to catch a visible player.
func is_route_endpoint_within_distance(
		confirmed_player_position: Vector3,
		maximum_distance: float
) -> bool:
	var endpoint := target_position
	if not route_points.is_empty():
		endpoint = route_points.back()
	return Vector2(
		endpoint.x - confirmed_player_position.x,
		endpoint.z - confirmed_player_position.z
	).length() <= maxf(maximum_distance, 0.0)


## Returns how often stall detection has rebuilt the current route for tests and diagnostics.
func get_wall_stall_recovery_count() -> int:
	return wall_stall_recovery_count


## Returns how often a colliding direct chase immediately fell back to its safe tile route.
func get_direct_shortcut_recovery_count() -> int:
	return direct_shortcut_recovery_count


## Returns how often an active destination has caused route calculation for diagnostics.
func get_route_rebuild_count() -> int:
	return route_rebuild_count


## Returns why the most recent route search succeeded or failed.
func get_last_route_search_status() -> RouteSearchStatus:
	return last_route_search_status


## Distinguishes active travel, successful arrival, and route-construction failure.
func get_route_traversal_status() -> RouteTraversalStatus:
	return route_traversal_status


## Reports when reachable-frontier results were cut short by the configured cell budget.
func was_last_frontier_search_truncated() -> bool:
	return last_frontier_search_was_truncated


## Reports whether the visible player is currently closer than the next safe tile waypoint.
func is_using_visible_player_shortcut() -> bool:
	return using_visible_player_shortcut


## Returns the direction travelled during the final approach to the completed target.
func get_last_arrival_direction() -> Vector3:
	return last_completed_route_direction


## Reports how strongly the most recent frontier candidates followed their direction hint.
func get_last_search_direction_match() -> SearchDirectionMatch:
	return last_search_direction_match


## Returns the final maze-path direction between two sound positions.
func get_path_arrival_direction(origin: Vector3, destination: Vector3) -> Vector3:
	if wall_grid_map == null or grid_bounds.size == Vector2i.ZERO:
		var direct_direction := destination - origin
		direct_direction.y = 0.0
		return direct_direction.normalized()

	var origin_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(origin))
	var destination_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(destination))
	origin_cell.y = wall_grid_y
	destination_cell.y = wall_grid_y
	origin_cell = _find_nearest_open_cell(origin_cell, wall_grid_map.to_local(origin))
	destination_cell = _find_nearest_open_cell(
		destination_cell,
		wall_grid_map.to_local(destination)
	)
	if origin_cell == INVALID_CELL or destination_cell == INVALID_CELL:
		return Vector3.ZERO
	var cell_route := _find_cell_route(origin_cell, destination_cell)
	if cell_route.size() < 2:
		return Vector3.ZERO
	var previous_point := wall_grid_map.to_global(
		wall_grid_map.map_to_local(cell_route[cell_route.size() - 2])
	)
	var final_point := wall_grid_map.to_global(
		wall_grid_map.map_to_local(cell_route[cell_route.size() - 1])
	)
	var arrival_direction := final_point - previous_point
	arrival_direction.y = 0.0
	return arrival_direction.normalized()


## Returns the initial maze-path direction from one known layout position to another.
func get_path_departure_direction(origin: Vector3, destination: Vector3) -> Vector3:
	if wall_grid_map == null or grid_bounds.size == Vector2i.ZERO:
		var direct_direction := destination - origin
		direct_direction.y = 0.0
		return direct_direction.normalized()

	var cell_route := _get_cell_route_between_world_positions(origin, destination)
	if cell_route.size() < 2:
		return Vector3.ZERO
	var origin_point := wall_grid_map.to_global(wall_grid_map.map_to_local(cell_route[0]))
	var next_point := wall_grid_map.to_global(wall_grid_map.map_to_local(cell_route[1]))
	var departure_direction := next_point - origin_point
	departure_direction.y = 0.0
	return departure_direction.normalized()


## Returns maze-route distance between two known layout positions without changing the active route.
func get_path_distance(origin: Vector3, destination: Vector3) -> float:
	if wall_grid_map == null or grid_bounds.size == Vector2i.ZERO:
		return Vector2(destination.x - origin.x, destination.z - origin.z).length()

	var cell_route := _get_cell_route_between_world_positions(origin, destination)
	if cell_route.is_empty():
		return INF
	if cell_route.size() == 1:
		return Vector2(destination.x - origin.x, destination.z - origin.z).length()
	var route_distance := 0.0
	for cell_index in range(1, cell_route.size()):
		var previous_point := wall_grid_map.to_global(
			wall_grid_map.map_to_local(cell_route[cell_index - 1])
		)
		var current_point := wall_grid_map.to_global(
			wall_grid_map.map_to_local(cell_route[cell_index])
		)
		route_distance += Vector2(
			current_point.x - previous_point.x,
			current_point.z - previous_point.z
		).length()
	return route_distance


## Projects confirmed movement onto a plausible reachable route without reading the live player.
func predict_reachable_target(
	last_seen_position: Vector3,
	last_seen_velocity: Vector3,
	prediction_seconds: float,
	maximum_distance: float,
	minimum_alignment: float,
	require_direction_match: bool = false,
	position_is_ruled_out: Callable = Callable()
) -> Vector3:
	var horizontal_velocity := last_seen_velocity
	horizontal_velocity.y = 0.0
	var prediction_distance := minf(
		horizontal_velocity.length() * maxf(prediction_seconds, 0.0),
		maxf(maximum_distance, 0.0)
	)
	if prediction_distance <= 0.001:
		return last_seen_position

	var direction := horizontal_velocity.normalized()
	var candidates := get_reachable_search_points(
		last_seen_position,
		prediction_distance,
		PREDICTION_FRONTIER_FRACTION,
		direction,
		minimum_alignment
	)
	if candidates.is_empty():
		return last_seen_position
	if require_direction_match and last_search_direction_match == SearchDirectionMatch.None:
		return last_seen_position

	var eligible_candidates: Array[Vector3] = []
	for candidate in candidates:
		if position_is_ruled_out.is_valid() \
				and bool(position_is_ruled_out.call(candidate)):
			continue
		eligible_candidates.append(candidate)
	if eligible_candidates.is_empty():
		return last_seen_position

	var selected := eligible_candidates[0]
	var selected_offset := selected - last_seen_position
	selected_offset.y = 0.0
	var selected_forward_distance := selected_offset.dot(direction)
	var selected_distance_error := absf(
		selected_offset.length() - prediction_distance
	)
	for candidate_index in range(1, eligible_candidates.size()):
		var candidate := eligible_candidates[candidate_index]
		var offset := candidate - last_seen_position
		offset.y = 0.0
		var forward_distance := offset.dot(direction)
		var distance_error := absf(offset.length() - prediction_distance)
		var wins_forward_tie := is_equal_approx(
			forward_distance,
			selected_forward_distance
		) and (
			distance_error < selected_distance_error \
			or (is_equal_approx(distance_error, selected_distance_error) \
				and _sort_search_point(candidate, selected))
		)
		if forward_distance > selected_forward_distance or wins_forward_tie:
			selected = candidate
			selected_forward_distance = forward_distance
			selected_distance_error = distance_error
	return selected


## Returns whether a candidate is close enough to reuse the current route destination.
func is_target_near(candidate: Vector3, maximum_distance: float) -> bool:
	var horizontal_distance := Vector2(
		candidate.x - target_position.x,
		candidate.z - target_position.z
	).length()
	return horizontal_distance <= maxf(maximum_distance, 0.0)


## Stops route movement immediately while the vampire pauses to investigate a junction.
func stop_immediately() -> void:
	has_target = false
	route_points.clear()
	route_index = 0
	route_traversal_status = RouteTraversalStatus.Idle
	current_horizontal_velocity = Vector3.ZERO
	wall_stall_elapsed = 0.0
	wall_stall_progress_distance = 0.0
	last_movement_direction = Vector3.ZERO
	clear_visible_player_position()
	if body != null:
		body.velocity.x = 0.0
		body.velocity.z = 0.0


## Turns the presentation toward a scan direction without starting route movement.
func face_direction(direction: Vector3, delta: float) -> void:
	var horizontal_direction := direction
	horizontal_direction.y = 0.0
	if horizontal_direction.is_zero_approx():
		return
	_face_direction(horizontal_direction.normalized(), delta)


## Returns reachable maze positions near the edge of the preferred branch's travel distance.
func get_reachable_search_points(
		origin: Vector3,
		maximum_travel_distance: float,
		minimum_distance_fraction: float,
		preferred_direction: Vector3 = Vector3.ZERO,
		minimum_direction_alignment: float = -1.0
) -> Array[Vector3]:
	var search_points: Array[Vector3] = []
	last_search_direction_match = SearchDirectionMatch.None
	last_frontier_search_was_truncated = false
	if body == null \
			or settings == null \
			or wall_grid_map == null \
			or grid_bounds.size == Vector2i.ZERO:
		return search_points

	var origin_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(origin))
	origin_cell.y = wall_grid_y
	origin_cell = _find_nearest_open_cell(origin_cell, wall_grid_map.to_local(origin))
	if origin_cell == INVALID_CELL:
		return search_points

	var cell_travel_distance := _get_maximum_world_cell_edge_length()
	var maximum_steps := floori(
		maxf(maximum_travel_distance, 0.0) / cell_travel_distance
	)
	if maximum_steps <= 0:
		return search_points
	var pending: Array[Vector3i] = [origin_cell]
	var read_index := 0
	var distance_by_cell: Dictionary = {origin_cell: 0}
	var first_step_by_cell: Dictionary = {origin_cell: Vector3i.ZERO}
	var furthest_steps := 0
	while read_index < pending.size() \
			and distance_by_cell.size() < settings.maximum_route_search_cells:
		var current := pending[read_index]
		read_index += 1
		var current_steps := int(distance_by_cell[current])
		furthest_steps = maxi(furthest_steps, current_steps)
		if current_steps >= maximum_steps:
			continue
		for neighbor in _get_neighbors(current):
			if distance_by_cell.has(neighbor) \
					or not _cell_is_in_bounds(neighbor) \
					or _is_wall(neighbor):
				continue
			distance_by_cell[neighbor] = current_steps + 1
			first_step_by_cell[neighbor] = neighbor - current \
				if current == origin_cell \
				else first_step_by_cell[current] as Vector3i
			pending.append(neighbor)
	last_frontier_search_was_truncated = read_index < pending.size() \
		and distance_by_cell.size() >= settings.maximum_route_search_cells

	var minimum_steps := maxi(
		floori(float(furthest_steps) * clampf(minimum_distance_fraction, 0.0, 1.0)),
		1
	)
	var direction_alignment_by_cell: Dictionary = {}
	var furthest_non_backtracking_steps := 0
	var furthest_forward_steps := 0
	var horizontal_preference := preferred_direction
	horizontal_preference.y = 0.0
	horizontal_preference = horizontal_preference.normalized()
	if not horizontal_preference.is_zero_approx():
		for cell_value in distance_by_cell:
			var cell := cell_value as Vector3i
			if cell == origin_cell:
				continue
			var first_step := first_step_by_cell[cell] as Vector3i
			var first_step_point := wall_grid_map.to_global(
				wall_grid_map.map_to_local(origin_cell + first_step)
			)
			var origin_point := wall_grid_map.to_global(
				wall_grid_map.map_to_local(origin_cell)
			)
			var first_world_direction := first_step_point - origin_point
			first_world_direction.y = 0.0
			var direction_alignment := first_world_direction.normalized().dot(
				horizontal_preference
			)
			direction_alignment_by_cell[cell] = direction_alignment
			var cell_steps := int(distance_by_cell[cell])
			if direction_alignment >= minimum_direction_alignment:
				furthest_non_backtracking_steps = maxi(
					furthest_non_backtracking_steps,
					cell_steps
				)
			if direction_alignment >= maxf(
				minimum_direction_alignment,
				FORWARD_DIRECTION_ALIGNMENT
			):
				furthest_forward_steps = maxi(furthest_forward_steps, cell_steps)

	var distance_fraction := clampf(minimum_distance_fraction, 0.0, 1.0)
	var minimum_non_backtracking_steps := maxi(
		floori(float(furthest_non_backtracking_steps) * distance_fraction),
		1
	)
	var minimum_forward_steps := maxi(
		floori(float(furthest_forward_steps) * distance_fraction),
		1
	)
	var unique_points: Dictionary = {}
	var non_backtracking_points: Array[Vector3] = []
	var forward_points: Array[Vector3] = []
	for cell_value in distance_by_cell:
		var cell := cell_value as Vector3i
		if cell == origin_cell:
			continue
		var point := wall_grid_map.to_global(
			wall_grid_map.map_to_local(cell) + _get_wall_clearance_offset(cell)
		)
		point.y = body.global_position.y
		if unique_points.has(point):
			continue
		unique_points[point] = true
		var cell_steps := int(distance_by_cell[cell])
		if cell_steps >= minimum_steps:
			search_points.append(point)
		if not direction_alignment_by_cell.has(cell):
			continue
		var direction_alignment := float(direction_alignment_by_cell[cell])
		if direction_alignment >= minimum_direction_alignment \
				and cell_steps >= minimum_non_backtracking_steps:
			non_backtracking_points.append(point)
		if direction_alignment >= maxf(
			minimum_direction_alignment,
			FORWARD_DIRECTION_ALIGNMENT
		) and cell_steps >= minimum_forward_steps:
			forward_points.append(point)

	if not forward_points.is_empty():
		last_search_direction_match = SearchDirectionMatch.Forward
		forward_points.sort_custom(_sort_search_point)
		return forward_points
	if not non_backtracking_points.is_empty():
		last_search_direction_match = SearchDirectionMatch.NonBacktracking
		non_backtracking_points.sort_custom(_sort_search_point)
		return non_backtracking_points
	search_points.sort_custom(_sort_search_point)
	return search_points


## Calculates a maze route without replacing the vampire's active movement target.
func build_route_to(world_target: Vector3) -> Array[Vector3]:
	return _build_route_to(world_target, true)


func _build_route_to(world_target: Vector3, simplify_route: bool) -> Array[Vector3]:
	var calculated_route: Array[Vector3] = []
	if body == null:
		last_route_search_status = RouteSearchStatus.Unreachable
		return calculated_route

	if wall_grid_map == null or grid_bounds.size == Vector2i.ZERO:
		last_route_search_status = RouteSearchStatus.NoGridMap
		return calculated_route

	var start_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(body.global_position))
	var target_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(world_target))
	start_cell.y = wall_grid_y
	target_cell.y = wall_grid_y
	start_cell = _find_nearest_open_cell(
		start_cell,
		wall_grid_map.to_local(body.global_position)
	)
	target_cell = _find_nearest_open_cell(
		target_cell,
		wall_grid_map.to_local(world_target)
	)
	if start_cell == INVALID_CELL or target_cell == INVALID_CELL:
		last_route_search_status = RouteSearchStatus.Unreachable
		return calculated_route

	var cell_route := _find_cell_route(start_cell, target_cell)
	var selected_cell_route := _simplify_cell_route(cell_route) if simplify_route else cell_route
	# The body's current cell is an origin, not a destination. Reintroducing its
	# centre on every visible repath makes an off-centre Vampire step backwards.
	var first_destination_index := 1 if selected_cell_route.size() > 1 else 0
	for cell_index in range(first_destination_index, selected_cell_route.size()):
		var cell := selected_cell_route[cell_index]
		var point := wall_grid_map.to_global(
			wall_grid_map.map_to_local(cell) + _get_wall_clearance_offset(cell)
		)
		point.y = body.global_position.y
		calculated_route.append(point)

	if not calculated_route.is_empty():
		var final_point := _get_body_clear_target_point(target_cell, world_target)
		final_point.y = body.global_position.y
		calculated_route[calculated_route.size() - 1] = final_point
	return calculated_route


func _advance_reached_route_points() -> void:
	while route_index < route_points.size():
		var waypoint := route_points[route_index]
		var horizontal_distance := Vector2(
			body.global_position.x - waypoint.x,
			body.global_position.z - waypoint.z
		).length()
		var reached_distance := _get_route_point_reached_distance(route_index)
		if horizontal_distance > reached_distance:
			return
		route_index += 1

	if has_visible_player_position and visible_player_direct_path_clear:
		var player_distance := Vector2(
			visible_player_position.x - body.global_position.x,
			visible_player_position.z - body.global_position.z
		).length()
		if player_distance > float(settings.target_reached_distance):
			return

	has_target = false
	route_traversal_status = RouteTraversalStatus.Arrived
	last_completed_route_direction = last_movement_direction


func _get_route_point_reached_distance(point_index: int) -> float:
	if point_index != route_points.size() - 1:
		return float(settings.waypoint_reached_distance)
	if has_visible_player_position:
		return float(settings.visible_target_reached_distance)
	return float(settings.target_reached_distance)


func _visible_player_is_closer_than(next_waypoint: Vector3) -> bool:
	if not has_visible_player_position or not visible_player_direct_path_clear:
		return false
	if route_index >= route_points.size():
		return true
	var waypoint_distance := Vector2(
		next_waypoint.x - body.global_position.x,
		next_waypoint.z - body.global_position.z
	).length()
	var player_distance := Vector2(
		visible_player_position.x - body.global_position.x,
		visible_player_position.z - body.global_position.z
	).length()
	return player_distance < waypoint_distance


func _abandon_blocked_visible_shortcut() -> void:
	if not using_visible_player_shortcut:
		return
	visible_player_direct_path_clear = false
	using_visible_player_shortcut = false
	direct_shortcut_recovery_count += 1
	_rebuild_route()


func _stop_horizontal(delta: float) -> void:
	current_horizontal_velocity = current_horizontal_velocity.move_toward(
		Vector3.ZERO,
		settings.deceleration * delta
	)
	body.velocity.x = current_horizontal_velocity.x
	body.velocity.z = current_horizontal_velocity.z


func _face_direction(direction: Vector3, delta: float) -> void:
	if pivot == null:
		return

	var target_yaw := atan2(direction.x, direction.z)
	pivot.rotation.y = lerp_angle(pivot.rotation.y, target_yaw, settings.turn_speed * delta)


func _rebuild_route() -> void:
	route_rebuild_count += 1
	# Active movement retains each adjacent maze cell. Connecting only direction-change
	# corners can cut diagonally across an inside wall after body-clearance offsets are
	# applied, which is unsafe for the Vampire's wider collision capsule.
	route_points = _build_route_to(target_position, false)
	route_index = 0
	_reset_stall_tracking()
	if route_points.is_empty():
		has_target = false
		route_traversal_status = RouteTraversalStatus.Failed
	else:
		route_traversal_status = RouteTraversalStatus.Following


func _update_wall_stall_recovery(
		delta: float,
		_collided_with_wall: bool,
		progress_speed: float,
		commanded_speed: float
) -> void:
	if commanded_speed < settings.wall_stall_minimum_speed:
		_reset_stall_tracking()
		return

	wall_stall_elapsed += delta
	wall_stall_progress_distance += maxf(progress_speed, 0.0) * delta
	if wall_stall_elapsed < settings.wall_stall_recovery_seconds:
		return
	var average_progress_speed := wall_stall_progress_distance \
		/ maxf(wall_stall_elapsed, _get_direction_epsilon())
	if average_progress_speed >= settings.wall_stall_minimum_progress_speed:
		_reset_stall_tracking()
		return

	route_points = _build_route_to(target_position, false)
	route_index = 0
	_reset_stall_tracking()
	current_horizontal_velocity = Vector3.ZERO
	wall_stall_recovery_count += 1
	if route_points.is_empty():
		has_target = false
		route_traversal_status = RouteTraversalStatus.Failed
	else:
		route_traversal_status = RouteTraversalStatus.Following


func _find_cell_route(start_cell: Vector3i, end_cell: Vector3i) -> Array[Vector3i]:
	var result := _route_search.find_cell_route(start_cell, end_cell)
	last_route_search_status = int(result["status"]) as RouteSearchStatus
	var route: Array[Vector3i] = []
	route.assign(result["route"] as Array)
	return route


func _get_cell_route_between_world_positions(
		origin: Vector3,
		destination: Vector3
) -> Array[Vector3i]:
	var result := _route_search.get_cell_route_between_world_positions(origin, destination)
	last_route_search_status = int(result["status"]) as RouteSearchStatus
	var route: Array[Vector3i] = []
	route.assign(result["route"] as Array)
	return route


func _get_body_clearance_world() -> float:
	return _navigation_clearance._get_body_clearance_world()


func _simplify_cell_route(route: Array[Vector3i]) -> Array[Vector3i]:
	return _route_search.simplify_cell_route(route)


func _find_nearest_open_cell(
		origin: Vector3i,
		reference_local_position: Vector3
) -> Vector3i:
	return _route_search.find_nearest_open_cell(origin, reference_local_position)


func _get_neighbors(cell: Vector3i) -> Array[Vector3i]:
	return _route_search.get_neighbors(cell)


func _sort_search_point(first: Vector3, second: Vector3) -> bool:
	if first.x != second.x:
		return first.x < second.x
	if first.z != second.z:
		return first.z < second.z
	return first.y < second.y


func _reset_stall_tracking() -> void:
	wall_stall_elapsed = 0.0
	wall_stall_progress_distance = 0.0


func _get_direction_epsilon() -> float:
	return _navigation_clearance.get_direction_epsilon()


func _get_direction_epsilon_squared() -> float:
	var epsilon := _get_direction_epsilon()
	return epsilon * epsilon


func _get_minimum_world_cell_edge_length() -> float:
	return _navigation_clearance.get_minimum_world_cell_edge_length()


func _get_maximum_world_cell_edge_length() -> float:
	return _navigation_clearance.get_maximum_world_cell_edge_length()


func _get_world_cell_edge_length(direction: Vector3i) -> float:
	return _navigation_clearance.get_world_cell_edge_length(direction)


func _get_wall_clearance_offset(cell: Vector3i) -> Vector3:
	return _navigation_clearance.get_wall_clearance_offset(cell)


func _get_body_clear_target_point(cell: Vector3i, world_target: Vector3) -> Vector3:
	return _navigation_clearance.get_body_clear_target_point(cell, world_target)


func _cell_is_in_bounds(cell: Vector3i) -> bool:
	return grid_bounds.has_point(Vector2i(cell.x, cell.z))


func _is_wall(cell: Vector3i) -> bool:
	if wall_grid_map == null:
		return false
	var item_id := wall_grid_map.get_cell_item(cell)
	return wall_item_ids.has(item_id)


func _get_wall_item_ids(grid_map: GridMap) -> Dictionary:
	var item_ids := {}
	if grid_map == null or grid_map.mesh_library == null:
		return item_ids
	for item_id in grid_map.mesh_library.get_item_list():
		if grid_map.mesh_library.get_item_name(item_id).to_lower().contains("wall"):
			item_ids[item_id] = true
	return item_ids


func _get_used_wall_bounds(grid_map: GridMap, grid_y: int) -> Rect2i:
	var used_cells := grid_map.get_used_cells()
	if used_cells.is_empty():
		return Rect2i()

	var minimum := Vector2i(2147483647, 2147483647)
	var maximum := Vector2i(-2147483648, -2147483648)
	for cell in used_cells:
		if cell.y != grid_y or not wall_item_ids.has(grid_map.get_cell_item(cell)):
			continue
		minimum.x = mini(minimum.x, cell.x)
		minimum.y = mini(minimum.y, cell.z)
		maximum.x = maxi(maximum.x, cell.x)
		maximum.y = maxi(maximum.y, cell.z)
	if minimum.x > maximum.x or minimum.y > maximum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _get_wall_grid_y(grid_map: GridMap) -> int:
	for cell in grid_map.get_used_cells():
		if wall_item_ids.has(grid_map.get_cell_item(cell)):
			return cell.y
	return 0


func _is_wall_item(grid_map: GridMap, item_id: int) -> bool:
	return item_id != GridMap.INVALID_CELL_ITEM \
		and grid_map.mesh_library != null \
		and grid_map.mesh_library.get_item_name(item_id).to_lower().contains("wall")
