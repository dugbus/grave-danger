class_name FloorSurfaceTestPlayer
extends CharacterBody3D

## Deterministic standalone controller used only by the floor-surface playground.

const SETTINGS_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_test_player_settings.gd"
)

signal reset_performed

## Shared movement settings kept separate from the production player.
@export var settings: SETTINGS_SCRIPT
## Camera used to translate input into screen-relative world movement.
@export var movement_camera_path: NodePath
## Labelled playground marker used for automatic and manual resets.
@export var reset_marker_path: NodePath

@onready var movement_camera := get_node_or_null(movement_camera_path) as Camera3D
@onready var reset_marker := get_node_or_null(reset_marker_path) as Node3D

var _initial_transform := Transform3D.IDENTITY


func _ready() -> void:
	_initial_transform = global_transform
	_apply_character_settings()


func _physics_process(delta: float) -> void:
	if settings == null:
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := get_camera_relative_direction(input_direction)
	update_velocity(move_direction, Input.is_action_just_pressed("jump"), is_on_floor(), delta)
	move_and_slide()
	if should_reset(global_position.y):
		reset_to_start()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		reset_to_start()
		get_viewport().set_input_as_handled()


## Converts two-axis input to a horizontal direction aligned with the active camera.
func get_camera_relative_direction(input_direction: Vector2) -> Vector3:
	if input_direction.is_zero_approx():
		return Vector3.ZERO
	if movement_camera == null:
		return Vector3(input_direction.x, 0.0, input_direction.y).normalized()

	var camera_right := movement_camera.global_basis.x
	var camera_forward := -movement_camera.global_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0
	camera_right = camera_right.normalized()
	camera_forward = camera_forward.normalized()
	return (camera_right * input_direction.x - camera_forward * input_direction.y).normalized()


## Advances velocity from explicit inputs so controller behaviour can be tested without input events.
func update_velocity(
	move_direction: Vector3,
	jump_requested: bool,
	is_grounded: bool,
	delta: float
) -> void:
	if settings == null:
		return

	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var horizontal_direction := Vector2(move_direction.x, move_direction.z).limit_length(1.0)
	if not horizontal_direction.is_zero_approx():
		var target_velocity := horizontal_direction * settings.movement_speed
		horizontal_velocity = horizontal_velocity.move_toward(
			target_velocity,
			settings.acceleration * delta
		)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(
			Vector2.ZERO,
			settings.deceleration * delta
		)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	if is_grounded:
		velocity.y = settings.get_jump_velocity() if jump_requested else 0.0
	else:
		velocity.y -= settings.gravity * delta


## Returns whether a world height is below the configured safe playground range.
func should_reset(world_y: float) -> bool:
	return settings != null and world_y < settings.fall_reset_y


## Returns the player to the labelled point and clears all accumulated motion.
func reset_to_start() -> void:
	var target_transform := _initial_transform
	if reset_marker != null and reset_marker.is_inside_tree():
		target_transform = reset_marker.global_transform
	reset_to_transform(target_transform)


## Applies an explicit reset pose, exposed for repeatable playground tests.
func reset_to_transform(target_transform: Transform3D) -> void:
	if is_inside_tree():
		global_transform = target_transform
	else:
		transform = target_transform
	velocity = Vector3.ZERO
	reset_performed.emit()


func _apply_character_settings() -> void:
	if settings == null:
		return
	floor_snap_length = settings.floor_snap_length
	floor_max_angle = settings.get_maximum_floor_angle_radians()
	floor_stop_on_slope = true
