extends Node3D
class_name GDPlayerAttention


enum AttentionPhase {
	Travel,
	EnemyTracking,
	CollectibleGlance,
	WanderingGlance,
	Returning,
}

const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const LOOK_SETTINGS := preload("res://game/character_look_settings.tres")
const COLLECTIBLE_LOOK_DISTANCE := 3.25
const ENEMY_GROUP: StringName = &"enemy"
const ENEMY_SIGHT_TARGET_HEIGHT := 0.75
const COLLECTIBLE_GROUPS: Array[StringName] = [
	&"inventory_pickup",
	&"flask_pickup",
]

## Visual pivot that faces the player's current travel direction.
@export var travel_pivot_path: NodePath = ^"../Pivot"
## Child pivot followed by the headlamp while the player glances.
@export var look_direction_path: NodePath = ^"../Pivot/LookDirection"
## Imported character containing the separately turnable head mesh.
@export var character_path: NodePath = ^"../Pivot/Character"
## Existing spotlight that follows the player's procedural head turn.
@export var headlamp_path: NodePath = ^"../Pivot/PlayerHeadlampLight"
## Authored ray used to reject attention targets hidden by level geometry.
@export var sight_ray_path: NodePath = ^"CollectibleSightRay"

@onready var player := get_parent() as CharacterBody3D
@onready var travel_pivot := get_node_or_null(travel_pivot_path) as Node3D
@onready var look_direction := get_node_or_null(look_direction_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var headlamp := get_node_or_null(headlamp_path) as SpotLight3D
@onready var sight_ray := get_node_or_null(sight_ray_path) as RayCast3D

var phase := AttentionPhase.Travel
var current_head_yaw := 0.0
var target_head_yaw := 0.0
var glance_elapsed := 0.0
var next_glance_seconds := 0.0
var next_glance_side := 1.0
var wandering_glance_side := 1.0
var wandering_glance_fraction := 1.0
var movement_focus_ratio := 0.0
var target_enemy: Node3D
var target_collectible: Node3D
var acknowledged_collectible_ids: Array[int] = []
var head: Node3D
var torso: Node3D
var head_rest_yaw := 0.0
var torso_rest_yaw := 0.0
var headlamp_head_offset := Transform3D.IDENTITY
var headlamp_rest_transform := Transform3D.IDENTITY
var glance_rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_priority = 100
	glance_rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"player_attention")
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
	if sight_ray != null and player != null:
		sight_ray.add_exception(player)
	_schedule_next_glance()


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


## Tracks close visible enemies before considering collectibles or ambient glances.
func update_attention(delta: float, current_movement_focus_ratio: float = 0.0) -> void:
	if player == null or travel_pivot == null or look_direction == null:
		return
	movement_focus_ratio = clampf(current_movement_focus_ratio, 0.0, 1.0)
	var nearby_enemy := _find_nearby_enemy()
	if nearby_enemy != null:
		target_enemy = nearby_enemy
		target_collectible = null
		phase = AttentionPhase.EnemyTracking
	elif phase == AttentionPhase.EnemyTracking:
		target_enemy = null
		phase = AttentionPhase.Returning
	else:
		target_enemy = null
	if phase == AttentionPhase.Travel and _uses_continuous_idle_scan():
		next_glance_seconds = 0.0

	match phase:
		AttentionPhase.EnemyTracking:
			target_collectible = null
		AttentionPhase.Travel:
			target_collectible = _find_nearby_collectible()
			if target_collectible != null:
				phase = AttentionPhase.CollectibleGlance
				glance_elapsed = 0.0
				acknowledged_collectible_ids.append(target_collectible.get_instance_id())
			else:
				glance_elapsed += maxf(delta, 0.0)
				if glance_elapsed >= next_glance_seconds:
					phase = AttentionPhase.WanderingGlance
					glance_elapsed = 0.0
					_choose_wandering_glance()
		AttentionPhase.CollectibleGlance:
			glance_elapsed += maxf(delta, 0.0)
			if not is_instance_valid(target_collectible) \
					or not _is_collectible_available(target_collectible) \
					or glance_elapsed >= float(LOOK_SETTINGS.get_wandering_hold_seconds(
						movement_focus_ratio
					)):
				phase = AttentionPhase.Returning
				target_collectible = null
		AttentionPhase.WanderingGlance:
			target_collectible = null
			glance_elapsed += maxf(delta, 0.0)
			if glance_elapsed >= float(LOOK_SETTINGS.get_wandering_hold_seconds(
				movement_focus_ratio
			)):
				glance_elapsed = 0.0
				if _uses_continuous_idle_scan():
					_choose_wandering_glance()
				else:
					phase = AttentionPhase.Returning
		AttentionPhase.Returning:
			target_collectible = null
			if is_zero_approx(current_head_yaw):
				glance_elapsed = 0.0
				if _uses_continuous_idle_scan():
					phase = AttentionPhase.WanderingGlance
					_choose_wandering_glance()
				else:
					phase = AttentionPhase.Travel
					_schedule_next_glance()

	target_head_yaw = _yaw_to_enemy(target_enemy) \
		if phase == AttentionPhase.EnemyTracking else 0.0
	if phase == AttentionPhase.CollectibleGlance:
		target_head_yaw = _yaw_to_collectible(target_collectible)
	if phase == AttentionPhase.WanderingGlance:
		target_head_yaw = _get_wandering_target_yaw()
	current_head_yaw = move_toward(
		current_head_yaw,
		target_head_yaw,
		float(LOOK_SETTINGS.head_turn_speed) * maxf(delta, 0.0)
	)
	look_direction.rotation.y = current_head_yaw


