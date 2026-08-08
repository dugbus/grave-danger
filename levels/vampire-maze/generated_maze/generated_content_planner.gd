@tool
class_name GDGeneratedDungeonContentPlanner
extends RefCounted

## Produces a deterministic, solvable content plan before any scenes are instanced.

enum PlacementBand {
    MainPath,
    Exploration,
}

const GRAPH_SCRIPT := preload(
    "res://levels/vampire-maze/generated_maze/generated_maze_graph.gd"
)
const ContentPlan := preload(
    "res://levels/vampire-maze/generated_maze/generated_content_plan.gd"
)
const TreasureBudget := preload(
    "res://levels/vampire-maze/generated_maze/generated_treasure_budget.gd"
)
const CellSelector := preload(
    "res://levels/vampire-maze/generated_maze/generated_content_cell_selector.gd"
)
const TREASURE_TYPES: Array[StringName] = [
    &"gold_coin",
    &"diamond",
    &"ruby",
    &"sapphire",
    &"emerald",
    &"amethyst",
    &"gold_bar",
]
const GEM_TYPES: Array[StringName] = [
    &"diamond",
    &"ruby",
    &"sapphire",
    &"emerald",
    &"amethyst",
]
const TREASURE_ITEMS := {
    &"gold_coin": preload("res://placeables/treasure/gold_coin_inventory.tres"),
    &"diamond": preload("res://placeables/treasure/gems/diamond_inventory.tres"),
    &"ruby": preload("res://placeables/treasure/gems/ruby_inventory.tres"),
    &"sapphire": preload("res://placeables/treasure/gems/sapphire_inventory.tres"),
    &"emerald": preload("res://placeables/treasure/gems/emerald_inventory.tres"),
    &"amethyst": preload("res://placeables/treasure/gems/amethyst_inventory.tres"),
    &"gold_bar": preload("res://placeables/treasure/gold_bar_inventory.tres"),
}
const GOLD_KEY_ITEM_TYPE := &"key"
const SILVER_KEY_ITEM_TYPE := &"silver_key"
const MIN_PLACEMENT_DISTANCE_FROM_SPAWN := 3
const MIN_EXIT_KEY_DISTANCE_FROM_GATE_TILES := 8
const DOOR_APPROACH_CLEARANCE_TILES := 2
var _treasure_budget := TreasureBudget.new()


