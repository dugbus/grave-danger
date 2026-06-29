class_name GDPushable
extends RigidBody3D


const PLAYER_COLLISION_LAYER := 2
const WORLD_COLLISION_LAYER := 1
const MIN_PUSH_SPEED := 0.05
const WALL_INTO_NORMAL_EPSILON := -0.01

@export_group("Collision")
@export var add_to_pushable_group := true
@export var add_to_navigation_blocker_group := true
@export var use_world_collision_layer := true
@export var collide_with_player := true
@export var constrain_to_starting_height := true
@export var lock_rotation_to_upright := true

@export_group("Motion")
@export_range(0.0, 5000.0, 10.0) var character_push_force := 650.0
@export_range(0.0, 20.0, 0.1) var max_character_push_speed := 2.2
@export_range(0.0, 20.0, 0.1) var max_planar_speed := 3.0
@export_range(0.0, 1.0, 0.01) var stop_below_speed := 0.04
@export_range(0.01, 0.5, 0.01) var character_push_interval := 0.08
@export_range(0.01, 0.5, 0.01) var character_push_memory_seconds := 0.14
@export_range(0.0, 1.0, 0.01) var character_contact_push_bias := 0.08

@export_group("Wall Sliding")
@export var wall_slide_enabled := true
@export_flags_3d_physics var wall_slide_collision_mask := WORLD_COLLISION_LAYER
@export_range(0.0, 1.0, 0.01) var wall_contact_min_horizontal_normal := 0.35
@export_range(0.0, 1.0, 0.01) var blocked_push_wall_dot_threshold := 0.2
@export_range(-1.0, 1.0, 0.01) var same_wall_normal_min_dot := 0.5
@export_range(-1.0, 1.0, 0.01) var corner_distinct_normal_max_dot := 0.35
@export var wall_slide_latch_enabled := true
@export_range(0.01, 0.5, 0.01) var wall_slide_latch_seconds := 0.16
@export_range(0.0, 1.0, 0.01) var wall_slide_parallel_dot_threshold := 0.35

@export_group("Corner Recovery")
@export var corner_recovery_enabled := true
@export_range(0.01, 1.0, 0.01) var corner_stuck_after_seconds := 0.08
@export_range(0.0001, 0.2, 0.0001) var corner_recovery_distance := 0.025
@export_range(0.0, 4.0, 0.01) var corner_recovery_velocity := 0.65
@export_range(0.0, 1.0, 0.01) var corner_stuck_speed_threshold := 0.12
@export_range(0.0, 3.0, 0.01) var corner_recovery_wall_bias := 0.7

var starting_height := 0.0

var wall_contact_normals: Array[Vector3] = []
var recent_push_direction := Vector3.ZERO
var recent_push_speed := 0.0
var recent_push_timer := 0.0
var recent_push_blocked_by_wall := false
var corner_stuck_timer := 0.0

var latched_wall_normal := Vector3.ZERO
var wall_slide_latch_timer := 0.0


func _ready() -> void:
	starting_height = global_position.y

	if add_to_pushable_group:
		add_to_group("pushable")

	if add_to_navigation_blocker_group:
		add_to_group("navigation_blocker")

	if use_world_collision_layer:
		collision_layer |= WORLD_COLLISION_LAYER

	if collide_with_player:
		collision_mask |= PLAYER_COLLISION_LAYER

	if constrain_to_starting_height:
		gravity_scale = 0.0
		axis_lock_linear_y = true

	if lock_rotation_to_upright:
		lock_rotation = true
		axis_lock_angular_x = true
		axis_lock_angular_y = true
		axis_lock_angular_z = true

	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = max(max_contacts_reported, 12)


func push(impulse: Vector3) -> void:
	var horizontal_impulse := Vector3(impulse.x, 0.0, impulse.z)
	if horizontal_impulse.is_zero_approx():
		return

	if wall_slide_enabled:
		horizontal_impulse = _remove_into_wall_component(horizontal_impulse)

	if horizontal_impulse.is_zero_approx():
		return

	sleeping = false
	apply_central_impulse(horizontal_impulse)


func push_from_character(character_velocity: Vector3, collision_normal: Vector3, delta: float) -> void:
	var horizontal_velocity := Vector3(character_velocity.x, 0.0, character_velocity.z)
	if horizontal_velocity.length_squared() < MIN_PUSH_SPEED * MIN_PUSH_SPEED:
		return

	var velocity_push_direction := horizontal_velocity.normalized()
	var contact_push_direction := _get_contact_push_direction(collision_normal)

	recent_push_direction = velocity_push_direction

	if not contact_push_direction.is_zero_approx():
		var moving_into_contact := velocity_push_direction.dot(contact_push_direction)

		if moving_into_contact > 0.05:
			recent_push_direction = (
				velocity_push_direction + contact_push_direction * character_contact_push_bias
			).normalized()

	recent_push_speed = minf(horizontal_velocity.length(), max_character_push_speed)
	recent_push_timer = character_push_memory_seconds

	sleeping = false


