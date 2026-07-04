extends "res://enemies/zombie/zombie_presentation.gd"


func _is_route_reachable(target_position: Vector3) -> bool:
    if target_position == Vector3.ZERO and patrol_points.is_empty():
        return false

    if _has_grid_navigation_path(target_position):
        return true

    if _has_navigation_path(target_position):
        return true

    return direct_navigation_fallback_enabled and not _has_static_blocker_between(_get_body_position(), target_position)

func _has_navigation_path(target_position: Vector3) -> bool:
    if navigation_agent == null:
        return false

    navigation_agent.target_position = target_position
    if navigation_agent.is_target_reachable():
        return true

    var next_position := navigation_agent.get_next_path_position()
    return next_position.distance_squared_to(_get_body_position()) > 0.0001

func _has_static_blocker_between(from_position: Vector3, to_position: Vector3) -> bool:
    var world := get_world_3d()
    if world == null:
        return false

    var from := from_position + Vector3.UP * 0.5
    var to := to_position + Vector3.UP * 0.5
    var query := PhysicsRayQueryParameters3D.create(from, to, map_collision_mask)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    query.exclude = _get_vision_excludes()
    return not world.direct_space_state.intersect_ray(query).is_empty()

func _follow_navigation_target(target_position: Vector3, delta: float, stop_on_static_blocker := true, movement_speed := -1.0) -> float:
    _set_navigation_target(target_position)
    var has_static_blocker := _has_static_blocker_between(_get_body_position(), target_position)
    var has_grid_blocker := _has_grid_blocker_between(_get_body_position(), target_position)
    var routed_with_grid := has_static_blocker or has_grid_blocker
    var requested_speed := movement_speed if movement_speed > 0.0 else shuffle_speed

    var next_position := target_position
    if routed_with_grid:
        next_position = _get_grid_navigation_next_position(target_position)

    if next_position == Vector3.INF:
        if stop_on_static_blocker:
            _stop_body()
            _update_stuck(delta, 0.0)
            return 0.0
        next_position = target_position
    elif not has_static_blocker and navigation_agent != null and not navigation_agent.is_navigation_finished():
        next_position = navigation_agent.get_next_path_position()

    var direction := next_position - _get_body_position()
    direction.y = 0.0
    if direction.length_squared() <= 0.0001:
        direction = target_position - _get_body_position()
        direction.y = 0.0

    if direction.length_squared() <= 0.0001:
        _stop_body()
        return 0.0

    direction = direction.normalized()
    var previous_position := _get_body_position()
    var movement_velocity := _update_locomotion_velocity_for_direction(requested_speed, direction, delta)
    zombie_body.velocity.x = movement_velocity.x
    zombie_body.velocity.z = movement_velocity.z
    zombie_body.move_and_slide()

    if _has_blocking_slide_collision() and not routed_with_grid:
        var slide_direction := _get_wall_slide_direction(direction)
        if slide_direction.length_squared() > 0.0001:
            movement_velocity = _update_locomotion_velocity_for_direction(requested_speed, slide_direction, delta)
            zombie_body.velocity.x = movement_velocity.x
            zombie_body.velocity.z = movement_velocity.z
            zombie_body.move_and_slide()
            repath_timer = 0.0
            direction = slide_direction

        var reroute_position := _get_grid_navigation_next_position(target_position)
        if reroute_position != Vector3.INF:
            next_position = reroute_position
            direction = next_position - _get_body_position()
            direction.y = 0.0
            if direction.length_squared() > 0.0001:
                direction = direction.normalized()
                movement_velocity = _update_locomotion_velocity_for_direction(requested_speed, direction, delta)
                zombie_body.velocity.x = movement_velocity.x
                zombie_body.velocity.z = movement_velocity.z
                zombie_body.move_and_slide()
                repath_timer = 0.0
                routed_with_grid = true

    if _would_hit_navigation_blocker(direction) or (_has_blocking_slide_collision() and not routed_with_grid):
        _stop_body()
        _update_stuck(delta, 0.0)
        repath_timer = 0.0
        return 0.0

    var horizontal_displacement := _get_body_position() - previous_position
    horizontal_displacement.y = 0.0
    var horizontal_speed := horizontal_displacement.length() / maxf(delta, 0.001)
    _face_direction(direction, delta)
    _update_stuck(delta, horizontal_displacement.length())
    return horizontal_speed

