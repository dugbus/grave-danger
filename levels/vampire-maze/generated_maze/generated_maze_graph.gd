class_name GDGeneratedMazeGraph
extends RefCounted

## Deterministic graph queries shared by generated maze content planners.

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
    Vector2i.UP,
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i.LEFT,
]


static func normalise_walkable_cells(floor_cells: Dictionary) -> Dictionary:
    var walkable := {}
    for cell_value in floor_cells:
        var cell := cell_value as Vector2i
        walkable[cell] = true
    return walkable


static func find_path(
    start: Vector2i,
    destination: Vector2i,
    walkable: Dictionary,
    blocked: Dictionary = {}
) -> Array[Vector2i]:
    if not walkable.has(start) or not walkable.has(destination):
        return []
    if blocked.has(start) or blocked.has(destination):
        return []

    var pending: Array[Vector2i] = [start]
    var read_index := 0
    var previous := {start: start}
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        if current == destination:
            break
        for direction in CARDINAL_DIRECTIONS:
            var neighbour := current + direction
            if not walkable.has(neighbour) or blocked.has(neighbour) or previous.has(neighbour):
                continue
            previous[neighbour] = current
            pending.append(neighbour)
    if not previous.has(destination):
        return []

    var reverse_path: Array[Vector2i] = [destination]
    var cursor := destination
    while cursor != start:
        cursor = previous[cursor] as Vector2i
        reverse_path.append(cursor)
    reverse_path.reverse()
    return reverse_path


static func get_reachable_cells(
    start: Vector2i,
    walkable: Dictionary,
    blocked: Dictionary
) -> Dictionary:
    if not walkable.has(start) or blocked.has(start):
        return {}
    var reachable := {start: true}
    var pending: Array[Vector2i] = [start]
    var read_index := 0
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        for direction in CARDINAL_DIRECTIONS:
            var neighbour := current + direction
            if not walkable.has(neighbour) or blocked.has(neighbour) or reachable.has(neighbour):
                continue
            reachable[neighbour] = true
            pending.append(neighbour)
    return reachable


static func build_distances_from_sources(
    sources: Array[Vector2i],
    walkable: Dictionary
) -> Dictionary:
    var distances := {}
    var pending: Array[Vector2i] = []
    for source in sources:
        if distances.has(source):
            continue
        distances[source] = 0
        pending.append(source)
    var read_index := 0
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        var next_distance := int(distances[current]) + 1
        for direction in CARDINAL_DIRECTIONS:
            var neighbour := current + direction
            if not walkable.has(neighbour) or distances.has(neighbour):
                continue
            distances[neighbour] = next_distance
            pending.append(neighbour)
    return distances


static func build_route_progress_by_cell(
    main_path: Array[Vector2i],
    walkable: Dictionary
) -> Dictionary:
    var route_index_by_cell := {}
    var pending: Array[Vector2i] = []
    for route_index in main_path.size():
        var route_cell := main_path[route_index]
        if route_index_by_cell.has(route_cell):
            continue
        route_index_by_cell[route_cell] = route_index
        pending.append(route_cell)

    var read_index := 0
    while read_index < pending.size():
        var current := pending[read_index]
        read_index += 1
        for direction in CARDINAL_DIRECTIONS:
            var neighbour := current + direction
            if not walkable.has(neighbour) or route_index_by_cell.has(neighbour):
                continue
            route_index_by_cell[neighbour] = route_index_by_cell[current]
            pending.append(neighbour)

    var progress_by_cell := {}
    var maximum_route_index := maxi(main_path.size() - 1, 1)
    for cell_value in route_index_by_cell:
        var cell := cell_value as Vector2i
        progress_by_cell[cell] = float(route_index_by_cell[cell]) \
            / float(maximum_route_index)
    return progress_by_cell


static func build_path_lookup(main_path: Array[Vector2i]) -> Dictionary:
    var lookup := {}
    for index in main_path.size():
        if not lookup.has(main_path[index]):
            lookup[main_path[index]] = index
    return lookup


static func cells_to_vector3i(cells: Array[Vector2i]) -> Array[Vector3i]:
    var converted: Array[Vector3i] = []
    for cell in cells:
        converted.append(Vector3i(cell.x, 0, cell.y))
    return converted


static func chance_succeeds(seed_value: int, salt: int, percent: float) -> bool:
    var roll := posmod(seed_value * 1103515245 + salt * 12345, 10000)
    return float(roll) / 100.0 < clampf(percent, 0.0, 100.0)


static func coordinate_score(cell: Vector2i, seed_value: int, salt: int) -> int:
    return posmod(
        cell.x * 73856093 ^ cell.y * 19349663 ^ seed_value * 83492791 ^ salt * 265443576,
        99991
    )


static func sort_scored_cell_descending(first: Dictionary, second: Dictionary) -> bool:
    return int(first["score"]) > int(second["score"])


static func sort_exploration_candidate_depth_descending(
    first: Dictionary,
    second: Dictionary
) -> bool:
    var first_score := int(first["path_distance"]) * 100000 \
        + int(first["random_score"])
    var second_score := int(second["path_distance"]) * 100000 \
        + int(second["random_score"])
    return first_score > second_score


static func sort_door_by_route_index(first: Dictionary, second: Dictionary) -> bool:
    return int(first["route_index"]) < int(second["route_index"])


static func has_minimum_cell_separation(
    cell: Vector2i,
    separation_cells: Array[Vector2i],
    minimum_separation_tiles: int
) -> bool:
    if minimum_separation_tiles <= 0:
        return true
    var minimum_distance_squared := minimum_separation_tiles * minimum_separation_tiles
    for other_cell in separation_cells:
        if cell.distance_squared_to(other_cell) < minimum_distance_squared:
            return false
    return true
