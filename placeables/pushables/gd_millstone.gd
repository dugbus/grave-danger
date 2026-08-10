class_name Millstone
extends RollingRock


@export_group("Millstone Rolling")
## Local horizontal direction in which this millstone can roll when placed in a level.
@export var local_roll_direction := Vector3.RIGHT
## Collision from the source model that is disabled in favour of the rigid-body cylinder.
@export var source_collision_path: NodePath = ^"Millstone/MeshInstance3D/StaticBody3D/CollisionShape3D"
## Minimum alignment with either rolling side required for a character push to move the millstone.
@export_range(0.0, 1.0, 0.01) var rolling_side_alignment := 0.7
## Maximum sideways player speed removed each second while actively pushing a rolling side.
@export_range(0.0, 20.0, 0.1, "suffix:m/s²") var push_alignment_assist_acceleration := 8.0
## Minimum rolling speed required for this millstone to kill an enemy on contact.
@export_range(0.0, 5.0, 0.01) var enemy_crush_speed := 0.15
## Minimum upward contact normal treated as supporting ground for rolling audio.
@export_range(0.0, 1.0, 0.01) var rolling_audio_ground_normal_y := 0.65
@export_group("")

var has_rolling_audio_ground_contact := false


func _ready() -> void:
	var source_collision := get_node_or_null(source_collision_path) as CollisionShape3D
	if source_collision != null:
		source_collision.disabled = true

	super._ready()


func push(impulse: Vector3) -> void:
	var constrained_impulse := _project_onto_roll_direction(impulse)
	if constrained_impulse.is_zero_approx():
		return

	super.push(constrained_impulse)


func push_from_character(
	character_velocity: Vector3,
	collision_normal: Vector3,
	delta: float
) -> void:
	var world_roll_direction := _get_world_roll_direction()
	var contact_direction := _get_character_contact_direction(collision_normal)
	if not _is_contact_on_rolling_side(contact_direction, world_roll_direction):
		return

	var constrained_velocity := _project_onto_roll_direction(character_velocity)
	if constrained_velocity.is_zero_approx():
		return

	super.push_from_character(constrained_velocity, collision_normal, delta)


func get_character_push_assist_velocity(
	requested_velocity: Vector3,
	resulting_velocity: Vector3,
	collision_normal: Vector3,
	delta: float
) -> Vector3:
	var world_roll_direction := _get_world_roll_direction()
	var contact_direction := _get_character_contact_direction(collision_normal)
	if not _is_contact_on_rolling_side(contact_direction, world_roll_direction):
		return resulting_velocity

	var requested_horizontal := Vector3(requested_velocity.x, 0.0, requested_velocity.z)
	if requested_horizontal.dot(contact_direction) <= 0.05:
		return resulting_velocity

	var resulting_horizontal := Vector3(resulting_velocity.x, 0.0, resulting_velocity.z)
	var along_roll_velocity := (
		world_roll_direction * resulting_horizontal.dot(world_roll_direction)
	)
	var sideways_velocity := resulting_horizontal - along_roll_velocity
	sideways_velocity = sideways_velocity.move_toward(
		Vector3.ZERO,
		push_alignment_assist_acceleration * maxf(delta, 0.0)
	)

	var assisted_velocity := along_roll_velocity + sideways_velocity
	assisted_velocity.y = resulting_velocity.y
	return assisted_velocity


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)
	has_rolling_audio_ground_contact = _has_supporting_ground_contact(state)

	var constrained_velocity := _project_onto_roll_direction(state.linear_velocity)
	constrained_velocity.y = state.linear_velocity.y
	state.linear_velocity = constrained_velocity


func _physics_process(delta: float) -> void:
	var movement := global_position - previous_position
	movement.y = 0.0

	var signed_distance := movement.dot(_get_world_roll_direction())
	var speed := absf(signed_distance) / maxf(delta, 0.0001)
	_update_rolling_audio(_get_audible_rolling_speed(speed), delta)

	if visual_roll_enabled and visual_rock != null and absf(signed_distance) > 0.001:
		var safe_roll_radius := maxf(visual_roll_radius, 0.001)
		var local_direction := _get_local_roll_direction()
		var local_roll_axis := Vector3.UP.cross(local_direction).normalized()
		visual_rock.rotate(local_roll_axis, signed_distance / safe_roll_radius)

	previous_position = global_position


func can_kill_enemy_by_rolling() -> bool:
	var rolling_velocity := _project_onto_roll_direction(linear_velocity)
	return rolling_velocity.length() >= enemy_crush_speed


func _get_audible_rolling_speed(speed: float) -> float:
	return speed if has_rolling_audio_ground_contact else 0.0


func _has_supporting_ground_contact(state: PhysicsDirectBodyState3D) -> bool:
	for contact_index in range(state.get_contact_count()):
		var contact_normal := state.transform.basis * state.get_contact_local_normal(contact_index)
		if contact_normal.normalized().y >= rolling_audio_ground_normal_y:
			return true

	return false


func _project_onto_roll_direction(vector: Vector3) -> Vector3:
	var horizontal_vector := Vector3(vector.x, 0.0, vector.z)
	var world_roll_direction := _get_world_roll_direction()
	return world_roll_direction * horizontal_vector.dot(world_roll_direction)


func _get_world_roll_direction() -> Vector3:
	var roll_basis := global_basis if is_inside_tree() else basis
	var world_direction := roll_basis * _get_local_roll_direction()
	world_direction.y = 0.0
	if world_direction.length_squared() <= 0.0001:
		return Vector3.RIGHT

	return world_direction.normalized()


func _get_local_roll_direction() -> Vector3:
	var horizontal_direction := Vector3(local_roll_direction.x, 0.0, local_roll_direction.z)
	if horizontal_direction.length_squared() <= 0.0001:
		return Vector3.RIGHT

	return horizontal_direction.normalized()


func _get_character_contact_direction(collision_normal: Vector3) -> Vector3:
	var contact_direction := Vector3(-collision_normal.x, 0.0, -collision_normal.z)
	if contact_direction.length_squared() <= 0.0001:
		return Vector3.ZERO

	return contact_direction.normalized()


func _is_contact_on_rolling_side(
	contact_direction: Vector3,
	world_roll_direction: Vector3
) -> bool:
	return not contact_direction.is_zero_approx() \
		and absf(contact_direction.dot(world_roll_direction)) >= rolling_side_alignment
