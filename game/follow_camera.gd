extends Camera3D
class_name GDFollowCamera


## Character or focus node this camera normally follows.
@export var target_path: NodePath = ^"../Player"

## Optional kill boundary used to auto-zoom until the safe area stays visible.
@export var kill_boundary_path: NodePath = ^"../LevelLayout/KillBoundary3D"

## Optional reusable set of camera tuning values for level-specific cameras.
@export var camera_profile: Resource:
	set(value):
		camera_profile = value
		if camera_profile != null:
			_apply_camera_profile_values(camera_profile)

## Base 2.5D offset before rotation and zoom scaling are applied.
@export var camera_offset := Vector3(0.0, 5.2, 5.6)

## Optional camera elevation angle above the ground plane. Negative uses camera_offset.
@export_range(-1.0, 89.0, 0.5) var view_elevation_degrees := -1.0

## Offset added to the followed position before the camera looks at it.
@export var look_ahead := Vector3(0.0, 0.55, 0.0)

## Extra distance to look past the target in the camera's forward direction.
@export var forward_look_ahead := 0.0

## Responsiveness of camera follow smoothing; higher values track faster.
@export var follow_lag := 4.0

## Current camera distance along the offset direction.
@export var zoom_distance := 18.0
## Closest manual or boundary-driven camera distance.
@export var min_zoom_distance := 4.2
## Farthest manual camera distance when no boundary controls zoom.
@export var max_zoom_distance := 18.0
## Manual zoom speed in distance units per second.
@export var manual_zoom_speed := 8.0

## Camera field of view, in degrees.
@export var field_of_view := 34.0
## Multiplier applied to kill-boundary bounds before fitting them on screen.
@export var boundary_padding := 1.25
## Responsiveness of boundary auto-zoom; higher values settle faster.
@export var boundary_zoom_lag := 3.0
## Farthest distance allowed while trying to fit the kill boundary.
## Keep this near max_zoom_distance so large flames do not force excessive zoom-out.
@export var max_boundary_zoom_distance := 18.0
## Binary-search iterations used to solve the boundary fit distance.
@export_range(4, 24, 1) var boundary_fit_iterations := 12

## Camera yaw rotation speed in radians per second from right-stick input.
@export var rotation_speed := 1.8
## Input magnitude ignored for camera rotation and manual zoom.
@export var camera_input_deadzone := 0.35

## Camera distance used while focusing on a dead player.
@export var death_zoom_distance := 2.4
## Focus offset from the dead player's origin during the death close-up.
@export var death_look_offset := Vector3(0.0, 0.38, 0.0)
## Responsiveness of death camera zoom and focus smoothing.
@export var death_zoom_lag := 4.5

# Cached scene references.
@onready var target: Node3D = get_node_or_null(target_path)
@onready var kill_boundary: Node = get_node_or_null(kill_boundary_path)

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

	if camera_profile != null:
		_apply_camera_profile_values(camera_profile)
	current = true
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = field_of_view

	# Start yaw from the authored camera offset.
	camera_yaw = atan2(camera_offset.x, camera_offset.z)

	if target != null:
		focus_position = target.global_position
		_update_camera_transform()


func apply_camera_profile(profile: Resource) -> void:
	camera_profile = profile


func _apply_camera_profile_values(profile: Resource) -> void:
	if profile == null:
		return

	camera_offset = profile.camera_offset
	view_elevation_degrees = profile.view_elevation_degrees
	look_ahead = profile.look_ahead
	forward_look_ahead = profile.forward_look_ahead
	follow_lag = profile.follow_lag
	zoom_distance = profile.zoom_distance
	min_zoom_distance = profile.min_zoom_distance
	max_zoom_distance = profile.max_zoom_distance
	manual_zoom_speed = profile.manual_zoom_speed
	field_of_view = profile.field_of_view
	boundary_padding = profile.boundary_padding
	boundary_zoom_lag = profile.boundary_zoom_lag
	max_boundary_zoom_distance = profile.max_boundary_zoom_distance
	boundary_fit_iterations = profile.boundary_fit_iterations
	rotation_speed = profile.rotation_speed
	camera_input_deadzone = profile.camera_input_deadzone
	death_zoom_distance = profile.death_zoom_distance
	death_look_offset = profile.death_look_offset
	death_zoom_lag = profile.death_zoom_lag
	fov = field_of_view
	camera_yaw = atan2(camera_offset.x, camera_offset.z)


