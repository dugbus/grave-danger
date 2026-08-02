extends "res://placeables/character_placeable.gd"
class_name GDVampire


signal target_selected(noise_position: Vector3)

enum VampireState {
	Idle,
	Hunting,
	ChasingPlayer,
	SearchingRoute,
	PursuingLastSeen,
	ScanningJunction,
	Disabled,
}

const CHARACTER_GROUP: StringName = &"character"
const ENEMY_GROUP: StringName = &"enemy"
const GAMEPLAY_PROCESS_GROUP: StringName = &"deterministic_gameplay_process"
const VAMPIRE_PROCESS_PRIORITY := 50

## Shared tuning resource for the vampire's scale, speed, and maze route following.
@export var settings: Resource
## Visual pivot turned toward the active maze route.
@export var pivot_path: NodePath = ^"Pivot"
## Imported vampire character used for animation lookup and model scaling.
@export var character_path: NodePath = ^"Pivot/Character"
## Component that builds and follows routes to last-heard noise positions.
@export var navigation_path: NodePath = ^"VampireNavigation"
## Component that independently aims the Vampire's head, sight, and headlamp.
@export var look_path: NodePath = ^"VampireLook"
## Component that selects idle and run animations from the imported character.
@export var presentation_path: NodePath = ^"VampirePresentation"
## Wall-occluded instant-kill area surrounding the doubled Vampire model.
@export var contact_path: NodePath = ^"VampireContact"
## Body-width floor-level sight cast used to acquire only physically reachable players.
@export var senses_path: NodePath = ^"VampireSenses"
## Hunt component that switches between confirmed sight, noise, prediction, and strategic search.
@export var hunt_path: NodePath = ^"VampireHunt"
## Strategic memory of known treasure, key, coffin, door, and gate locations.
@export var layout_knowledge_path: NodePath = ^"VampireLayoutKnowledge"
## Full-screen purple fog controller driven by the player's distance from this vampire.
@export var proximity_fog_path: NodePath = ^"VampireProximityFog"

@export_group("Development")
## Disables this vampire's AI, movement, collisions, lights, fog, and instant-kill contact for testing.
@export var disable_vampire_for_testing := false:
	set(value):
		disable_vampire_for_testing = value
		if is_node_ready():
			_apply_testing_disabled_state()

@onready var pivot := get_node_or_null(pivot_path) as Node3D
@onready var character := get_node_or_null(character_path) as Node3D
@onready var navigation: Node = get_node_or_null(navigation_path)
@onready var look: Node = get_node_or_null(look_path)
@onready var presentation: Node = get_node_or_null(presentation_path)
@onready var contact := get_node_or_null(contact_path) as GDVampireContact
@onready var senses: Node = get_node_or_null(senses_path)
@onready var hunt: Node = get_node_or_null(hunt_path)
@onready var layout_knowledge: Node = get_node_or_null(layout_knowledge_path)
@onready var proximity_fog: Node = get_node_or_null(proximity_fog_path)

var state := VampireState.Idle
var _enabled_state_cached := false
var _visible_when_enabled := true
var _process_mode_when_enabled := Node.PROCESS_MODE_INHERIT
var _collision_layer_when_enabled := 0
var _collision_mask_when_enabled := 0
var _contact_monitoring_when_enabled := true
var _contact_collision_mask_when_enabled := 0
var _senses_enabled_when_enabled := true
var _passthrough_obstacle_bodies: Array[PhysicsBody3D] = []
var _passthrough_obstacle_shapes: Array[CollisionShape3D] = []
var _pivot_rest_position := Vector3.ZERO
var _configuration_error_reported := false
var _corridor_look_active := false
var _corridor_look_latched := false
var _corridor_look_elapsed := 0.0
var _next_corridor_look_side := 1.0


func _ready() -> void:
	add_to_group(CHARACTER_GROUP)
	add_to_group(ENEMY_GROUP)
	add_to_group(GAMEPLAY_PROCESS_GROUP)
	process_physics_priority = VAMPIRE_PROCESS_PRIORITY
	if pivot != null:
		_pivot_rest_position = pivot.position
	if character != null and settings != null:
		character.scale = Vector3.ONE * settings.model_scale
	if navigation != null:
		navigation.configure(self, pivot, settings)
	if look != null:
		look.configure()
	if presentation != null:
		presentation.configure(character)
	if contact != null:
		contact.configure(settings)
	_cache_enabled_state()
	_apply_testing_disabled_state()
	super._ready()


