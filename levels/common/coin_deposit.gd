extends Node3D

const COIN_PICKUP_SOUND := preload("res://Assets/audio/coin-pickup.mp3")

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


func _ready() -> void:
	add_to_group("coin_deposit")
	rng.randomize()
	wobble_node = get_node_or_null(wobble_node_path) as Node3D
	if wobble_node == null:
		wobble_node = self
	wobble_rest_rotation = wobble_node.rotation
	_create_detection_area()


func _physics_process(delta: float) -> void:
	deposit_cooldown = maxf(deposit_cooldown - delta, 0.0)
	if deposit_cooldown > 0.0:
		return

	for body in candidate_bodies.duplicate():
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

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = detection_radius
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)


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
	var sound_player := AudioStreamPlayer3D.new()
	sound_player.name = "CoinAbsorbAudio"
	sound_player.stream = COIN_PICKUP_SOUND
	sound_player.pitch_scale = randf_range(0.88, 1.05)
	sound_player.volume_db = randf_range(-3.0, 1.0)
	sound_player.finished.connect(sound_player.queue_free)
	add_child(sound_player)
	sound_player.global_position = global_position
	sound_player.play()


func _random_landing_offset() -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var radius := sqrt(rng.randf()) * landing_spread_radius
	return (
		global_transform.basis.x.normalized() * cos(angle) * radius
		+ global_transform.basis.z.normalized() * sin(angle) * radius
	)