## Returns route and placement data suitable for editor or runtime scene creation.
func build_plan(
    floor_cells: Dictionary,
    player_cell_3d: Vector3i,
    vampire_cell_3d: Vector3i,
    end_gate_cell_3d: Vector3i,
    map_size: Vector2i,
    seed_value: int,
    configuration: Resource
) -> Dictionary:
    var errors: Array[String] = []
    var warnings: Array[String] = []
    if configuration == null:
        return {"errors": ["Generated dungeon content requires a configuration resource."]}

    var walkable := GRAPH_SCRIPT.normalise_walkable_cells(floor_cells) as Dictionary
    var player_cell := Vector2i(player_cell_3d.x, player_cell_3d.z)
    var vampire_cell := Vector2i(vampire_cell_3d.x, vampire_cell_3d.z)
    var end_gate_cell := Vector2i(end_gate_cell_3d.x, end_gate_cell_3d.z)
    var main_path := GRAPH_SCRIPT.find_path(player_cell, end_gate_cell, walkable) \
        as Array[Vector2i]
    if main_path.is_empty():
        return {"errors": ["Generated dungeon has no route from the player to the end gate."]}

    var distance_from_main_path := GRAPH_SCRIPT.build_distances_from_sources(
        main_path,
        walkable
    ) as Dictionary
    var occupied := {
        player_cell: true,
        vampire_cell: true,
        end_gate_cell: true,
    }
    _occupy_straight_passage_between(occupied, vampire_cell, end_gate_cell)
    var door_result := _plan_doors_and_keys(
        main_path,
        walkable,
        distance_from_main_path,
        occupied,
        seed_value,
        configuration
    )
    var doors: Array = door_result.get("doors", []) as Array
    var keys: Array = door_result.get("keys", []) as Array
    for warning_value in door_result.get("warnings", []):
        warnings.append(String(warning_value))
    for door_value in doors:
        var door := door_value as Dictionary
        _occupy_door_clearance(occupied, door)
    for key_value in keys:
        var key := key_value as Dictionary
        occupied[key["cell"] as Vector2i] = true
    var hazard_occupied := occupied.duplicate()

    var treasure_budgets := _get_treasure_budgets(configuration)
    var treasure_caches := _plan_treasure_caches(
        main_path,
        walkable,
        distance_from_main_path,
        occupied,
        map_size,
        treasure_budgets,
        seed_value,
        configuration,
        errors
    )
    for cache_value in treasure_caches:
        var cache := cache_value as Dictionary
        occupied[cache["cell"] as Vector2i] = true

    var placed_budgets := _sum_cache_budgets(treasure_caches)
    treasure_budgets[&"gold_coin"] = int(placed_budgets.get(&"gold_coin", 0))
    if placed_budgets != treasure_budgets:
        errors.append("Generated treasure pile counts do not match the configured budgets.")

    var total_treasure_weight := _get_total_treasure_weight(treasure_budgets)
    var treasure_cells: Array[Vector2i] = []
    for cache_value in treasure_caches:
        var cache := cache_value as Dictionary
        treasure_cells.append(cache["cell"] as Vector2i)
    var coffins := _plan_coffins(
        main_path,
        walkable,
        distance_from_main_path,
        occupied,
        treasure_cells,
        map_size,
        total_treasure_weight,
        configuration,
        seed_value
    )
    for coffin_value in coffins:
        var coffin := coffin_value as Dictionary
        occupied[coffin["cell"] as Vector2i] = true

    var bat_nests := _plan_bat_nests(
        main_path,
        walkable,
        distance_from_main_path,
        occupied,
        hazard_occupied,
        seed_value,
        configuration
    )

    var plan := ContentPlan.new()
    plan.errors = errors
    plan.warnings = warnings
    plan.seed_value = seed_value
    plan.main_path = main_path
    plan.main_path_cells = GRAPH_SCRIPT.cells_to_vector3i(main_path)
    plan.doors = doors
    plan.keys = keys
    plan.coffins = coffins
    plan.treasure_caches = treasure_caches
    plan.bat_nests = bat_nests
    plan.treasure_budgets = treasure_budgets
    plan.placed_treasure_budgets = placed_budgets
    plan.total_treasure_weight = total_treasure_weight
    plan.main_path_treasure_percent = float(configuration.get("main_path_treasure_percent"))
    return plan.to_dictionary()


func _occupy_straight_passage_between(
    occupied: Dictionary,
    first_cell: Vector2i,
    second_cell: Vector2i
) -> void:
    if first_cell.x == second_cell.x:
        for y_coordinate in range(
            mini(first_cell.y, second_cell.y) + 1,
            maxi(first_cell.y, second_cell.y)
        ):
            occupied[Vector2i(first_cell.x, y_coordinate)] = true
    elif first_cell.y == second_cell.y:
        for x_coordinate in range(
            mini(first_cell.x, second_cell.x) + 1,
            maxi(first_cell.x, second_cell.x)
        ):
            occupied[Vector2i(x_coordinate, first_cell.y)] = true


