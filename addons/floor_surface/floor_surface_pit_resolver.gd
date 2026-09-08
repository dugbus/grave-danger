@tool
class_name FloorSurfacePitResolver
extends RefCounted

## Resolves one crack-free horizontal datum for each connected bounded hole region.

const MAP_SCRIPT := preload("res://addons/floor_surface/floor_map.gd")
const PROFILE_SCRIPT := preload("res://addons/floor_surface/floor_elevation_profile.gd")
const STYLE_SCRIPT := preload("res://addons/floor_surface/floor_style.gd")
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]


## Returns bottom heights by absent cell plus the number of rimmed hole regions.
## A region uses the lowest `rim top - rim style depth` candidate, so mixed-height
## walls always meet one bottom without making any rim shallower than its authored depth.
func resolve(
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	styles: Array[STYLE_SCRIPT]
) -> Dictionary:
	var bottom_heights: Dictionary[Vector2i, float] = {}
	var visited: Dictionary[Vector2i, bool] = {}
	var region_count := 0
	if floor_map == null or profile == null or styles.is_empty():
		return {"bottom_heights": bottom_heights, "region_count": region_count}
	for z_coordinate in range(floor_map.minimum_cell.y, floor_map.minimum_cell.y + floor_map.dimensions.y):
		for x_coordinate in range(floor_map.minimum_cell.x, floor_map.minimum_cell.x + floor_map.dimensions.x):
			var cell := Vector2i(x_coordinate, z_coordinate)
			if floor_map.has_floor(cell) or visited.has(cell):
				continue
			var region := _collect_region(cell, floor_map, visited)
			var rim := _collect_rim(region, floor_map)
			if rim.is_empty():
				continue
			var bottom_height := _resolve_region_bottom(rim, floor_map, profile, styles)
			if is_inf(bottom_height):
				continue
			for hole_cell in region:
				bottom_heights[hole_cell] = bottom_height
			region_count += 1
	return {"bottom_heights": bottom_heights, "region_count": region_count}


func _collect_region(
	start: Vector2i,
	floor_map: MAP_SCRIPT,
	visited: Dictionary[Vector2i, bool]
) -> Array[Vector2i]:
	var region: Array[Vector2i] = []
	var pending: Array[Vector2i] = [start]
	visited[start] = true
	var pending_index := 0
	while pending_index < pending.size():
		var cell := pending[pending_index]
		pending_index += 1
		region.append(cell)
		for direction in CARDINAL_DIRECTIONS:
			var neighbour := cell + direction
			if not floor_map.is_in_bounds(neighbour) \
					or floor_map.has_floor(neighbour) or visited.has(neighbour):
				continue
			visited[neighbour] = true
			pending.append(neighbour)
	return region


func _collect_rim(region: Array[Vector2i], floor_map: MAP_SCRIPT) -> Array[Vector2i]:
	var rim_lookup: Dictionary[Vector2i, bool] = {}
	for cell in region:
		for direction in CARDINAL_DIRECTIONS:
			var neighbour := cell + direction
			if floor_map.has_floor(neighbour):
				rim_lookup[neighbour] = true
	var rim: Array[Vector2i] = []
	for cell_value in rim_lookup.keys():
		rim.append(cell_value as Vector2i)
	rim.sort_custom(_is_cell_before)
	return rim


func _resolve_region_bottom(
	rim: Array[Vector2i],
	floor_map: MAP_SCRIPT,
	profile: PROFILE_SCRIPT,
	styles: Array[STYLE_SCRIPT]
) -> float:
	var bottom_height := INF
	for rim_cell in rim:
		var style_index := _resolve_style_index(floor_map.get_cell_style(rim_cell), styles.size())
		var style := styles[style_index] as STYLE_SCRIPT
		if style == null:
			continue
		var rim_height := profile.elevation_to_world(floor_map.get_cell_elevation(rim_cell))
		bottom_height = minf(bottom_height, rim_height - maxf(style.pit_depth, 0.01))
	return bottom_height


func _resolve_style_index(authored_index: int, palette_size: int) -> int:
	if authored_index >= 0 and authored_index < palette_size:
		return authored_index
	return 0


func _is_cell_before(left: Vector2i, right: Vector2i) -> bool:
	return left.y < right.y or (left.y == right.y and left.x < right.x)
