class_name GDTreasureDeposit
extends Node3D

const DEFAULT_ABSORB_SOUND := preload("res://Assets/audio/coin-pickup.mp3")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const ABSORB_SOUND_VOLUME_OFFSET_DB := -2.5
const ABSORB_SOUND_PITCH_MIN := 0.82
const ABSORB_SOUND_PITCH_MAX := 0.98
const ABSORB_SOUND_VOLUME_MIN_DB := -3.0
const ABSORB_SOUND_VOLUME_MAX_DB := 1.0

## Treasure value added to the level score when an item reaches the deposit.
signal treasure_absorbed(value: int)
## Exact treasure object absorbed, used to bank typed currency after the attempt.
signal treasure_item_absorbed(item_type: StringName, value: int)

## Radius around the deposit that accepts players carrying treasure.
@export var detection_radius := 1.4
## Minimum seconds between treasure items being pulled from a player.
@export var deposit_interval := 0.12
## Extra vertical height added to the arcing deposit animation.
@export var launch_height := 1.25
## Seconds a visual treasure item takes to fly from the player to the deposit.
@export var flight_time := 0.45
## Random landing offset radius around the deposit target point.
@export var landing_spread_radius := 0.16
## Physics mask used by the generated deposit trigger area to detect players.
@export var player_collision_mask := 2
## Node that wobbles when treasure is absorbed; defaults to the parent.
@export var wobble_node_path: NodePath = ^".."
## Peak wobble rotation, in degrees, applied when treasure lands.
@export var wobble_angle_degrees := 5.0
## Total seconds for the deposit wobble animation.
@export var wobble_duration := 0.18

var candidate_bodies: Array[Node3D] = []
var deposit_cooldown := 0.0
var rng := RandomNumberGenerator.new()
var wobble_node: Node3D
var wobble_rest_rotation := Vector3.ZERO
var wobble_tween: Tween
var deposit_area: Area3D
var pickup_radius_multiplier := 1.0


func _ready() -> void:
	add_to_group("treasure_deposit")
	add_to_group("pickup_radius_scalable")
	rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"treasure_deposit")
	wobble_node = get_node_or_null(wobble_node_path) as Node3D
	if wobble_node == null:
		wobble_node = self
	wobble_rest_rotation = wobble_node.rotation
	set_pickup_radius_multiplier(_get_runtime_pickup_radius_multiplier())
	_create_detection_area()


func _physics_process(delta: float) -> void:
	deposit_cooldown = maxf(deposit_cooldown - delta, 0.0)
	if deposit_cooldown > 0.0:
		return

	for body in _get_sorted_candidate_bodies():
		if not is_instance_valid(body):
			candidate_bodies.erase(body)
			continue

		var treasure_item := _take_treasure_item(body)
		if treasure_item != null:
			_launch_deposit_treasure(body, treasure_item)
			deposit_cooldown = deposit_interval
			return


func _create_detection_area() -> void:
	var area := Area3D.new()
	area.name = "DepositArea"
	area.collision_layer = 0
	area.collision_mask = player_collision_mask
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)
	deposit_area = area

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = detection_radius
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	_apply_pickup_radius_multiplier()


func set_pickup_radius_multiplier(multiplier: float) -> void:
	pickup_radius_multiplier = maxf(multiplier, 0.01)
	_apply_pickup_radius_multiplier()


func _on_body_entered(body: Node3D) -> void:
	if not candidate_bodies.has(body):
		candidate_bodies.append(body)


func _on_body_exited(body: Node3D) -> void:
	candidate_bodies.erase(body)


func _take_treasure_item(player_body: Node3D) -> Resource:
	if player_body.has_method("take_highest_value_carried_treasure"):
		return player_body.take_highest_value_carried_treasure() as Resource

	return null


func _launch_deposit_treasure(player_body: Node3D, item: Resource) -> void:
	var treasure_visual := _create_visual_treasure(item)
	var treasure_value := _get_treasure_value(item)
	if treasure_visual == null:
		_absorb_treasure(treasure_value, item)
		return

	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = self
	spawn_parent.add_child(treasure_visual)

	var start_position := player_body.global_position + Vector3.UP * 0.6
	var landing_offset := _random_landing_offset()
	var end_position := global_position + landing_offset
	treasure_visual.global_position = start_position

	var tween := create_tween()
	tween.tween_method(
		func(progress: float) -> void:
			if not is_instance_valid(treasure_visual):
				return

			var arc_position := start_position.lerp(end_position, progress)
			arc_position.y += sin(progress * PI) * launch_height
			treasure_visual.global_position = arc_position,
		0.0,
		1.0,
		flight_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		treasure_visual,
		"rotation",
		treasure_visual.rotation + Vector3(PI * 3.0, PI * 2.0, PI),
		flight_time
	)
	tween.tween_callback(
		_finish_deposit_treasure.bind(treasure_visual, treasure_value, item)
	)


