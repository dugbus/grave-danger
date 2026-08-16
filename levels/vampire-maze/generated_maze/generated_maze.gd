@tool
class_name GDSeededGridMaze
extends Node3D

## Builds a deterministic, two-tile-wide maze into child GridMaps, with the
## locked exit opposite the player and the vampire waiting safely inside it.

signal maze_generated(seed: int, generation_result: Dictionary)

enum MazeCell {
    Wall,
    Floor,
}

enum MazeConnectionAxis {
    Horizontal,
    Vertical,
}

const REPAIRER_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const MESH_CATALOG_SCRIPT := preload("res://addons/png_to_gridmap/png_to_gridmap_mesh_catalog.gd")
const GridBuilder := preload("res://levels/vampire-maze/generated_maze/generated_maze_grid_builder.gd")
const FloorRoute := preload("res://levels/vampire-maze/generated_maze/generated_floor_route.gd")
const LayoutBuilder := preload("res://levels/vampire-maze/generated_maze/generated_maze_layout_builder.gd")
const DEFAULT_CONFIG := preload("res://levels/vampire-maze/generated_maze/generated_maze_config.tres")
const CARDINAL_DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const BASE_WALL_ITEM_REF := "Wall"
const EDITOR_REGENERATION_DEBOUNCE_MILLISECONDS := 300
const PERIMETER_CONNECTIONS_PER_BREAK := 12
const INTERNAL_CONNECTION_RANDOM_SALT := 1597463007
const CURRENT_GENERATION_VERSION := 20

## Seed used for deterministic scene and runtime maze generation.
@export var maze_seed := 1:
    set(value):
        if maze_seed == value:
            return
        maze_seed = value
        _queue_regeneration()
## Shared dimensions and wall-repair rules used by this maze instance.
@export var configuration: Resource = DEFAULT_CONFIG:
    set(value):
        configuration = value
        _connect_configuration_changes()
        _queue_regeneration()
@export_group("Generated Floor")
## Material applied to every generated floor tile.
@export var floor_material: BaseMaterial3D:
    set(value):
        floor_material = value
        _queue_regeneration()
## Generated floor cells covered by one texture along the local X and Z/texture-Y axes.
@export var floor_texture_tiles := Vector2i.ONE:
    set(value):
        floor_texture_tiles = Vector2i(maxi(value.x, 1), maxi(value.y, 1))
        _queue_regeneration()
@export_group("")
@export_group("Routed Floor")
## Objective followed by the generated Road-tile corridor.
@export_enum("Gate", "Gate Key") var floor_tile_route_destination: int = FloorRoute.Destination.GateKey:
    set(value):
        if floor_tile_route_destination == value:
            return
        floor_tile_route_destination = value
        _queue_regeneration()
## Independent chance that each walkable cell across the objective corridor receives a Road tile.
@export_range(0.0, 100.0, 1.0, "suffix:%") var floor_tile_route_percent := 30.0:
    set(value):
        var clamped_value := clampf(value, 0.0, 100.0)
        if is_equal_approx(floor_tile_route_percent, clamped_value):
            return
        floor_tile_route_percent = clamped_value
        _queue_regeneration()
@export_group("")
## Child GridMap that receives generated and repaired wall cells.
@export var wall_grid_map_path: NodePath = ^"Layout/PNGGridMap"
## Child GridMap that receives a complete floor below the maze.
@export var floor_grid_map_path: NodePath = ^"Layout/PNGFloorGridMap"
## Player placed in the generated entrance corner.
@export var player_path: NodePath = ^"../Player"
## Vampire placed two cells inside the locked gate opposite the player.
@export var vampire_path: NodePath = ^"../Vampire"
## Child responsible for planning and instancing generated dungeon content.
@export var generated_content_path: NodePath = ^"Layout/GeneratedContent"
## Optional authored-content root disabled when generated budgets are active.
@export var authored_content_path: NodePath
## Height added above the generated floor for both character roots.
@export_range(0.0, 4.0, 0.05) var character_spawn_height := 0.05
## Allows live generation while editing; disable it to preserve manual level edits.
@export var generate_in_editor := true:
    set(value):
        if generate_in_editor == value:
            return
        generate_in_editor = value
        if generate_in_editor:
            _queue_regeneration()
