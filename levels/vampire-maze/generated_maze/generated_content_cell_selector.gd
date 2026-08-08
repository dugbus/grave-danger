extends RefCounted
class_name GDGeneratedContentCellSelector

const GRAPH_SCRIPT := preload(
	"res://levels/vampire-maze/generated_maze/generated_maze_graph.gd"
)
const TREASURE_TYPES: Array[StringName] = [
	&"gold_coin", &"diamond", &"ruby", &"sapphire", &"emerald", &"amethyst", &"gold_bar",
]
const GEM_TYPES: Array[StringName] = [&"diamond", &"ruby", &"sapphire", &"emerald", &"amethyst"]


static func has_additional_treasure_budget(budgets: Dictionary) -> bool:
	for item_type in TREASURE_TYPES:
		if item_type != &"gold_coin" and int(budgets.get(item_type, 0)) > 0:
			return true
	return false


static func has_gem_budget(budgets: Dictionary) -> bool:
	for item_type in GEM_TYPES:
		if int(budgets.get(item_type, 0)) > 0:
			return true
	return false


static func get_deterministic_pile_coin_count(
	cell: Vector2i,
	seed_value: int,
	pile_index: int,
	minimum_coins: int,
	maximum_coins: int
) -> int:
	var count_range := maximum_coins - minimum_coins + 1
	if count_range <= 1:
		return minimum_coins
	return minimum_coins + posmod(
		GRAPH_SCRIPT.coordinate_score(cell, seed_value, pile_index + 401),
		count_range
	)


static func new_treasure_cache(
	cell: Vector2i,
	placement_band: int,
	route_progress: float,
	walkable: Dictionary,
	map_size: Vector2i
) -> Dictionary:
	var counts := {}
	for item_type in TREASURE_TYPES:
		counts[item_type] = 0
	return {
		"cell": cell,
		"cell_3d": Vector3i(cell.x, 0, cell.y),
		"placement_band": placement_band,
		"route_progress": clampf(route_progress, 0.0, 1.0),
		"escape_option_count": get_walkable_neighbour_count(cell, walkable),
		"open_area_cell_count": get_open_area_cell_count(cell, walkable),
		"map_edge_clearance_tiles": get_map_edge_clearance(cell, map_size),
		"counts": counts,
	}


static func distribute_treasure_count(
	caches: Array[Dictionary],
	preferred_indices: Array[int],
	item_type: StringName,
	count: int
) -> void:
	if count <= 0 or caches.is_empty():
		return
	var indices := preferred_indices
	if indices.is_empty():
		indices = []
		for index in caches.size():
			indices.append(index)
	for item_index in count:
		var cache_index := indices[item_index % indices.size()]
		var cache := caches[cache_index]
		var counts := cache["counts"] as Dictionary
		counts[item_type] = int(counts[item_type]) + 1
		cache["counts"] = counts
		caches[cache_index] = cache


