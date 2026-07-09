class_name GDLevelSelectCrypt
extends Node3D

## Adds runtime hinge physics and level-select trigger behavior to the imported
## level crypt without editing the source Blender scene.

const DOOR_BODY_NAME := "DoorBody"
const DOOR_COLLISION_NAME := "DoorCollision"
const PUSH_AREA_NAME := "DoorPushArea"
const PUSH_AREA_COLLISION_NAME := "DoorPushAreaCollision"
const LEVEL_TRIGGER_AREA_NAME := "LevelTriggerArea"
const LEVEL_TRIGGER_COLLISION_NAME := "LevelTriggerCollision"
const DEFAULT_DOOR_PATH := ^"crypt-large-door/door"
const DEFAULT_LEVEL_TRIGGER_PATH := ^"level-trigger"
const PLAYER_COLLISION_LAYER := 2
const WORLD_COLLISION_LAYER := 1
const GAME_SCENE := "res://game/graveyard.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")

@export_group("Door")
@export var openable := true:
	set(value):
		openable = value
		_apply_lock_state()

@export var locked := false:
	set(value):
		locked = value
		_apply_lock_state()

@export var door_path: NodePath = DEFAULT_DOOR_PATH
@export_range(0.0, 180.0, 1.0, "degrees") var open_limit_degrees := 105.0
@export_range(0.0, 50.0, 0.1) var push_torque := 16.0
@export_range(0.0, 20.0, 0.1) var limit_spring_strength := 9.0
@export_range(0.0, 10.0, 0.1) var closed_latch_strength := 1.2
@export_range(0.0, 5.0, 0.05) var closed_latch_angle_degrees := 4.0
@export_range(0.0, 1.0, 0.01) var collision_padding := 0.04
@export_range(0.0, 1.5, 0.05) var push_area_padding := 0.35

@export_group("Level Trigger")
@export var level_trigger_path: NodePath = DEFAULT_LEVEL_TRIGGER_PATH
@export_range(1, 8, 1) var target_level_number := 1
@export_range(0.0, 4.0, 0.05) var trigger_fade_out_duration := 0.8

var door_body: RigidBody3D
var push_area: Area3D
var level_trigger_area: Area3D
var level_trigger_center := Vector3.ZERO
var level_trigger_half_extents := Vector3.ZERO
var closed_transform := Transform3D.IDENTITY
var closed_yaw := 0.0
var is_configured := false
var is_trigger_configured := false
var is_changing_level := false


func _ready() -> void:
	_configure_door_physics()
	_configure_level_trigger()


func set_locked(value: bool) -> void:
	locked = value


func set_openable(value: bool) -> void:
	openable = value


func is_locked() -> bool:
	return locked


func is_openable() -> bool:
	return openable


func _physics_process(delta: float) -> void:
	if is_configured and door_body != null:
		if not openable or locked:
			_hold_closed()
		else:
			_apply_player_push()
			_apply_hinge_limits(delta)

	_check_level_trigger()


func _configure_door_physics() -> void:
	if is_configured:
		return

	door_body = get_node_or_null(DOOR_BODY_NAME) as RigidBody3D
	if door_body == null:
		door_body = _create_door_body()
	if door_body == null:
		push_warning("Crypt door mesh not found at %s." % door_path)
		return

	closed_transform = door_body.global_transform
	closed_yaw = _get_body_yaw()
	_configure_body()
	_configure_collision()
	_configure_push_area()
	_apply_lock_state()
	is_configured = true