func set_runtime_targets(target_node: Node, kill_boundary_node: Node) -> void:
	target = target_node as Node3D
	kill_boundary = kill_boundary_node
	death_target = null
	controls_enabled = true

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

	# Smoothly lag the camera focus behind the desired point.
	var t := 1.0 - exp(-follow_lag * delta)
	focus_position = focus_position.lerp(_get_desired_focus_position(), t)

	if _has_kill_boundary():
		_update_boundary_zoom(delta)
	elif controls_enabled:
		_update_manual_zoom(delta)

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
	# Adjust zoom so the current kill-boundary rectangle fits in the viewport.

	if not _has_kill_boundary():
		return

	var bounds_size := kill_boundary.get_bounds_size() as Vector2
	if bounds_size.x <= 0.0 or bounds_size.y <= 0.0:
		return

	var desired_distance := _get_distance_for_bounds(bounds_size * boundary_padding)
	var t := 1.0 - exp(-boundary_zoom_lag * delta)
	zoom_distance = lerpf(zoom_distance, maxf(desired_distance, min_zoom_distance), t)


func _get_distance_for_bounds(bounds_size: Vector2) -> float:
	# Work out the camera distance needed to see the kill-boundary rectangle as if the
	# camera focus were centered in the boundary. The actual camera can still
	# follow the player, but the target zoom stays stable as the player moves.

	var points := _get_boundary_fit_points(bounds_size)
	if points.is_empty():
		return min_zoom_distance

	var fit_focus := _get_boundary_fit_focus()
	var low := min_zoom_distance
	var high := maxf(zoom_distance, low)
	high = maxf(high, _get_initial_bounds_distance(bounds_size))
	high = minf(high, max_boundary_zoom_distance)

	while not _can_see_points_at_distance(points, high, fit_focus) and high < max_boundary_zoom_distance:
		low = high
		high = minf(high * 1.5 + 1.0, max_boundary_zoom_distance)

	if not _can_see_points_at_distance(points, high, fit_focus):
		return high

	for i in boundary_fit_iterations:
		var midpoint := (low + high) * 0.5
		if _can_see_points_at_distance(points, midpoint, fit_focus):
			high = midpoint
		else:
			low = midpoint

	return high


func _get_initial_bounds_distance(bounds_size: Vector2) -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_fov := deg_to_rad(fov)
	var horizontal_fov := 2.0 * atan(tan(vertical_fov * 0.5) * aspect)
	var required_vertical := bounds_size.y * 0.5 / tan(vertical_fov * 0.5)
	var required_horizontal := bounds_size.x * 0.5 / tan(horizontal_fov * 0.5)
	return maxf(required_vertical, required_horizontal)


func _get_boundary_fit_points(bounds_size: Vector2) -> Array[Vector3]:
	var bounds_transform := Transform3D(Basis.IDENTITY, kill_boundary.get_bounds_center())
	if kill_boundary.has_method("get_camera_fit_transform"):
		bounds_transform = kill_boundary.get_camera_fit_transform()
	elif kill_boundary.has_method("get_bounds_transform"):
		bounds_transform = kill_boundary.get_bounds_transform()

	var height := 0.0
	if kill_boundary.has_method("get_bounds_height"):
		height = maxf(kill_boundary.get_bounds_height(), 0.0)

	var half_x := bounds_size.x * 0.5
	var half_z := bounds_size.y * 0.5
	var points: Array[Vector3] = []

	for x in [-half_x, half_x]:
		for z in [-half_z, half_z]:
			points.append(bounds_transform * Vector3(x, 0.0, z))
			if height > 0.0:
				points.append(bounds_transform * Vector3(x, height, z))

	return points