func _plan_doors_and_keys(
    main_path: Array[Vector2i],
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    seed_value: int,
    configuration: Resource
) -> Dictionary:
    var requested_count := maxi(int(configuration.get("door_count")), 0)
    var minimum_spacing := maxi(int(configuration.get("minimum_door_spacing")), 3)
    var candidates := _find_gating_door_candidates(main_path, walkable)
    var doors := _select_door_candidates(candidates, requested_count, main_path.size(), minimum_spacing)
    var warnings: Array[String] = []
    if doors.size() < requested_count:
        warnings.append(
            "Requested %d doors but only %d guaranteed route cut points were available."
            % [requested_count, doors.size()]
        )

    for door_value in doors:
        var occupied_door := door_value as Dictionary
        _occupy_door_clearance(occupied, occupied_door)

    var keys: Array[Dictionary] = []
    var path_lookup := GRAPH_SCRIPT.build_path_lookup(main_path) as Dictionary
    for door_index in doors.size():
        var blocked := {}
        for future_index in range(door_index, doors.size()):
            var future_door := doors[future_index] as Dictionary
            for blocked_cell in future_door.get("blocked_cells", []):
                blocked[blocked_cell as Vector2i] = true
        var reachable := GRAPH_SCRIPT.get_reachable_cells(
            main_path[0],
            walkable,
            blocked
        ) as Dictionary
        var door := doors[door_index] as Dictionary
        var should_hide := GRAPH_SCRIPT.chance_succeeds(
            seed_value,
            door_index + 101,
            float(configuration.get("key_off_path_percent"))
        )
        var key_cell := _select_key_cell(
            reachable,
            path_lookup,
            distance_from_main_path,
            occupied,
            int(door["route_index"]),
            should_hide,
            seed_value,
            door_index
        )
        if key_cell == Vector2i(-1, -1):
            warnings.append("Door %d has no distinct key placement cell." % [door_index + 1])
            continue
        occupied[key_cell] = true
        keys.append({
            "cell": key_cell,
            "cell_3d": Vector3i(key_cell.x, 0, key_cell.y),
            "item_type": SILVER_KEY_ITEM_TYPE,
            "unlocks_door_index": door_index,
            "off_main_path": int(distance_from_main_path.get(key_cell, 0)) > 0,
        })

    var exit_key_cell := _select_exit_key_cell(
        main_path,
        walkable,
        distance_from_main_path,
        occupied,
        seed_value
    )
    if exit_key_cell != Vector2i(-1, -1):
        occupied[exit_key_cell] = true
        keys.append({
            "cell": exit_key_cell,
            "cell_3d": Vector3i(exit_key_cell.x, 0, exit_key_cell.y),
            "item_type": GOLD_KEY_ITEM_TYPE,
            "unlocks_door_index": doors.size(),
            "off_main_path": int(distance_from_main_path.get(exit_key_cell, 0)) > 0,
        })
    else:
        warnings.append("The generated end gate has no distinct gold-key placement cell.")
    return {"doors": doors, "keys": keys, "warnings": warnings}


func _find_gating_door_candidates(
    main_path: Array[Vector2i],
    walkable: Dictionary
) -> Array[Dictionary]:
    var candidates: Array[Dictionary] = []
    for route_index in range(4, main_path.size() - 4):
        var previous := main_path[route_index - 1]
        var current := main_path[route_index]
        var next := main_path[route_index + 1]
        var incoming := current - previous
        var outgoing := next - current
        if incoming != outgoing:
            continue

        var perpendicular := Vector2i(-incoming.y, incoming.x)
        var side_cells: Array[Vector2i] = []
        if walkable.has(current + perpendicular):
            side_cells.append(current + perpendicular)
        if walkable.has(current - perpendicular):
            side_cells.append(current - perpendicular)
        if side_cells.size() != 1:
            continue

        var blocked_cells: Array[Vector2i] = [current, side_cells[0]]
        var blocked := {blocked_cells[0]: true, blocked_cells[1]: true}
        if not GRAPH_SCRIPT.find_path(
            main_path[0],
            main_path[-1],
            walkable,
            blocked
        ).is_empty():
            continue
        candidates.append({
            "cell": current,
            "paired_cell": side_cells[0],
            "blocked_cells": blocked_cells,
            "travel_direction": incoming,
            "route_index": route_index,
        })
    return candidates


func _select_door_candidates(
    candidates: Array[Dictionary],
    requested_count: int,
    path_length: int,
    minimum_spacing: int
) -> Array[Dictionary]:
    var selected: Array[Dictionary] = []
    var used := {}
    for slot_index in requested_count:
        var target_index := roundi(
            float(path_length - 1) * float(slot_index + 1) / float(requested_count + 1)
        )
        var best_candidate_index := -1
        var best_distance := 2147483647
        for candidate_index in candidates.size():
            if used.has(candidate_index):
                continue
            var candidate := candidates[candidate_index]
            var route_index := int(candidate["route_index"])
            var separated := true
            for selected_door in selected:
                if absi(route_index - int(selected_door["route_index"])) < minimum_spacing:
                    separated = false
                    break
            if not separated:
                continue
            var distance := absi(route_index - target_index)
            if distance < best_distance:
                best_distance = distance
                best_candidate_index = candidate_index
        if best_candidate_index < 0:
            break
        used[best_candidate_index] = true
        selected.append(candidates[best_candidate_index])
    selected.sort_custom(GRAPH_SCRIPT.sort_door_by_route_index)
    return selected


