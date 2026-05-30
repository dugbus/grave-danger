extends Node3D


# Scene used for every falling/dropped coin.
const GOLD_COIN_SCENE := preload("res://gold_coin.tscn")

# How frequently coins fall into the world.
@export var spawn_interval := 0.01

# How far above the graveyard the coins appear.
@export var spawn_height := 1.0

# Width/depth of the square area where coins are spawned.
@export var spawn_area_size := 1.0

# Stop automatic spawning after this many coins.
@export var max_spawned_coins := 200

# Spawn timer and total count.
var spawn_elapsed := 0.0
var spawned_coins := 0

# Random source for coin positions and spin.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	# This runs once when the graveyard scene starts.

	rng.randomize()


func _physics_process(delta: float) -> void:
	# This runs repeatedly during the physics step.

	if spawned_coins >= max_spawned_coins:
		return

	# Spawn repeatedly if a slow frame crosses more than one interval.
	spawn_elapsed += delta
	while spawn_elapsed >= spawn_interval and spawned_coins < max_spawned_coins:
		spawn_elapsed -= spawn_interval
		_spawn_gold_coin()


func _spawn_gold_coin() -> void:
	# Create one coin at a random point in the spawn area.

	var gold_coin := GOLD_COIN_SCENE.instantiate() as RigidBody3D
	add_child(gold_coin)
	spawned_coins += 1

	# Pick a random X/Z position inside the square spawn area.
	var half_area_size := spawn_area_size * 0.5
	var offset := Vector3(
		rng.randf_range(-half_area_size, half_area_size),
		spawn_height,
		rng.randf_range(-half_area_size, half_area_size)
	)
	gold_coin.global_position = global_position + offset

	# Add a little spin so coins do not all fall identically.
	gold_coin.angular_velocity = Vector3(
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(-2.0, 2.0)
	)