func _has_blocking_slide_collision() -> bool:
    if zombie_body == null:
        return false

    for collision_index in zombie_body.get_slide_collision_count():
        var collision := zombie_body.get_slide_collision(collision_index)
        if collision == null:
            continue

        if collision.get_normal().y < navigation_collision_floor_normal_y:
            return true

    return false

func _is_blocked_by_zombie() -> bool:
    if zombie_body == null:
        return false

    for collision_index in zombie_body.get_slide_collision_count():
        var collision := zombie_body.get_slide_collision(collision_index)
        if collision == null:
            continue

        if _is_other_zombie_collider(collision.get_collider() as Object):
            return true

    return false

func _is_other_zombie_collider(collider: Object) -> bool:
    if collider == null or not collider is Node:
        return false

    var node := collider as Node
    while node != null:
        if node == self:
            return false
        if node.is_in_group(SMART_ZOMBIE_GROUP):
            return true
        node = node.get_parent()

    return false

func _get_blocking_slide_normal() -> Vector3:
    if zombie_body == null:
        return Vector3.ZERO

    for collision_index in zombie_body.get_slide_collision_count():
        var collision := zombie_body.get_slide_collision(collision_index)
        if collision == null:
            continue

        if collision.get_normal().y < navigation_collision_floor_normal_y:
            return collision.get_normal()

    return Vector3.ZERO

func _get_wall_slide_direction(direction: Vector3) -> Vector3:
    var normal := _get_blocking_slide_normal()
    if normal.length_squared() <= 0.0001:
        return Vector3.ZERO

    var slide_direction := direction.slide(normal)
    slide_direction.y = 0.0
    if slide_direction.length_squared() <= 0.0001:
        return Vector3.ZERO

    return slide_direction.normalized()

func _get_grid_navigation_next_position(target_position: Vector3) -> Vector3:
    var grid_map := _select_navigation_grid_map(_get_body_position(), target_position)
    if grid_map == null:
        return Vector3.INF

    var start_cell := grid_map.local_to_map(grid_map.to_local(_get_body_position()))
    var target_cell := grid_map.local_to_map(grid_map.to_local(target_position))
    if _is_grid_cell_blocked(grid_map, target_cell):
        var nearest_cell := _find_nearest_unblocked_grid_cell(grid_map, target_cell)
        if nearest_cell == INVALID_GRID_CELL:
            return Vector3.INF
        target_cell = nearest_cell

    if start_cell == target_cell:
        return target_position

    var path := _find_grid_path(grid_map, start_cell, target_cell)
    if path.size() < 2:
        return Vector3.INF

    var next_position := grid_map.to_global(grid_map.map_to_local(path[1]))
    next_position.y = _get_body_position().y
    return next_position

func _has_grid_navigation_path(target_position: Vector3) -> bool:
    var grid_map := _select_navigation_grid_map(_get_body_position(), target_position)
    if grid_map == null:
        return false

    var start_cell := grid_map.local_to_map(grid_map.to_local(_get_body_position()))
    var target_cell := grid_map.local_to_map(grid_map.to_local(target_position))
    if _is_grid_cell_blocked(grid_map, target_cell):
        target_cell = _find_nearest_unblocked_grid_cell(grid_map, target_cell)
        if target_cell == INVALID_GRID_CELL:
            return false

    if start_cell == target_cell:
        return true

    return not _find_grid_path(grid_map, start_cell, target_cell).is_empty()

func _select_navigation_grid_map(from_position: Vector3, to_position: Vector3) -> GridMap:
    for grid_map in navigation_grid_maps:
        if grid_map == null:
            continue

        var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
        var from_cell := grid_map.local_to_map(grid_map.to_local(from_position))
        var to_cell := grid_map.local_to_map(grid_map.to_local(to_position))
        if bounds.has_point(Vector2i(from_cell.x, from_cell.z)) and bounds.has_point(Vector2i(to_cell.x, to_cell.z)):
            return grid_map

    return null

func _has_grid_blocker_between(from_position: Vector3, to_position: Vector3) -> bool:
    var grid_map := _select_navigation_grid_map(from_position, to_position)
    if grid_map == null:
        return false

    var from_cell := grid_map.local_to_map(grid_map.to_local(from_position))
    var to_cell := grid_map.local_to_map(grid_map.to_local(to_position))
    var step_count := maxi(absi(to_cell.x - from_cell.x), absi(to_cell.z - from_cell.z))
    if step_count <= 1:
        return false

    for step in range(1, step_count):
        var ratio := float(step) / float(step_count)
        var sample_cell := Vector3i(
            roundi(lerpf(float(from_cell.x), float(to_cell.x), ratio)),
            from_cell.y,
            roundi(lerpf(float(from_cell.z), float(to_cell.z), ratio))
        )
        if _is_grid_cell_blocked(grid_map, sample_cell):
            return true

    return false

