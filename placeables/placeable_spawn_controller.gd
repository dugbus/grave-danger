class_name GDPlaceableSpawnController
extends Node

## Delays one authored map item without requiring its native Godot node type to change.


enum SpawnState {
    Present,
    Waiting,
    Dropping,
}

const MAP_PLACEABLE_GROUP: StringName = &"map_placeable"
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const SPAWN_ROTATION_NAMESPACE: StringName = &"placeable_spawn_rotation"
const SPAWN_SPIN_NAMESPACE: StringName = &"placeable_spawn_spin"
const LANDING_TOLERANCE := 0.05

var state := SpawnState.Present
var elapsed_time := 0.0
var spawn_time := 0.0
var spawn_drop_height := 0.0
var spawn_spin_speed := 0.0
var placeable_owner: Node
var spawn_root: Node3D
var uses_rigid_body_drop := false
var initial_visible := true
var initial_position := Vector3.ZERO
var process_states: Dictionary = {}
var collision_states: Dictionary = {}
var area_states: Dictionary = {}
var rigid_body: RigidBody3D
var rigid_freeze := false
var rigid_gravity_scale := 1.0
var rigid_axis_lock_y := false
var restoring_vertical_constraints := false


func configure(
    owner_node: Node,
    root_node: Node3D,
    delay_seconds: float,
    drop_height: float,
    use_rigid_body_drop: bool,
    initial_spin_speed: float = 0.0
) -> void:
    placeable_owner = owner_node
    spawn_root = root_node
    spawn_time = maxf(delay_seconds, 0.0)
    spawn_drop_height = maxf(drop_height, 0.0)
    spawn_spin_speed = maxf(initial_spin_speed, 0.0)
    uses_rigid_body_drop = use_rigid_body_drop and spawn_root is RigidBody3D

    if spawn_root == null:
        return

    spawn_root.add_to_group(MAP_PLACEABLE_GROUP)
    if Engine.is_editor_hint() or spawn_time <= 0.0:
        return

    state = SpawnState.Waiting
    initial_visible = spawn_root.visible
    initial_position = spawn_root.global_position
    _capture_and_suspend(spawn_root)
    spawn_root.visible = false

    if uses_rigid_body_drop:
        rigid_body = spawn_root as RigidBody3D
        rigid_freeze = rigid_body.freeze
        rigid_gravity_scale = rigid_body.gravity_scale
        rigid_axis_lock_y = rigid_body.axis_lock_linear_y
        rigid_body.freeze = true


func is_spawned() -> bool:
    return state != SpawnState.Waiting


func is_waiting() -> bool:
    return state == SpawnState.Waiting


func _physics_process(delta: float) -> void:
    match state:
        SpawnState.Waiting:
            elapsed_time += maxf(delta, 0.0)
            if elapsed_time >= spawn_time:
                _begin_spawn()
        SpawnState.Dropping:
            _restore_constraints_after_landing()
        SpawnState.Present:
            pass


func _begin_spawn() -> void:
    if spawn_root == null:
        state = SpawnState.Present
        return

    if uses_rigid_body_drop and rigid_body != null:
        var spawn_transform := rigid_body.global_transform
        spawn_transform.origin = initial_position + Vector3.UP * spawn_drop_height
        spawn_transform.basis = Basis.from_euler(_get_random_spawn_rotation()) \
            * spawn_transform.basis
        rigid_body.global_transform = spawn_transform
        restoring_vertical_constraints = rigid_freeze \
            or rigid_axis_lock_y \
            or rigid_gravity_scale <= 0.0
        if restoring_vertical_constraints:
            rigid_body.axis_lock_linear_y = false
            rigid_body.gravity_scale = maxf(rigid_gravity_scale, 1.0)
        rigid_body.freeze = false
        rigid_body.sleeping = false
        if spawn_spin_speed > 0.0:
            rigid_body.angular_velocity = _get_random_spawn_spin_axis() * spawn_spin_speed

    spawn_root.visible = initial_visible
    _restore_suspended_state()
    state = SpawnState.Dropping if restoring_vertical_constraints else SpawnState.Present
    if placeable_owner != null and placeable_owner.has_signal(&"placeable_spawned"):
        placeable_owner.emit_signal(&"placeable_spawned")