func _configure_level_trigger() -> void:
	if is_trigger_configured:
		return

	var trigger_mesh := get_node_or_null(level_trigger_path) as MeshInstance3D
	if trigger_mesh == null:
		push_warning("Crypt level trigger mesh not found at %s." % level_trigger_path)
		return

	_disable_imported_visuals(trigger_mesh)
	if trigger_mesh.mesh == null:
		return

	var aabb := trigger_mesh.mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		maxf(aabb.size.x, 0.05),
		maxf(aabb.size.y, 0.05),
		maxf(aabb.size.z, 0.05)
	)
	level_trigger_center = aabb.position + aabb.size * 0.5
	level_trigger_half_extents = shape.size * 0.5

	level_trigger_area = get_node_or_null(LEVEL_TRIGGER_AREA_NAME) as Area3D
	if level_trigger_area == null:
		level_trigger_area = Area3D.new()
		level_trigger_area.name = LEVEL_TRIGGER_AREA_NAME
		add_child(level_trigger_area)
	level_trigger_area.global_transform = trigger_mesh.global_transform
	level_trigger_area.collision_layer = 0
	level_trigger_area.collision_mask = PLAYER_COLLISION_LAYER
	level_trigger_area.monitoring = true

	var collision := level_trigger_area.get_node_or_null(LEVEL_TRIGGER_COLLISION_NAME) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = LEVEL_TRIGGER_COLLISION_NAME
		level_trigger_area.add_child(collision)
	collision.shape = shape
	collision.position = level_trigger_center
	is_trigger_configured = true


func _create_door_body() -> RigidBody3D:
	var door_mesh := get_node_or_null(door_path) as MeshInstance3D
	if door_mesh == null:
		return null

	var door_transform := door_mesh.global_transform
	var body := RigidBody3D.new()
	body.name = DOOR_BODY_NAME

	var old_parent := door_mesh.get_parent()
	if old_parent != null:
		_disable_imported_door_collision(old_parent)
		old_parent.add_child(body)
		body.global_transform = door_transform
		old_parent.remove_child(door_mesh)
	else:
		_disable_imported_door_collision(door_mesh)
	body.add_child(door_mesh)
	door_mesh.global_transform = door_transform

	return body


func _configure_body() -> void:
	door_body.collision_layer = WORLD_COLLISION_LAYER
	door_body.collision_mask = PLAYER_COLLISION_LAYER
	door_body.mass = 8.0
	door_body.gravity_scale = 0.0
	door_body.linear_damp = 20.0
	door_body.angular_damp = 4.0
	door_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	door_body.center_of_mass = Vector3.ZERO
	door_body.can_sleep = false
	door_body.lock_rotation = false
	door_body.axis_lock_linear_x = true
	door_body.axis_lock_linear_y = true
	door_body.axis_lock_linear_z = true
	door_body.axis_lock_angular_x = true
	door_body.axis_lock_angular_y = false
	door_body.axis_lock_angular_z = true


func _configure_collision() -> void:
	var door_mesh := _get_door_mesh()
	if door_mesh == null or door_mesh.mesh == null:
		return

	var aabb := door_mesh.mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		maxf(aabb.size.x + collision_padding, 0.05),
		maxf(aabb.size.y + collision_padding, 0.05),
		maxf(aabb.size.z + collision_padding, 0.05)
	)

	var collision := door_body.get_node_or_null(DOOR_COLLISION_NAME) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = DOOR_COLLISION_NAME
		door_body.add_child(collision)
	collision.shape = shape
	collision.position = aabb.position + aabb.size * 0.5


func _configure_push_area() -> void:
	var door_mesh := _get_door_mesh()
	if door_mesh == null or door_mesh.mesh == null:
		return

	var aabb := door_mesh.mesh.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = Vector3(
		maxf(aabb.size.x + push_area_padding, 0.1),
		maxf(aabb.size.y + push_area_padding, 0.1),
		maxf(aabb.size.z + push_area_padding, 0.1)
	)

	push_area = door_body.get_node_or_null(PUSH_AREA_NAME) as Area3D
	if push_area == null:
		push_area = Area3D.new()
		push_area.name = PUSH_AREA_NAME
		door_body.add_child(push_area)
	push_area.collision_layer = 0
	push_area.collision_mask = PLAYER_COLLISION_LAYER

	var collision := push_area.get_node_or_null(PUSH_AREA_COLLISION_NAME) as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = PUSH_AREA_COLLISION_NAME
		push_area.add_child(collision)
	collision.shape = shape
	collision.position = aabb.position + aabb.size * 0.5