## Freezes live regeneration and makes the current generated content persist for manual editing.
@export_tool_button("Freeze Generated Level") var freeze_generated_level_action: Callable:
    get:
        # Getter-backed callables survive tool-script hot reloads, where an
        # initialized Callable member can otherwise remain Nil.
        return Callable(self, &"freeze_generated_level_for_editing")
## Generator revision that produced serialized editor cells; used to avoid stale runtime reuse.
@export_storage var baked_generation_version := 0
## Seed that produced serialized editor cells; used to validate runtime reuse.
@export_storage var baked_maze_seed := -1
## Width of serialized editor cells; used to validate runtime reuse.
@export_storage var baked_width := 0
## Height of serialized editor cells; used to validate runtime reuse.
@export_storage var baked_height := 0

var _generation_queued := false
var _is_generating := false
var _connected_configuration: Resource
var _connected_content_configuration: Resource
var _last_regeneration_request_milliseconds := 0
var _grid_builder := GridBuilder.new()


func _ready() -> void:
    _connect_configuration_changes()
    if Engine.is_editor_hint() and not generate_in_editor:
        return
    var player := get_node_or_null(player_path) as Node3D
    var vampire := get_node_or_null(vampire_path) as Node3D
    if not Engine.is_editor_hint() and _can_reuse_runtime_grid_maps(configuration):
        _generate_from_config(configuration, maze_seed, player, vampire, false)
        return
    generate_from_config(configuration, maze_seed, player, vampire)


func _exit_tree() -> void:
    _disconnect_configuration_changes()

## Regenerates this node's GridMaps and configured characters using the current seed.
func regenerate_maze() -> Dictionary:
    var player := get_node_or_null(player_path) as Node3D
    var vampire := get_node_or_null(vampire_path) as Node3D
    return generate_from_config(configuration, maze_seed, player, vampire)

## Stops editor regeneration and preserves the current generated nodes for manual editing.
func freeze_generated_level_for_editing() -> void:
    if not Engine.is_editor_hint():
        return
    generate_in_editor = false
    _generation_queued = false
    var generated_content := get_node_or_null(generated_content_path)
    if generated_content != null and generated_content.has_method(&"make_generated_children_editable"):
        generated_content.call(&"make_generated_children_editable")
    EditorInterface.mark_scene_as_unsaved()
    notify_property_list_changed()


## Public runtime API used by future random-dungeon configuration and scene creation.
func generate_from_config(
    runtime_configuration: Resource,
    seed_value: int,
    player: Node3D = null,
    vampire: Node3D = null
) -> Dictionary:
    return _generate_from_config(
        runtime_configuration,
        seed_value,
        player,
        vampire,
        true
    )

