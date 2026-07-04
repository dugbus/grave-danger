extends "res://enemies/zombie/zombie_combat.gd"
class_name GDZombiePath

const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")


func _ready() -> void:
	add_to_group(CHARACTER_GROUP)
	add_to_group(SMART_ZOMBIE_GROUP)
	_seed_deterministic_rng()
	_load_footstep_sounds()
	_load_punch_hit_sound()
	_randomize_next_footstep_distance()
	_configure_nodes()
	_apply_start_progress()
	_build_patrol_points()
	_sync_body_to_path_start()
	_configure_shadow_casting()
	_configure_zombie_light()
	_set_attack_hitboxes_enabled(false)

	if character != null:
		animation_player = _find_animation_player(character)
		_resolve_animation_names()

	previous_body_position = _get_body_position()
	navigation_ready = ai_enabled_on_ready
	state = ZombieState.PATROL if navigation_ready else ZombieState.LEVEL_START

	if drop_in_time > 0.0:
		_set_active_visible(false)
	else:
		_finish_drop_in()

func _physics_process(delta: float) -> void:
	if zombie_body == null:
		_update_animation(0.0)
		return

	if is_dead:
		return

	if not _update_drop_in(delta):
		_update_animation(0.0)
		return

	if not navigation_ready:
		_change_state(ZombieState.LEVEL_START)
		_stop_body()
		_update_animation(0.0)
		return

	_resolve_player()
	_update_rolling_ball_death(delta)
	_update_state(delta)

func set_navigation_ready(is_ready: bool) -> void:
	navigation_ready = is_ready
	navigation_ready_changed.emit(navigation_ready)
	if navigation_ready and state == ZombieState.LEVEL_START:
		_change_state(ZombieState.PATROL)
		_set_next_patrol_target()
	elif not navigation_ready:
		_change_state(ZombieState.LEVEL_START)
		_stop_body()

func set_ai_enabled(enabled: bool) -> void:
	set_navigation_ready(enabled)

func set_ai_player(target_player: Node3D) -> void:
	player = target_player
	vision_timer = 0.0
	last_seen_timer = lost_sight_seconds
	cached_player_visible = false

func set_navigation_grid_maps(grid_maps: Array[GridMap]) -> void:
	navigation_grid_maps.clear()
	navigation_grid_bounds_by_id.clear()

	for grid_map in grid_maps:
		if grid_map == null:
			continue

		navigation_grid_maps.append(grid_map)
		navigation_grid_bounds_by_id[grid_map.get_instance_id()] = _get_grid_navigation_bounds(grid_map)

func get_zombie_state() -> ZombieState:
	return state

func die_from_spike_trap() -> void:
	_die_from_rolling_ball()

func can_be_hit_by_spike_trap() -> bool:
	return not is_dead

func get_spike_trap_position() -> Vector3:
	return _get_body_position()

func force_state_for_test(next_state: ZombieState) -> void:
	_change_state(next_state)

func _configure_nodes() -> void:
	if zombie_body != null:
		zombie_body.collision_layer |= ZOMBIE_COLLISION_LAYER
		zombie_body.collision_mask |= WORLD_COLLISION_LAYER | PLAYER_COLLISION_LAYER | ZOMBIE_COLLISION_LAYER

	if navigation_agent != null:
		navigation_agent.path_desired_distance = 0.18
		navigation_agent.target_desired_distance = 0.35
		navigation_agent.avoidance_enabled = false

	if crush_check_area != null:
		crush_check_area.monitoring = true
		crush_check_area.monitorable = false

func _seed_deterministic_rng() -> void:
	footstep_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"zombie")

