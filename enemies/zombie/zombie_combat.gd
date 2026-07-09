extends "res://enemies/zombie/zombie_navigation.gd"


func _resolve_player() -> void:
    if is_instance_valid(player):
        return

    var tree := get_tree()
    if tree == null:
        return

    var player_nodes := tree.get_nodes_in_group(PLAYER_GROUP)
    for player_node in player_nodes:
        if player_node is Node3D:
            player = player_node as Node3D
            return

    var root := tree.current_scene
    if root == null:
        root = tree.root
    player = _find_player(root)

func _find_player(node: Node) -> Node3D:
    if node == null:
        return null

    if node is Node3D and node.has_method("die_from_flames"):
        return node as Node3D

    for child in node.get_children():
        var result := _find_player(child)
        if result != null:
            return result

    return null

func _start_attack() -> void:
    attack_timer = 0.0
    attack_hit_applied = false
    var animation_name := attack_animation_names[attack_index % attack_animation_names.size()]
    active_attack_hitbox = attack_hitbox_right if attack_index % 2 == 0 else attack_hitbox_left
    attack_index += 1
    if animation_player != null:
        animation_player.speed_scale = 1.0
    _configure_attack_hit_window(animation_name)
    _set_attack_hitboxes_enabled(false)
    _play_animation(animation_name)

func _configure_attack_hit_window(animation_name: String) -> void:
    var animation_duration := _get_animation_duration_seconds(animation_name)
    if animation_duration <= 0.0:
        current_attack_hit_start_seconds = maxf(attack_hit_start_seconds, 0.0)
        current_attack_hit_end_seconds = maxf(attack_hit_end_seconds, current_attack_hit_start_seconds + 0.01)
        return

    var start_ratio := clampf(attack_hit_start_ratio, 0.0, 1.0)
    var end_ratio := clampf(attack_hit_end_ratio, start_ratio, 1.0)
    current_attack_hit_start_seconds = animation_duration * start_ratio
    current_attack_hit_end_seconds = maxf(animation_duration * end_ratio, current_attack_hit_start_seconds + 0.01)

func _get_animation_duration_seconds(animation_name: String) -> float:
    if animation_player == null:
        return 0.0

    var resolved_animation_name := _resolve_animation_name(animation_name)
    if resolved_animation_name.is_empty() or not animation_player.has_animation(resolved_animation_name):
        return 0.0

    var animation := animation_player.get_animation(resolved_animation_name)
    if animation == null:
        return 0.0

    return animation.length

func _apply_attack_damage() -> bool:
    var targets := _get_attack_damage_targets()
    var hit_landed := false

    for target in targets:
        if not _is_live_player_body(target):
            continue

        if target.has_method("apply_flame_damage"):
            target.apply_flame_damage(attack_damage)
            hit_landed = true
        elif target.has_method("die_from_flames"):
            target.die_from_flames()
            hit_landed = true

    if hit_landed:
        _play_punch_hit_sound()

    return hit_landed

func _get_attack_damage_targets() -> Array[Node]:
    var targets := _get_attack_hitbox_targets(active_attack_hitbox)
    if _is_player_within_attack_range(attack_range):
        _append_unique_node_target(targets, player)
    return targets

func _get_attack_hitbox_targets(hitbox: Area3D) -> Array[Node]:
    var targets: Array[Node] = []
    if hitbox == null:
        return targets

    for body in hitbox.get_overlapping_bodies():
        _append_unique_node_target(targets, body)

    var world := get_world_3d()
    if world == null:
        return targets

    for child in hitbox.get_children():
        var collision_shape := child as CollisionShape3D
        if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
            continue

        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = collision_shape.shape
        query.transform = collision_shape.global_transform
        query.collision_mask = hitbox.collision_mask
        query.collide_with_areas = false
        query.collide_with_bodies = true
        query.exclude = _get_vision_excludes()

        for hit: Dictionary in world.direct_space_state.intersect_shape(query, 16):
            _append_unique_node_target(targets, hit.get("collider") as Object)

    return targets

func _append_unique_node_target(targets: Array[Node], candidate: Object) -> void:
    if candidate == null or not candidate is Node:
        return

    var node := candidate as Node
    if not targets.has(node):
        targets.append(node)

func _should_force_vision_update() -> bool:
    return (
        state == ZombieState.Chase
        or state == ZombieState.SearchLastSeen
        or state == ZombieState.ReturnToPatrol
        or state == ZombieState.PositionForAttack
    )

func _can_see_player(force_update := false) -> bool:
    vision_timer -= get_physics_process_delta_time()
    if vision_timer > 0.0 and not force_update:
        return cached_player_visible

    vision_timer = vision_interval
    if player == null or _is_player_dead():
        cached_player_visible = false
        return false

    var origin := _get_vision_origin()
    var target := _get_player_target_position()
    var to_player := target - origin
    if to_player.length() > vision_range:
        cached_player_visible = false
        return false

    var horizontal_to_player := Vector3(to_player.x, 0.0, to_player.z)
    if horizontal_to_player.length_squared() <= 0.0001:
        cached_player_visible = _has_line_of_sight_to_player()
        return cached_player_visible

    var angle_cos := cos(deg_to_rad(fov_degrees * 0.5))
    if absf(facing_direction.normalized().dot(horizontal_to_player.normalized())) < angle_cos:
        cached_player_visible = false
        return false

    cached_player_visible = _has_line_of_sight_to_player()
    return cached_player_visible

