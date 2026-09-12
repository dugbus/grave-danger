@tool
class_name FloorSurfaceFloodFill
extends RefCounted

## Builds deterministic, four-connected fill regions that never leave authored map bounds.

const FLOOR_MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")

enum MatchProperty {
	Shape,
	Elevation,
	Style,
}

const NEIGHBOUR_OFFSETS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


## Shape matches occupancy; elevation matches present height; style matches style and occupancy.
static func footprint(
	floor_map: FLOOR_MAP_SCRIPT,
	seed: Vector2i,
	match_property: MatchProperty
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if floor_map == null or not floor_map.is_in_bounds(seed):
		return result
	if match_property == MatchProperty.Elevation and not floor_map.has_floor(seed):
		return result
	var open: Array[Vector2i] = [seed]
	var visited: Dictionary[Vector2i, bool] = {seed: true}
	while not open.is_empty():
		var cell := open.pop_front() as Vector2i
		result.append(cell)
		for offset in NEIGHBOUR_OFFSETS:
			var neighbour := cell + offset
			if visited.has(neighbour) or not floor_map.is_in_bounds(neighbour):
				continue
			visited[neighbour] = true
			if _matches_seed(floor_map, seed, neighbour, match_property):
				open.append(neighbour)
	result.sort_custom(_is_cell_before)
	return result


static func describe_match(match_property: MatchProperty) -> String:
	match match_property:
		MatchProperty.Elevation:
			return "Fill matches connected floor tiles at the seed's exact elevation."
		MatchProperty.Style:
			return "Fill matches connected cells with the seed's style and floor/hole state."
		_:
			return "Fill matches connected cells with the seed's floor/hole state, within current bounds."


static func _matches_seed(
	floor_map: FLOOR_MAP_SCRIPT,
	seed: Vector2i,
	candidate: Vector2i,
	match_property: MatchProperty
) -> bool:
	match match_property:
		MatchProperty.Elevation:
			return floor_map.has_floor(candidate) \
				and floor_map.get_cell_elevation(candidate) == floor_map.get_cell_elevation(seed)
		MatchProperty.Style:
			return floor_map.has_floor(candidate) == floor_map.has_floor(seed) \
				and floor_map.get_cell_style(candidate) == floor_map.get_cell_style(seed)
		_:
			return floor_map.has_floor(candidate) == floor_map.has_floor(seed)


static func _is_cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)