func _update_state(delta: float) -> void:
	if is_dead:
		_change_state(ZombieState.DIE)
		return

	if _is_crushed(delta):
		_change_state(ZombieState.CRUSHED)
		_die_from_rolling_ball()
		return

	if _is_player_dead():
		_return_to_patrol_after_player_death()

	var visible_player := false if _is_player_dead() else _can_see_player(_should_force_vision_update())
	if visible_player:
		last_seen_position = _get_player_navigation_position()
		last_seen_timer = 0.0
		if state != ZombieState.ATTACK and _is_route_reachable(last_seen_position):
			if _can_start_attack():
				_change_state(ZombieState.ATTACK)
			else:
				_change_state(ZombieState.CHASE)
	else:
		last_seen_timer += delta

	match state:
		ZombieState.LEVEL_START:
			_stop_body()
		ZombieState.PATROL:
			_update_patrol(delta)
		ZombieState.CHASE:
			_update_chase(delta, visible_player)
		ZombieState.SEARCH_LAST_SEEN:
			_update_search_last_seen(delta, visible_player)
		ZombieState.RETURN_TO_PATROL:
			_update_return_to_patrol(delta, visible_player)
		ZombieState.POSITION_FOR_ATTACK:
			_update_position_for_attack(delta, visible_player)
		ZombieState.ATTACK:
			_update_attack(delta, visible_player)
		ZombieState.SITDOWN:
			_update_sitdown(delta, visible_player)
		ZombieState.CRUSHED:
			_stop_body()
		ZombieState.DIE:
			_stop_body()

func _update_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(ZombieState.SITDOWN)
		return

	var body_position := _get_body_position()
	if body_position.distance_to(current_target) <= patrol_point_reached_distance:
		_advance_patrol_target()

	if not _is_route_reachable(current_target):
		_update_stuck(delta, 0.0)
		if stuck_timer >= stuck_seconds_before_sit:
			_change_state(ZombieState.SITDOWN)
		return

	var horizontal_speed := _follow_navigation_target(current_target, delta)
	_after_motion(delta, horizontal_speed)

func _update_chase(delta: float, visible_player: bool) -> void:
	if player == null or _is_player_dead():
		_change_state(ZombieState.RETURN_TO_PATROL)
		return

	if visible_player:
		last_seen_position = _get_player_navigation_position()
		last_seen_timer = 0.0

	if _can_start_attack():
		_change_state(ZombieState.ATTACK)
		return

	if last_seen_timer >= lost_sight_seconds:
		_change_state(ZombieState.SEARCH_LAST_SEEN)
		_set_navigation_target(last_seen_position)
		return

	var chase_target := _get_player_navigation_position() if visible_player else last_seen_position
	repath_timer -= delta
	if repath_timer <= 0.0:
		repath_timer = repath_interval
		if visible_player and not _is_route_reachable(chase_target):
			_change_state(ZombieState.SITDOWN)
			return
		_set_navigation_target(chase_target)

	var horizontal_speed := _follow_navigation_target(chase_target, delta, false, shuffle_speed)
	if visible_player and _is_blocked_by_zombie() and _select_attack_position_target():
		_change_state(ZombieState.POSITION_FOR_ATTACK)
		_update_animation(horizontal_speed)
		return

	if visible_player:
		_after_motion(delta, horizontal_speed)
	else:
		_update_animation(horizontal_speed)
		_update_footsteps(delta, horizontal_speed)

func _update_search_last_seen(delta: float, visible_player: bool) -> void:
	if visible_player:
		_change_state(ZombieState.CHASE)
		return

	search_timer += delta
	var body_position := _get_body_position()
	if body_position.distance_to(last_seen_position) > patrol_point_reached_distance:
		var horizontal_speed := _follow_navigation_target(last_seen_position, delta, false)
		_after_motion(delta, horizontal_speed)
		if search_timer < search_duration:
			return

	_stop_body()
	_scan_deterministically(delta)
	_update_animation(0.0)
	if search_timer >= search_duration:
		_change_state(ZombieState.RETURN_TO_PATROL)

func _update_return_to_patrol(delta: float, visible_player: bool) -> void:
	if visible_player:
		_change_state(ZombieState.CHASE)
		return

	if patrol_points.is_empty():
		_change_state(ZombieState.SITDOWN)
		return

	var body_position := _get_body_position()
	if body_position.distance_to(current_target) <= patrol_point_reached_distance:
		_change_state(ZombieState.PATROL)
		return

	var horizontal_speed := _follow_navigation_target(current_target, delta)
	_after_motion(delta, horizontal_speed)

