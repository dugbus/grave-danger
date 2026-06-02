extends Node


# Inventory owns every gold-related player behavior:
# carry count, pickup acceptance, pickup audio, held-input dropping, and the
# carrying-weight multiplier used by movement and animation.

# The most coins the player can carry.
const MAX_CARRIED_GOLD_COINS = 100

# A coin can only be collected if it is roughly in front of the character.
const PICKUP_FACING_DOT = 0.35

# Where dropped coins are placed relative to the player.
const DROP_BACK_DISTANCE = 0.75
const DROP_UPWARD_OFFSET = 0.28

# How quickly held drop input creates coins.
const DROP_REPEAT_INTERVAL = 0.02

# How much space a dropped coin needs, and how hard nearby coins are nudged.
const DROP_CLEAR_RADIUS = 0.18
const DROP_NUDGE_RADIUS = 0.35
const DROP_NUDGE_IMPULSE = 0.025

const GOLD_COIN_SCENE := preload("res://gold_coin.tscn")
const COIN_PICKUP_SOUND := preload("res://Assets/coin-pickup.mp3")

signal carried_gold_coins_changed(carried_count: int)


@export var pivot_path: NodePath = ^"../Pivot"

@onready var player := get_parent() as CharacterBody3D
@onready var pivot: Node3D = get_node_or_null(pivot_path)

# Public state kept here rather than on Player so future UI or upgrades can
# depend on the inventory component directly.
var carried_gold_coins := 0
var drop_cooldown := 0.0


func update_drop_input(delta: float) -> void:
	# Dropping uses held input instead of just-pressed input so the player can
	# dump a pile of coins quickly under pressure.
	if not Input.is_action_pressed("drop_carried"):
		drop_cooldown = 0.0
		return

	drop_cooldown -= delta
	if drop_cooldown > 0.0:
		return

	_drop_carried_gold_coin()
	drop_cooldown = DROP_REPEAT_INTERVAL


func try_collect_gold_coin(gold_coin: Node3D) -> bool:
	# Gold coins keep asking while the player is inside their pickup area. This
	# component rejects collection when full or when the coin is behind the
	# character, which prevents immediately re-collecting freshly dropped coins.
	if carried_gold_coins >= MAX_CARRIED_GOLD_COINS or not _is_facing(gold_coin.global_position):
		return false

	carried_gold_coins += 1
	carried_gold_coins_changed.emit(carried_gold_coins)
	_play_coin_pickup_sound()
	return true


func spend_carried_gold_coin() -> bool:
	if carried_gold_coins <= 0:
		return false

	carried_gold_coins -= 1
	carried_gold_coins_changed.emit(carried_gold_coins)
	return true


func get_carried_gold_coins() -> int:
	return carried_gold_coins


func weight_multiplier(empty_value: float, full_value: float) -> float:
	# Shared carrying-weight curve. Callers provide their empty/full values so
	# speed, acceleration, jump, rotation, and animation can scale differently.
	return lerpf(empty_value, full_value, _weight_ratio())


func _drop_carried_gold_coin() -> void:
	# Create one physical coin just behind the player and remove it from the
	# carried count only once the spawn is going to happen.
	if carried_gold_coins <= 0 or player == null or pivot == null:
		return

	# The imported character faces local +Z, so pivot +Z is the visual forward.
	var forward := pivot.global_transform.basis.z.normalized()
	var back := -forward
	var spawn_position := _find_drop_position(player.global_position + back * DROP_BACK_DISTANCE, back)

	carried_gold_coins -= 1
	carried_gold_coins_changed.emit(carried_gold_coins)

	var gold_coin := GOLD_COIN_SCENE.instantiate()

	# Runtime scenes normally have current_scene. The parent fallback makes the
	# component safer when player.tscn is launched by itself for validation.
	var spawn_parent := get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = player.get_parent()
	spawn_parent.add_child(gold_coin)

	var spawn_transform := Transform3D(Basis(), spawn_position + Vector3.UP * DROP_UPWARD_OFFSET)
	if gold_coin.has_method("throw_from"):
		gold_coin.throw_from(spawn_transform, Vector3.ZERO)
	else:
		gold_coin.global_transform = spawn_transform