func _generate_from_config(
    runtime_configuration: Resource,
    seed_value: int,
    player: Node3D,
    vampire: Node3D,
    populate_grid_maps: bool
) -> Dictionary:
    if _is_generating:
        return {"errors": ["Maze generation is already in progress."]}
    _is_generating = true
    maze_seed = seed_value

    var errors: Array[String] = []
    if runtime_configuration == null:
        errors.append("GeneratedMaze requires a configuration resource.")
    elif populate_grid_maps and LayoutBuilder.replace(self) == null:
        errors.append("GeneratedMaze could not create its Layout node.")
    var wall_grid_map := get_node_or_null(wall_grid_map_path) as GridMap
    var floor_grid_map := get_node_or_null(floor_grid_map_path) as GridMap
    if wall_grid_map == null:
        errors.append("GeneratedMaze could not find its wall GridMap.")
    if floor_grid_map == null:
        errors.append("GeneratedMaze could not find its floor GridMap.")
    if not errors.is_empty():
        _is_generating = false
        return {"errors": errors}

    GDGeneratedFloorSettings.apply(
        floor_grid_map,
        floor_material,
        floor_texture_tiles
    )
    var width := maxi(int(runtime_configuration.get("width")), 7)
    var height := maxi(int(runtime_configuration.get("height")), 7)
    var hallway_width := maxi(int(runtime_configuration.get("hallway_width")), 1)
    var internal_connection_percent := clampf(
        float(runtime_configuration.get("internal_connection_percent")),
        0.0,
        100.0
    )
    var internal_connection_count := _get_internal_connection_count(
        width,
        height,
        hallway_width,
        internal_connection_percent
    )
    var floor_cells := _build_floor_cells(
        width,
        height,
        hallway_width,
        seed_value,
        internal_connection_percent
    )
    if bool(runtime_configuration.get("carve_spawn_sightline")):
        _carve_spawn_sightline(floor_cells, width, hallway_width)
    if bool(runtime_configuration.get("carve_end_gate_opening")):
        _carve_end_gate_opening(
            floor_cells,
            width,
            height,
            hallway_width
        )

    if populate_grid_maps:
        var placement_errors := _populate_grid_maps(
            wall_grid_map,
            floor_grid_map,
            floor_cells,
            width,
            height,
            runtime_configuration.get("wall_repair_settings") as Resource
        )
        errors.append_array(placement_errors)
        if Engine.is_editor_hint() and placement_errors.is_empty():
            baked_generation_version = CURRENT_GENERATION_VERSION
            baked_maze_seed = seed_value
            baked_width = width
            baked_height = height
    else:
        errors.append_array(
            _synchronize_baked_end_gate_opening(
                wall_grid_map,
                width,
                height,
                hallway_width,
                runtime_configuration.get("wall_repair_settings") as Resource
            )
        )

    var logical_layout := _get_logical_maze_layout(
        width,
        height,
        hallway_width
    )
    var end_gate_layout := _get_end_gate_layout(
        width,
        height,
        hallway_width
    )
    var end_gate_opening_width := 1
    var player_cell := Vector3i(1, 0, 1)
    var vampire_cell := end_gate_layout["vampire_cell"] as Vector3i
    var end_gate_cell := end_gate_layout["end_gate_cell"] as Vector3i
    var player_spawn := _spawn_transform_for_cell(wall_grid_map, player_cell, character_spawn_height)
    var vampire_spawn := _spawn_transform_for_cell(wall_grid_map, vampire_cell, character_spawn_height)
    var end_gate_spawn := _end_gate_transform(
        wall_grid_map,
        end_gate_cell
    )
    _place_character(player, player_spawn)
    _place_character(vampire, vampire_spawn)
    _disable_authored_content()

    var result := {
        "errors": errors,
        "seed": seed_value,
        "width": width,
        "height": height,
        "hallway_width": hallway_width,
        "maze_origin": logical_layout["origin"],
        "logical_width": int(logical_layout["width"]),
        "logical_height": int(logical_layout["height"]),
        "internal_connection_percent": internal_connection_percent,
        "internal_connection_count": internal_connection_count,
        "reused_grid_maps": not populate_grid_maps,
        "floor_cells": floor_cells.keys(),
        "player_cell": player_cell,
        "vampire_cell": vampire_cell,
        "end_gate_cell": end_gate_cell,
        "end_gate_passage_origin_x": int(end_gate_layout["passage_origin_x"]),
        "end_gate_opening_origin_x": end_gate_cell.x,
        "end_gate_opening_width_tiles": end_gate_opening_width,
        "end_gate_outward_direction": Vector2i.DOWN,
        "player_spawn": player_spawn,
        "vampire_spawn": vampire_spawn,
        "end_gate_spawn": end_gate_spawn,
    }
    var generated_content := get_node_or_null(generated_content_path)
    var content_configuration := runtime_configuration.get("content_configuration") as Resource
    var content_plan := {}
    if generated_content != null and generated_content.has_method("regenerate_content") \
            and content_configuration != null:
        content_plan = generated_content.call(
            &"regenerate_content",
            floor_cells,
            result,
            seed_value,
            floor_grid_map,
            content_configuration,
            player,
            vampire as PhysicsBody3D
        ) as Dictionary
        result["content_plan"] = content_plan
        if generated_content.has_method("get_end_gate"):
            result["end_gate"] = generated_content.call(&"get_end_gate") as Node3D
        for content_error in content_plan.get("errors", []):
            errors.append(String(content_error))
        for content_warning in content_plan.get("warnings", []):
            push_warning(String(content_warning))
    var floor_route := FloorRoute.new()
    var floor_route_result := floor_route.populate(
        wall_grid_map,
        floor_cells,
        player_cell,
        end_gate_cell,
        content_plan,
        floor_tile_route_destination as FloorRoute.Destination,
        seed_value,
        floor_tile_route_percent
    ) as Dictionary
    for floor_route_error in floor_route_result.get("errors", []):
        errors.append(String(floor_route_error))
    result["floor_tile_route"] = floor_route_result.get("route", [])
    result["floor_tile_route_band"] = floor_route_result.get("route_band", [])
    result["routed_floor_cells"] = floor_route_result.get("cells", [])
    _is_generating = false
    maze_generated.emit(seed_value, result)
    return result


