extends "res://inventory/inventory_pickup.gd"
class_name GDGoldCoin


const GOLD_COIN_ITEM := preload("res://placeables/treasure/gold_coin_inventory.tres")
const TREASURE_OUTLINE_MATERIAL := preload(
    "res://placeables/treasure/treasure_outline_material.tres"
)

## Visual root whose mesh vertices define this coin's convex physics hull.
@export var physics_mesh_root_path: NodePath = ^"CoinMesh"
## CollisionShape3D that receives the convex hull generated from the visual mesh.
@export var physics_collision_shape_path: NodePath = ^"CollisionShape3D"

## World Y position below which the coin is treated as fallen out of bounds.
@export var despawn_below_y := -5.0

## Distance a tipped coin may roll on its edge before being settled flat.
@export var max_edge_roll_distance := 1.0

## Maximum up-axis alignment still considered edge rolling; lower is more tipped.
@export_range(0.0, 1.0, 0.01) var edge_roll_up_dot := 0.45
## Minimum horizontal speed required before edge-roll limiting starts tracking.
@export var edge_roll_min_speed := 0.08
## Horizontal velocity multiplier applied when an edge-rolling coin is settled.
@export var edge_roll_horizontal_damping := 0.25

static var physics_shape_cache: Dictionary[String, ConvexPolygonShape3D] = {}

# Horizontal position where the current edge-roll stretch started.
var edge_roll_start_position := Vector2.ZERO
var is_tracking_edge_roll := false


func _ready() -> void:
	_apply_outline_to_visual_meshes()
	rebuild_physics_shape_from_visual()
	if carried_item == null:
		carried_item = GOLD_COIN_ITEM
	add_to_group("gold_coin")
	add_to_group("pickup_radius_scalable")
	set_pickup_radius_multiplier(_get_runtime_pickup_radius_multiplier())
	super._ready()


## Rebuilds dynamic-body collision from every visual mesh under the configured coin root.
func rebuild_physics_shape_from_visual() -> bool:
	var mesh_root := get_node_or_null(physics_mesh_root_path) as Node3D
	var collision_shape := get_node_or_null(
		physics_collision_shape_path
	) as CollisionShape3D
	if mesh_root == null or collision_shape == null:
		push_warning("Gold coin cannot build mesh collision; visual or collision node is missing.")
		return false

	var cache_key := _get_collision_cache_key(mesh_root, collision_shape)
	if physics_shape_cache.has(cache_key):
		collision_shape.shape = physics_shape_cache[cache_key]
		return true

	var hull_points := PackedVector3Array()
	_append_collision_points(mesh_root, collision_shape, hull_points)
	if hull_points.size() < 4:
		push_warning("Gold coin visual has too few mesh vertices for convex collision.")
		return false

	var convex_shape := ConvexPolygonShape3D.new()
	convex_shape.points = hull_points
	collision_shape.shape = convex_shape
	physics_shape_cache[cache_key] = convex_shape
	return true


func _physics_process(_delta: float) -> void:
	if global_position.y < despawn_below_y:
		queue_free()
		return

	_limit_edge_roll_distance()
	super._physics_process(_delta)


func throw_from(spawn_transform: Transform3D, impulse: Vector3) -> void:
	is_tracking_edge_roll = false
	super.throw_from(spawn_transform, impulse)


func _limit_edge_roll_distance() -> void:
	var coin_up_alignment := absf(global_transform.basis.y.normalized().dot(Vector3.UP))
	var horizontal_velocity := Vector2(linear_velocity.x, linear_velocity.z)
	var is_edge_rolling := coin_up_alignment < edge_roll_up_dot \
		and horizontal_velocity.length() > edge_roll_min_speed

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
	var current_transform := global_transform
	var x_axis := current_transform.basis.x
	x_axis.y = 0.0
	if x_axis.length_squared() <= 0.0001:
		x_axis = Vector3.RIGHT
	else:
		x_axis = x_axis.normalized()

	var y_axis := Vector3.UP
	var z_axis := x_axis.cross(y_axis).normalized()
	current_transform.basis = Basis(x_axis, y_axis, z_axis).orthonormalized()
	global_transform = current_transform

	linear_velocity.x *= edge_roll_horizontal_damping
	linear_velocity.z *= edge_roll_horizontal_damping
	angular_velocity.x = 0.0
	angular_velocity.z = 0.0
	is_tracking_edge_roll = false


func _after_collection_deactivated() -> void:
	remove_from_group("gold_coin")


func _append_collision_points(
	node: Node,
	collision_shape: CollisionShape3D,
	hull_points: PackedVector3Array
) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_to_collision := collision_shape.global_transform.affine_inverse() \
				* mesh_instance.global_transform
			for mesh_point in mesh_instance.mesh.get_faces():
				hull_points.append(mesh_to_collision * mesh_point)

	for child in node.get_children():
		_append_collision_points(child, collision_shape, hull_points)


func _apply_outline_to_visual_meshes() -> void:
	var mesh_root := get_node_or_null(physics_mesh_root_path)
	if mesh_root != null:
		_apply_outline_recursive(mesh_root)


func _apply_outline_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = TREASURE_OUTLINE_MATERIAL
	for child in node.get_children():
		_apply_outline_recursive(child)


func _get_collision_cache_key(
	mesh_root: Node,
	collision_shape: CollisionShape3D
) -> String:
	var mesh_signatures := PackedStringArray()
	_append_mesh_signatures(mesh_root, collision_shape, mesh_signatures)
	return "|".join(mesh_signatures)


func _append_mesh_signatures(
	node: Node,
	collision_shape: CollisionShape3D,
	mesh_signatures: PackedStringArray
) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_to_collision := collision_shape.global_transform.affine_inverse() \
				* mesh_instance.global_transform
			mesh_signatures.append(
				"%d:%s" % [
					mesh_instance.mesh.get_instance_id(),
					mesh_to_collision,
				]
			)
	for child in node.get_children():
		_append_mesh_signatures(child, collision_shape, mesh_signatures)
