@tool
class_name GDGeneratedFloorRoute
extends RefCounted

## Builds deterministic Road-cell routes in the maze's structural GridMap.

enum Destination {
	Gate,
	GateKey,
}

const GRAPH_SCRIPT := preload(
	"res://levels/vampire-maze/generated_maze/generated_maze_graph.gd"
)
const MESH_CATALOG_SCRIPT := preload(
	"res://addons/png_to_gridmap/png_to_gridmap_mesh_catalog.gd"
)
const GOLD_KEY_ITEM_TYPE := &"key"
const ROUTE_TILE_RANDOM_SALT := 1879
const FLOOR_TILE_ITEM_REF := "Road"
const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
]

func populate(
	target_grid_map: GridMap,
	floor_cells: Dictionary,
	player_cell_3d: Vector3i,
	end_gate_cell_3d: Vector3i,
	content_plan: Dictionary,
	destination: Destination,
	seed_value: int,
	placement_percent: float
) -> Dictionary:
	if target_grid_map == null or target_grid_map.mesh_library == null:
		return {
			"errors": ["Generated floor route requires a target MeshLibrary."],
			"route": [],
			"cells": [],
		}
	var item_refs := MESH_CATALOG_SCRIPT.ref_to_id(
		target_grid_map.mesh_library
	) as Dictionary
	if not item_refs.has(FLOOR_TILE_ITEM_REF):
		return {
			"errors": [
				"Generated floor route MeshLibrary has no '%s' item." \
					% FLOOR_TILE_ITEM_REF,
			],
			"route": [],
			"cells": [],
		}
	var floor_item_id := int(item_refs[FLOOR_TILE_ITEM_REF])
	var route := build_route(
		floor_cells,
		player_cell_3d,
		end_gate_cell_3d,
		content_plan,
		destination
	)
	var route_band := build_corridor_band(route, floor_cells)
	var selected_cells := select_tile_cells(
		route_band,
		seed_value,
		placement_percent,
		route[-1] if not route.is_empty() else Vector2i(-1, -1)
	)
	for cell in selected_cells:
		target_grid_map.set_cell_item(Vector3i(cell.x, 0, cell.y), floor_item_id)
	return {
		"errors": [],
		"route": route,
		"route_band": route_band,
		"cells": selected_cells,
	}


static func build_route(
	floor_cells: Dictionary,
	player_cell_3d: Vector3i,
	end_gate_cell_3d: Vector3i,
	content_plan: Dictionary,
	destination: Destination
) -> Array[Vector2i]:
	var player_cell := Vector2i(player_cell_3d.x, player_cell_3d.z)
	var destination_cell := Vector2i(end_gate_cell_3d.x, end_gate_cell_3d.z)
	if destination == Destination.GateKey:
		destination_cell = _find_gate_key_cell(content_plan)
	if destination_cell == Vector2i(-1, -1):
		return []

	var walkable := GRAPH_SCRIPT.normalise_walkable_cells(floor_cells) as Dictionary
	return GRAPH_SCRIPT.find_path(
		player_cell,
		destination_cell,
		walkable
	) as Array[Vector2i]


static func select_tile_cells(
	candidates: Array[Vector2i],
	seed_value: int,
	placement_percent: float,
	guaranteed_destination: Vector2i = Vector2i(-1, -1)
) -> Array[Vector2i]:
	var selected: Array[Vector2i] = []
	for cell in candidates:
		var coordinate_salt := GRAPH_SCRIPT.coordinate_score(
			cell,
			seed_value,
			ROUTE_TILE_RANDOM_SALT
		)
		if GRAPH_SCRIPT.chance_succeeds(
			seed_value,
			coordinate_salt,
			placement_percent
		):
			selected.append(cell)
	if placement_percent > 0.0 \
			and candidates.has(guaranteed_destination) \
			and not selected.has(guaranteed_destination):
		selected.append(guaranteed_destination)
	return selected


static func build_corridor_band(
	route: Array[Vector2i],
	floor_cells: Dictionary
) -> Array[Vector2i]:
	var band: Array[Vector2i] = []
	var included := {}
	for route_cell in route:
		_append_unique_cell(band, included, route_cell)
	for route_cell in route:
		for direction in CARDINAL_DIRECTIONS:
			var neighbour := route_cell + direction
			if floor_cells.has(neighbour):
				_append_unique_cell(band, included, neighbour)
	return band


static func _append_unique_cell(
	cells: Array[Vector2i],
	included: Dictionary,
	cell: Vector2i
) -> void:
	if included.has(cell):
		return
	included[cell] = true
	cells.append(cell)


static func _find_gate_key_cell(content_plan: Dictionary) -> Vector2i:
	for key_value in content_plan.get("keys", []):
		var key := key_value as Dictionary
		if key.get("item_type", &"") as StringName == GOLD_KEY_ITEM_TYPE:
			return key.get("cell", Vector2i(-1, -1)) as Vector2i
	return Vector2i(-1, -1)