func _can_reuse_runtime_grid_maps(runtime_configuration: Resource) -> bool:
    if runtime_configuration == null:
        return false
    var wall_grid_map := get_node_or_null(wall_grid_map_path) as GridMap
    var floor_grid_map := get_node_or_null(floor_grid_map_path) as GridMap
    if wall_grid_map == null or floor_grid_map == null:
        return false

    var width := maxi(int(runtime_configuration.get("width")), 7)
    var height := maxi(int(runtime_configuration.get("height")), 7)
    if baked_generation_version != CURRENT_GENERATION_VERSION \
            or baked_maze_seed != maze_seed \
            or baked_width != width \
            or baked_height != height:
        return false
    if floor_grid_map.get_used_cells().size() != width * height:
        return false
    if floor_grid_map.get_cell_item(Vector3i.ZERO) == GridMap.INVALID_CELL_ITEM \
            or floor_grid_map.get_cell_item(
                Vector3i(width - 1, 0, height - 1)
            ) == GridMap.INVALID_CELL_ITEM:
        return false
    return not wall_grid_map.get_used_cells().is_empty()


func _synchronize_baked_end_gate_opening(
    wall_grid_map: GridMap,
    width: int,
    height: int,
    hallway_width: int,
    wall_repair_settings: Resource
) -> Array[String]:
    var opening_cells := {}
    _carve_end_gate_opening(
        opening_cells,
        width,
        height,
        hallway_width
    )
    var changed := false
    for opening_cell_value in opening_cells:
        var opening_cell := opening_cell_value as Vector2i
        var wall_cell := Vector3i(opening_cell.x, 0, opening_cell.y)
        if wall_grid_map.get_cell_item(wall_cell) == GridMap.INVALID_CELL_ITEM:
            continue
        wall_grid_map.set_cell_item(wall_cell, GridMap.INVALID_CELL_ITEM)
        changed = true
    if not changed:
        return []
    return _repair_wall_cells(wall_grid_map, wall_repair_settings)


func _queue_regeneration() -> void:
    if _is_generating or not is_inside_tree():
        return
    if Engine.is_editor_hint() and not generate_in_editor:
        return
    _last_regeneration_request_milliseconds = Time.get_ticks_msec()
    if _generation_queued:
        return
    _generation_queued = true
    call_deferred(&"_run_queued_regeneration")


func _run_queued_regeneration() -> void:
    if not is_inside_tree():
        _generation_queued = false
        return
    if Engine.is_editor_hint():
        var quiet_milliseconds := (
            Time.get_ticks_msec() - _last_regeneration_request_milliseconds
        )
        if quiet_milliseconds < EDITOR_REGENERATION_DEBOUNCE_MILLISECONDS:
            var remaining_seconds := float(
                EDITOR_REGENERATION_DEBOUNCE_MILLISECONDS - quiet_milliseconds
            ) / 1000.0
            get_tree().create_timer(remaining_seconds).timeout.connect(
                _run_queued_regeneration,
                CONNECT_ONE_SHOT
            )
            return
    _generation_queued = false
    regenerate_maze()


func _connect_configuration_changes() -> void:
    if not is_inside_tree():
        return
    if _connected_configuration != configuration:
        _disconnect_configuration_changes()
        _connected_configuration = configuration
        if _connected_configuration != null:
            _connected_configuration.changed.connect(_on_configuration_changed)

    var content_configuration: Resource
    if configuration != null:
        content_configuration = configuration.get("content_configuration") as Resource
    if _connected_content_configuration == content_configuration:
        return
    if _connected_content_configuration != null \
            and _connected_content_configuration.changed.is_connected(_on_content_configuration_changed):
        _connected_content_configuration.changed.disconnect(_on_content_configuration_changed)
    _connected_content_configuration = content_configuration
    if _connected_content_configuration != null:
        _connected_content_configuration.changed.connect(_on_content_configuration_changed)