func is_recent_push_blocked_by_wall() -> bool:
	return recent_push_timer > 0.0 and recent_push_blocked_by_wall


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_update_wall_contact_normals(state)

	recent_push_timer = maxf(recent_push_timer - state.step, 0.0)

	if recent_push_timer <= 0.0:
		recent_push_direction = Vector3.ZERO
		recent_push_speed = 0.0
		recent_push_blocked_by_wall = false
		corner_stuck_timer = 0.0
	else:
		recent_push_blocked_by_wall = wall_slide_enabled and _is_push_direction_blocked_by_wall(recent_push_direction)

	_update_wall_slide_latch(state.step)

	var current_velocity := state.linear_velocity
	var planar_velocity := Vector3(current_velocity.x, 0.0, current_velocity.z)

	if wall_slide_enabled:
		planar_velocity = _remove_into_wall_component(planar_velocity)

	if recent_push_timer > 0.0:
		planar_velocity = _apply_character_push_force(planar_velocity, state.step)

	var planar_speed := planar_velocity.length()

	if max_planar_speed > 0.0 and planar_speed > max_planar_speed:
		planar_velocity = planar_velocity.normalized() * max_planar_speed
	elif planar_speed < stop_below_speed and recent_push_timer <= 0.0:
		planar_velocity = Vector3.ZERO

	current_velocity.x = planar_velocity.x
	current_velocity.z = planar_velocity.z

	if constrain_to_starting_height:
		current_velocity.y = 0.0

	state.linear_velocity = current_velocity

	if corner_recovery_enabled:
		_apply_corner_recovery(state, planar_velocity)

	if constrain_to_starting_height:
		var current_transform := state.transform
		current_transform.origin.y = starting_height
		state.transform = current_transform

	if lock_rotation_to_upright:
		state.angular_velocity = Vector3.ZERO


func _apply_character_push_force(planar_velocity: Vector3, delta: float) -> Vector3:
	if recent_push_direction.is_zero_approx():
		return planar_velocity

	if recent_push_speed <= 0.0:
		return planar_velocity

	var push_direction := Vector3(recent_push_direction.x, 0.0, recent_push_direction.z)

	if push_direction.length_squared() < 0.0001:
		return planar_velocity

	push_direction = push_direction.normalized()

	if wall_slide_enabled:
		push_direction = _remove_into_wall_component(push_direction)

	if push_direction.length_squared() < 0.0001:
		return planar_velocity

	push_direction = push_direction.normalized()

	var current_speed_along_push := planar_velocity.dot(push_direction)
	var target_speed_along_push := recent_push_speed

	# Important:
	# Touching a moving ball from behind must not slow it down.
	# If the ball is already moving at or above the player's useful push speed,
	# do not pull it back toward the player speed.
	if current_speed_along_push >= target_speed_along_push:
		return planar_velocity

	var safe_mass := maxf(mass, 0.001)
	var push_acceleration := character_push_force / safe_mass
	var speed_to_add := minf(push_acceleration * delta, target_speed_along_push - current_speed_along_push)

	if speed_to_add <= 0.0:
		return planar_velocity

	return planar_velocity + push_direction * speed_to_add


func _get_contact_push_direction(collision_normal: Vector3) -> Vector3:
	var horizontal_normal := Vector3(collision_normal.x, 0.0, collision_normal.z)

	if horizontal_normal.length_squared() < 0.0001:
		return Vector3.ZERO

	return -horizontal_normal.normalized()


func _update_wall_contact_normals(state: PhysicsDirectBodyState3D) -> void:
	wall_contact_normals.clear()

	for contact_index in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(contact_index)

		if not _is_wall_slide_collider(collider):
			continue

		var normal := state.transform.basis * state.get_contact_local_normal(contact_index)
		normal = Vector3(normal.x, 0.0, normal.z)

		if normal.length() < wall_contact_min_horizontal_normal:
			continue

		_add_wall_contact_normal(normal.normalized())