func _find_grid_path(grid_map: GridMap, start_cell: Vector3i, target_cell: Vector3i) -> Array[Vector3i]:
    var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
    if not bounds.has_point(Vector2i(start_cell.x, start_cell.z)) or not bounds.has_point(Vector2i(target_cell.x, target_cell.z)):
        return []

    var open_cells: Array[Vector3i] = [start_cell]
    var came_from := {start_cell: start_cell}
    var search_count := 0

    while not open_cells.is_empty() and search_count < grid_navigation_max_search_cells:
        search_count += 1
        var current := open_cells.pop_front() as Vector3i
        if current == target_cell:
            return _reconstruct_grid_path(came_from, current)

        for neighbor in _get_grid_neighbors(current):
            if came_from.has(neighbor):
                continue

            var neighbor_point := Vector2i(neighbor.x, neighbor.z)
            if not bounds.has_point(neighbor_point):
                continue

            if _is_grid_cell_blocked(grid_map, neighbor):
                continue

            came_from[neighbor] = current
            open_cells.append(neighbor)

    return []

func _reconstruct_grid_path(came_from: Dictionary, end_cell: Vector3i) -> Array[Vector3i]:
    var path: Array[Vector3i] = [end_cell]
    var current := end_cell
    while came_from.has(current) and came_from[current] != current:
        current = came_from[current] as Vector3i
        path.push_front(current)
    return path

func _get_grid_neighbors(cell: Vector3i) -> Array[Vector3i]:
    return [
        cell + Vector3i(1, 0, 0),
        cell + Vector3i(-1, 0, 0),
        cell + Vector3i(0, 0, 1),
        cell + Vector3i(0, 0, -1),
    ]

func _find_nearest_unblocked_grid_cell(grid_map: GridMap, blocked_cell: Vector3i) -> Vector3i:
    var bounds := navigation_grid_bounds_by_id.get(grid_map.get_instance_id(), Rect2i()) as Rect2i
    var open_cells: Array[Vector3i] = [blocked_cell]
    var visited := {blocked_cell: true}

    while not open_cells.is_empty() and visited.size() < grid_navigation_max_search_cells:
        var current := open_cells.pop_front() as Vector3i
        if bounds.has_point(Vector2i(current.x, current.z)) and not _is_grid_cell_blocked(grid_map, current):
            return current

        for neighbor in _get_grid_neighbors(current):
            if visited.has(neighbor):
                continue

            visited[neighbor] = true
            if bounds.has_point(Vector2i(neighbor.x, neighbor.z)):
                open_cells.append(neighbor)

    return INVALID_GRID_CELL

func _is_grid_cell_blocked(grid_map: GridMap, cell: Vector3i) -> bool:
    var item_id := grid_map.get_cell_item(cell)
    if item_id == GridMap.INVALID_CELL_ITEM:
        return false

    var library := grid_map.mesh_library
    if library == null:
        return false

    var item_name := library.get_item_name(item_id).to_lower()
    return item_name.contains("wall")

func _get_grid_navigation_bounds(grid_map: GridMap) -> Rect2i:
    var used_cells := grid_map.get_used_cells()
    if used_cells.is_empty():
        return Rect2i(Vector2i.ZERO, Vector2i.ZERO)

    var min_x := 2147483647
    var min_z := 2147483647
    var max_x := -2147483648
    var max_z := -2147483648
    for cell in used_cells:
        min_x = mini(min_x, cell.x)
        min_z = mini(min_z, cell.z)
        max_x = maxi(max_x, cell.x)
        max_z = maxi(max_z, cell.z)

    var padding := maxi(grid_navigation_padding_cells, 0)
    var grid_position := Vector2i(min_x - padding, min_z - padding)
    var end := Vector2i(max_x + padding + 1, max_z + padding + 1)
    return Rect2i(grid_position, end - grid_position)

func _set_navigation_target(target_position: Vector3) -> void:
    current_target = target_position
    if navigation_agent != null:
        navigation_agent.target_position = target_position

func _stop_body() -> void:
    current_movement_velocity = Vector3.ZERO
    if zombie_body == null:
        return
    zombie_body.velocity = Vector3.ZERO

