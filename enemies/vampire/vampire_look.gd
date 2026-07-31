extends Node
class_name GDVampireLook


enum LookPhase {
    Travel,
    Glancing,
    Returning,
}

const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const LOOK_SETTINGS := preload("res://game/character_look_settings.tres")

## Visual pivot that continues to face the Vampire's direction of travel.
@export var travel_pivot_path: NodePath = ^"../Pivot"
## Child pivot whose positive Z axis drives gameplay sight and the headlamp.
@export var look_direction_path: NodePath = ^"../Pivot/LookDirection"
## Imported character containing the separately turnable head mesh.
@export var character_path: NodePath = ^"../Pivot/Character"
## Existing spotlight that follows the Vampire's procedural head turn.
@export var headlamp_path: NodePath = ^"../Pivot/VampireHeadlampLight"

@onready var travel_pivot := get_node_or_null(travel_pivot_path) as Node3D
@onready var look_direction := get_node_or_null(look_direction_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var headlamp := get_node_or_null(headlamp_path) as SpotLight3D

var phase := LookPhase.Travel
var current_head_yaw := 0.0
var target_head_yaw := 0.0
var phase_elapsed := 0.0
var next_glance_seconds := 0.0
var next_glance_side := 1.0
var wandering_glance_side := 1.0
var wandering_glance_fraction := 1.0
var has_directed_look := false
var directed_world_direction := Vector3.ZERO
var head: Node3D
var torso: Node3D
var head_rest_yaw := 0.0
var torso_rest_yaw := 0.0
var headlamp_head_offset := Transform3D.IDENTITY
var headlamp_rest_transform := Transform3D.IDENTITY
var glance_rng := RandomNumberGenerator.new()


func _ready() -> void:
    process_priority = 100
    glance_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"vampire_look")
    head = _find_named_node(character, &"head")
    if head != null:
        head_rest_yaw = head.rotation.y
        torso = head.get_parent() as Node3D
    if torso != null:
        torso_rest_yaw = torso.rotation.y
    if headlamp != null:
        headlamp_rest_transform = headlamp.global_transform
        if head != null:
            headlamp_head_offset = head.global_transform.affine_inverse() \
                * headlamp.global_transform
    _schedule_next_glance(0.0)


func _process(_delta: float) -> void:
    var upper_body_yaw := current_head_yaw \
        * float(LOOK_SETTINGS.upper_body_turn_fraction)
    if torso != null:
        torso.rotation.y = torso_rest_yaw + upper_body_yaw
    if head != null:
        # The imported animation owns pitch and roll; this late process pass owns yaw.
        head.rotation.y = head_rest_yaw + current_head_yaw - upper_body_yaw
    if headlamp != null:
        if head != null:
            # Preserve the authored lamp offset while following the complete animated head.
            headlamp.global_transform = head.global_transform * headlamp_head_offset
        else:
            var fallback_rotation := Quaternion(Vector3.UP, current_head_yaw) \
                * headlamp_rest_transform.basis.get_rotation_quaternion()
            headlamp.global_transform = Transform3D(
                Basis(fallback_rotation),
                headlamp_rest_transform.origin
            )


func configure() -> void:
    return_to_travel_direction()


## Temporarily aims sight toward a chosen world direction without changing travel.
func look_in_world_direction(world_direction: Vector3) -> void:
    var horizontal_direction := world_direction
    horizontal_direction.y = 0.0
    if horizontal_direction.is_zero_approx():
        return_to_travel_direction()
        return
    has_directed_look = true
    directed_world_direction = horizontal_direction.normalized()


## Releases explicit look control so the head returns to travel and resumes glancing.
func return_to_travel_direction() -> void:
    has_directed_look = false
    directed_world_direction = Vector3.ZERO
    phase = LookPhase.Returning
    phase_elapsed = 0.0
    target_head_yaw = 0.0


## Updates gameplay look direction after navigation has established travel facing.
func update_look(
    delta: float,
    observed_position: Vector3 = Vector3.ZERO,
    has_observed_position: bool = false,
    allow_wandering_glances: bool = true,
    movement_focus_ratio: float = 0.0
) -> void:
    if look_direction == null or travel_pivot == null:
        return

    if has_directed_look:
        target_head_yaw = _clamped_yaw_to_direction(directed_world_direction)
        phase = LookPhase.Glancing
    elif has_observed_position:
        var observed_direction := observed_position - travel_pivot.global_position
        target_head_yaw = _clamped_yaw_to_direction(observed_direction)
        phase = LookPhase.Glancing
    elif not allow_wandering_glances:
        target_head_yaw = 0.0
        phase = LookPhase.Returning
    else:
        var wandering_strength := float(LOOK_SETTINGS.get_wandering_strength(
            movement_focus_ratio
        ))
        if phase == LookPhase.Travel \
                and wandering_strength \
                    >= float(LOOK_SETTINGS.continuous_idle_strength_threshold):
            next_glance_seconds = 0.0
        _update_wandering_glance(delta, movement_focus_ratio)

    current_head_yaw = move_toward(
        current_head_yaw,
        target_head_yaw,
        float(LOOK_SETTINGS.head_turn_speed) * maxf(delta, 0.0)
    )
    look_direction.rotation.y = current_head_yaw