func _is_wall_slide_collider(collider: Object) -> bool:
	if not collider is CollisionObject3D:
		return false

	var collision_object := collider as CollisionObject3D

	if collision_object == self:
		return false

	if collision_object.is_in_group("pushable"):
		return false

	if collider is RigidBody3D:
		return false

	return (collision_object.collision_layer & wall_slide_collision_mask) != 0


func _add_wall_contact_normal(normal: Vector3) -> void:
	for normal_index in range(wall_contact_normals.size()):
		var existing_normal := wall_contact_normals[normal_index]

		if existing_normal.dot(normal) <= same_wall_normal_min_dot:
			continue

		if _should_replace_same_wall_normal(existing_normal, normal):
			wall_contact_normals[normal_index] = normal

		return

	wall_contact_normals.append(normal)


func _should_replace_same_wall_normal(existing_normal: Vector3, candidate_normal: Vector3) -> bool:
	var existing_axis_strength := maxf(absf(existing_normal.x), absf(existing_normal.z))
	var candidate_axis_strength := maxf(absf(candidate_normal.x), absf(candidate_normal.z))

	if candidate_axis_strength > existing_axis_strength + 0.05:
		return true

	if existing_axis_strength > candidate_axis_strength + 0.05:
		return false

	if recent_push_direction.length_squared() > 0.0001:
		var push_direction := recent_push_direction.normalized()
		return absf(push_direction.dot(candidate_normal)) < absf(push_direction.dot(existing_normal))

	return false


func _update_wall_slide_latch(delta: float) -> void:
	if not wall_slide_latch_enabled:
		wall_slide_latch_timer = 0.0
		latched_wall_normal = Vector3.ZERO
		return

	wall_slide_latch_timer = maxf(wall_slide_latch_timer - delta, 0.0)

	if recent_push_timer <= 0.0 or recent_push_direction.length_squared() < 0.0001:
		wall_slide_latch_timer = 0.0
		latched_wall_normal = Vector3.ZERO
		return

	var best_wall_normal := _get_best_wall_normal_for_parallel_slide(recent_push_direction)

	if best_wall_normal.length_squared() < 0.0001:
		if wall_slide_latch_timer <= 0.0:
			latched_wall_normal = Vector3.ZERO

		return

	latched_wall_normal = best_wall_normal
	wall_slide_latch_timer = wall_slide_latch_seconds


func _get_best_wall_normal_for_parallel_slide(push_direction: Vector3) -> Vector3:
	var horizontal_push := Vector3(push_direction.x, 0.0, push_direction.z)

	if horizontal_push.length_squared() < 0.0001:
		return Vector3.ZERO

	horizontal_push = horizontal_push.normalized()

	var best_normal := Vector3.ZERO
	var best_abs_dot := INF

	for wall_normal in wall_contact_normals:
		var normal_dot := horizontal_push.dot(wall_normal)
		var abs_dot := absf(normal_dot)

		if abs_dot > wall_slide_parallel_dot_threshold:
			continue

		if abs_dot >= best_abs_dot:
			continue

		best_abs_dot = abs_dot
		best_normal = wall_normal

	return best_normal


func _remove_into_wall_component(vector: Vector3) -> Vector3:
	var adjusted := Vector3(vector.x, 0.0, vector.z)

	if adjusted.length_squared() < 0.000001:
		return Vector3.ZERO

	if _has_active_wall_slide_latch():
		return _remove_into_latched_wall_component(adjusted)

	if _has_corner_contact():
		return _remove_into_corner_wall_components(adjusted)

	return _remove_into_single_wall_component(adjusted)


func _has_active_wall_slide_latch() -> bool:
	return wall_slide_latch_timer > 0.0 and latched_wall_normal.length_squared() > 0.0001


func _remove_into_latched_wall_component(vector: Vector3) -> Vector3:
	var wall_normal := latched_wall_normal.normalized()
	var into_wall_amount := vector.dot(wall_normal)

	if into_wall_amount >= WALL_INTO_NORMAL_EPSILON:
		return vector

	return vector - wall_normal * into_wall_amount


func _remove_into_single_wall_component(vector: Vector3) -> Vector3:
	var wall_normal := _get_best_single_wall_normal_for_slide(vector)

	if wall_normal.length_squared() < 0.0001:
		return vector

	var into_wall_amount := vector.dot(wall_normal)

	if into_wall_amount >= WALL_INTO_NORMAL_EPSILON:
		return vector

	return vector - wall_normal * into_wall_amount


func _remove_into_corner_wall_components(vector: Vector3) -> Vector3:
	var adjusted := vector

	for wall_normal in wall_contact_normals:
		var into_wall_amount := adjusted.dot(wall_normal)

		if into_wall_amount < WALL_INTO_NORMAL_EPSILON:
			adjusted -= wall_normal * into_wall_amount

	return adjusted