func _occupy_door_clearance(occupied: Dictionary, door: Dictionary) -> void:
    var travel_direction := door["travel_direction"] as Vector2i
    for blocked_cell_value in door.get("blocked_cells", []):
        var blocked_cell := blocked_cell_value as Vector2i
        occupied[blocked_cell] = true
        for distance in range(1, DOOR_APPROACH_CLEARANCE_TILES + 1):
            occupied[blocked_cell + travel_direction * distance] = true
            occupied[blocked_cell - travel_direction * distance] = true


func _select_key_cell(
    reachable: Dictionary,
    path_lookup: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    door_route_index: int,
    should_hide: bool,
    seed_value: int,
    salt: int
) -> Vector2i:
    var candidates: Array[Dictionary] = []
    for cell_value in reachable:
        var cell := cell_value as Vector2i
        if occupied.has(cell):
            continue
        var route_index := int(path_lookup.get(cell, -1))
        var off_path_distance := int(distance_from_main_path.get(cell, 0))
        if should_hide and off_path_distance <= 0:
            continue
        if not should_hide and (route_index < 1 or route_index >= door_route_index - 1):
            continue
        var strategic_score := off_path_distance * 100000 if should_hide else route_index * 100000
        candidates.append({
            "cell": cell,
            "score": strategic_score + GRAPH_SCRIPT.coordinate_score(
                cell,
                seed_value,
                salt
            ),
        })
    if candidates.is_empty() and should_hide:
        return _select_key_cell(
            reachable,
            path_lookup,
            distance_from_main_path,
            occupied,
            door_route_index,
            false,
            seed_value,
            salt
        )
    candidates.sort_custom(GRAPH_SCRIPT.sort_scored_cell_descending)
    return candidates[0]["cell"] as Vector2i if not candidates.is_empty() else Vector2i(-1, -1)


func _select_exit_key_cell(
    main_path: Array[Vector2i],
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    seed_value: int
) -> Vector2i:
    var reachable := GRAPH_SCRIPT.get_reachable_cells(
        main_path[0],
        walkable,
        {main_path[-1]: true}
    ) as Dictionary
    var distance_from_gate := GRAPH_SCRIPT.build_distances_from_sources(
        [main_path[-1]] as Array[Vector2i],
        walkable
    ) as Dictionary
    var distance_from_spawn := GRAPH_SCRIPT.build_distances_from_sources(
        [main_path[0]] as Array[Vector2i],
        walkable
    ) as Dictionary
    var candidates: Array[Dictionary] = []
    for cell_value in reachable:
        var cell := cell_value as Vector2i
        var gate_distance := int(distance_from_gate.get(cell, 0))
        var spawn_distance := int(distance_from_spawn.get(cell, 0))
        var exploration_depth := int(distance_from_main_path.get(cell, 0))
        if occupied.has(cell) \
                or exploration_depth <= 0 \
                or gate_distance < MIN_EXIT_KEY_DISTANCE_FROM_GATE_TILES \
                or spawn_distance < MIN_PLACEMENT_DISTANCE_FROM_SPAWN:
            continue
        candidates.append({
            "cell": cell,
            "score": exploration_depth * 1000000000 \
                + mini(gate_distance, spawn_distance) * 1000000 \
                + GRAPH_SCRIPT.coordinate_score(cell, seed_value, 701),
        })
    candidates.sort_custom(GRAPH_SCRIPT.sort_scored_cell_descending)
    return candidates[0]["cell"] as Vector2i \
        if not candidates.is_empty() else Vector2i(-1, -1)


func _get_treasure_budgets(configuration: Resource) -> Dictionary:
    return _treasure_budget.from_configuration(configuration)


func _get_total_treasure_weight(treasure_budgets: Dictionary) -> float:
    return _treasure_budget.get_total_weight(treasure_budgets)