## Returns the live world-space direction used by Vampire sight and minimap diagnostics.
func get_look_direction() -> Vector3:
    return look_direction.global_basis.z.normalized() \
        if look_direction != null else Vector3.FORWARD


## Returns the signed head turn for tests and debug displays.
func get_current_head_yaw() -> float:
    return current_head_yaw


## Returns the shared safe walking limit applied to every procedural head turn.
func get_maximum_head_turn_radians() -> float:
    return _maximum_head_turn_radians()


func _update_wandering_glance(delta: float, movement_focus_ratio: float) -> void:
    phase_elapsed += maxf(delta, 0.0)
    match phase:
        LookPhase.Travel:
            target_head_yaw = 0.0
            if phase_elapsed >= next_glance_seconds:
                phase = LookPhase.Glancing
                phase_elapsed = 0.0
                _choose_wandering_glance(movement_focus_ratio)
        LookPhase.Glancing:
            target_head_yaw = _get_wandering_target_yaw(movement_focus_ratio)
            if phase_elapsed >= float(LOOK_SETTINGS.get_wandering_hold_seconds(
                movement_focus_ratio
            )):
                phase_elapsed = 0.0
                if _uses_continuous_idle_scan(movement_focus_ratio):
                    _choose_wandering_glance(movement_focus_ratio)
                else:
                    phase = LookPhase.Returning
                    target_head_yaw = 0.0
        LookPhase.Returning:
            target_head_yaw = 0.0
            if is_zero_approx(current_head_yaw):
                phase_elapsed = 0.0
                if _uses_continuous_idle_scan(movement_focus_ratio):
                    phase = LookPhase.Glancing
                    _choose_wandering_glance(movement_focus_ratio)
                else:
                    phase = LookPhase.Travel
                    _schedule_next_glance(movement_focus_ratio)


func _schedule_next_glance(movement_focus_ratio: float) -> void:
    next_glance_seconds = glance_rng.randf_range(
        float(LOOK_SETTINGS.get_wandering_interval_min_seconds(movement_focus_ratio)),
        float(LOOK_SETTINGS.get_wandering_interval_max_seconds(movement_focus_ratio))
    )


func _get_wandering_target_yaw(movement_focus_ratio: float) -> float:
    return float(LOOK_SETTINGS.get_wandering_head_turn_radians(
        movement_focus_ratio
    )) * wandering_glance_fraction * wandering_glance_side


func _choose_wandering_glance(movement_focus_ratio: float) -> void:
    wandering_glance_fraction = glance_rng.randf_range(0.45, 1.0)
    wandering_glance_side = next_glance_side
    next_glance_side *= -1.0
    target_head_yaw = _get_wandering_target_yaw(movement_focus_ratio)


func _uses_continuous_idle_scan(movement_focus_ratio: float) -> bool:
    return float(LOOK_SETTINGS.get_wandering_strength(movement_focus_ratio)) \
        >= float(LOOK_SETTINGS.continuous_idle_strength_threshold)


func _clamped_yaw_to_direction(world_direction: Vector3) -> float:
    var horizontal_direction := world_direction
    horizontal_direction.y = 0.0
    if horizontal_direction.is_zero_approx() or travel_pivot == null:
        return 0.0
    var local_direction := travel_pivot.global_basis.inverse() \
        * horizontal_direction.normalized()
    return clampf(
        atan2(local_direction.x, local_direction.z),
        -_maximum_head_turn_radians(),
        _maximum_head_turn_radians()
    )


func _maximum_head_turn_radians() -> float:
    return deg_to_rad(float(LOOK_SETTINGS.maximum_head_turn_degrees))


func _find_named_node(root: Node, node_name: StringName) -> Node3D:
    if root == null:
        return null
    if StringName(root.name.to_lower()) == node_name and root is Node3D:
        return root as Node3D
    for child in root.get_children():
        var result := _find_named_node(child, node_name)
        if result != null:
            return result
    return null