func _has_line_of_sight_to_player() -> bool:
    if player == null:
        return false

    var world := get_world_3d()
    if world == null:
        return false

    var excludes := _get_vision_excludes()
    var query := PhysicsRayQueryParameters3D.create(
        _get_vision_origin(),
        _get_player_target_position(),
        vision_collision_mask
    )
    query.collide_with_areas = false
    query.collide_with_bodies = true

    while true:
        query.exclude = excludes
        var hit := world.direct_space_state.intersect_ray(query)
        if hit.is_empty():
            return true

        var collider := hit.get("collider") as Object
        if collider == player or _is_descendant_of(collider, player):
            return true

        if collider == zombie_body or _is_descendant_of(collider, zombie_body):
            var rid := hit.get("rid", RID()) as RID
            if rid.is_valid():
                excludes.append(rid)
                continue

        return false

    return false

func _is_player_dead() -> bool:
    return player != null and player.has_method("is_dead") and player.is_dead()

func _can_start_attack() -> bool:
    return _is_player_within_attack_range(attack_range) or _is_touching_player_collision(false)

func _can_continue_attack() -> bool:
    return _is_player_within_attack_range(maxf(attack_continue_range, attack_range))

func _select_attack_position_target() -> bool:
    if player == null or _is_player_dead():
        has_attack_position_target = false
        return false

    var slot_count := maxi(attack_position_slot_count, 1)
    var player_position := _get_player_navigation_position()
    var body_position := _get_body_position()
    var attack_radius := maxf(attack_range * 0.9, 0.1)
    var best_position := Vector3.INF
    var best_score := INF
    var angle_offset := atan2(body_position.x - player_position.x, body_position.z - player_position.z)

    for slot_index in range(slot_count):
        var angle := angle_offset + TAU * float(slot_index) / float(slot_count)
        var candidate := player_position + Vector3(sin(angle), 0.0, cos(angle)) * attack_radius
        candidate.y = body_position.y
        if not _is_attack_position_free(candidate):
            continue

        var score := body_position.distance_squared_to(candidate)
        if score < best_score:
            best_score = score
            best_position = candidate

    if best_position == Vector3.INF:
        has_attack_position_target = false
        return false

    attack_position_target = best_position
    attack_position_player_anchor = player_position
    has_attack_position_target = true
    stuck_timer = 0.0
    _set_navigation_target(attack_position_target)
    return true

func _is_attack_position_free(candidate: Vector3) -> bool:
    if player != null and _has_static_blocker_between(_get_player_navigation_position(), candidate):
        return false

    var tree := get_tree()
    if tree == null:
        return true

    var clearance := maxf(attack_position_clearance, 0.0)
    var clearance_squared := clearance * clearance
    for zombie_node in tree.get_nodes_in_group(SMART_ZOMBIE_GROUP):
        if zombie_node == self or not zombie_node is Node:
            continue

        var other_zombie := zombie_node as Node
        if not other_zombie.has_method("get_spike_trap_position"):
            continue

        var other_position: Vector3 = other_zombie.get_spike_trap_position()
        other_position.y = candidate.y
        if other_position.distance_squared_to(candidate) < clearance_squared:
            return false

        if other_zombie.has_method("has_reserved_attack_position") and other_zombie.has_reserved_attack_position():
            var reserved_position: Vector3 = other_zombie.get_reserved_attack_position()
            reserved_position.y = candidate.y
            if reserved_position.distance_squared_to(candidate) < clearance_squared:
                return false

    return true

func _is_player_within_attack_range(range_to_check: float) -> bool:
    if player == null or not _is_live_player_body(player):
        return false

    var to_player := player.global_position - _get_body_position()
    to_player.y = 0.0
    return to_player.length() <= maxf(range_to_check, 0.0)

func _is_touching_player_collision(include_slide_collisions := true) -> bool:
    if player == null or zombie_body == null:
        return false

    if include_slide_collisions:
        for collision_index in zombie_body.get_slide_collision_count():
            var collision := zombie_body.get_slide_collision(collision_index)
            if collision != null and _is_live_player_body(collision.get_collider() as Node):
                return true

    var body_shape := _find_collision_shape(zombie_body)
    if body_shape == null or body_shape.shape == null:
        return false

    var world := get_world_3d()
    if world == null:
        return false

    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = _get_touch_attack_query_shape(body_shape.shape)
    query.transform = body_shape.global_transform
    query.collision_mask = PLAYER_COLLISION_LAYER
    query.collide_with_areas = false
    query.collide_with_bodies = true
    query.exclude = _get_vision_excludes()

    for hit: Dictionary in world.direct_space_state.intersect_shape(query, 8):
        var collider := hit.get("collider") as Node
        if _is_live_player_body(collider):
            return true

    return false

func _get_touch_attack_query_shape(source_shape: Shape3D) -> Shape3D:
    var margin := maxf(player_touch_attack_probe_margin, 0.0)
    if source_shape is CapsuleShape3D:
        var source_capsule := source_shape as CapsuleShape3D
        var capsule := CapsuleShape3D.new()
        capsule.radius = source_capsule.radius + margin
        capsule.height = source_capsule.height + margin * 2.0
        return capsule

    if source_shape is SphereShape3D:
        var source_sphere := source_shape as SphereShape3D
        var sphere := SphereShape3D.new()
        sphere.radius = source_sphere.radius + margin
        return sphere

    if source_shape is BoxShape3D:
        var source_box := source_shape as BoxShape3D
        var box := BoxShape3D.new()
        box.size = source_box.size + Vector3.ONE * margin * 2.0
        return box

    return source_shape