func _disconnect_configuration_changes() -> void:
    if _connected_configuration != null \
            and _connected_configuration.changed.is_connected(_on_configuration_changed):
        _connected_configuration.changed.disconnect(_on_configuration_changed)
    if _connected_content_configuration != null \
            and _connected_content_configuration.changed.is_connected(_on_content_configuration_changed):
        _connected_content_configuration.changed.disconnect(_on_content_configuration_changed)
    _connected_configuration = null
    _connected_content_configuration = null


func _on_configuration_changed() -> void:
    _connect_configuration_changes()
    _queue_regeneration()


func _on_content_configuration_changed() -> void:
    # Content changes reuse the current seed, leaving independently generated
    # maze geometry and structural placements stable.
    _queue_regeneration()


func _build_floor_cells(
    width: int,
    height: int,
    hallway_width: int,
    seed_value: int,
    internal_connection_percent: float = 0.0
) -> Dictionary:
    var floor_cells := {}
    var logical_layout := _get_logical_maze_layout(
        width,
        height,
        hallway_width
    )
    var logical_width := int(logical_layout["width"])
    var logical_height := int(logical_layout["height"])
    var maze_origin := logical_layout["origin"] as Vector2i
    if logical_width <= 0 or logical_height <= 0:
        return floor_cells

    var random := RandomNumberGenerator.new()
    random.seed = seed_value
    var start := Vector2i(
        random.randi_range(1, logical_width - 2) if logical_width > 2 else 0,
        random.randi_range(1, logical_height - 2) if logical_height > 2 else 0
    )
    var visited := {start: true}
    var stack: Array[Vector2i] = [start]
    _carve_logical_cell(floor_cells, start, hallway_width, maze_origin)

    while not stack.is_empty():
        var current := stack.back() as Vector2i
        var directions := _shuffled_directions(random)
        var advanced := false
        for direction in directions:
            var neighbour: Vector2i = current + direction
            if neighbour.x < 0 or neighbour.y < 0:
                continue
            if neighbour.x >= logical_width or neighbour.y >= logical_height:
                continue
            if not _logical_transition_is_allowed(
                current,
                neighbour,
                logical_width,
                logical_height
            ):
                continue
            if visited.has(neighbour):
                continue
            visited[neighbour] = true
            _carve_logical_cell(
                floor_cells,
                neighbour,
                hallway_width,
                maze_origin
            )
            _carve_connection(
                floor_cells,
                current,
                neighbour,
                hallway_width,
                maze_origin
            )
            stack.append(neighbour)
            advanced = true
            break
        if not advanced:
            stack.pop_back()
    _carve_internal_connections(
        floor_cells,
        logical_width,
        logical_height,
        hallway_width,
        seed_value,
        internal_connection_percent,
        maze_origin
    )
    return floor_cells


func _get_internal_connection_count(
    width: int,
    height: int,
    hallway_width: int,
    internal_connection_percent: float
) -> int:
    var logical_layout := _get_logical_maze_layout(
        width,
        height,
        hallway_width
    )
    var logical_width := int(logical_layout["width"])
    var logical_height := int(logical_layout["height"])
    if logical_width <= 0 or logical_height <= 0 \
            or internal_connection_percent <= 0.0:
        return 0
    var connected_logical_cells := {}
    var possible_connection_count := 0
    for logical_z in logical_height:
        for logical_x in logical_width:
            var logical_cell := Vector2i(logical_x, logical_z)
            if logical_x + 1 < logical_width and _logical_transition_is_allowed(
                logical_cell,
                logical_cell + Vector2i.RIGHT,
                logical_width,
                logical_height
            ):
                connected_logical_cells[logical_cell] = true
                connected_logical_cells[logical_cell + Vector2i.RIGHT] = true
                possible_connection_count += 1
            if logical_z + 1 < logical_height and _logical_transition_is_allowed(
                logical_cell,
                logical_cell + Vector2i.DOWN,
                logical_width,
                logical_height
            ):
                connected_logical_cells[logical_cell] = true
                connected_logical_cells[logical_cell + Vector2i.DOWN] = true
                possible_connection_count += 1
    var logical_cell_count := connected_logical_cells.size()
    if logical_cell_count <= 1:
        return 0
    var closed_connection_count := possible_connection_count \
        - (logical_cell_count - 1)
    if closed_connection_count <= 0:
        return 0
    return mini(
        ceili(
            float(closed_connection_count)
            * clampf(internal_connection_percent, 0.0, 100.0)
            / 100.0
        ),
        closed_connection_count
    )


