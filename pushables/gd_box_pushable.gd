class_name GDBoxPushable
extends CharacterBody3D


const PLAYER_COLLISION_LAYER := 2
const WORLD_COLLISION_LAYER := 1
const MIN_PUSH_SPEED := 0.05
const TOP_CONTACT_MIN_NORMAL_Y := 0.65

@export_group("Collision")
@export var add_to_pushable_group := true
@export var add_to_navigation_blocker_group := true
@export var use_world_collision_layer := true
@export var collide_with_player := true
@export var constrain_to_starting_height := true
@export var lock_rotation_to_upright := true

@export_group("Motion")
@export_range(1.0, 500.0, 1.0) var effective_mass := 46.0
@export_range(0.0, 5000.0, 10.0) var push_force := 740.0
@export_range(0.0, 50.0, 0.1) var stop_acceleration := 24.0
@export_range(0.0, 20.0, 0.1) var max_character_push_speed := 2.2
@export_range(0.0, 20.0, 0.1) var max_planar_speed := 3.0
@export_range(0.0, 1.0, 0.01) var stop_below_speed := 0.04
@export_range(0.01, 0.5, 0.01) var character_push_memory_seconds := 0.14
@export var lock_movement_to_axis := true

var starting_height := 0.0
var target_velocity := Vector3.ZERO
var movement_axis := Vector3.ZERO
var push_timer := 0.0


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


func _physics_process(delta: float) -> void:
	push_timer = maxf(push_timer - delta, 0.0)

	if push_timer <= 0.0:
		target_velocity = Vector3.ZERO

	var planar_velocity := Vector3(velocity.x, 0.0, velocity.z)

	if lock_movement_to_axis and not movement_axis.is_zero_approx():
		planar_velocity = _project_to_axis(planar_velocity, movement_axis)

	var acceleration := _get_push_acceleration()

	if target_velocity.is_zero_approx():
		acceleration = stop_acceleration

	planar_velocity = planar_velocity.move_toward(target_velocity, acceleration * delta)

	if max_planar_speed > 0.0 and planar_velocity.length() > max_planar_speed:
		planar_velocity = planar_velocity.normalized() * max_planar_speed
	elif planar_velocity.length() < stop_below_speed and target_velocity.is_zero_approx():
		planar_velocity = Vector3.ZERO
		movement_axis = Vector3.ZERO

	velocity = Vector3(planar_velocity.x, 0.0, planar_velocity.z)
	move_and_slide()

	if lock_movement_to_axis and not movement_axis.is_zero_approx():
		var axis_velocity := _project_to_axis(Vector3(velocity.x, 0.0, velocity.z), movement_axis)
		velocity = Vector3(axis_velocity.x, 0.0, axis_velocity.z)

	if constrain_to_starting_height:
		global_position.y = starting_height

	if lock_rotation_to_upright:
		rotation = Vector3.ZERO


func push(impulse: Vector3) -> void:
	var horizontal_impulse := Vector3(impulse.x, 0.0, impulse.z)
	if horizontal_impulse.is_zero_approx():
		return

	_set_push_velocity(horizontal_impulse)


func push_from_character(character_velocity: Vector3, collision_normal: Vector3, _delta: float) -> void:
	if collision_normal.y >= TOP_CONTACT_MIN_NORMAL_Y:
		target_velocity = Vector3.ZERO
		movement_axis = Vector3.ZERO
		push_timer = 0.0
		return

	var horizontal_velocity := Vector3(character_velocity.x, 0.0, character_velocity.z)
	if horizontal_velocity.length_squared() < MIN_PUSH_SPEED * MIN_PUSH_SPEED:
		return

	_set_push_velocity(horizontal_velocity)


func _set_push_velocity(horizontal_velocity: Vector3) -> void:
	if lock_movement_to_axis:
		horizontal_velocity = _get_axis_locked_velocity(horizontal_velocity)

	var push_speed := minf(horizontal_velocity.length(), max_character_push_speed)

	if push_speed <= 0.0:
		return

	movement_axis = horizontal_velocity.normalized()
	target_velocity = horizontal_velocity.normalized() * push_speed
	push_timer = character_push_memory_seconds


func _get_push_acceleration() -> float:
	var safe_mass := maxf(effective_mass, 1.0)

	return push_force / safe_mass


func _get_axis_locked_velocity(horizontal_velocity: Vector3) -> Vector3:
	var x_strength := absf(horizontal_velocity.x)
	var z_strength := absf(horizontal_velocity.z)

	if x_strength >= z_strength:
		return Vector3(horizontal_velocity.x, 0.0, 0.0)

	return Vector3(0.0, 0.0, horizontal_velocity.z)


func _project_to_axis(planar_velocity: Vector3, axis: Vector3) -> Vector3:
	if axis.is_zero_approx():
		return Vector3.ZERO

	var normalized_axis := axis.normalized()

	return normalized_axis * planar_velocity.dot(normalized_axis)