func _create_visual_treasure(item: Resource) -> Node3D:
	var world_scene_path := String(item.get("world_scene_path")) if item != null else ""
	if world_scene_path.is_empty():
		push_warning("Deposited treasure has no world scene path for its visual.")
		return null

	var world_scene := load(world_scene_path) as PackedScene
	if world_scene == null:
		push_warning("Deposited treasure visual could not load '%s'." % world_scene_path)
		return null

	var treasure_visual := world_scene.instantiate() as Node3D
	if treasure_visual == null:
		push_warning("Deposited treasure visual '%s' is not a Node3D." % world_scene_path)
		return null

	treasure_visual.name = "Deposit%sVisual" % String(item.get("display_name")).replace(" ", "")
	_prepare_deposit_visual(treasure_visual)
	return treasure_visual


func _prepare_deposit_visual(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CollisionObject3D:
		var collision_object := node as CollisionObject3D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	if node is RigidBody3D:
		var rigid_body := node as RigidBody3D
		rigid_body.freeze = true
		rigid_body.linear_velocity = Vector3.ZERO
		rigid_body.angular_velocity = Vector3.ZERO
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = \
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		_prepare_deposit_visual(child)


func _finish_deposit_treasure(
	treasure_visual: Node3D,
	treasure_value: int,
	item: Resource
) -> void:
	if is_instance_valid(treasure_visual):
		treasure_visual.queue_free()
	_absorb_treasure(treasure_value, item)


func _absorb_treasure(treasure_value: int, item: Resource = null) -> void:
	var safe_value := maxi(treasure_value, 0)
	treasure_absorbed.emit(safe_value)
	treasure_item_absorbed.emit(_get_treasure_type(item), safe_value)
	get_tree().call_group("treasure_score_display", "add_score", safe_value)
	_play_absorb_sound(item)
	_wobble()


func _get_treasure_value(item: Resource) -> int:
	return maxi(int(item.get("treasure_value")), 0) if item != null else 0


func _get_treasure_type(item: Resource) -> StringName:
	return StringName(item.get("item_type")) if item != null else &""


func _wobble() -> void:
	if wobble_node == null:
		return

	if wobble_tween != null:
		wobble_tween.kill()

	wobble_node.rotation = wobble_rest_rotation
	var wobble_angle := deg_to_rad(wobble_angle_degrees)
	wobble_tween = create_tween()
	wobble_tween.tween_property(
		wobble_node,
		"rotation",
		wobble_rest_rotation + Vector3(wobble_angle, 0.0, -wobble_angle * 0.6),
		wobble_duration * 0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	wobble_tween.tween_property(
		wobble_node,
		"rotation",
		wobble_rest_rotation + Vector3(-wobble_angle * 0.55, 0.0, wobble_angle * 0.35),
		wobble_duration * 0.3
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(
		wobble_node,
		"rotation",
		wobble_rest_rotation,
		wobble_duration * 0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _play_absorb_sound(item: Resource = null) -> void:
	var absorb_sound := item.get("pickup_sound") as AudioStream if item != null else null
	if absorb_sound == null:
		absorb_sound = DEFAULT_ABSORB_SOUND
	var pitch_scale := rng.randf_range(ABSORB_SOUND_PITCH_MIN, ABSORB_SOUND_PITCH_MAX)
	var volume_db := rng.randf_range(
		ABSORB_SOUND_VOLUME_MIN_DB + ABSORB_SOUND_VOLUME_OFFSET_DB,
		ABSORB_SOUND_VOLUME_MAX_DB + ABSORB_SOUND_VOLUME_OFFSET_DB
	)
	GDAudio.play_one_shot_3d(
		self,
		absorb_sound,
		"TreasureAbsorbAudio",
		volume_db,
		pitch_scale
	)


func _random_landing_offset() -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf()) * landing_spread_radius
	return (
		global_transform.basis.x.normalized() * cos(angle) * radius
		+ global_transform.basis.z.normalized() * sin(angle) * radius
	)


func _apply_pickup_radius_multiplier() -> void:
	if deposit_area == null:
		return

	for child in deposit_area.get_children():
		if not child is CollisionShape3D:
			continue

		var collision_shape := child as CollisionShape3D
		if not collision_shape.has_meta("base_pickup_scale"):
			collision_shape.set_meta("base_pickup_scale", collision_shape.scale)
		var base_scale: Vector3 = collision_shape.get_meta("base_pickup_scale")
		collision_shape.scale = base_scale * pickup_radius_multiplier


func _get_runtime_pickup_radius_multiplier() -> float:
	for body in _get_sorted_flame_vulnerable_bodies():
		if is_instance_valid(body) and body.has_method("get_pickup_radius_multiplier"):
			return maxf(float(body.get_pickup_radius_multiplier()), 0.01)

	return 1.0


func _get_sorted_candidate_bodies() -> Array[Node3D]:
	var sorted_bodies := candidate_bodies.duplicate()
	sorted_bodies.sort_custom(_sort_nodes_by_path)
	return sorted_bodies


func _get_sorted_flame_vulnerable_bodies() -> Array[Node]:
	var bodies: Array[Node] = []
	for body in get_tree().get_nodes_in_group("flame_vulnerable"):
		if body is Node:
			bodies.append(body as Node)

	bodies.sort_custom(_sort_nodes_by_path)
	return bodies


func _sort_nodes_by_path(a: Node, b: Node) -> bool:
	return str(a.get_path()) < str(b.get_path())