func _carve_internal_connections(
    floor_cells: Dictionary,
    logical_width: int,
    logical_height: int,
    hallway_width: int,
    seed_value: int,
    internal_connection_percent: float,
    maze_origin: Vector2i
) -> void:
    if internal_connection_percent <= 0.0:
        return
    var candidates: Array[Dictionary] = []
    for logical_z in logical_height:
        for logical_x in logical_width:
            var logical_cell := Vector2i(logical_x, logical_z)
            if logical_x + 1 < logical_width and _logical_transition_is_allowed(
                logical_cell,
                logical_cell + Vector2i.RIGHT,
                logical_width,
                logical_height
            ):
                _append_internal_connection_candidate(
                    candidates,
                    floor_cells,
                    logical_cell,
                    logical_cell + Vector2i.RIGHT,
                    MazeConnectionAxis.Horizontal,
                    hallway_width,
                    maze_origin
                )
            if logical_z + 1 < logical_height and _logical_transition_is_allowed(
                logical_cell,
                logical_cell + Vector2i.DOWN,
                logical_width,
                logical_height
            ):
                _append_internal_connection_candidate(
                    candidates,
                    floor_cells,
                    logical_cell,
                    logical_cell + Vector2i.DOWN,
                    MazeConnectionAxis.Vertical,
                    hallway_width,
                    maze_origin
                )
    var connection_random := RandomNumberGenerator.new()
    connection_random.seed = seed_value ^ INTERNAL_CONNECTION_RANDOM_SALT
    for candidate_index in candidates.size():
        candidates[candidate_index]["score"] = connection_random.randi()
    candidates.sort_custom(_sort_internal_connection_candidate)
    var requested_count := mini(
        ceili(
            float(candidates.size())
            * clampf(internal_connection_percent, 0.0, 100.0)
            / 100.0
        ),
        candidates.size()
    )
    for candidate_index in mini(requested_count, candidates.size()):
        var candidate := candidates[candidate_index]
        _carve_connection(
            floor_cells,
            candidate["from"] as Vector2i,
            candidate["to"] as Vector2i,
            hallway_width,
            maze_origin
        )


func _logical_transition_is_allowed(
    from_cell: Vector2i,
    to_cell: Vector2i,
    logical_width: int,
    logical_height: int
) -> bool:
    if not _is_logical_boundary_cell(from_cell, logical_width, logical_height) \
            or not _is_logical_boundary_cell(to_cell, logical_width, logical_height):
        return true
    var connection_index := -1
    var connection_count := 0
    if from_cell.y == to_cell.y \
            and (from_cell.y == 0 or from_cell.y == logical_height - 1):
        connection_index = mini(from_cell.x, to_cell.x)
        connection_count = logical_width - 1
    elif from_cell.x == to_cell.x \
            and (from_cell.x == 0 or from_cell.x == logical_width - 1):
        connection_index = mini(from_cell.y, to_cell.y)
        connection_count = logical_height - 1
    if connection_index < 0:
        return true
    return not _perimeter_connection_is_break(connection_index, connection_count)


func _perimeter_connection_is_break(
    connection_index: int,
    connection_count: int
) -> bool:
    # Sparse breaks stop the border becoming a bypass while leaving its
    # corridors looking and behaving like the rest of the generated maze.
    if connection_count < 4:
        return false
    var break_count := maxi(
        ceili(float(connection_count) / float(PERIMETER_CONNECTIONS_PER_BREAK)),
        1
    )
    for break_index in break_count:
        var break_connection := floori(
            float(break_index + 1)
            * float(connection_count)
            / float(break_count + 1)
        )
        if connection_index == clampi(break_connection, 1, connection_count - 2):
            return true
    return false


func _is_logical_boundary_cell(
    cell: Vector2i,
    logical_width: int,
    logical_height: int
) -> bool:
    return cell.x == 0 or cell.y == 0 \
        or cell.x == logical_width - 1 \
        or cell.y == logical_height - 1