## Returns the close enemy currently holding priority over other attention.
func get_target_enemy() -> Node3D:
	return target_enemy


## Returns the current attention target for tests and future presentation hooks.
func get_target_collectible() -> Node3D:
	return target_collectible


## Returns the signed head turn for tests and debug tooling.
func get_current_head_yaw() -> float:
	return current_head_yaw


## Returns the shared safe walking limit applied to every procedural head turn.
func get_maximum_head_turn_radians() -> float:
	return _maximum_head_turn_radians()


func _find_nearby_enemy() -> Node3D:
	var closest_enemy: Node3D = null
	var closest_distance_squared := INF
	for candidate_node in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not candidate_node is Node3D:
			continue
		var candidate := candidate_node as Node3D
		if not _is_enemy_available(candidate):
			continue
		var target_position := _get_enemy_attention_position(candidate)
		var horizontal_offset := target_position - player.global_position
		horizontal_offset.y = 0.0
		var distance_squared := horizontal_offset.length_squared()
		if distance_squared > pow(float(LOOK_SETTINGS.enemy_attention_distance), 2.0):
			continue
		if absf(_raw_yaw_to_position(target_position)) \
				> _enemy_attention_half_arc_radians():
			continue
		var sight_target := target_position + Vector3.UP * ENEMY_SIGHT_TARGET_HEIGHT
		if not _has_line_of_sight(candidate, sight_target):
			continue
		if distance_squared < closest_distance_squared or (
				is_equal_approx(distance_squared, closest_distance_squared) \
				and (closest_enemy == null \
				or str(candidate.get_path()) < str(closest_enemy.get_path()))
		):
			closest_enemy = candidate
			closest_distance_squared = distance_squared
	return closest_enemy


func _is_enemy_available(candidate: Node3D) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if candidate.has_method("is_available_for_player_attention"):
		return bool(candidate.call("is_available_for_player_attention"))
	return candidate.is_visible_in_tree()


func _get_enemy_attention_position(candidate: Node3D) -> Vector3:
	if candidate != null and candidate.has_method("get_player_attention_position"):
		var attention_position: Vector3 = candidate.call("get_player_attention_position")
		return attention_position
	return candidate.global_position if candidate != null else player.global_position


func _find_nearby_collectible() -> Node3D:
	var candidates: Array[Node3D] = []
	var active_ids: Array[int] = []
	for group_name in COLLECTIBLE_GROUPS:
		for candidate_node in get_tree().get_nodes_in_group(group_name):
			if not candidate_node is Node3D:
				continue
			var candidate := candidate_node as Node3D
			active_ids.append(candidate.get_instance_id())
			if _is_collectible_available(candidate):
				candidates.append(candidate)
	_prune_acknowledged_ids(active_ids)
	candidates.sort_custom(_sort_collectibles)
	for candidate in candidates:
		if acknowledged_collectible_ids.has(candidate.get_instance_id()):
			continue
		if _is_in_safe_head_arc(candidate) and _has_line_of_sight(
			candidate,
			candidate.global_position + Vector3.UP * 0.25
		):
			return candidate
	return null