func _get_best_single_wall_normal_for_slide(vector: Vector3) -> Vector3:
	var direction := Vector3(vector.x, 0.0, vector.z)

	if direction.length_squared() < 0.0001:
		return Vector3.ZERO

	direction = direction.normalized()

	var best_normal := Vector3.ZERO
	var best_dot := -INF

	for wall_normal in wall_contact_normals:
		var normal_dot := direction.dot(wall_normal)

		if normal_dot >= WALL_INTO_NORMAL_EPSILON:
			continue

		if normal_dot > best_dot:
			best_dot = normal_dot
			best_normal = wall_normal

	return best_normal


func _is_push_direction_blocked_by_wall(push_direction: Vector3) -> bool:
	var horizontal_push := Vector3(push_direction.x, 0.0, push_direction.z)

	if horizontal_push.is_zero_approx():
		return false

	horizontal_push = horizontal_push.normalized()

	for wall_normal in wall_contact_normals:
		if _has_active_wall_slide_latch():
			if wall_normal.dot(latched_wall_normal) < same_wall_normal_min_dot:
				continue

		if horizontal_push.dot(wall_normal) < -blocked_push_wall_dot_threshold:
			return true

	return false


func _has_corner_contact() -> bool:
	if wall_contact_normals.size() < 2:
		return false

	if _has_active_wall_slide_latch():
		return false

	for index_a in range(wall_contact_normals.size()):
		for index_b in range(index_a + 1, wall_contact_normals.size()):
			if wall_contact_normals[index_a].dot(wall_contact_normals[index_b]) <= corner_distinct_normal_max_dot:
				return true

	return false


func _get_wall_escape_direction() -> Vector3:
	var escape_direction := Vector3.ZERO

	for wall_normal in wall_contact_normals:
		escape_direction += wall_normal

	escape_direction.y = 0.0

	if escape_direction.length_squared() < 0.0001:
		return Vector3.ZERO

	return escape_direction.normalized()


func _get_corner_recovery_direction() -> Vector3:
	var push_direction := Vector3(recent_push_direction.x, 0.0, recent_push_direction.z)
	var wall_escape_direction := _get_wall_escape_direction()

	if wall_escape_direction.length_squared() > 0.0001:
		wall_escape_direction = wall_escape_direction.normalized()

	if not push_direction.is_zero_approx():
		push_direction = push_direction.normalized()

		var safe_push_direction := _remove_into_corner_wall_components(push_direction)

		if safe_push_direction.length_squared() > 0.0001:
			safe_push_direction = safe_push_direction.normalized()

			if wall_escape_direction.length_squared() > 0.0001:
				var biased_direction := safe_push_direction + wall_escape_direction * corner_recovery_wall_bias

				if biased_direction.length_squared() > 0.0001:
					return biased_direction.normalized()

			return safe_push_direction

	if wall_escape_direction.length_squared() > 0.0001:
		return wall_escape_direction

	return Vector3.ZERO


func _apply_corner_recovery(state: PhysicsDirectBodyState3D, planar_velocity: Vector3) -> void:
	if recent_push_timer <= 0.0:
		corner_stuck_timer = 0.0
		return

	if not _has_corner_contact():
		corner_stuck_timer = 0.0
		return

	if planar_velocity.length() > corner_stuck_speed_threshold:
		corner_stuck_timer = 0.0
		return

	var recovery_direction := _get_corner_recovery_direction()

	if recovery_direction.length_squared() < 0.0001:
		corner_stuck_timer = 0.0
		return

	corner_stuck_timer += state.step

	if corner_stuck_timer < corner_stuck_after_seconds:
		return

	var current_transform := state.transform
	current_transform.origin += recovery_direction * corner_recovery_distance

	if constrain_to_starting_height:
		current_transform.origin.y = starting_height

	state.transform = current_transform

	if corner_recovery_velocity > 0.0:
		var current_velocity := state.linear_velocity
		var current_planar_velocity := Vector3(current_velocity.x, 0.0, current_velocity.z)
		var current_recovery_speed := current_planar_velocity.dot(recovery_direction)

		if current_recovery_speed < corner_recovery_velocity:
			var added_velocity := recovery_direction * (corner_recovery_velocity - current_recovery_speed)
			current_velocity.x += added_velocity.x
			current_velocity.z += added_velocity.z
			state.linear_velocity = current_velocity

	corner_stuck_timer = corner_stuck_after_seconds
