extends RigidBody3D
class_name GDInventoryPickup


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
var pickup_radius_multiplier := 1.0
var pickup_block_ticks_remaining := 0


func _ready() -> void:
	add_to_group("inventory_pickup")
	_bind_or_create_pickup_area()
	_block_pickup_for(pickup_delay)


func _physics_process(_delta: float) -> void:
	_update_pickup_block()
	if not can_be_collected or is_being_collected:
		return

	for body in _get_sorted_candidate_bodies():
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


func set_pickup_radius_multiplier(multiplier: float) -> void:
	pickup_radius_multiplier = maxf(multiplier, 0.01)
	_apply_pickup_radius_multiplier()


func _bind_or_create_pickup_area() -> void:
	pickup_area = get_node_or_null(pickup_area_path) as Area3D
	if pickup_area == null:
		pickup_area = _create_pickup_area()

	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)
	_apply_pickup_radius_multiplier()


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

	pickup_area.set_deferred("monitoring", false)
	pickup_area.set_deferred("monitorable", false)
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
	pickup_block_ticks_remaining = _seconds_to_physics_ticks(seconds)


func _apply_pickup_radius_multiplier() -> void:
	if pickup_area == null:
		return

	for child in pickup_area.get_children():
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


func _update_pickup_block() -> void:
	if is_being_collected or can_be_collected:
		return

	pickup_block_ticks_remaining -= 1
	if pickup_block_ticks_remaining <= 0:
		can_be_collected = true


func _seconds_to_physics_ticks(seconds: float) -> int:
	var ticks_per_second := maxi(Engine.physics_ticks_per_second, 1)
	return maxi(ceili(maxf(seconds, 0.0) * float(ticks_per_second)), 1)


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