func _get_boundary_fit_focus() -> Vector3:
	return kill_boundary.get_bounds_center()


func _can_see_points_at_distance(points: Array[Vector3], distance: float, fit_focus: Vector3) -> bool:
	var camera_transform := _get_camera_transform_for_distance(distance, fit_focus)
	var inverse_transform := camera_transform.affine_inverse()
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_tan := tan(deg_to_rad(fov) * 0.5)
	var horizontal_tan := vertical_tan * aspect

	for point in points:
		var local_point := inverse_transform * point
		var depth := -local_point.z
		if depth <= near:
			return false

		if absf(local_point.y) > depth * vertical_tan:
			return false

		if absf(local_point.x) > depth * horizontal_tan:
			return false

	return true


func _get_desired_focus_position() -> Vector3:
	# The camera always follows the player. Boundary mode only changes zoom.
	return target.global_position


func _has_kill_boundary() -> bool:
	return (
		kill_boundary != null
		and is_instance_valid(kill_boundary)
		and (not kill_boundary is Node3D or (kill_boundary as Node3D).is_visible_in_tree())
		and kill_boundary.has_method("get_bounds_size")
		and kill_boundary.has_method("get_bounds_center")
	)


func _update_camera_transform() -> void:
	# Apply the current focus, yaw, and zoom to the actual Camera3D transform.

	global_position = focus_position + _get_rotated_camera_offset()
	look_at(_get_look_target(focus_position))


func _get_rotated_camera_offset() -> Vector3:
	return _get_rotated_camera_offset_for_distance(zoom_distance)


func _get_rotated_camera_offset_for_distance(distance: float) -> Vector3:
	# Rotate the base offset around the Y axis and scale it by zoom_distance.

	var base_horizontal_distance := Vector2(camera_offset.x, camera_offset.z).length()
	var base_distance := Vector3(camera_offset.x, camera_offset.y, camera_offset.z).length()
	var distance_scale := distance / maxf(base_distance, 0.001)
	var horizontal_distance := base_horizontal_distance * distance_scale
	var vertical_distance := camera_offset.y * distance_scale

	if view_elevation_degrees >= 0.0:
		var elevation := deg_to_rad(clampf(view_elevation_degrees, 0.0, 89.0))
		horizontal_distance = cos(elevation) * distance
		vertical_distance = sin(elevation) * distance

	return Vector3(
		sin(camera_yaw) * horizontal_distance,
		vertical_distance,
		cos(camera_yaw) * horizontal_distance
	)


func _get_camera_transform_for_distance(distance: float, fit_focus: Vector3) -> Transform3D:
	var camera_position := fit_focus + _get_rotated_camera_offset_for_distance(distance)
	var look_position := _get_look_target_for_distance(fit_focus, distance)
	return Transform3D(Basis.IDENTITY, camera_position).looking_at(look_position, Vector3.UP)


func _get_look_target(focus: Vector3) -> Vector3:
	return _get_look_target_for_distance(focus, zoom_distance)


func _get_look_target_for_distance(focus: Vector3, distance: float) -> Vector3:
	return focus + look_ahead + _get_forward_look_ahead_offset(distance)


func _get_forward_look_ahead_offset(distance: float) -> Vector3:
	if is_zero_approx(forward_look_ahead):
		return Vector3.ZERO

	var offset := _get_rotated_camera_offset_for_distance(distance)
	var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
	if horizontal_offset.is_zero_approx():
		return Vector3.ZERO

	return -horizontal_offset.normalized() * forward_look_ahead


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