func _update_locomotion_velocity_for_direction(requested_speed: float, direction: Vector3, delta: float) -> Vector3:
    var target_speed := _get_turn_limited_speed(requested_speed, direction)
    var target_velocity := direction * target_speed
    var current_speed := current_movement_velocity.length()
    var speed_change := movement_acceleration if target_speed >= current_speed else movement_deceleration
    if speed_change <= 0.0:
        current_movement_velocity = target_velocity
    else:
        current_movement_velocity = current_movement_velocity.move_toward(target_velocity, speed_change * delta)

    current_movement_velocity.y = 0.0
    return current_movement_velocity

func _get_turn_limited_speed(requested_speed: float, direction: Vector3) -> float:
    var clamped_requested_speed := maxf(requested_speed, 0.0)
    if clamped_requested_speed <= 0.0:
        return 0.0

    var turn_angle_degrees := _get_visual_turn_angle_degrees(direction)
    if turn_angle_degrees < sharp_turn_slow_angle_degrees:
        return clamped_requested_speed

    var turn_speed_multiplier := clampf(sharp_turn_speed_multiplier, 0.0, 1.0)
    return clamped_requested_speed * turn_speed_multiplier

func _get_visual_turn_angle_degrees(direction: Vector3) -> float:
    if direction.length_squared() <= 0.0001:
        return 0.0

    var target_yaw := atan2(direction.x, direction.z)
    var current_yaw := pivot.rotation.y if pivot != null else atan2(facing_direction.x, facing_direction.z)
    return rad_to_deg(absf(angle_difference(current_yaw, target_yaw)))

func _update_stuck(delta: float, moved_distance: float) -> void:
    if moved_distance < stuck_min_move_distance:
        stuck_timer += delta
    else:
        stuck_timer = 0.0

func _would_hit_navigation_blocker(direction: Vector3) -> bool:
    var world := get_world_3d()
    if world == null:
        return false

    var probe_shape := SphereShape3D.new()
    probe_shape.radius = 0.42
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = probe_shape
    query.transform = Transform3D(Basis.IDENTITY, _get_body_position() + Vector3.UP * 0.5 + direction * 0.35)
    query.collision_mask = map_collision_mask
    query.collide_with_areas = false
    query.collide_with_bodies = true

    for hit in world.direct_space_state.intersect_shape(query, 8):
        var collider := hit.get("collider") as Object
        if _is_navigation_blocker(collider):
            return true

    return false

func _is_navigation_blocker(collider: Object) -> bool:
    if collider == null or not collider is Node:
        return false

    var node := collider as Node
    return node.is_in_group(NAVIGATION_BLOCKER_GROUP)

func _build_patrol_points() -> void:
    patrol_points.clear()
    if curve == null:
        return

    for point_index in range(curve.point_count):
        patrol_points.append(to_global(curve.get_point_position(point_index)))

    if patrol_points.is_empty() and curve.get_baked_length() > 0.001:
        patrol_points.append(to_global(curve.sample_baked(0.0, true)))
        patrol_points.append(to_global(curve.sample_baked(curve.get_baked_length(), true)))

    patrol_index = _get_closest_patrol_index(_get_body_position())
    _initialize_patrol_facing()
    _set_next_patrol_target()

func _initialize_patrol_facing() -> void:
    if patrol_points.size() < 2:
        return

    var current_index := clampi(patrol_index, 0, patrol_points.size() - 1)
    var next_index := current_index
    if loop_patrol or curve.closed:
        next_index = wrapi(current_index + 1, 0, patrol_points.size())
    else:
        next_index = mini(current_index + 1, patrol_points.size() - 1)

    var direction := patrol_points[next_index] - patrol_points[current_index]
    direction.y = 0.0
    if direction.length_squared() > 0.0001:
        facing_direction = direction.normalized()

func _set_next_patrol_target() -> void:
    if patrol_points.is_empty():
        return
    patrol_index = clampi(patrol_index, 0, patrol_points.size() - 1)
    _set_navigation_target(patrol_points[patrol_index])

func _advance_patrol_target() -> void:
    if patrol_points.size() <= 1:
        return

    if loop_patrol or curve.closed:
        patrol_index = wrapi(patrol_index + 1, 0, patrol_points.size())
    elif reverse_at_path_ends:
        var next_index := patrol_index + patrol_direction
        if next_index >= patrol_points.size():
            patrol_direction = -1
            next_index = max(patrol_points.size() - 2, 0)
        elif next_index < 0:
            patrol_direction = 1
            next_index = min(1, patrol_points.size() - 1)
        patrol_index = next_index
    else:
        patrol_index = mini(patrol_index + 1, patrol_points.size() - 1)

    _set_next_patrol_target()

