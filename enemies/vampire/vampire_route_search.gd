extends RefCounted
class_name GDVampireRouteSearch

const INVALID_CELL := Vector3i(2147483647, 2147483647, 2147483647)

enum SearchStatus {
	Complete,
	AlreadyAtTarget,
	Unreachable,
	SearchBudgetExhausted,
	NoGridMap,
}

var settings: Resource
var wall_grid_map: GridMap
var wall_item_ids: Dictionary = {}
var grid_bounds := Rect2i()
var wall_grid_y := 0


func configure(
	vampire_settings: Resource,
	grid_map: GridMap,
	wall_ids: Dictionary,
	bounds: Rect2i,
	grid_y: int
) -> void:
	settings = vampire_settings
	wall_grid_map = grid_map
	wall_item_ids = wall_ids
	grid_bounds = bounds
	wall_grid_y = grid_y


func find_cell_route(start_cell: Vector3i, end_cell: Vector3i) -> Dictionary:
	if settings == null:
		return {"route": [], "status": SearchStatus.Unreachable}
	if start_cell == end_cell:
		return {"route": [start_cell], "status": SearchStatus.AlreadyAtTarget}

	var open_cells: Array[Vector3i] = [start_cell]
	var read_index := 0
	var came_from: Dictionary = {start_cell: start_cell}
	var search_count := 0
	while read_index < open_cells.size() and search_count < settings.maximum_route_search_cells:
		var current := open_cells[read_index]
		read_index += 1
		search_count += 1
		if current == end_cell:
			return {
				"route": _reconstruct_route(came_from, current),
				"status": SearchStatus.Complete,
			}
		for neighbor in get_neighbors(current):
			if came_from.has(neighbor) or not _cell_is_in_bounds(neighbor) or _is_wall(neighbor):
				continue
			came_from[neighbor] = current
			open_cells.append(neighbor)
	return {
		"route": [],
		"status": SearchStatus.SearchBudgetExhausted \
			if read_index < open_cells.size() else SearchStatus.Unreachable,
	}


func get_cell_route_between_world_positions(origin: Vector3, destination: Vector3) -> Dictionary:
	if wall_grid_map == null:
		return {"route": [], "status": SearchStatus.NoGridMap}
	var origin_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(origin))
	var destination_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(destination))
	origin_cell.y = wall_grid_y
	destination_cell.y = wall_grid_y
	origin_cell = find_nearest_open_cell(origin_cell, wall_grid_map.to_local(origin))
	destination_cell = find_nearest_open_cell(
		destination_cell,
		wall_grid_map.to_local(destination)
	)
	if origin_cell == INVALID_CELL or destination_cell == INVALID_CELL:
		return {"route": [], "status": SearchStatus.Unreachable}
	return find_cell_route(origin_cell, destination_cell)


func simplify_cell_route(route: Array[Vector3i]) -> Array[Vector3i]:
	if route.size() <= 2:
		return route
	var simplified: Array[Vector3i] = [route[0]]
	var previous_direction := route[1] - route[0]
	for index in range(1, route.size() - 1):
		var next_direction := route[index + 1] - route[index]
		if next_direction != previous_direction:
			simplified.append(route[index])
		previous_direction = next_direction
	simplified.append(route[route.size() - 1])
	return simplified


func find_nearest_open_cell(origin: Vector3i, reference_local_position: Vector3) -> Vector3i:
	if _cell_is_in_bounds(origin) and not _is_wall(origin):
		return origin
	if settings == null or grid_bounds.size == Vector2i.ZERO:
		return INVALID_CELL

	var search_origin := origin
	search_origin.x = clampi(search_origin.x, grid_bounds.position.x, grid_bounds.end.x - 1)
	search_origin.z = clampi(search_origin.z, grid_bounds.position.y, grid_bounds.end.y - 1)
	search_origin.y = wall_grid_y
	if not _is_wall(search_origin):
		return search_origin

	var wall_frontier: Array[Vector3i] = [search_origin]
	var visited: Dictionary = {search_origin: true}
	while not wall_frontier.is_empty() and visited.size() < settings.maximum_route_search_cells:
		var next_wall_frontier: Array[Vector3i] = []
		var open_candidates: Array[Vector3i] = []
		for current in wall_frontier:
			for neighbor in get_neighbors(current):
				if visited.has(neighbor) or not _cell_is_in_bounds(neighbor):
					continue
				visited[neighbor] = true
				if _is_wall(neighbor):
					next_wall_frontier.append(neighbor)
				else:
					open_candidates.append(neighbor)
		if not open_candidates.is_empty():
			return _get_closest_open_cell(open_candidates, reference_local_position)
		wall_frontier = next_wall_frontier
	return INVALID_CELL


func get_neighbors(cell: Vector3i) -> Array[Vector3i]:
	return [
		cell + Vector3i(1, 0, 0),
		cell + Vector3i(-1, 0, 0),
		cell + Vector3i(0, 0, 1),
		cell + Vector3i(0, 0, -1),
	]


func _reconstruct_route(came_from: Dictionary, end_cell: Vector3i) -> Array[Vector3i]:
	var route: Array[Vector3i] = [end_cell]
	var current := end_cell
	while came_from.has(current) and came_from[current] != current:
		current = came_from[current] as Vector3i
		route.push_front(current)
	return route


func _get_closest_open_cell(
	open_candidates: Array[Vector3i],
	reference_local_position: Vector3
) -> Vector3i:
	var selected_cell := open_candidates[0]
	var selected_distance := _get_horizontal_cell_distance_squared(selected_cell, reference_local_position)
	for candidate_index in range(1, open_candidates.size()):
		var candidate := open_candidates[candidate_index]
		var candidate_distance := _get_horizontal_cell_distance_squared(
			candidate,
			reference_local_position
		)
		var wins_distance_tie := is_equal_approx(candidate_distance, selected_distance) \
			and _cell_sorts_before(candidate, selected_cell)
		if candidate_distance < selected_distance or wins_distance_tie:
			selected_cell = candidate
			selected_distance = candidate_distance
	return selected_cell


func _get_horizontal_cell_distance_squared(
	cell: Vector3i,
	reference_local_position: Vector3
) -> float:
	var cell_position := wall_grid_map.map_to_local(cell)
	var horizontal_offset := Vector2(
		cell_position.x - reference_local_position.x,
		cell_position.z - reference_local_position.z
	)
	return horizontal_offset.length_squared()


func _cell_sorts_before(first: Vector3i, second: Vector3i) -> bool:
	if first.x != second.x:
		return first.x < second.x
	if first.z != second.z:
		return first.z < second.z
	return first.y < second.y


func _cell_is_in_bounds(cell: Vector3i) -> bool:
	return grid_bounds.has_point(Vector2i(cell.x, cell.z))


func _is_wall(cell: Vector3i) -> bool:
	if wall_grid_map == null:
		return false
	return wall_item_ids.has(wall_grid_map.get_cell_item(cell))