func _plan_coffins(
    main_path: Array[Vector2i],
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    treasure_cells: Array[Vector2i],
    map_size: Vector2i,
    total_treasure_weight: float,
    configuration: Resource,
    seed_value: int
) -> Array[Dictionary]:
    var carry_capacity := maxf(float(configuration.get("assumed_carry_capacity")), 1.0)
    var load_ratio := clampf(float(configuration.get("target_carry_load_percent")) / 100.0, 0.1, 1.0)
    var target_load := carry_capacity * load_ratio
    var required_count := ceili(total_treasure_weight / target_load) if total_treasure_weight > 0.0 else 0
    var coffin_count := maxi(required_count, int(configuration.get("minimum_coffin_count")))
    var preferred_clearance := maxi(
        int(configuration.get("preferred_coffin_treasure_clearance_tiles")),
        1
    )
    var preferred_coffin_spacing := maxi(
        int(configuration.get("minimum_coffin_spacing_tiles")),
        1
    )
    var preferred_occupied := occupied.duplicate()
    var route_progress_by_cell := GRAPH_SCRIPT.build_route_progress_by_cell(
        main_path,
        walkable
    ) as Dictionary
    var cells := _select_distributed_coffin_cells(
        walkable,
        preferred_occupied,
        treasure_cells,
        coffin_count,
        map_size,
        seed_value,
        preferred_clearance,
        preferred_coffin_spacing
    )
    if cells.size() < coffin_count:
        cells.append_array(CellSelector.select_exploration_cells(
            walkable,
            distance_from_main_path,
            preferred_occupied,
            coffin_count - cells.size(),
            seed_value,
            401,
            treasure_cells,
            preferred_clearance,
            route_progress_by_cell
        ))
    if cells.size() < coffin_count:
        var fallback_occupied := occupied.duplicate()
        for cell in cells:
            fallback_occupied[cell] = true
        cells.append_array(_select_spread_path_cells(
            main_path,
            fallback_occupied,
            coffin_count - cells.size(),
            0.18,
            0.9
        ))
        if cells.size() < coffin_count:
            cells.append_array(CellSelector.select_exploration_cells(
                walkable,
                distance_from_main_path,
                fallback_occupied,
                coffin_count - cells.size(),
                seed_value,
                409,
                cells,
                1,
                route_progress_by_cell
            ))
    var coffins: Array[Dictionary] = []
    for index in cells.size():
        var cell := cells[index]
        coffins.append({
            "cell": cell,
            "cell_3d": Vector3i(cell.x, 0, cell.y),
            "target_load_weight": target_load,
            "route_progress": float(route_progress_by_cell.get(cell, 0.0)),
        })
    return coffins


func _select_distributed_coffin_cells(
    walkable: Dictionary,
    occupied: Dictionary,
    treasure_cells: Array[Vector2i],
    count: int,
    map_size: Vector2i,
    seed_value: int,
    treasure_clearance_tiles: int,
    coffin_spacing_tiles: int
) -> Array[Vector2i]:
    var selected: Array[Vector2i] = []
    if count <= 0:
        return selected
    var candidates: Array[Dictionary] = []
    for cell_value in walkable:
        var cell := cell_value as Vector2i
        if occupied.has(cell) or not GRAPH_SCRIPT.has_minimum_cell_separation(
            cell,
            treasure_cells,
            treasure_clearance_tiles
        ):
            continue
        candidates.append({
            "cell": cell,
            "random_score": GRAPH_SCRIPT.coordinate_score(cell, seed_value, 397),
        })

    var region_targets := CellSelector.build_region_targets(
        count,
        map_size,
        seed_value ^ 397
    )
    for target_position in region_targets:
        var best_cell := Vector2i(-1, -1)
        var best_score := -INF
        for candidate in candidates:
            var cell := candidate["cell"] as Vector2i
            if occupied.has(cell) or not GRAPH_SCRIPT.has_minimum_cell_separation(
                cell,
                selected,
                coffin_spacing_tiles
            ):
                continue
            var distance_squared := Vector2(cell).distance_squared_to(target_position)
            var score := -distance_squared * 100000.0 \
                + float(candidate["random_score"])
            if score > best_score:
                best_cell = cell
                best_score = score
        if best_cell == Vector2i(-1, -1):
            continue
        selected.append(best_cell)
        occupied[best_cell] = true
    return selected