func _update_position_for_attack(delta: float, visible_player: bool) -> void:
	if player == null or _is_player_dead():
		_change_state(ZombieState.RETURN_TO_PATROL)
		return

	if visible_player:
		last_seen_position = _get_player_navigation_position()
		last_seen_timer = 0.0
	elif last_seen_timer >= lost_sight_seconds:
		_change_state(ZombieState.SEARCH_LAST_SEEN)
		return

	if _can_start_attack():
		_change_state(ZombieState.ATTACK)
		return

	var current_player_position := _get_player_navigation_position()
	if has_attack_position_target and current_player_position.distance_to(attack_position_player_anchor) > attack_position_reached_distance:
		_change_state(ZombieState.CHASE)
		return

	repath_timer -= delta
	if repath_timer <= 0.0:
		repath_timer = repath_interval
		if not _select_attack_position_target():
			_change_state(ZombieState.CHASE)
			return

	if not has_attack_position_target or _has_static_blocker_between(_get_player_navigation_position(), attack_position_target):
		if not _select_attack_position_target():
			_change_state(ZombieState.CHASE)
			return

	var body_position := _get_body_position()
	if body_position.distance_to(attack_position_target) <= attack_position_reached_distance:
		if not _select_attack_position_target():
			_change_state(ZombieState.CHASE)
			return

	var horizontal_speed := _follow_navigation_target(attack_position_target, delta, false, shuffle_speed)
	if _is_blocked_by_zombie():
		_select_attack_position_target()

	_after_motion(delta, horizontal_speed)

func _update_attack(delta: float, visible_player: bool) -> void:
	_stop_body()

	if not _can_continue_attack():
		_set_attack_hitboxes_enabled(false)
		if player != null and _is_player_dead():
			_change_state(ZombieState.RETURN_TO_PATROL)
		elif player == null or last_seen_timer >= lost_sight_seconds:
			_change_state(ZombieState.SEARCH_LAST_SEEN)
		else:
			_change_state(ZombieState.CHASE)
		return

	_face_position(_get_player_target_position(), delta)
	attack_timer += delta

	if attack_timer >= current_attack_hit_start_seconds and attack_timer <= current_attack_hit_end_seconds:
		_set_attack_hitbox_enabled(active_attack_hitbox, true)
		if not attack_hit_applied:
			attack_hit_applied = _apply_attack_damage()

	if attack_timer >= current_attack_hit_end_seconds:
		_set_attack_hitboxes_enabled(false)

	var attack_cycle_seconds := maxf(attack_cooldown, current_attack_hit_end_seconds)
	if attack_timer < attack_cycle_seconds:
		return

	if not visible_player:
		if last_seen_timer >= lost_sight_seconds:
			_change_state(ZombieState.SEARCH_LAST_SEEN)
		else:
			_change_state(ZombieState.CHASE)
	elif _can_start_attack():
		_start_attack()
	else:
		_change_state(ZombieState.CHASE)

func _update_sitdown(delta: float, visible_player: bool) -> void:
	_stop_body()
	sit_vision_timer -= delta
	sit_repath_timer -= delta

	if _is_player_dead() and not patrol_points.is_empty():
		_change_state(ZombieState.RETURN_TO_PATROL)
		return

	if visible_player:
		if _can_start_attack():
			_change_state(ZombieState.ATTACK)
		else:
			_change_state(ZombieState.CHASE)
		return

	_scan_randomly_while_idle(delta)
	_update_animation(0.0)

	if sit_repath_timer <= 0.0:
		sit_repath_timer = sit_repath_interval
		if _select_closest_reachable_patrol_target():
			_change_state(ZombieState.RETURN_TO_PATROL)

