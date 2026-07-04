extends Node3D
class_name GDCoinDeposit

const COIN_PICKUP_SOUND := preload("res://Assets/audio/coin-pickup.mp3")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const COIN_SOUND_VOLUME_OFFSET_DB := -2.5
const COIN_SOUND_PITCH_MIN := 0.82
const COIN_SOUND_PITCH_MAX := 0.98
const COIN_SOUND_VOLUME_MIN_DB := -3.0
const COIN_SOUND_VOLUME_MAX_DB := 1.0

signal coin_absorbed(count: int)

## Radius around the deposit that accepts players carrying coins.
@export var detection_radius := 1.4
## Minimum seconds between coins being pulled from a player.
@export var deposit_interval := 0.12
## Extra vertical height added to the arcing deposit coin animation.
@export var launch_height := 1.25
## Seconds a visual coin takes to fly from the player to the deposit.
@export var flight_time := 0.45
## Random landing offset radius around the deposit target point.
@export var landing_spread_radius := 0.16
## Physics mask used by the generated deposit trigger area to detect players.
@export var player_collision_mask := 2
## Node that wobbles when a coin is absorbed; defaults to the parent.
@export var wobble_node_path: NodePath = ^".."
## Peak wobble rotation, in degrees, applied when a coin lands.
@export var wobble_angle_degrees := 5.0
## Total seconds for the deposit wobble animation.
@export var wobble_duration := 0.18

var candidate_bodies: Array[Node3D] = []
var deposit_cooldown := 0.0
var rng := RandomNumberGenerator.new()
var wobble_node: Node3D
var wobble_rest_rotation := Vector3.ZERO
var wobble_tween: Tween
var visual_coin_mesh: CylinderMesh
var deposit_area: Area3D
var pickup_radius_multiplier := 1.0


func _ready() -> void:
	add_to_group("coin_deposit")
	add_to_group("pickup_radius_scalable")
	rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"coin_deposit")
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

		if body.has_method("spend_carried_gold_coin") and body.spend_carried_gold_coin():
			_launch_deposit_coin(body)
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


func _launch_deposit_coin(player_body: Node3D) -> void:
	var coin := _create_visual_coin()

	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = self
	spawn_parent.add_child(coin)

	var start_position := player_body.global_position + Vector3.UP * 0.6
	var landing_offset := _random_landing_offset()
	var end_position := global_position + landing_offset
	coin.global_position = start_position

	var tween := create_tween()
	tween.tween_method(
		func(progress: float) -> void:
			if not is_instance_valid(coin):
				return

			var arc_position := start_position.lerp(end_position, progress)
			arc_position.y += sin(progress * PI) * launch_height
			coin.global_position = arc_position,
		0.0,
		1.0,
		flight_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin, "rotation", coin.rotation + Vector3(PI * 3.0, PI * 2.0, PI), flight_time)
	tween.tween_callback(_finish_deposit_coin.bind(coin))


func _create_visual_coin() -> MeshInstance3D:
	var coin := MeshInstance3D.new()
	coin.name = "DepositCoinVisual"
	coin.mesh = _get_visual_coin_mesh()
	return coin


func _get_visual_coin_mesh() -> CylinderMesh:
	if visual_coin_mesh != null:
		return visual_coin_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.72, 0.08, 1)
	material.metallic = 0.65
	material.roughness = 0.28
	material.emission_enabled = true
	material.emission = Color(1, 0.68, 0.06, 1)
	material.emission_energy_multiplier = 2.0

	visual_coin_mesh = CylinderMesh.new()
	visual_coin_mesh.material = material
	visual_coin_mesh.top_radius = 0.08
	visual_coin_mesh.bottom_radius = 0.08
	visual_coin_mesh.height = 0.035
	visual_coin_mesh.radial_segments = 32
	return visual_coin_mesh


func _finish_deposit_coin(coin: Node3D) -> void:
	if is_instance_valid(coin):
		coin.queue_free()
	_absorb_coin()


func _absorb_coin() -> void:
	coin_absorbed.emit(1)
	get_tree().call_group("coin_score_display", "add_score", 1)
	_play_absorb_sound()
	_wobble()


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


func _play_absorb_sound() -> void:
	var pitch_scale := rng.randf_range(COIN_SOUND_PITCH_MIN, COIN_SOUND_PITCH_MAX)
	var volume_db := rng.randf_range(
		COIN_SOUND_VOLUME_MIN_DB + COIN_SOUND_VOLUME_OFFSET_DB,
		COIN_SOUND_VOLUME_MAX_DB + COIN_SOUND_VOLUME_OFFSET_DB
	)
	GDAudio.play_one_shot_3d(self, COIN_PICKUP_SOUND, "CoinAbsorbAudio", volume_db, pitch_scale)


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
