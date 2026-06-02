extends RigidBody3D


# How long a newly spawned or dropped coin must wait before pickup is allowed.
@export var pickup_delay := 0.35

# Coins below this height are assumed to have fallen out of the world.
@export var despawn_below_y := -5.0

# How far a coin is allowed to travel while tipped onto its edge before it is
# treated like a rounded-edge coin and settled back onto a face.
@export var max_edge_roll_distance := 1.0

@export_range(0.0, 1.0, 0.01) var edge_roll_up_dot := 0.45
@export var edge_roll_min_speed := 0.08
@export var edge_roll_horizontal_damping := 0.25

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

# Horizontal position where the current edge-roll stretch started.
var edge_roll_start_position := Vector2.ZERO
var is_tracking_edge_roll := false


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

	_limit_edge_roll_distance()

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
	is_tracking_edge_roll = false
	_block_pickup_for(pickup_delay)
	apply_impulse(impulse)


func _limit_edge_roll_distance() -> void:
	var coin_up_alignment := absf(global_transform.basis.y.normalized().dot(Vector3.UP))
	var horizontal_velocity := Vector2(linear_velocity.x, linear_velocity.z)
	var is_edge_rolling := coin_up_alignment < edge_roll_up_dot and horizontal_velocity.length() > edge_roll_min_speed

	if not is_edge_rolling:
		is_tracking_edge_roll = false
		return

	var horizontal_position := Vector2(global_position.x, global_position.z)
	if not is_tracking_edge_roll:
		edge_roll_start_position = horizontal_position
		is_tracking_edge_roll = true
		return

	if edge_roll_start_position.distance_to(horizontal_position) < max_edge_roll_distance:
		return

	_settle_flat_from_edge_roll()


func _settle_flat_from_edge_roll() -> void:
	var transform := global_transform
	var x_axis := transform.basis.x
	x_axis.y = 0.0
	if x_axis.length_squared() <= 0.0001:
		x_axis = Vector3.RIGHT
	else:
		x_axis = x_axis.normalized()

	var y_axis := Vector3.UP
	var z_axis := x_axis.cross(y_axis).normalized()
	transform.basis = Basis(x_axis, y_axis, z_axis).orthonormalized()
	global_transform = transform

	linear_velocity.x *= edge_roll_horizontal_damping
	linear_velocity.z *= edge_roll_horizontal_damping
	angular_velocity.x = 0.0
	angular_velocity.z = 0.0
	is_tracking_edge_roll = false


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
		_deactivate_after_collection()
		queue_free()
		return true

	return false


func _deactivate_after_collection() -> void:
	is_being_collected = true
	can_be_collected = false
	candidate_bodies.clear()
	remove_from_group("gold_coin")

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	collision_layer = 0
	collision_mask = 0
	visible = false

	_disable_pickup_area()
	_disable_collision_shapes(self)


func _disable_pickup_area() -> void:
	if pickup_area == null:
		return

	pickup_area.monitoring = false
	pickup_area.monitorable = false
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 0


func _disable_collision_shapes(node: Node) -> void:
	if node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true

	for child in node.get_children():
		_disable_collision_shapes(child)


func _block_pickup_for(seconds: float) -> void:
	# Temporarily disable pickup.

	can_be_collected = false
	is_being_collected = false
	await get_tree().create_timer(seconds).timeout
	if not is_being_collected:
		can_be_collected = true
