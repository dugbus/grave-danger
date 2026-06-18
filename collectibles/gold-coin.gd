extends "res://inventory/inventory_pickup.gd"


const GOLD_COIN_ITEM := preload("res://inventory/items/gold_coin.tres")

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

# Horizontal position where the current edge-roll stretch started.
var edge_roll_start_position := Vector2.ZERO
var is_tracking_edge_roll := false


func _ready() -> void:
	if carried_item == null:
		carried_item = GOLD_COIN_ITEM
	add_to_group("gold_coin")
	super._ready()


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


func _after_collection_deactivated() -> void:
	remove_from_group("gold_coin")
