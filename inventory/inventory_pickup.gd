extends RigidBody3D


## Item definition added to the player's inventory when collected.
@export var carried_item: Resource
## Seconds a newly spawned or dropped item waits before pickup is allowed.
@export var pickup_delay := 0.35
## Existing pickup area. If missing, a small sphere area is created at runtime.
@export var pickup_area_path: NodePath = ^"PickupArea"
## Physics mask used by the generated pickup area to detect players.
@export var pickup_collision_mask := 2
## Radius used when this pickup creates its own area.
@export var generated_pickup_radius := 0.42

var pickup_area: Area3D
var can_be_collected := false
var is_being_collected := false
var candidate_bodies: Array[Node3D] = []


func _ready() -> void:
	add_to_group("inventory_pickup")
	_bind_or_create_pickup_area()
	_block_pickup_for(pickup_delay)


func _physics_process(_delta: float) -> void:
	if not can_be_collected or is_being_collected:
		return

	for body in candidate_bodies.duplicate():
		if not is_instance_valid(body):
			candidate_bodies.erase(body)
			continue

		if _try_collect(body):
			return


func get_carried_item() -> Resource:
	return carried_item


func throw_from(spawn_transform: Transform3D, impulse: Vector3) -> void:
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_block_pickup_for(pickup_delay)
	apply_impulse(impulse)


func _bind_or_create_pickup_area() -> void:
	pickup_area = get_node_or_null(pickup_area_path) as Area3D
	if pickup_area == null:
		pickup_area = _create_pickup_area()

	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)


func _create_pickup_area() -> Area3D:
	var area := Area3D.new()
	area.name = "PickupArea"
	area.collision_layer = 0
	area.collision_mask = pickup_collision_mask
	add_child(area)

	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = generated_pickup_radius
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	return area


func _on_pickup_area_body_entered(body: Node3D) -> void:
	if not candidate_bodies.has(body):
		candidate_bodies.append(body)
	_try_collect(body)


func _on_pickup_area_body_exited(body: Node3D) -> void:
	candidate_bodies.erase(body)


func _try_collect(body: Node3D) -> bool:
	if is_being_collected or not can_be_collected or carried_item == null:
		return false
	if not body.has_method("try_collect_carried_item"):
		return false

	if body.try_collect_carried_item(self):
		_deactivate_after_collection()
		queue_free()
		return true

	return false


func _deactivate_after_collection() -> void:
	is_being_collected = true
	can_be_collected = false
	candidate_bodies.clear()

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	collision_layer = 0
	collision_mask = 0
	visible = false

	_disable_pickup_area()
	_disable_collision_shapes(self)
	_after_collection_deactivated()


func _after_collection_deactivated() -> void:
	pass


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
	can_be_collected = false
	is_being_collected = false
	await get_tree().create_timer(seconds).timeout
	if not is_being_collected:
		can_be_collected = true