func _append_internal_connection_candidate(
    candidates: Array[Dictionary],
    floor_cells: Dictionary,
    from_cell: Vector2i,
    to_cell: Vector2i,
    axis: MazeConnectionAxis,
    hallway_width: int,
    maze_origin: Vector2i
) -> void:
    if _logical_connection_is_open(
        floor_cells,
        from_cell,
        to_cell,
        hallway_width,
        maze_origin
    ):
        return
    candidates.append({
        "from": from_cell,
        "to": to_cell,
        "axis": axis,
        "score": 0,
    })


func _logical_connection_is_open(
    floor_cells: Dictionary,
    from_cell: Vector2i,
    to_cell: Vector2i,
    hallway_width: int,
    maze_origin: Vector2i
) -> bool:
    var from_origin := maze_origin + from_cell * (hallway_width + 1)
    var connection_cell := from_origin
    if to_cell.x > from_cell.x:
        connection_cell.x += hallway_width
    else:
        connection_cell.y += hallway_width
    return floor_cells.has(connection_cell)


func _sort_internal_connection_candidate(first: Dictionary, second: Dictionary) -> bool:
    var first_score := int(first["score"])
    var second_score := int(second["score"])
    if first_score != second_score:
        return first_score < second_score
    var first_cell := first["from"] as Vector2i
    var second_cell := second["from"] as Vector2i
    if first_cell.y != second_cell.y:
        return first_cell.y < second_cell.y
    if first_cell.x != second_cell.x:
        return first_cell.x < second_cell.x
    return int(first["axis"]) < int(second["axis"])


func _shuffled_directions(random: RandomNumberGenerator) -> Array[Vector2i]:
    var directions: Array[Vector2i] = CARDINAL_DIRECTIONS.duplicate()
    for index in range(directions.size() - 1, 0, -1):
        var swap_index := random.randi_range(0, index)
        var held := directions[index]
        directions[index] = directions[swap_index]
        directions[swap_index] = held
    return directions


func _carve_logical_cell(
    floor_cells: Dictionary,
    logical_cell: Vector2i,
    hallway_width: int,
    maze_origin: Vector2i
) -> void:
    var origin := maze_origin + logical_cell * (hallway_width + 1)
    for z_offset in hallway_width:
        for x_offset in hallway_width:
            floor_cells[origin + Vector2i(x_offset, z_offset)] = MazeCell.Floor


func _carve_connection(
    floor_cells: Dictionary,
    from_cell: Vector2i,
    to_cell: Vector2i,
    hallway_width: int,
    maze_origin: Vector2i
) -> void:
    var from_origin := maze_origin + from_cell * (hallway_width + 1)
    if to_cell.x > from_cell.x:
        for offset in hallway_width:
            floor_cells[Vector2i(from_origin.x + hallway_width, from_origin.y + offset)] = MazeCell.Floor
    elif to_cell.x < from_cell.x:
        for offset in hallway_width:
            floor_cells[Vector2i(from_origin.x - 1, from_origin.y + offset)] = MazeCell.Floor
    elif to_cell.y > from_cell.y:
        for offset in hallway_width:
            floor_cells[Vector2i(from_origin.x + offset, from_origin.y + hallway_width)] = MazeCell.Floor
    else:
        for offset in hallway_width:
            floor_cells[Vector2i(from_origin.x + offset, from_origin.y - 1)] = MazeCell.Floor


func _carve_spawn_sightline(floor_cells: Dictionary, width: int, hallway_width: int) -> void:
    for x_coordinate in range(1, width - 1):
        for z_coordinate in range(1, 1 + hallway_width):
            floor_cells[Vector2i(x_coordinate, z_coordinate)] = MazeCell.Floor