func _select_closest_reachable_patrol_target() -> bool:
    if patrol_points.is_empty():
        return false

    var candidates: Array[Dictionary] = []
    var body_position := _get_body_position()
    for index in range(patrol_points.size()):
        candidates.append({
            "index": index,
            "distance": body_position.distance_squared_to(patrol_points[index]),
        })

    candidates.sort_custom(_sort_patrol_candidates)
    for candidate in candidates:
        var index := int(candidate["index"])
        if _is_route_reachable(patrol_points[index]):
            patrol_index = index
            _set_next_patrol_target()
            return true

    return false

func _sort_patrol_candidates(a: Dictionary, b: Dictionary) -> bool:
    var distance_a := float(a["distance"])
    var distance_b := float(b["distance"])
    if is_equal_approx(distance_a, distance_b):
        return int(a["index"]) < int(b["index"])
    return distance_a < distance_b

func _get_closest_patrol_index(world_position: Vector3) -> int:
    var closest_index := 0
    var closest_distance := INF
    for index in range(patrol_points.size()):
        var distance := world_position.distance_squared_to(patrol_points[index])
        if distance < closest_distance:
            closest_distance = distance
            closest_index = index
    return closest_index

func _scan_deterministically(delta: float) -> void:
    if pivot == null:
        return
    var scan_phase := fmod(search_timer, 1.0)
    var scan_direction := -1.0 if scan_phase < 0.5 else 1.0
    pivot.rotation.y = lerp_angle(pivot.rotation.y, scan_direction * 0.65, turn_speed * delta)

func _scan_randomly_while_idle(delta: float) -> void:
    if pivot == null:
        return

    idle_scan_timer -= delta
    if idle_scan_timer <= 0.0:
        var min_seconds := maxf(idle_scan_min_seconds, 0.1)
        var max_seconds := maxf(idle_scan_max_seconds, min_seconds)
        idle_scan_timer = footstep_rng.randf_range(min_seconds, max_seconds)
        var max_turn := deg_to_rad(maxf(idle_scan_max_turn_degrees, 0.0))
        idle_scan_target_yaw = pivot.rotation.y + footstep_rng.randf_range(-max_turn, max_turn)

    pivot.rotation.y = lerp_angle(pivot.rotation.y, idle_scan_target_yaw, turn_speed * delta)

func _apply_start_progress() -> void:
    if path_follow == null or curve == null:
        return

    var path_length := curve.get_baked_length()
    if path_length <= 0.001:
        return

    path_follow.progress = clampf(start_progress_ratio, 0.0, 1.0) * path_length

func _sync_body_to_path_start() -> void:
    if zombie_body == null:
        return

    if path_follow != null:
        zombie_body.global_position = path_follow.global_position
    elif not patrol_points.is_empty():
        zombie_body.global_position = patrol_points[0]

func _update_drop_in(delta: float) -> bool:
    if has_dropped_in:
        return true

    elapsed_time += delta
    if not is_dropping_in and elapsed_time < drop_in_time:
        return false

    if not is_dropping_in:
        _start_drop_in()

    drop_elapsed += delta
    var duration := maxf(drop_duration, 0.001)
    var ratio := clampf(drop_elapsed / duration, 0.0, 1.0)
    var eased_ratio := 1.0 - pow(1.0 - ratio, 3.0)
    if drop_pivot != null:
        drop_pivot.position.y = lerpf(maxf(drop_height, 0.0), 0.0, eased_ratio)

    if ratio >= 1.0:
        _finish_drop_in()
        return true

    return false

func _start_drop_in() -> void:
    is_dropping_in = true
    drop_elapsed = 0.0
    if drop_pivot != null:
        drop_pivot.position.y = maxf(drop_height, 0.0)
    _set_active_visible(true)
    _set_kill_area_enabled(false)

func _finish_drop_in() -> void:
    has_dropped_in = true
    is_dropping_in = false
    if drop_pivot != null:
        drop_pivot.position.y = 0.0
    _set_zombie_transparency(0.0)
    _set_active_visible(true)
    _set_kill_area_enabled(false)
    _update_animation(0.0)
