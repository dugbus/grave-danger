extends RigidBody3D
class_name GDLockableHingedLeaf


const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2
const MIN_PUSH_SPEED_SQUARED := 0.01
const MIN_HINGE_DISTANCE_SQUARED := 0.001

@export_range(0.0, 180.0, 1.0, "degrees") var open_limit_degrees := 105.0
@export_range(0.0, 50.0, 0.1) var push_torque := 16.0
@export_range(0.0, 20.0, 0.1) var limit_spring_strength := 9.0
@export_range(0.0, 10.0, 0.1) var closed_latch_strength := 1.2
@export_range(0.0, 5.0, 0.05) var closed_latch_angle_degrees := 4.0
@export var push_area_path: NodePath = ^"PushArea"

var closed_transform := Transform3D.IDENTITY
var closed_yaw := 0.0
var locked := true

@onready var push_area := get_node_or_null(push_area_path) as Area3D


func _ready() -> void:
	closed_transform = global_transform
	closed_yaw = _get_body_yaw()
	_configure_body()
	set_locked(locked)


func _physics_process(delta: float) -> void:
	if locked:
		_hold_closed()
		return

	_apply_player_push()
	_apply_hinge_limits(delta)


func set_locked(value: bool) -> void:
	locked = value
	freeze = locked
	if locked:
		_hold_closed()


func is_locked() -> bool:
	return locked


func push_from_character(push_velocity: Vector3, collision_normal: Vector3, _delta: float) -> void:
	if locked:
		return

	var velocity := Vector3(push_velocity.x, 0.0, push_velocity.z)
	if velocity.length_squared() < MIN_PUSH_SPEED_SQUARED:
		return

	var hinge_to_character := Vector3(collision_normal.x, 0.0, collision_normal.z)
	if hinge_to_character.length_squared() < MIN_HINGE_DISTANCE_SQUARED:
		return

	_apply_push_torque(velocity, hinge_to_character.normalized())


func _configure_body() -> void:
	collision_layer = WORLD_COLLISION_LAYER
	collision_mask = PLAYER_COLLISION_LAYER
	gravity_scale = 0.0
	linear_damp = 20.0
	angular_damp = 4.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3.ZERO
	can_sleep = false
	lock_rotation = false
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = false
	axis_lock_angular_z = true


func _apply_player_push() -> void:
	if push_area == null:
		return

	for body in push_area.get_overlapping_bodies():
		if not (body is CharacterBody3D):
			continue

		var character := body as CharacterBody3D
		var velocity := Vector3(character.velocity.x, 0.0, character.velocity.z)
		if velocity.length_squared() < MIN_PUSH_SPEED_SQUARED:
			continue

		var hinge_to_character := character.global_position - global_position
		hinge_to_character.y = 0.0
		if hinge_to_character.length_squared() < MIN_HINGE_DISTANCE_SQUARED:
			continue

		_apply_push_torque(velocity, hinge_to_character.normalized())


func _apply_push_torque(velocity: Vector3, hinge_to_character: Vector3) -> void:
	var torque := hinge_to_character.cross(velocity).y * push_torque
	apply_torque(Vector3.UP * torque)


func _apply_hinge_limits(delta: float) -> void:
	var limit := deg_to_rad(open_limit_degrees)
	if limit <= 0.0:
		_hold_closed()
		return

	var angle := _get_open_angle()
	if absf(angle) <= deg_to_rad(closed_latch_angle_degrees):
		apply_torque(Vector3.UP * -angle * closed_latch_strength)

	if angle > limit:
		apply_torque(Vector3.UP * (limit - angle) * limit_spring_strength / maxf(delta, 0.001))
		if angular_velocity.y > 0.0:
			angular_velocity.y = 0.0
	elif angle < -limit:
		apply_torque(Vector3.UP * (-limit - angle) * limit_spring_strength / maxf(delta, 0.001))
		if angular_velocity.y < 0.0:
			angular_velocity.y = 0.0


func _hold_closed() -> void:
	freeze = true
	global_transform = closed_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _get_open_angle() -> float:
	return wrapf(_get_body_yaw() - closed_yaw, -PI, PI)


func _get_body_yaw() -> float:
	var forward := -global_basis.z
	return atan2(forward.x, forward.z)