static func build_region_targets(
	count: int,
	map_size: Vector2i,
	random_seed: int
) -> Array[Vector2]:
	var targets: Array[Vector2] = []
	if count <= 0:
		return targets
	var usable_width := maxi(map_size.x, 1)
	var usable_height := maxi(map_size.y, 1)
	var aspect_ratio := float(usable_width) / float(usable_height)
	var column_count := maxi(ceili(sqrt(float(count) * aspect_ratio)), 1)
	var row_count := maxi(ceili(float(count) / float(column_count)), 1)
	var region_indices: Array[int] = []
	for region_index in column_count * row_count:
		region_indices.append(region_index)
	var random := RandomNumberGenerator.new()
	random.seed = random_seed
	for index in range(region_indices.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var held_index := region_indices[index]
		region_indices[index] = region_indices[swap_index]
		region_indices[swap_index] = held_index
	var minimum_coordinate := Vector2.ZERO
	var maximum_coordinate := Vector2(map_size - Vector2i.ONE)
	for slot_index in count:
		var region_index := region_indices[slot_index]
		var column_index := region_index % column_count
		var row_index := floori(float(region_index) / float(column_count))
		targets.append(Vector2(
			lerpf(
				minimum_coordinate.x,
				maximum_coordinate.x,
				(float(column_index) + random.randf()) / float(column_count)
			),
			lerpf(
				minimum_coordinate.y,
				maximum_coordinate.y,
				(float(row_index) + random.randf()) / float(row_count)
			)
		))
	return targets


static func get_walkable_neighbour_count(cell: Vector2i, walkable: Dictionary) -> int:
	var neighbour_count := 0
	for direction in GRAPH_SCRIPT.CARDINAL_DIRECTIONS:
		if walkable.has(cell + direction):
			neighbour_count += 1
	return neighbour_count


static func get_open_area_cell_count(cell: Vector2i, walkable: Dictionary) -> int:
	var open_cell_count := 0
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			if walkable.has(cell + Vector2i(x_offset, y_offset)):
				open_cell_count += 1
	return open_cell_count


static func get_map_edge_clearance(cell: Vector2i, map_size: Vector2i) -> int:
	return mini(mini(cell.x, cell.y), mini(map_size.x - 1 - cell.x, map_size.y - 1 - cell.y))


static func find_nearest_free_path_cell(
	main_path: Array[Vector2i],
	occupied: Dictionary,
	target_index: int,
	minimum_index: int,
	maximum_index: int,
	separation_cells: Array[Vector2i] = [],
	minimum_separation_tiles: int = 0
) -> Vector2i:
	var maximum_offset := maxi(target_index - minimum_index, maximum_index - target_index)
	for offset in range(0, maximum_offset + 1):
		for sign_value: int in [-1, 1]:
			if offset == 0 and sign_value > 0:
				continue
			var candidate_index: int = target_index + offset * sign_value
			if candidate_index < minimum_index or candidate_index > maximum_index:
				continue
			var cell := main_path[candidate_index]
			if not occupied.has(cell) and GRAPH_SCRIPT.has_minimum_cell_separation(
				cell,
				separation_cells,
				minimum_separation_tiles
			):
				return cell
	return Vector2i(-1, -1)


static func select_exploration_cells(
	walkable: Dictionary,
	distance_from_main_path: Dictionary,
	occupied: Dictionary,
	count: int,
	seed_value: int,
	salt: int,
	separation_cells: Array[Vector2i] = [],
	minimum_separation_tiles: int = 2,
	route_progress_by_cell: Dictionary = {}
) -> Array[Vector2i]:
	var candidates: Array[Dictionary] = []
	for cell_value in walkable:
		var cell := cell_value as Vector2i
		var path_distance := int(distance_from_main_path.get(cell, 0))
		if occupied.has(cell) or path_distance <= 0:
			continue
		candidates.append({
			"cell": cell,
			"path_distance": path_distance,
			"route_progress": float(route_progress_by_cell.get(cell, 0.0)),
			"random_score": GRAPH_SCRIPT.coordinate_score(cell, seed_value, salt),
		})
	if route_progress_by_cell.is_empty():
		candidates.sort_custom(GRAPH_SCRIPT.sort_exploration_candidate_depth_descending)
	var selected: Array[Vector2i] = []
	var all_separation_cells := separation_cells.duplicate()
	if route_progress_by_cell.is_empty():
		for candidate in candidates:
			var cell := candidate["cell"] as Vector2i
			if not GRAPH_SCRIPT.has_minimum_cell_separation(
				cell, all_separation_cells, minimum_separation_tiles
			):
				continue
			selected.append(cell)
			all_separation_cells.append(cell)
			occupied[cell] = true
			if selected.size() >= count:
				break
		return selected

	var progress_band_radius := maxf(0.5 / float(maxi(count, 1)), 0.02)
	for slot_index in count:
		var target_progress := float(slot_index + 1) / float(count + 1)
		var selected_candidate := _select_exploration_progress_candidate(
			candidates, occupied, all_separation_cells, minimum_separation_tiles,
			target_progress, progress_band_radius
		)
		if selected_candidate.is_empty():
			selected_candidate = _select_exploration_progress_candidate(
				candidates, occupied, all_separation_cells, minimum_separation_tiles,
				target_progress, 1.0
			)
		if selected_candidate.is_empty():
			continue
		var cell := selected_candidate["cell"] as Vector2i
		selected.append(cell)
		all_separation_cells.append(cell)
		occupied[cell] = true
	return selected


static func _select_exploration_progress_candidate(
	candidates: Array[Dictionary],
	occupied: Dictionary,
	separation_cells: Array[Vector2i],
	minimum_separation_tiles: int,
	target_progress: float,
	maximum_progress_difference: float
) -> Dictionary:
	var best_candidate := {}
	var best_score := -INF
	for candidate in candidates:
		var cell := candidate["cell"] as Vector2i
		if occupied.has(cell) or not GRAPH_SCRIPT.has_minimum_cell_separation(
			cell, separation_cells, minimum_separation_tiles
		):
			continue
		var progress_difference := absf(float(candidate["route_progress"]) - target_progress)
		if progress_difference > maximum_progress_difference:
			continue
		var candidate_score := float(candidate["path_distance"]) * 1000000.0 \
			- progress_difference * 100000.0 + float(candidate["random_score"])
		if candidate_score > best_score:
			best_candidate = candidate
			best_score = candidate_score
	return best_candidate