func _apply_player_push() -> void:
	if push_area == null:
		return

	for body in push_area.get_overlapping_bodies():
		if not body is CharacterBody3D:
			continue

		var character := body as CharacterBody3D
		var velocity := Vector3(character.velocity.x, 0.0, character.velocity.z)
		if velocity.length_squared() < 0.01:
			continue

		var hinge_to_character := character.global_position - door_body.global_position
		hinge_to_character.y = 0.0
		if hinge_to_character.length_squared() < 0.001:
			continue

		var torque := hinge_to_character.cross(velocity).y * push_torque
		door_body.apply_torque(Vector3.UP * torque)


func _check_level_trigger() -> void:
	if not is_trigger_configured or level_trigger_area == null or is_changing_level:
		return

	for body in level_trigger_area.get_overlapping_bodies():
		if body is CharacterBody3D and _is_body_inside_level_trigger(body as CharacterBody3D):
			_start_level_transition()
			return


func _is_body_inside_level_trigger(body: CharacterBody3D) -> bool:
	var collision_center: Variant = _get_body_collision_center(body)
	if collision_center is Vector3:
		return _is_trigger_point_inside(collision_center)

	return _is_trigger_point_inside(body.global_position)


func _get_body_collision_center(body: CharacterBody3D) -> Variant:
	var collisions := _get_collision_shapes(body)
	if collisions.is_empty():
		return null

	for collision in collisions:
		if collision.disabled or collision.shape == null:
			continue

		return collision.global_position

	return null


func _get_collision_shapes(root: Node) -> Array[CollisionShape3D]:
	var collisions: Array[CollisionShape3D] = []
	if root is CollisionShape3D:
		collisions.append(root as CollisionShape3D)

	for child in root.get_children():
		collisions.append_array(_get_collision_shapes(child))

	return collisions


func _is_collision_shape_inside_level_trigger(collision: CollisionShape3D) -> bool:
	var shape := collision.shape
	if shape is SphereShape3D:
		return _is_trigger_sphere_inside(
			collision.global_position,
			_get_scaled_sphere_radius(collision, shape as SphereShape3D)
		)
	if shape is CapsuleShape3D:
		return _is_trigger_capsule_inside(collision, shape as CapsuleShape3D)
	if shape is BoxShape3D:
		return _is_trigger_box_inside(collision, shape as BoxShape3D)

	return _is_trigger_point_inside(collision.global_position)


func _is_trigger_sphere_inside(global_center: Vector3, radius: float) -> bool:
	var center := level_trigger_area.global_transform.affine_inverse() * global_center
	return (
		center.x - radius >= level_trigger_center.x - level_trigger_half_extents.x
		and center.x + radius <= level_trigger_center.x + level_trigger_half_extents.x
		and center.y - radius >= level_trigger_center.y - level_trigger_half_extents.y
		and center.y + radius <= level_trigger_center.y + level_trigger_half_extents.y
		and center.z - radius >= level_trigger_center.z - level_trigger_half_extents.z
		and center.z + radius <= level_trigger_center.z + level_trigger_half_extents.z
	)


func _is_trigger_capsule_inside(collision: CollisionShape3D, shape: CapsuleShape3D) -> bool:
	var absolute_basis_scale := _absolute_scale(collision.global_basis.get_scale())
	var radius := shape.radius * maxf(absolute_basis_scale.x, absolute_basis_scale.z)
	var half_height := maxf(shape.height * absolute_basis_scale.y * 0.5 - radius, 0.0)
	var offset := collision.global_basis.y.normalized() * half_height
	return (
		_is_trigger_sphere_inside(collision.global_position + offset, radius)
		and _is_trigger_sphere_inside(collision.global_position - offset, radius)
	)


func _is_trigger_box_inside(collision: CollisionShape3D, shape: BoxShape3D) -> bool:
	var half_size := shape.size * 0.5
	for x in [-half_size.x, half_size.x]:
		for y in [-half_size.y, half_size.y]:
			for z in [-half_size.z, half_size.z]:
				var point := collision.global_transform * Vector3(x, y, z)
				if not _is_trigger_point_inside(point):
					return false

	return true