func _capture_and_suspend(node: Node) -> void:
    if node != self:
        process_states[node] = [
            node.is_processing(),
            node.is_physics_processing(),
            node.is_processing_input(),
            node.is_processing_unhandled_input(),
            node.is_processing_unhandled_key_input(),
        ]
        node.set_process(false)
        node.set_physics_process(false)
        node.set_process_input(false)
        node.set_process_unhandled_input(false)
        node.set_process_unhandled_key_input(false)

    if node is CollisionObject3D:
        var collision_object := node as CollisionObject3D
        collision_states[collision_object] = Vector2i(
            collision_object.collision_layer,
            collision_object.collision_mask
        )
        collision_object.collision_layer = 0
        collision_object.collision_mask = 0

    if node is Area3D:
        var area := node as Area3D
        area_states[area] = Vector2i(int(area.monitoring), int(area.monitorable))
        area.set_deferred(&"monitoring", false)
        area.set_deferred(&"monitorable", false)

    for child in node.get_children():
        _capture_and_suspend(child)


func _restore_suspended_state() -> void:
    for node_value in process_states:
        var node := node_value as Node
        if not is_instance_valid(node):
            continue
        var saved := process_states[node] as Array
        node.set_process(saved[0] as bool)
        node.set_physics_process(saved[1] as bool)
        node.set_process_input(saved[2] as bool)
        node.set_process_unhandled_input(saved[3] as bool)
        node.set_process_unhandled_key_input(saved[4] as bool)

    for object_value in collision_states:
        var collision_object := object_value as CollisionObject3D
        if not is_instance_valid(collision_object):
            continue
        var saved := collision_states[collision_object] as Vector2i
        collision_object.collision_layer = saved.x
        collision_object.collision_mask = saved.y

    for area_value in area_states:
        var area := area_value as Area3D
        if not is_instance_valid(area):
            continue
        var saved := area_states[area] as Vector2i
        area.set_deferred(&"monitoring", bool(saved.x))
        area.set_deferred(&"monitorable", bool(saved.y))


func _restore_constraints_after_landing() -> void:
    if rigid_body == null or not is_instance_valid(rigid_body):
        state = SpawnState.Present
        return
    var reached_authored_height := \
        rigid_body.global_position.y <= initial_position.y + LANDING_TOLERANCE
    if rigid_freeze:
        if not rigid_body.sleeping:
            return
    elif not reached_authored_height and not rigid_body.sleeping:
        return

    if reached_authored_height and not rigid_freeze:
        var landed_position := rigid_body.global_position
        landed_position.y = initial_position.y
        rigid_body.global_position = landed_position
    rigid_body.linear_velocity.y = 0.0
    rigid_body.gravity_scale = rigid_gravity_scale
    rigid_body.axis_lock_linear_y = rigid_axis_lock_y
    rigid_body.freeze = rigid_freeze
    state = SpawnState.Present


func _get_random_spawn_rotation() -> Vector3:
    var random_number_generator := RandomNumberGenerator.new()
    random_number_generator.seed = DETERMINISTIC_SEED.from_node(
        rigid_body,
        0,
        SPAWN_ROTATION_NAMESPACE
    )
    return Vector3(
        random_number_generator.randf_range(-PI, PI),
        random_number_generator.randf_range(-PI, PI),
        random_number_generator.randf_range(-PI, PI)
    )


func _get_random_spawn_spin_axis() -> Vector3:
    var random_number_generator := RandomNumberGenerator.new()
    random_number_generator.seed = DETERMINISTIC_SEED.from_node(
        rigid_body,
        0,
        SPAWN_SPIN_NAMESPACE
    )
    var spin_axis := Vector3(
        random_number_generator.randf_range(-1.0, 1.0),
        random_number_generator.randf_range(-1.0, 1.0),
        random_number_generator.randf_range(-1.0, 1.0)
    ).normalized()
    return Vector3.RIGHT if spin_axis.is_zero_approx() else spin_axis