func _plan_treasure_caches(
    main_path: Array[Vector2i],
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    map_size: Vector2i,
    budgets: Dictionary,
    seed_value: int,
    configuration: Resource,
    errors: Array[String]
) -> Array[Dictionary]:
    var requested_cache_count := maxi(int(configuration.get("treasure_pile_count")), 0)
    if requested_cache_count <= 0:
        if CellSelector.has_additional_treasure_budget(budgets):
            errors.append("Generated gems and gold bars require at least one treasure pile.")
        return []

    var main_percent := clampf(
        float(configuration.get("main_path_treasure_percent")),
        0.0,
        100.0
    )
    var main_cache_count := clampi(
        roundi(float(requested_cache_count) * main_percent / 100.0),
        0,
        requested_cache_count
    )
    var off_cache_count := requested_cache_count - main_cache_count
    if CellSelector.has_gem_budget(budgets) and off_cache_count <= 0:
        off_cache_count = 1
        main_cache_count = requested_cache_count - off_cache_count
    var minimum_spacing := maxi(
        int(configuration.get("minimum_treasure_pile_spacing_tiles")),
        1
    )
    var route_progress_by_cell := GRAPH_SCRIPT.build_route_progress_by_cell(
        main_path,
        walkable
    ) as Dictionary
    var main_cells := _select_treasure_area_cells(
        walkable,
        distance_from_main_path,
        occupied,
        map_size,
        main_cache_count,
        PlacementBand.MainPath,
        seed_value ^ 211,
        [],
        minimum_spacing
    )
    var off_cells := _select_treasure_area_cells(
        walkable,
        distance_from_main_path,
        occupied,
        map_size,
        off_cache_count,
        PlacementBand.Exploration,
        seed_value ^ 223,
        main_cells,
        minimum_spacing
    )
    var all_treasure_cells: Array[Vector2i] = []
    all_treasure_cells.append_array(main_cells)
    all_treasure_cells.append_array(off_cells)

    # Keep the configured spacing whenever the maze has room. On compact mazes,
    # relax it deterministically before giving up any of the requested piles.
    for relaxed_spacing in range(minimum_spacing - 1, 0, -1):
        var missing_main_count := maxi(main_cache_count - main_cells.size(), 0)
        if missing_main_count > 0:
            var additional_main_cells := _select_treasure_area_cells(
                walkable,
                distance_from_main_path,
                occupied,
                map_size,
                missing_main_count,
                PlacementBand.MainPath,
                seed_value ^ (211 + relaxed_spacing),
                all_treasure_cells,
                relaxed_spacing
            )
            main_cells.append_array(additional_main_cells)
            all_treasure_cells.append_array(additional_main_cells)

        var missing_off_count := maxi(off_cache_count - off_cells.size(), 0)
        if missing_off_count > 0:
            var additional_off_cells := _select_treasure_area_cells(
                walkable,
                distance_from_main_path,
                occupied,
                map_size,
                missing_off_count,
                PlacementBand.Exploration,
                seed_value ^ (223 + relaxed_spacing),
                all_treasure_cells,
                relaxed_spacing
            )
            off_cells.append_array(additional_off_cells)
            all_treasure_cells.append_array(additional_off_cells)
        if main_cells.size() + off_cells.size() >= requested_cache_count:
            break

    # Preserve the requested count as the final priority. Occupied cells still
    # prevent overlap; this fallback only drops the preferred spacing.
    var unplaced_count := requested_cache_count - main_cells.size() - off_cells.size()
    if unplaced_count > 0:
        var fallback_main_cells := _select_treasure_area_cells(
            walkable,
            distance_from_main_path,
            occupied,
            map_size,
            unplaced_count,
            PlacementBand.MainPath,
            seed_value ^ 229,
            all_treasure_cells,
            0
        )
        main_cells.append_array(fallback_main_cells)
        all_treasure_cells.append_array(fallback_main_cells)
        unplaced_count -= fallback_main_cells.size()
    if unplaced_count > 0:
        var fallback_off_cells := _select_treasure_area_cells(
            walkable,
            distance_from_main_path,
            occupied,
            map_size,
            unplaced_count,
            PlacementBand.Exploration,
            seed_value ^ 233,
            all_treasure_cells,
            0
        )
        off_cells.append_array(fallback_off_cells)
    if main_cells.is_empty() and off_cells.is_empty():
        return []

    var caches: Array[Dictionary] = []
    for cell in main_cells:
        caches.append(CellSelector.new_treasure_cache(
            cell,
            PlacementBand.MainPath,
            float(main_path.find(cell)) / float(maxi(main_path.size() - 1, 1)),
            walkable,
            map_size
        ))
    for cell in off_cells:
        caches.append(CellSelector.new_treasure_cache(
            cell,
            PlacementBand.Exploration,
            float(route_progress_by_cell.get(cell, 0.0)),
            walkable,
            map_size
        ))

    if caches.size() < requested_cache_count:
        errors.append(
            "Requested %d treasure piles but only %d distinct placement cells were available."
            % [requested_cache_count, caches.size()]
        )

    var main_indices: Array[int] = []
    var off_indices: Array[int] = []
    for index in caches.size():
        if caches[index]["placement_band"] == PlacementBand.MainPath:
            main_indices.append(index)
        else:
            off_indices.append(index)

    var minimum_coins := maxi(int(configuration.get("minimum_coins_per_pile")), 0)
    var maximum_coins := maxi(
        int(configuration.get("maximum_coins_per_pile")),
        minimum_coins
    )
    for cache_index in caches.size():
        var cache := caches[cache_index]
        var counts := cache["counts"] as Dictionary
        counts[&"gold_coin"] = CellSelector.get_deterministic_pile_coin_count(
            cache["cell"] as Vector2i,
            seed_value,
            cache_index,
            minimum_coins,
            maximum_coins
        )
        cache["counts"] = counts
        caches[cache_index] = cache

    for item_type in TREASURE_TYPES:
        if item_type == &"gold_coin":
            continue
        var budget := int(budgets.get(item_type, 0))
        if item_type in GEM_TYPES:
            if budget > 0 and off_indices.is_empty():
                errors.append(
                    "Configured gems require an off-main-path treasure pile."
                )
                continue
            CellSelector.distribute_treasure_count(caches, off_indices, item_type, budget)
            continue
        var main_budget := clampi(roundi(float(budget) * main_percent / 100.0), 0, budget)
        CellSelector.distribute_treasure_count(caches, main_indices, item_type, main_budget)
        CellSelector.distribute_treasure_count(caches, off_indices, item_type, budget - main_budget)
    return caches