func _is_trigger_point_inside(global_point: Vector3) -> bool:
	var point := level_trigger_area.global_transform.affine_inverse() * global_point
	return (
		point.x >= level_trigger_center.x - level_trigger_half_extents.x
		and point.x <= level_trigger_center.x + level_trigger_half_extents.x
		and point.y >= level_trigger_center.y - level_trigger_half_extents.y
		and point.y <= level_trigger_center.y + level_trigger_half_extents.y
		and point.z >= level_trigger_center.z - level_trigger_half_extents.z
		and point.z <= level_trigger_center.z + level_trigger_half_extents.z
	)


func _get_scaled_sphere_radius(collision: CollisionShape3D, shape: SphereShape3D) -> float:
	var absolute_basis_scale := _absolute_scale(collision.global_basis.get_scale())
	return shape.radius * maxf(absolute_basis_scale.x, maxf(absolute_basis_scale.y, absolute_basis_scale.z))


func _absolute_scale(source_scale: Vector3) -> Vector3:
	return Vector3(absf(source_scale.x), absf(source_scale.y), absf(source_scale.z))


func _start_level_transition() -> void:
	if is_changing_level:
		return

	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection == null or not level_selection.has_method("select_level"):
		return

	var target_index := target_level_number - 1
	if not level_selection.select_level(target_index):
		push_warning("Could not select target level %d." % target_level_number)
		return

	is_changing_level = true
	if level_trigger_area != null:
		level_trigger_area.monitoring = false

	var tween := SCREEN_FADE.fade_out(self, "LevelTriggerFade", trigger_fade_out_duration, "LevelTriggerFadeLayer")
	await tween.finished
	if is_inside_tree():
		get_tree().change_scene_to_file(GAME_SCENE)


func _apply_hinge_limits(delta: float) -> void:
	var limit := deg_to_rad(open_limit_degrees)
	if limit <= 0.0:
		_hold_closed()
		return

	var angle := _get_open_angle()
	if absf(angle) <= deg_to_rad(closed_latch_angle_degrees):
		door_body.apply_torque(Vector3.UP * -angle * closed_latch_strength)

	if angle > limit:
		door_body.apply_torque(Vector3.UP * (limit - angle) * limit_spring_strength / maxf(delta, 0.001))
		if door_body.angular_velocity.y > 0.0:
			door_body.angular_velocity.y = 0.0
	elif angle < -limit:
		door_body.apply_torque(Vector3.UP * (-limit - angle) * limit_spring_strength / maxf(delta, 0.001))
		if door_body.angular_velocity.y < 0.0:
			door_body.angular_velocity.y = 0.0


func _hold_closed() -> void:
	door_body.freeze = true
	door_body.global_transform = closed_transform
	door_body.linear_velocity = Vector3.ZERO
	door_body.angular_velocity = Vector3.ZERO


func _apply_lock_state() -> void:
	if door_body == null:
		return

	door_body.freeze = not openable or locked
	if door_body.freeze:
		_hold_closed()


func _get_open_angle() -> float:
	return wrapf(_get_body_yaw() - closed_yaw, -PI, PI)


func _get_body_yaw() -> float:
	var forward := -door_body.global_basis.z
	return atan2(forward.x, forward.z)


func _get_door_mesh() -> MeshInstance3D:
	if door_body == null:
		return null

	for child in door_body.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D

	return null


func _disable_imported_door_collision(root: Node) -> void:
	if root is CollisionObject3D:
		var collision_object := root as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0

	for child in root.get_children():
		_disable_imported_door_collision(child)


func _disable_imported_visuals(root: Node) -> void:
	if root is CanvasItem:
		(root as CanvasItem).visible = false

	if root is Node3D:
		(root as Node3D).visible = false

	if root is GeometryInstance3D:
		var geometry := root as GeometryInstance3D
		geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		geometry.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		geometry.layers = 0

	for child in root.get_children():
		_disable_imported_visuals(child)
