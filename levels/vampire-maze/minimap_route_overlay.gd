extends MultiMeshInstance3D
class_name GDVampireMazeMinimapRouteOverlay


const INVALID_CELL := Vector3i(2147483647, 2147483647, 2147483647)
const MINIMAP_ROUTE_VISUAL_LAYER := 1 << 18
const CARDINAL_DIRECTIONS: Array[Vector3i] = [
	Vector3i.LEFT,
	Vector3i.RIGHT,
	Vector3i.FORWARD,
	Vector3i.BACK,
]

## Player whose current maze cell starts the displayed routes.
@export var player_path: NodePath = ^"../Player"
## End gate whose nearest walkable cell finishes the displayed routes.
@export var end_gate_path: NodePath = ^"../LockedGate"
## GridMap containing maze walls that routes cannot cross.
@export var wall_grid_map_path: NodePath = ^"../PNGGridMap"
## GridMap containing the floor cells on which route tiles are drawn.
@export var floor_grid_map_path: NodePath = ^"../PNGFloorGridMap"
## Height above the floor used to prevent the coloured route from flickering.
@export_range(0.01, 0.5, 0.01) var route_height := 0.04

var player: Node3D
var end_gate: Node3D
var wall_grid_map: GridMap
var floor_grid_map: GridMap
var highlighted_cells: Array[Vector3i] = []
var last_player_cell := INVALID_CELL


func _ready() -> void:
	layers = MINIMAP_ROUTE_VISUAL_LAYER
	if multimesh != null:
		multimesh = multimesh.duplicate(true) as MultiMesh
	_resolve_references()
	refresh_route()
	_hide_from_gameplay_camera()


func _process(_delta: float) -> void:
	_hide_from_gameplay_camera()
	if player == null or floor_grid_map == null:
		_resolve_references()
	if player == null or floor_grid_map == null:
		return

	var player_cell := _world_to_floor_cell(player.global_position)
	if player_cell != last_player_cell:
		refresh_route()


## Rebuilds the coloured tiles from the player's current cell to the end gate.
func refresh_route() -> void:
	highlighted_cells.clear()
	if not _has_route_references():
		_apply_highlighted_cells()
		return

	var walkable_cells := _get_walkable_cells()
	var start_cell := _find_nearest_walkable_cell(
		_world_to_floor_cell(player.global_position),
		walkable_cells
	)
	var end_cell := _find_nearest_walkable_cell(
		_world_to_floor_cell(end_gate.global_position),
		walkable_cells
	)
	last_player_cell = start_cell
	if start_cell == INVALID_CELL or end_cell == INVALID_CELL:
		_apply_highlighted_cells()
		return

	var distances_from_start := _build_distances(start_cell, walkable_cells)
	if not distances_from_start.has(end_cell):
		_apply_highlighted_cells()
		return

	var distances_from_end := _build_distances(end_cell, walkable_cells)
	var shortest_distance := int(distances_from_start[end_cell])
	for cell_value: Variant in walkable_cells:
		var cell := cell_value as Vector3i
		if not distances_from_start.has(cell) or not distances_from_end.has(cell):
			continue
		if int(distances_from_start[cell]) + int(distances_from_end[cell]) == shortest_distance:
			highlighted_cells.append(cell)

	_apply_highlighted_cells()


## Returns every floor cell belonging to at least one shortest route for tests and tooling.
func get_highlighted_cells() -> Array[Vector3i]:
	return highlighted_cells.duplicate()


func _resolve_references() -> void:
	player = get_node_or_null(player_path) as Node3D
	end_gate = get_node_or_null(end_gate_path) as Node3D
	wall_grid_map = get_node_or_null(wall_grid_map_path) as GridMap
	floor_grid_map = get_node_or_null(floor_grid_map_path) as GridMap


func _has_route_references() -> bool:
	return player != null \
		and end_gate != null \
		and wall_grid_map != null \
		and floor_grid_map != null \
		and multimesh != null


func _get_walkable_cells() -> Dictionary:
	var walkable_cells: Dictionary = {}
	for floor_cell in floor_grid_map.get_used_cells():
		var floor_position := floor_grid_map.to_global(floor_grid_map.map_to_local(floor_cell))
		var wall_cell := wall_grid_map.local_to_map(wall_grid_map.to_local(floor_position))
		if wall_grid_map.get_cell_item(wall_cell) == GridMap.INVALID_CELL_ITEM:
			walkable_cells[floor_cell] = true
	return walkable_cells


func _world_to_floor_cell(world_position: Vector3) -> Vector3i:
	var cell := floor_grid_map.local_to_map(floor_grid_map.to_local(world_position))
	var floor_cells := floor_grid_map.get_used_cells()
	if not floor_cells.is_empty():
		cell.y = floor_cells[0].y
	return cell


func _find_nearest_walkable_cell(origin: Vector3i, walkable_cells: Dictionary) -> Vector3i:
	if walkable_cells.has(origin):
		return origin

	var nearest_cell := INVALID_CELL
	var nearest_distance := INF
	var origin_2d := Vector2i(origin.x, origin.z)
	for cell_value: Variant in walkable_cells:
		var cell := cell_value as Vector3i
		var cell_2d := Vector2i(cell.x, cell.z)
		var distance := float(origin_2d.distance_squared_to(cell_2d))
		if distance < nearest_distance:
			nearest_cell = cell
			nearest_distance = distance
	return nearest_cell


func _build_distances(origin: Vector3i, walkable_cells: Dictionary) -> Dictionary:
	var distances: Dictionary = {origin: 0}
	var pending: Array[Vector3i] = [origin]
	var read_index := 0
	while read_index < pending.size():
		var cell := pending[read_index]
		read_index += 1
		var next_distance := int(distances[cell]) + 1
		for direction in CARDINAL_DIRECTIONS:
			var neighbor := cell + direction
			if not walkable_cells.has(neighbor) or distances.has(neighbor):
				continue
			distances[neighbor] = next_distance
			pending.append(neighbor)
	return distances


func _apply_highlighted_cells() -> void:
	if multimesh == null:
		return

	multimesh.instance_count = highlighted_cells.size()
	for index in highlighted_cells.size():
		var floor_position := floor_grid_map.map_to_local(highlighted_cells[index])
		var world_position := floor_grid_map.to_global(floor_position)
		var overlay_position := to_local(world_position)
		overlay_position.y += route_height
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, overlay_position))


func _hide_from_gameplay_camera() -> void:
	var gameplay_camera := get_viewport().get_camera_3d()
	if gameplay_camera != null:
		gameplay_camera.cull_mask &= ~MINIMAP_ROUTE_VISUAL_LAYER