func _plan_bat_nests(
    main_path: Array[Vector2i],
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    hazard_occupied: Dictionary,
    seed_value: int,
    configuration: Resource
) -> Array[Dictionary]:
    var requested_count := maxi(int(configuration.get("bat_nest_count")), 0)
    var off_percent := clampf(float(configuration.get("bat_off_path_percent")), 0.0, 100.0)
    var off_count := clampi(roundi(float(requested_count) * off_percent / 100.0), 0, requested_count)
    var main_count := requested_count - off_count
    var main_cells := _select_spread_path_cells(main_path, occupied, main_count, 0.12, 0.88)
    for cell in main_cells:
        occupied[cell] = true
    var off_cells := CellSelector.select_exploration_cells(
        walkable,
        distance_from_main_path,
        occupied,
        off_count,
        seed_value,
        307
    )
    for cell in main_cells:
        hazard_occupied[cell] = true
    for cell in off_cells:
        hazard_occupied[cell] = true
    if main_cells.size() < main_count:
        main_cells.append_array(_select_spread_path_cells(
            main_path,
            hazard_occupied,
            main_count - main_cells.size(),
            0.12,
            0.88
        ))
    if off_cells.size() < off_count:
        off_cells.append_array(CellSelector.select_exploration_cells(
            walkable,
            distance_from_main_path,
            hazard_occupied,
            off_count - off_cells.size(),
            seed_value,
            311
        ))
    var bat_nests: Array[Dictionary] = []
    for cell in main_cells:
        bat_nests.append({
            "cell": cell,
            "cell_3d": Vector3i(cell.x, 0, cell.y),
            "placement_band": PlacementBand.MainPath,
        })
    for cell in off_cells:
        bat_nests.append({
            "cell": cell,
            "cell_3d": Vector3i(cell.x, 0, cell.y),
            "placement_band": PlacementBand.Exploration,
        })
    return bat_nests


