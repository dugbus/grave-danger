class_name FloorSurfaceTestPlayer
extends CharacterBody3D

## Deterministic standalone controller used only by the floor-surface playground.

const SETTINGS_SCRIPT := preload(
	"res://addons/floor_surface/test/floor_surface_test_player_settings.gd"
)
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")

signal reset_performed
signal traversal_mode_changed(mode: int)

## Shared movement settings kept separate from the production player.
@export var settings: SETTINGS_SCRIPT
## Camera used to translate input into screen-relative world movement.
@export var movement_camera_path: NodePath
## Labelled playground marker used for automatic and manual resets.
@export var reset_marker_path: NodePath
## Isolated FloorSurface used only for provisional walkable-step assistance.
@export var floor_surface_path: NodePath = ^"../FloorSurface"

@onready var movement_camera := get_node_or_null(movement_camera_path) as Camera3D
@onready var reset_marker := get_node_or_null(reset_marker_path) as Node3D
@onready var floor_surface := get_node_or_null(floor_surface_path) as SURFACE_SCRIPT
@onready var collision_shape := get_node_or_null(^"CollisionShape3D") as CollisionShape3D

var _initial_transform := Transform3D.IDENTITY
var traversal_mode := SETTINGS_SCRIPT.TraversalMode.Normal


func _ready() -> void:
	_initial_transform = global_transform
	_apply_character_settings()


func _physics_process(delta: float) -> void:
	if settings == null:
		return

	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := get_camera_relative_direction(input_direction)
	var was_grounded := is_on_floor()
	update_velocity(move_direction, Input.is_action_just_pressed("jump"), was_grounded, delta)
	_apply_walkable_step(move_direction, was_grounded)
	_apply_traversal_gate(move_direction)
	move_and_slide()
	if should_reset(global_position.y):
		reset_to_start()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_R:
		reset_to_start()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_U:
		toggle_traversal_mode()
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
		velocity.y = settings.get_jump_velocity(traversal_mode) if jump_requested else 0.0
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


## Changes the active reset point so each comparison lane can be repeated quickly.
func set_reset_marker(marker: Node3D) -> void:
	reset_marker = marker


## Switches the temporary movement mode used to exercise the reserved jump threshold.
func toggle_traversal_mode() -> void:
	traversal_mode = (
		SETTINGS_SCRIPT.TraversalMode.Unencumbered
		if traversal_mode == SETTINGS_SCRIPT.TraversalMode.Normal
		else SETTINGS_SCRIPT.TraversalMode.Normal
	)
	traversal_mode_changed.emit(traversal_mode)


## Returns the human-readable test mode displayed by the playground HUD.
func get_traversal_mode_name() -> String:
	return "Unencumbered" \
		if traversal_mode == SETTINGS_SCRIPT.TraversalMode.Unencumbered else "Normal"


## Resolves a safe one-frame step lift from sampled heights and the body's current foot height.
func resolve_walkable_step_height(
	current_surface_height: float,
	target_surface_height: float,
	current_foot_height: float,
	is_grounded: bool
) -> float:
	if settings == null or not is_grounded:
		return 0.0
	if absf(current_foot_height - current_surface_height) > 0.08:
		return 0.0
	var rise := target_surface_height - current_surface_height
	if rise <= 0.0 or rise > settings.maximum_step_height + 0.001:
		return 0.0
	return rise


## Reports whether the selected test mode may enter an upward edge classification.
func can_enter_traversal(traversal: int) -> bool:
	if floor_surface == null or floor_surface.elevation_profile == null:
		return true
	match traversal as FloorElevationProfile.TraversalClass:
		FloorElevationProfile.TraversalClass.UnencumberedOnlyJump:
			return traversal_mode == SETTINGS_SCRIPT.TraversalMode.Unencumbered
		FloorElevationProfile.TraversalClass.BlockedLedge:
			return false
		_:
			return true


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


func _apply_walkable_step(move_direction: Vector3, is_grounded: bool) -> void:
	if floor_surface == null or settings == null or move_direction.is_zero_approx():
		return
	var current_sample := floor_surface.sample_surface(global_position)
	var probe_position := global_position + move_direction.normalized() * settings.step_probe_distance
	var target_sample := floor_surface.sample_surface(probe_position)
	if not current_sample.valid or not target_sample.valid:
		return
	var step_height := resolve_walkable_step_height(
		current_sample.world_height,
		target_sample.world_height,
		_get_current_foot_height(),
		is_grounded
	)
	if step_height > 0.0:
		global_position.y += step_height


func _apply_traversal_gate(move_direction: Vector3) -> void:
	if floor_surface == null or settings == null or move_direction.is_zero_approx():
		return
	var current_cell := floor_surface.world_to_cell(global_position)
	var probe_position := global_position + move_direction.normalized() * settings.step_probe_distance
	var target_cell := floor_surface.world_to_cell(probe_position)
	if current_cell == target_cell or not floor_surface.has_floor(current_cell) \
			or not floor_surface.has_floor(target_cell):
		return
	if can_enter_traversal(floor_surface.classify_edge(current_cell, target_cell)):
		return
	velocity.x = 0.0
	velocity.z = 0.0


func _get_current_foot_height() -> float:
	if collision_shape == null or not (collision_shape.shape is CapsuleShape3D):
		return global_position.y
	var capsule := collision_shape.shape as CapsuleShape3D
	return global_position.y + collision_shape.position.y - capsule.height * 0.5