func _find_drop_position(base_position: Vector3, back: Vector3) -> Vector3:
	# Held dropping can create many coins in a tight space. Before choosing a
	# position, nudge existing coins away and then probe a small local pattern.
	_nudge_blocking_coins(base_position, back)

	var right := back.cross(Vector3.UP).normalized()
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		back * DROP_CLEAR_RADIUS,
		right * DROP_CLEAR_RADIUS,
		-right * DROP_CLEAR_RADIUS,
		(back + right).normalized() * DROP_CLEAR_RADIUS,
		(back - right).normalized() * DROP_CLEAR_RADIUS,
		right * DROP_CLEAR_RADIUS * 2.0,
		-right * DROP_CLEAR_RADIUS * 2.0,
		back * DROP_CLEAR_RADIUS * 2.0,
	]

	for offset: Vector3 in offsets:
		# Use the first clear position so coins spread out instead of stacking.
		var candidate: Vector3 = base_position + offset
		if not _is_drop_position_blocked(candidate):
			return candidate

	# If every nearby position is blocked, still drop the coin instead of
	# swallowing input. Physics will separate it on later frames.
	return base_position


func _is_drop_position_blocked(position: Vector3) -> bool:
	# Only existing gold coins matter here. Environment collision is intentionally
	# ignored so a player can always drop carried gold.
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not coin is Node3D:
			continue

		var coin_position := (coin as Node3D).global_position
		var delta := Vector2(coin_position.x - position.x, coin_position.z - position.z)
		if delta.length() < DROP_CLEAR_RADIUS:
			return true

	return false


func _nudge_blocking_coins(position: Vector3, fallback_direction: Vector3) -> void:
	# Nearby dropped coins get a small horizontal impulse away from the intended
	# spawn point. The impulse is intentionally tiny so it prevents clumping
	# without making coins burst across the level.
	for coin in get_tree().get_nodes_in_group("gold_coin"):
		if not coin is RigidBody3D:
			continue

		var rigid_coin := coin as RigidBody3D
		var offset := rigid_coin.global_position - position
		offset.y = 0.0
		var distance := offset.length()
		if distance >= DROP_NUDGE_RADIUS:
			continue

		var direction := offset.normalized() if distance > 0.001 else fallback_direction
		var strength := 1.0 - clampf(distance / DROP_NUDGE_RADIUS, 0.0, 1.0)
		rigid_coin.apply_impulse(direction * DROP_NUDGE_IMPULSE * strength)


func _is_facing(world_position: Vector3) -> bool:
	# Compare the flattened player forward vector with the flattened direction to
	# the coin. Y is ignored because coins can be falling or bouncing.
	if player == null or pivot == null:
		return false

	var to_position := world_position - player.global_position
	to_position.y = 0.0
	if to_position.is_zero_approx():
		return true

	var forward := pivot.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized().dot(to_position.normalized()) >= PICKUP_FACING_DOT


func _weight_ratio() -> float:
	# Convert carried coins into a 0.0 to 1.0 normalized load value.
	return float(carried_gold_coins) / float(MAX_CARRIED_GOLD_COINS)


func _play_coin_pickup_sound() -> void:
	# One-shot player-owned audio keeps rapid pickups responsive. Randomized
	# pitch/volume avoids the repeated sound becoming too mechanical.
	var sound_player := AudioStreamPlayer.new()
	sound_player.stream = COIN_PICKUP_SOUND
	sound_player.pitch_scale = randf_range(0.92, 1.1)
	sound_player.volume_db = randf_range(-4.0, 0.5)
	sound_player.finished.connect(sound_player.queue_free)

	if player != null:
		player.add_child(sound_player)
	else:
		add_child(sound_player)

	sound_player.play()