func _select_treasure_area_cells(
    walkable: Dictionary,
    distance_from_main_path: Dictionary,
    occupied: Dictionary,
    map_size: Vector2i,
    count: int,
    placement_band: PlacementBand,
    random_seed: int,
    separation_cells: Array[Vector2i] = [],
    minimum_separation_tiles: int = 0
) -> Array[Vector2i]:
    var selected: Array[Vector2i] = []
    if count <= 0:
        return selected
    var candidates: Array[Dictionary] = []
    for cell_value in walkable:
        var cell := cell_value as Vector2i
        if occupied.has(cell):
            continue
        var distance_to_main_path := int(distance_from_main_path.get(cell, 0))
        var is_main_path_cell := distance_to_main_path == 0
        match placement_band:
            PlacementBand.MainPath:
                if not is_main_path_cell:
                    continue
            PlacementBand.Exploration:
                if is_main_path_cell:
                    continue
        candidates.append({
            "cell": cell,
            "random_score": GRAPH_SCRIPT.coordinate_score(cell, random_seed, 0),
        })

    var all_separation_cells := separation_cells.duplicate()
    var region_targets := CellSelector.build_region_targets(count, map_size, random_seed)
    for target_position in region_targets:
        var selected_candidate := _select_treasure_area_candidate(
            candidates,
            occupied,
            all_separation_cells,
            minimum_separation_tiles,
            target_position
        )
        if selected_candidate.is_empty():
            continue
        var cell := selected_candidate["cell"] as Vector2i
        selected.append(cell)
        all_separation_cells.append(cell)
        occupied[cell] = true
    return selected


func _select_treasure_area_candidate(
    candidates: Array[Dictionary],
    occupied: Dictionary,
    separation_cells: Array[Vector2i],
    minimum_separation_tiles: int,
    target_position: Vector2
) -> Dictionary:
    var best_candidate := {}
    var best_score := -INF
    for candidate in candidates:
        var cell := candidate["cell"] as Vector2i
        if occupied.has(cell) or not GRAPH_SCRIPT.has_minimum_cell_separation(
            cell,
            separation_cells,
            minimum_separation_tiles
        ):
            continue
        var target_distance_squared := Vector2(cell).distance_squared_to(target_position)
        # Each pile claims a random point in a different map region. All cells in
        # its placement band compete equally, including the perimeter corridors.
        var candidate_score := -target_distance_squared * 1000000.0 \
            + float(candidate["random_score"])
        if candidate_score > best_score:
            best_candidate = candidate
            best_score = candidate_score
    return best_candidate


func _select_spread_path_cells(
    main_path: Array[Vector2i],
    occupied: Dictionary,
    count: int,
    minimum_progress: float,
    maximum_progress: float,
    separation_cells: Array[Vector2i] = [],
    minimum_separation_tiles: int = 0
) -> Array[Vector2i]:
    var selected: Array[Vector2i] = []
    var all_separation_cells := separation_cells.duplicate()
    if count <= 0 or main_path.is_empty():
        return selected
    var minimum_index := clampi(
        roundi(float(main_path.size() - 1) * minimum_progress),
        0,
        main_path.size() - 1
    )
    var maximum_index := clampi(
        roundi(float(main_path.size() - 1) * maximum_progress),
        minimum_index,
        main_path.size() - 1
    )
    for slot_index in count:
        var progress := float(slot_index + 1) / float(count + 1)
        var target_index := roundi(lerpf(float(minimum_index), float(maximum_index), progress))
        var cell := CellSelector.find_nearest_free_path_cell(
            main_path,
            occupied,
            target_index,
            minimum_index,
            maximum_index,
            all_separation_cells,
            minimum_separation_tiles
        )
        if cell == Vector2i(-1, -1):
            continue
        selected.append(cell)
        all_separation_cells.append(cell)
        occupied[cell] = true
    return selected


func _sum_cache_budgets(caches: Array[Dictionary]) -> Dictionary:
    return _treasure_budget.sum_caches(caches)