func _change_state(next_state: ZombieState) -> void:
	if state == next_state:
		return

	state = next_state
	stuck_timer = 0.0
	if state != ZombieState.POSITION_FOR_ATTACK:
		has_attack_position_target = false

	match state:
		ZombieState.LEVEL_START:
			_play_animation(static_animation_name)
		ZombieState.PATROL:
			_set_next_patrol_target()
		ZombieState.CHASE:
			repath_timer = 0.0
		ZombieState.SEARCH_LAST_SEEN:
			search_timer = 0.0
			_set_navigation_target(last_seen_position)
		ZombieState.RETURN_TO_PATROL:
			_select_closest_reachable_patrol_target()
		ZombieState.POSITION_FOR_ATTACK:
			repath_timer = 0.0
			_select_attack_position_target()
		ZombieState.ATTACK:
			_start_attack()
		ZombieState.SITDOWN:
			sit_repath_timer = 0.0
			sit_vision_timer = 0.0
			idle_scan_timer = 0.0
			_set_attack_hitboxes_enabled(false)
			_play_animation(idle_animation_name)
		ZombieState.CRUSHED:
			_set_attack_hitboxes_enabled(false)
		ZombieState.DIE:
			_set_attack_hitboxes_enabled(false)

func _return_to_patrol_after_player_death() -> void:
	cached_player_visible = false
	last_seen_timer = lost_sight_seconds
	_set_attack_hitboxes_enabled(false)

	if patrol_points.is_empty():
		if state != ZombieState.SITDOWN:
			_change_state(ZombieState.SITDOWN)
		return

	if state != ZombieState.PATROL and state != ZombieState.RETURN_TO_PATROL:
		_change_state(ZombieState.RETURN_TO_PATROL)

func _after_motion(delta: float, horizontal_speed: float) -> void:
	_update_animation(horizontal_speed)
	_update_footsteps(delta, horizontal_speed)
	if stuck_timer >= stuck_seconds_before_sit:
		_change_state(ZombieState.SITDOWN)

func _is_crushed(delta: float) -> bool:
	if crush_check_area == null:
		return false

	var crushed := false
	for body in crush_check_area.get_overlapping_bodies():
		if _is_rolling_ball_body(body):
			crushed = true
			break

	crush_timer = crush_timer + delta if crushed else 0.0
	return crush_timer >= crush_confirm_seconds

func _update_rolling_ball_death(_delta: float) -> void:
	if not rolling_ball_death_enabled or is_dead:
		return

	var world := get_world_3d()
	if world == null:
		return

	var detection_center := _get_detection_center()
	var query_shape := SphereShape3D.new()
	query_shape.radius = rolling_ball_death_detection_radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = query_shape
	query.transform = Transform3D(Basis.IDENTITY, detection_center)
	query.collision_mask = map_collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hits := world.direct_space_state.intersect_shape(query, 8)
	for hit: Dictionary in hits:
		var collider := hit.get("collider") as Object
		if not _is_rolling_ball_body(collider):
			continue

		var collider_3d := collider as Node3D
		if collider_3d == null:
			continue

		var encroachment_percent := _get_rolling_ball_encroachment_percent(detection_center, collider_3d.global_position)
		if encroachment_percent >= rolling_ball_death_encroachment_percent:
			_die_from_rolling_ball()
			return

func _get_detection_center() -> Vector3:
	var collision_shape := _find_collision_shape(kill_area)
	if collision_shape != null:
		return collision_shape.global_position

	return _get_body_position()

func _get_rolling_ball_encroachment_percent(detection_center: Vector3, ball_position: Vector3) -> float:
	var horizontal_delta := ball_position - detection_center
	horizontal_delta.y = 0.0

	var overlap_depth := rolling_ball_death_detection_radius + rolling_ball_death_radius - horizontal_delta.length()
	if overlap_depth <= 0.0:
		return 0.0

	var detection_radius := maxf(rolling_ball_death_detection_radius, 0.001)
	return clampf(overlap_depth / detection_radius * 100.0, 0.0, 100.0)

func _die_from_rolling_ball() -> void:
	if is_dead:
		return

	is_dead = true
	_change_state(ZombieState.DIE)
	footstep_distance_accumulator = 0.0
	_stop_body()
	_set_kill_area_enabled(false)
	_set_attack_hitboxes_enabled(false)
	_play_death_scream()
	_play_death_animation()

	if zombie_light != null:
		zombie_light.visible = false

	_disappear_after_death()

func _is_rolling_ball_body(collider: Object) -> bool:
	if collider == null or not collider is Node:
		return false

	var node := collider as Node
	return node is RollingRock or String(node.name).contains("RollingRock")
