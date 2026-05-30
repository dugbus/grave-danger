extends RigidBody3D


# How long a newly spawned or dropped coin must wait before pickup is allowed.
@export var pickup_delay := 0.35

# Coins below this height are assumed to have fallen out of the world.
@export var despawn_below_y := -5.0

# Area used to detect players close enough to collect the coin.
@onready var pickup_area: Area3D = $PickupArea

# Whether this coin can currently be collected.
var can_be_collected := false

# Once a pickup succeeds, the coin is already counted by an inventory and is
# waiting for queue_free() at the end of the frame. This guard prevents another
# pickup-area callback or physics retry from counting the same physical coin a
# second time before Godot actually removes it from the tree.
var is_being_collected := false

# Bodies currently inside the pickup area.
var candidate_bodies: Array[Node3D] = []


func _ready() -> void:
	# This runs once when the coin enters the scene.

	add_to_group("gold_coin")

	# Track bodies that enter and leave the pickup area.
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)

	# Prevent immediate re-pickup after spawning or dropping.
	_block_pickup_for(pickup_delay)


func _physics_process(_delta: float) -> void:
	# This runs repeatedly during the physics step.

	if global_position.y < despawn_below_y:
		queue_free()
		return

	if not can_be_collected or is_being_collected:
		return

	for body in candidate_bodies.duplicate():
		if not is_instance_valid(body):
			candidate_bodies.erase(body)
			continue

		# Keep trying while a body remains inside the area.
		# This matters when the player was not facing the coin at first.
		if _try_collect(body):
			return


func throw_from(spawn_transform: Transform3D, impulse: Vector3) -> void:
	# Place this coin in the world and optionally apply an impulse.
	# Dropped coins currently use a zero impulse so they fall naturally.

	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_block_pickup_for(pickup_delay)
	apply_impulse(impulse)


func _on_pickup_area_body_entered(body: Node3D) -> void:
	# Start considering this body for collection.

	if not candidate_bodies.has(body):
		candidate_bodies.append(body)
	_try_collect(body)


func _on_pickup_area_body_exited(body: Node3D) -> void:
	# Stop considering this body for collection.

	candidate_bodies.erase(body)


func _try_collect(body: Node3D) -> bool:
	# Ask the body whether it wants to collect this coin.
	# The player can reject collection if full, dead, or not facing the coin.

	if is_being_collected or not can_be_collected or not body.has_method("try_collect_gold_coin"):
		return false

	if body.try_collect_gold_coin(self):
		is_being_collected = true
		can_be_collected = false
		queue_free()
		return true

	return false


func _block_pickup_for(seconds: float) -> void:
	# Temporarily disable pickup.

	can_be_collected = false
	is_being_collected = false
	await get_tree().create_timer(seconds).timeout
	if not is_being_collected:
		can_be_collected = true
