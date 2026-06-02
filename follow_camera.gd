extends Camera3D


# The character this camera normally follows.
@export var target_path: NodePath = ^"../Player"

# The flame boundary controls the zoom so the safe area stays visible.
@export var flame_boundary_path: NodePath = ^"../LevelLayout/FlameBoundary"

# Base 2.5D camera offset before rotation and zoom scaling are applied.
@export var camera_offset := Vector3(0.0, 5.2, 5.6)

# The camera looks slightly above the focus point.
@export var look_ahead := Vector3(0.0, 0.55, 0.0)

# How quickly the camera position follows the moving focus point.
@export var follow_lag := 4.0

# Current and allowed camera distance.
@export var zoom_distance := 18.0
@export var min_zoom_distance := 4.2
@export var max_zoom_distance := 18.0
@export var manual_zoom_speed := 8.0

# Perspective and safe-area fitting settings.
@export var field_of_view := 34.0
@export var boundary_padding := 1.25
@export var boundary_zoom_lag := 3.0

# Right stick rotation settings.
@export var rotation_speed := 1.8
@export var camera_input_deadzone := 0.35

# Death camera settings.
@export var death_zoom_distance := 2.4
@export var death_look_offset := Vector3(0.0, 0.38, 0.0)
@export var death_zoom_lag := 4.5

# Cached scene references.
@onready var target: Node3D = get_node_or_null(target_path)
@onready var flame_boundary: Node = get_node_or_null(flame_boundary_path)

# The point the camera is currently following.
var focus_position := Vector3.ZERO

# Current camera rotation around the map.
var camera_yaw := 0.0

# Camera controls are disabled during death zoom.
var controls_enabled := true

# Set when the camera should focus on a dead player.
var death_target: Node3D


func _ready() -> void:
	# This runs once when the camera enters the scene.

	#current = true
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = field_of_view

	# Start yaw from the authored camera offset.
	camera_yaw = atan2(camera_offset.x, camera_offset.z)

	if target != null:
		focus_position = target.global_position
		_update_camera_transform()


func _physics_process(delta: float) -> void:
	# This runs repeatedly during the physics step.

	if death_target != null:
		_update_death_zoom(delta)
		return

	if target == null:
		return

	if controls_enabled:
		_update_camera_controls(delta)

	if _has_flame_boundary():
		_update_boundary_zoom(delta)
	elif controls_enabled:
		_update_manual_zoom(delta)

	# Smoothly lag the camera focus behind the desired point.
	var t := 1.0 - exp(-follow_lag * delta)
	focus_position = focus_position.lerp(_get_desired_focus_position(), t)
	_update_camera_transform()


func _update_camera_controls(delta: float) -> void:
	# Rotate the viewpoint with the right stick's left/right axis.

	var rotate_input := Input.get_axis("camera_rotate_left", "camera_rotate_right")

	rotate_input = 0.0 if absf(rotate_input) < camera_input_deadzone else rotate_input

	camera_yaw += rotate_input * rotation_speed * delta


func _update_manual_zoom(delta: float) -> void:
	var zoom_input := Input.get_axis("camera_zoom_in", "camera_zoom_out")
	zoom_input = 0.0 if absf(zoom_input) < camera_input_deadzone else zoom_input

	zoom_distance = clampf(
		zoom_distance + zoom_input * manual_zoom_speed * delta,
		min_zoom_distance,
		max_zoom_distance
	)


func _update_boundary_zoom(delta: float) -> void:
	# Adjust zoom so the current flame rectangle fits in the viewport.

	if not _has_flame_boundary():
		return

	var bounds_size := flame_boundary.get_bounds_size() as Vector2
	var desired_distance := _get_distance_for_bounds(bounds_size * boundary_padding)
	var t := 1.0 - exp(-boundary_zoom_lag * delta)
	zoom_distance = lerpf(zoom_distance, clampf(desired_distance, min_zoom_distance, max_zoom_distance), t)


func _get_distance_for_bounds(bounds_size: Vector2) -> float:
	# Work out the camera distance needed to see a rectangle of this size.
	#
	# The result checks both vertical and horizontal field of view,
	# then uses whichever distance is larger.

	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_fov := deg_to_rad(fov)
	var horizontal_fov := 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	var required_vertical := bounds_size.y * 0.5 / tan(vertical_fov * 0.5)
	var required_horizontal := bounds_size.x * 0.5 / tan(horizontal_fov * 0.5)
	return maxf(required_vertical, required_horizontal)


func _get_desired_focus_position() -> Vector3:
	# Follow the flame boundary centre when available,
	# otherwise fall back to the player.

	if _has_flame_boundary():
		return flame_boundary.get_bounds_center()

	return target.global_position


func _has_flame_boundary() -> bool:
	return (
		flame_boundary != null
		and is_instance_valid(flame_boundary)
		and flame_boundary.has_method("get_bounds_size")
		and flame_boundary.has_method("get_bounds_center")
	)


func _update_camera_transform() -> void:
	# Apply the current focus, yaw, and zoom to the actual Camera3D transform.

	global_position = focus_position + _get_rotated_camera_offset()
	look_at(focus_position + look_ahead)


func _get_rotated_camera_offset() -> Vector3:
	# Rotate the base offset around the Y axis and scale it by zoom_distance.

	var base_horizontal_distance := Vector2(camera_offset.x, camera_offset.z).length()
	var base_distance := Vector3(camera_offset.x, camera_offset.y, camera_offset.z).length()
	var distance_scale := zoom_distance / base_distance
	var horizontal_distance := base_horizontal_distance * distance_scale
	return Vector3(
		sin(camera_yaw) * horizontal_distance,
		camera_offset.y * distance_scale,
		cos(camera_yaw) * horizontal_distance
	)


func focus_on_dead_player(player: Node3D) -> void:
	# Called by the player when the death animation starts.

	controls_enabled = false
	death_target = player


func _update_death_zoom(delta: float) -> void:
	# Smoothly move the camera toward the dead player's face.

	var desired_look := death_target.global_position + death_look_offset
	var view_direction := (global_position - desired_look).normalized()
	var desired_position := desired_look + view_direction * death_zoom_distance
	var t := 1.0 - exp(-death_zoom_lag * delta)

	global_position = global_position.lerp(desired_position, t)
	fov = lerpf(fov, 28.0, t)
	look_at(desired_look)