func _is_collectible_available(candidate: Node3D) -> bool:
	if not is_instance_valid(candidate) or not candidate.is_inside_tree():
		return false
	if not candidate.visible:
		return false
	if bool(candidate.get("is_being_collected")):
		return false
	var horizontal_offset := candidate.global_position - player.global_position
	horizontal_offset.y = 0.0
	return horizontal_offset.length() <= COLLECTIBLE_LOOK_DISTANCE


func _is_in_safe_head_arc(candidate: Node3D) -> bool:
	return absf(_raw_yaw_to_collectible(candidate)) \
		<= _movement_scaled_head_turn_radians()


func _has_line_of_sight(candidate: Node3D, target_position: Vector3) -> bool:
	if sight_ray == null:
		return false
	sight_ray.target_position = sight_ray.to_local(target_position)
	sight_ray.force_raycast_update()
	if not sight_ray.is_colliding():
		return true
	var collider := sight_ray.get_collider() as Node
	return _nodes_share_branch(collider, candidate)


func _yaw_to_collectible(candidate: Node3D) -> float:
	return clampf(
		_raw_yaw_to_collectible(candidate),
		-_movement_scaled_head_turn_radians(),
		_movement_scaled_head_turn_radians()
	)


func _raw_yaw_to_collectible(candidate: Node3D) -> float:
	if candidate == null or travel_pivot == null:
		return 0.0
	return _raw_yaw_to_position(candidate.global_position)


func _yaw_to_enemy(candidate: Node3D) -> float:
	if candidate == null:
		return 0.0
	return clampf(
		_raw_yaw_to_position(_get_enemy_attention_position(candidate)),
		-_maximum_head_turn_radians(),
		_maximum_head_turn_radians()
	)


func _raw_yaw_to_position(world_position: Vector3) -> float:
	if travel_pivot == null:
		return 0.0
	var world_direction := world_position - travel_pivot.global_position
	world_direction.y = 0.0
	if world_direction.is_zero_approx():
		return 0.0
	var local_direction := travel_pivot.global_basis.inverse() \
		* world_direction.normalized()
	return atan2(local_direction.x, local_direction.z)


func _maximum_head_turn_radians() -> float:
	return deg_to_rad(float(LOOK_SETTINGS.maximum_head_turn_degrees))


func _enemy_attention_half_arc_radians() -> float:
	return deg_to_rad(float(LOOK_SETTINGS.enemy_attention_half_arc_degrees))


func _movement_scaled_head_turn_radians() -> float:
	return float(LOOK_SETTINGS.get_wandering_head_turn_radians(
		movement_focus_ratio
	))


func _get_wandering_target_yaw() -> float:
	return _movement_scaled_head_turn_radians() \
		* wandering_glance_fraction \
		* wandering_glance_side


func _choose_wandering_glance() -> void:
	wandering_glance_fraction = glance_rng.randf_range(0.45, 1.0)
	wandering_glance_side = next_glance_side
	next_glance_side *= -1.0
	target_head_yaw = _get_wandering_target_yaw()


func _uses_continuous_idle_scan() -> bool:
	return float(LOOK_SETTINGS.get_wandering_strength(movement_focus_ratio)) \
		>= float(LOOK_SETTINGS.continuous_idle_strength_threshold)


func _schedule_next_glance() -> void:
	next_glance_seconds = glance_rng.randf_range(
		float(LOOK_SETTINGS.get_wandering_interval_min_seconds(
			movement_focus_ratio
		)),
		float(LOOK_SETTINGS.get_wandering_interval_max_seconds(
			movement_focus_ratio
		))
	)


func _sort_collectibles(a: Node3D, b: Node3D) -> bool:
	var a_distance := player.global_position.distance_squared_to(a.global_position)
	var b_distance := player.global_position.distance_squared_to(b.global_position)
	if not is_equal_approx(a_distance, b_distance):
		return a_distance < b_distance
	return str(a.get_path()) < str(b.get_path())


func _prune_acknowledged_ids(active_ids: Array[int]) -> void:
	for instance_id in acknowledged_collectible_ids.duplicate():
		if not active_ids.has(instance_id):
			acknowledged_collectible_ids.erase(instance_id)


func _nodes_share_branch(first: Node, second: Node) -> bool:
	if first == null or second == null:
		return false
	return first == second or first.is_ancestor_of(second) or second.is_ancestor_of(first)


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