func _carve_end_gate_opening(
    floor_cells: Dictionary,
    width: int,
    height: int,
    hallway_width: int
) -> void:
    var logical_layout := _get_logical_maze_layout(
        width,
        height,
        hallway_width
    )
    var end_gate_layout := _get_end_gate_layout(
        width,
        height,
        hallway_width
    )
    var maze_origin := logical_layout["origin"] as Vector2i
    var logical_height := int(logical_layout["height"])
    var passage_origin_x := int(end_gate_layout["passage_origin_x"])
    var last_logical_origin_y := maze_origin.y \
        + (logical_height - 1) * (hallway_width + 1)

    # Bring the full hallway to the inside edge, then pierce the boundary at
    # only the gate lane so the authored gate occupies one unscaled tile.
    for x_coordinate in range(
        passage_origin_x,
        mini(passage_origin_x + hallway_width, width)
    ):
        for z_coordinate in range(last_logical_origin_y, height - 1):
            floor_cells[Vector2i(x_coordinate, z_coordinate)] = MazeCell.Floor
    var gate_cell := end_gate_layout["end_gate_cell"] as Vector3i
    floor_cells[Vector2i(gate_cell.x, gate_cell.z)] = MazeCell.Floor



func _get_end_gate_layout(
    width: int,
    height: int,
    hallway_width: int
) -> Dictionary:
    var logical_layout := _get_logical_maze_layout(
        width,
        height,
        hallway_width
    )
    var maze_origin := logical_layout["origin"] as Vector2i
    var logical_width := int(logical_layout["width"])
    var preferred_logical_x := maxi(logical_width - 2, 0)
    var preferred_origin_x := maze_origin.x \
        + preferred_logical_x * (hallway_width + 1)
    var minimum_origin_x := maze_origin.x
    var maximum_origin_x := maxi(
        width - hallway_width - 1,
        minimum_origin_x
    )
    var passage_origin_x := clampi(
        preferred_origin_x,
        minimum_origin_x,
        maximum_origin_x
    )
    var route_lane_x := mini(
        passage_origin_x + floori(float(hallway_width) * 0.5),
        width - 2
    )
    return {
        "passage_origin_x": passage_origin_x,
        "end_gate_cell": Vector3i(route_lane_x, 0, height - 1),
        "vampire_cell": Vector3i(route_lane_x, 0, height - 3),
    }


func _get_logical_maze_layout(
    width: int,
    height: int,
    hallway_width: int
) -> Dictionary:
    return {
        "origin": Vector2i.ONE,
        "width": maxi(
            floori(float(width - 1) / float(hallway_width + 1)),
            1
        ),
        "height": maxi(
            floori(float(height - 1) / float(hallway_width + 1)),
            1
        ),
    }


func _populate_grid_maps(
    wall_grid_map: GridMap,
    floor_grid_map: GridMap,
    floor_cells: Dictionary,
    width: int,
    height: int,
    wall_repair_settings: Resource
) -> Array[String]:
    return _grid_builder.populate(
        wall_grid_map,
        floor_grid_map,
        floor_cells,
        width,
        height,
        floor_texture_tiles,
        wall_repair_settings
    )


func _repair_wall_cells(wall_grid_map: GridMap, wall_repair_settings: Resource) -> Array[String]:
    return _grid_builder.repair(wall_grid_map, wall_repair_settings)


func _spawn_transform_for_cell(grid_map: GridMap, cell: Vector3i, height_offset: float) -> Transform3D:
    var world_position := grid_map.to_global(grid_map.map_to_local(cell))
    world_position.y += height_offset
    return Transform3D(Basis.IDENTITY, world_position)


func _end_gate_transform(
    grid_map: GridMap,
    gate_cell: Vector3i
) -> Transform3D:
    var gate_position := grid_map.to_global(grid_map.map_to_local(gate_cell))
    return Transform3D(Basis(Vector3.UP, PI * 0.5), gate_position)


func _place_character(character: Node3D, spawn_transform: Transform3D) -> void:
    if character == null:
        return
    character.global_transform = spawn_transform


func _disable_authored_content() -> void:
    if authored_content_path.is_empty():
        return
    var authored_content := get_node_or_null(authored_content_path)
    if authored_content == null:
        return
    authored_content.process_mode = Node.PROCESS_MODE_DISABLED
    if authored_content is Node3D:
        (authored_content as Node3D).visible = false
    _disable_authored_collisions(authored_content)


func _disable_authored_collisions(node: Node) -> void:
    if node is CollisionObject3D:
        var collision_object := node as CollisionObject3D
        collision_object.collision_layer = 0
        collision_object.collision_mask = 0
    if node is CollisionShape3D:
        (node as CollisionShape3D).disabled = true
    for child in node.get_children():
        _disable_authored_collisions(child)