## Returns the point the player's close-threat awareness should follow.
func get_player_attention_position() -> Vector3:
	return global_position


## Reports whether this vampire should currently hold the player's attention.
func is_available_for_player_attention() -> bool:
	return not disable_vampire_for_testing and is_visible_in_tree()


func _physics_process(delta: float) -> void:
	if disable_vampire_for_testing:
		velocity = Vector3.ZERO
		return
	if hunt != null:
		hunt.update_hunt(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	var horizontal_speed := 0.0
	if navigation != null:
		horizontal_speed = navigation.update_velocity(delta)
		if state == VampireState.Hunting and not navigation.has_target and hunt == null:
			state = VampireState.Idle
	_update_look(delta)
	move_and_slide()
	_update_passthrough_obstacle_stride(delta)
	if contact != null:
		for collision_index in get_slide_collision_count():
			var collider := get_slide_collision(collision_index).get_collider() as Node3D
			contact.kill_touching_body(collider)
		contact.check_contacts()
	if navigation != null:
		navigation.update_after_movement(delta)
	if presentation != null:
		presentation.update_animation(horizontal_speed)


func configure_navigation(wall_grid_map: GridMap) -> void:
	if navigation != null:
		navigation.set_wall_grid_map(wall_grid_map)
	if senses != null:
		senses.set_wall_grid_map(wall_grid_map)


## Lets this boss pass through every physics body owned by a placed route obstacle.
func add_passthrough_obstacle(obstacle_root: Node) -> void:
	if obstacle_root == null:
		return
	var obstacle_bodies: Array[PhysicsBody3D] = []
	_collect_physics_bodies(obstacle_root, obstacle_bodies)
	for obstacle_body in obstacle_bodies:
		add_collision_exception_with(obstacle_body)
		obstacle_body.add_collision_exception_with(self)
		if not _passthrough_obstacle_bodies.has(obstacle_body):
			_passthrough_obstacle_bodies.append(obstacle_body)
		_collect_body_collision_shapes(
			obstacle_body,
			obstacle_body,
			_passthrough_obstacle_shapes
		)


func configure_hunt(
		target_player: Node3D,
		end_gate: Node3D,
		entrance_position: Vector3
) -> bool:
	var wall_grid_map: GridMap = navigation.wall_grid_map \
		if navigation != null else null
	if not validate_configuration(target_player, end_gate, wall_grid_map):
		return false
	velocity = Vector3.ZERO
	state = VampireState.Idle
	if hunt != null:
		hunt.configure(
			self,
			navigation,
			senses,
			layout_knowledge,
			target_player,
			end_gate,
			settings
		)
	if proximity_fog != null:
		proximity_fog.configure(self, target_player, settings)
	_hear_noise(entrance_position, false, GDVampireHunt.AwarenessSource.Entrance)
	if disable_vampire_for_testing:
		_apply_testing_disabled_state()
	return true


## Lists every dependency required for a fully functional, non-omniscient Vampire.
func get_configuration_errors(
		target_player: Node3D,
		end_gate: Node3D,
		wall_grid_map: GridMap
) -> PackedStringArray:
	var missing := PackedStringArray()
	if target_player == null:
		missing.append("player")
	if wall_grid_map == null:
		missing.append("wall GridMap")
	if contact == null:
		missing.append("contact area")
	if end_gate == null:
		missing.append("end gate")
	if settings == null:
		missing.append("settings resource")
	if navigation == null:
		missing.append("navigation component")
	if senses == null:
		missing.append("senses component")
	if hunt == null:
		missing.append("hunt component")
	return missing


## Reports the complete dependency failure as one diagnostic and suppresses duplicates.
func validate_configuration(
		target_player: Node3D,
		end_gate: Node3D,
		wall_grid_map: GridMap
) -> bool:
	var errors := get_configuration_errors(target_player, end_gate, wall_grid_map)
	if errors.is_empty():
		_configuration_error_reported = false
		return true
	if not _configuration_error_reported:
		push_error(
			"Vampire configuration invalid; missing: %s" % ", ".join(errors)
		)
		_configuration_error_reported = true
	return false


## Gives the boss complete authored knowledge of strategic landmarks in this level.
func configure_layout_knowledge(layout_landmarks: Array[Dictionary]) -> void:
	if layout_knowledge != null:
		layout_knowledge.configure(layout_landmarks)


func hear_noise(noise_position: Vector3) -> void:
	_hear_noise(noise_position, false, GDVampireHunt.AwarenessSource.Noise)


## Hunts a pickup or deposit sound and updates knowledge of the disturbed landmark.
func hear_landmark_noise(noise_position: Vector3) -> void:
	_hear_noise(noise_position, true, GDVampireHunt.AwarenessSource.Noise)


func _hear_noise(
		noise_position: Vector3,
		records_landmark_evidence: bool,
		awareness_source: GDVampireHunt.AwarenessSource
) -> void:
	if disable_vampire_for_testing or navigation == null:
		return
	if state != VampireState.Idle \
			and bool(navigation.get("has_target")) \
			and navigation.is_target_near(
		noise_position,
		settings.noise_retarget_distance
	):
		if hunt != null:
			hunt.refresh_noise_origin(noise_position, records_landmark_evidence)
		return
	if hunt != null:
		var accepted_noise := bool(hunt.notify_noise(
			noise_position,
			records_landmark_evidence,
			awareness_source
		))
		if not accepted_noise:
			return
	if navigation.select_target(noise_position):
		state = VampireState.Hunting
		target_selected.emit(noise_position)
	elif hunt != null:
		hunt.recover_from_route_failure()


## Routes toward an intercept and only permits a body-clear player line to bypass its next tile.
func chase_visible_player(
		route_target: Vector3,
		visible_player_position: Vector3,
		direct_path_clear: bool
) -> bool:
	if disable_vampire_for_testing or navigation == null:
		return false
	if not navigation.select_visible_target(
		route_target,
		visible_player_position,
		direct_path_clear
	):
		return false
	state = VampireState.ChasingPlayer
	target_selected.emit(route_target)
	return true


func search_route(search_position: Vector3) -> bool:
	if disable_vampire_for_testing or navigation == null:
		return false
	if not navigation.select_target(search_position):
		return false
	state = VampireState.SearchingRoute
	target_selected.emit(search_position)
	return true


func pursue_last_seen_player(last_seen_position: Vector3) -> bool:
	if disable_vampire_for_testing or navigation == null:
		return false
	if not navigation.select_target(last_seen_position):
		return false
	state = VampireState.PursuingLastSeen
	target_selected.emit(last_seen_position)
	return true


func begin_junction_scan() -> void:
	if disable_vampire_for_testing:
		return
	state = VampireState.ScanningJunction


func face_scan_direction(direction: Vector3, _delta: float) -> void:
	if look != null:
		look.look_in_world_direction(direction)


## Releases a completed or interrupted corridor check back toward travel facing.
func finish_junction_scan() -> void:
	if look != null:
		look.return_to_travel_direction()


func finish_search() -> void:
	if disable_vampire_for_testing:
		return
	state = VampireState.Idle


func get_vampire_state() -> VampireState:
	return state


## Returns whether the public boss state currently represents confirmed-player pursuit.
func is_chasing_player() -> bool:
	return state == VampireState.ChasingPlayer


## Returns whether the editor development toggle has completely disabled this boss.
func is_disabled_for_testing() -> bool:
	return disable_vampire_for_testing


## Returns whether a moving search currently aims the head into a side corridor.
func is_corridor_look_active() -> bool:
	return _corridor_look_active


## Captures focused replay evidence when a player marks a Vampire problem for Codex.
func get_codex_diagnostics() -> Dictionary:
	var state_names := VampireState.keys()
	var navigation_diagnostics := {}
	if navigation != null:
		var route := navigation.get_route_points() as Array[Vector3]
		navigation_diagnostics = {
			"has_target": bool(navigation.get("has_target")),
			"target_position": _vector3_to_array(
				navigation.get("target_position") as Vector3
			),
			"route_index": int(navigation.get("route_index")),
			"route_points": route.size(),
			"route_search_status": _enum_name(
				GDVampireNavigation.RouteSearchStatus.keys(),
				int(navigation.get_last_route_search_status())
			),
			"route_traversal_status": _enum_name(
				GDVampireNavigation.RouteTraversalStatus.keys(),
				int(navigation.get_route_traversal_status())
			),
			"route_rebuilds": int(navigation.get_route_rebuild_count()),
			"stall_recoveries": int(navigation.get_wall_stall_recovery_count()),
			"using_visible_shortcut": bool(
				navigation.is_using_visible_player_shortcut()
			),
		}
	var hunt_diagnostics := {}
	if hunt != null:
		hunt_diagnostics = {
			"player_visible": bool(hunt.is_player_visible()),
			"awareness_source": _enum_name(
				GDVampireHunt.AwarenessSource.keys(),
				int(hunt.get_awareness_source())
			),
			"last_confirmed_player_position": _vector3_to_array(
				hunt.get("last_confirmed_player_position") as Vector3
			),
			"noise_target_active": bool(hunt.get("noise_target_active")),
			"searching": bool(hunt.get("searching")),
		}
	return {
		"position": _vector3_to_array(global_position),
		"velocity": _vector3_to_array(velocity),
		"state": _enum_name(state_names, state),
		"visible": visible,
		"disabled_for_testing": disable_vampire_for_testing,
		"navigation": navigation_diagnostics,
		"hunt": hunt_diagnostics,
	}


## Captures live spatial perception details for the Vampire minimap diagnostics overlay.
func get_minimap_debug_snapshot() -> Dictionary:
	var has_belief := false
	var belief_position := Vector3.ZERO
	var belief_kind := "Unknown"
	var awareness_name := "None"
	var player_visible := false
	var uncertainty_radius := 0.0
	var evidence_age := 0.0
	var evidence_confidence := -1.0
	var search_plan_name := "None"
	var has_actual_player := false
	var actual_player_position := Vector3.ZERO

	if hunt != null:
		player_visible = bool(hunt.is_player_visible())
		awareness_name = _enum_name(
			GDVampireHunt.AwarenessSource.keys(),
			int(hunt.get_awareness_source())
		)
		has_actual_player = is_instance_valid(hunt.get("player") as Node3D)
		if has_actual_player:
			actual_player_position = (hunt.get("player") as Node3D).global_position

		var has_visible_observation := bool(hunt.get("has_visible_observation"))
		var has_noise_position := bool(hunt.get("has_noise_position"))
		var has_chase_target := bool(hunt.get("has_chase_target"))
		var pursuing_last_seen := bool(hunt.get("pursuing_last_seen_position"))
		if player_visible:
			has_belief = true
			belief_position = hunt.get("last_confirmed_player_position") as Vector3
			belief_kind = "Confirmed Sight"
			evidence_confidence = 1.0
		elif pursuing_last_seen and has_chase_target:
			has_belief = true
			belief_position = hunt.get("last_chase_target") as Vector3
			belief_kind = "Predicted Sight"
			uncertainty_radius = float(hunt.get_last_seen_uncertainty_radius())
			evidence_age = float(hunt.get("player_location_unknown_elapsed"))
		elif has_visible_observation:
			has_belief = true
			belief_position = hunt.get("last_confirmed_player_position") as Vector3
			belief_kind = "Last Confirmed"
			uncertainty_radius = float(hunt.get_last_seen_uncertainty_radius())
			evidence_age = float(hunt.get("player_location_unknown_elapsed"))
		elif has_noise_position:
			has_belief = true
			belief_position = hunt.get("last_noise_position") as Vector3
			belief_kind = "Sound Origin"
			uncertainty_radius = float(hunt.get_noise_uncertainty_radius())
			evidence_age = float(hunt.get("noise_elapsed_seconds"))
			evidence_confidence = float(hunt.get_noise_evidence_relevance())

		if bool(hunt.get("junction_scan_active")):
			search_plan_name = _enum_name(
				GDVampireHunt.SearchPlan.keys(),
				int(hunt.get("search_plan_after_scan"))
			)
		elif bool(hunt.get("searching")):
			search_plan_name = _enum_name(
				GDVampireHunt.SearchPlan.keys(),
				int(hunt.get("active_search_plan"))
			)
		elif pursuing_last_seen:
			search_plan_name = _enum_name(
				GDVampireHunt.SearchPlan.keys(),
				GDVampireHunt.SearchPlan.LastSeenDirection
			)
		elif bool(hunt.get("noise_target_active")):
			search_plan_name = _enum_name(
				GDVampireHunt.SearchPlan.keys(),
				GDVampireHunt.SearchPlan.NoiseRadius
			)

	var has_navigation_target := navigation != null \
		and bool(navigation.get("has_target"))
	var navigation_target := navigation.get("target_position") as Vector3 \
		if has_navigation_target else Vector3.ZERO
	var route := navigation.get_route_points() as Array[Vector3] \
		if navigation != null else []
	var route_status := _enum_name(
		GDVampireNavigation.RouteTraversalStatus.keys(),
		int(navigation.get_route_traversal_status())
	) if navigation != null else "Unavailable"
	var facing_direction := look.get_look_direction() as Vector3 \
		if look != null else (
			pivot.global_basis.z if pivot != null else Vector3.FORWARD
		)
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	var belief_error := _horizontal_distance(
		belief_position,
		actual_player_position
	) if has_belief and has_actual_player else 0.0
	var destination_distance := _horizontal_distance(
		global_position,
		navigation_target
	) if has_navigation_target else 0.0

	return {
		"state": _enum_name(VampireState.keys(), state),
		"vampire_position": global_position,
		"facing_direction": facing_direction,
		"head_yaw_degrees": rad_to_deg(float(look.get_current_head_yaw())) \
			if look != null else 0.0,
		"corridor_look_active": _corridor_look_active,
		"sight_distance": float(settings.sight_distance) \
			if settings != null else 0.0,
		"sight_field_of_view_degrees": float(settings.sight_field_of_view_degrees) \
			if settings != null else 0.0,
		"speed": horizontal_velocity.length(),
		"player_visible": player_visible,
		"awareness_source": awareness_name,
		"has_belief": has_belief,
		"belief_position": belief_position,
		"belief_kind": belief_kind,
		"uncertainty_radius": uncertainty_radius,
		"evidence_age": evidence_age,
		"evidence_confidence": evidence_confidence,
		"has_actual_player": has_actual_player,
		"actual_player_position": actual_player_position,
		"belief_error": belief_error,
		"search_plan": search_plan_name,
		"has_navigation_target": has_navigation_target,
		"navigation_target": navigation_target,
		"destination_distance": destination_distance,
		"route_index": int(navigation.get("route_index")) if navigation != null else 0,
		"route_points": route.size(),
		"route_status": route_status,
	}


func _update_look(delta: float) -> void:
	if look == null:
		return
	var has_observed_position := hunt != null and bool(hunt.is_player_visible())
	var observed_position := hunt.get("last_confirmed_player_position") as Vector3 \
		if has_observed_position else Vector3.ZERO
	_update_moving_corridor_look(delta, has_observed_position)
	var movement_focus_ratio := clampf(
		Vector2(velocity.x, velocity.z).length() \
			/ maxf(float(settings.max_speed), 0.01),
		0.0,
		1.0
	) if settings != null else 0.0
	look.update_look(
		delta,
		observed_position,
		has_observed_position,
		state != VampireState.ScanningJunction,
		movement_focus_ratio
	)


func _update_moving_corridor_look(
		delta: float,
		has_observed_position: bool
) -> void:
	if has_observed_position or not _is_searching_while_moving():
		_cancel_moving_corridor_look()
		_corridor_look_latched = false
		return
	var side_directions: Array[Vector3] = []
	if senses != null and settings != null:
		side_directions = senses.get_clear_side_corridor_directions(
			float(settings.junction_scan_probe_distance)
		) as Array[Vector3]
	if side_directions.is_empty():
		_corridor_look_latched = false
	if _corridor_look_active:
		_corridor_look_elapsed += maxf(delta, 0.0)
		if _corridor_look_elapsed \
				>= float(settings.junction_scan_seconds_per_direction):
			_cancel_moving_corridor_look()
		return
	if _corridor_look_latched or side_directions.is_empty():
		return
	_corridor_look_latched = true
	_corridor_look_active = true
	_corridor_look_elapsed = 0.0
	var selected_direction := _select_corridor_look_direction(side_directions)
	look.look_in_world_direction(selected_direction)


func _cancel_moving_corridor_look() -> void:
	if _corridor_look_active and look != null:
		look.return_to_travel_direction()
	_corridor_look_active = false
	_corridor_look_elapsed = 0.0


func _select_corridor_look_direction(
		side_directions: Array[Vector3]
) -> Vector3:
	var selected_direction := side_directions[0]
	for direction in side_directions:
		var local_direction := pivot.global_basis.inverse() * direction
		if signf(local_direction.x) == _next_corridor_look_side:
			selected_direction = direction
			break
	_next_corridor_look_side *= -1.0
	return selected_direction


func _is_searching_while_moving() -> bool:
	return state == VampireState.Hunting \
		or state == VampireState.SearchingRoute \
		or state == VampireState.PursuingLastSeen


func _enum_name(names: Array, value: int) -> String:
	return String(names[value]) if value >= 0 and value < names.size() else "Unknown"


func _vector3_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()


func _collect_physics_bodies(
		root: Node,
		found: Array[PhysicsBody3D]
) -> void:
	if root is PhysicsBody3D:
		found.append(root as PhysicsBody3D)
	for child in root.get_children():
		_collect_physics_bodies(child, found)


func _collect_body_collision_shapes(
		root: Node,
		owning_body: PhysicsBody3D,
		found: Array[CollisionShape3D]
) -> void:
	if root != owning_body and root is CollisionObject3D:
		return
	if root is CollisionShape3D:
		var collision_shape := root as CollisionShape3D
		if not found.has(collision_shape):
			found.append(collision_shape)
	for child in root.get_children():
		_collect_body_collision_shapes(child, owning_body, found)


func _update_passthrough_obstacle_stride(delta: float) -> void:
	if pivot == null or settings == null:
		return

	var target_height := _get_passthrough_obstacle_height(global_position)
	var movement_direction := Vector3(velocity.x, 0.0, velocity.z).normalized()
	if not movement_direction.is_zero_approx():
		var forward_probe := global_position + movement_direction \
			* float(settings.sight_clearance_radius)
		target_height = maxf(
			target_height,
			_get_passthrough_obstacle_height(forward_probe)
		)

	var target_position := _pivot_rest_position + Vector3.UP * target_height
	pivot.position = pivot.position.move_toward(
		target_position,
		maxf(float(settings.obstacle_stride_vertical_speed), 0.1) \
			* maxf(delta, 0.0)
	)


func _get_passthrough_obstacle_height(sample_position: Vector3) -> float:
	var obstacle_height := 0.0
	for shape_index in range(_passthrough_obstacle_shapes.size() - 1, -1, -1):
		var collision_shape := _passthrough_obstacle_shapes[shape_index]
		if not is_instance_valid(collision_shape):
			_passthrough_obstacle_shapes.remove_at(shape_index)
			continue
		if collision_shape.disabled or collision_shape.shape == null:
			continue
		var debug_mesh := collision_shape.shape.get_debug_mesh()
		if debug_mesh == null:
			continue
		var world_bounds := collision_shape.global_transform * debug_mesh.get_aabb()
		var bounds_end := world_bounds.end
		if sample_position.x < world_bounds.position.x \
				or sample_position.x > bounds_end.x \
				or sample_position.z < world_bounds.position.z \
				or sample_position.z > bounds_end.z:
			continue
		obstacle_height = maxf(
			obstacle_height,
			bounds_end.y - global_position.y
		)
	return maxf(obstacle_height, 0.0)


func _cache_enabled_state() -> void:
	if _enabled_state_cached:
		return
	_enabled_state_cached = true
	_visible_when_enabled = visible
	_process_mode_when_enabled = process_mode
	_collision_layer_when_enabled = collision_layer
	_collision_mask_when_enabled = collision_mask
	if contact != null:
		_contact_monitoring_when_enabled = contact.monitoring
		_contact_collision_mask_when_enabled = contact.collision_mask
	var sight_cast := senses as ShapeCast3D
	if sight_cast != null:
		_senses_enabled_when_enabled = sight_cast.enabled


func _apply_testing_disabled_state() -> void:
	_cache_enabled_state()
	var sight_cast := senses as ShapeCast3D
	if disable_vampire_for_testing:
		velocity = Vector3.ZERO
		if pivot != null:
			pivot.position = _pivot_rest_position
		if navigation != null:
			navigation.stop_immediately()
		state = VampireState.Disabled
		visible = false
		collision_layer = 0
		collision_mask = 0
		if contact != null:
			contact.monitoring = false
			contact.collision_mask = 0
		if sight_cast != null:
			sight_cast.enabled = false
		if proximity_fog != null and proximity_fog.has_method(&"set_suppressed"):
			proximity_fog.call(&"set_suppressed", true)
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	process_mode = _process_mode_when_enabled
	visible = _visible_when_enabled
	collision_layer = _collision_layer_when_enabled
	collision_mask = _collision_mask_when_enabled
	if contact != null:
		contact.monitoring = _contact_monitoring_when_enabled
		contact.collision_mask = _contact_collision_mask_when_enabled
	if sight_cast != null:
		sight_cast.enabled = _senses_enabled_when_enabled
	if proximity_fog != null and proximity_fog.has_method(&"set_suppressed"):
		proximity_fog.call(&"set_suppressed", false)
	if state == VampireState.Disabled:
		state = VampireState.Idle
