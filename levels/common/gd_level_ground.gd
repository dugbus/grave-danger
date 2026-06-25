@tool
extends Node3D
class_name GDLevelGround

var _applying_scale := false
var _floor_material: StandardMaterial3D

@export var ground_size := Vector2(80.0, 80.0):
	set(value):
		ground_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_sync_ground()

@export var floor_y := 0.0:
	set(value):
		floor_y = value
		_sync_ground()

@export var collision_thickness := 2.0:
	set(value):
		collision_thickness = maxf(value, 0.05)
		_sync_ground()

@export var visible_floor := true:
	set(value):
		visible_floor = value
		_sync_ground()

## Texture applied to this level ground instance's floor material.
@export var floor_texture: Texture2D:
	set(value):
		floor_texture = value
		_sync_ground()

## Optional normal map applied to this level ground instance's floor material.
@export var floor_normal_texture: Texture2D:
	set(value):
		floor_normal_texture = value
		_sync_ground()

@export var floor_texture_tile_size := 2.0:
	set(value):
		floor_texture_tile_size = maxf(value, 0.05)
		_sync_ground()


func _enter_tree() -> void:
	set_notify_transform(true)


func _ready() -> void:
	_apply_node_scale_to_size()
	_sync_ground()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_apply_node_scale_to_size()


func _apply_node_scale_to_size() -> void:
	if _applying_scale:
		return
	if is_equal_approx(scale.x, 1.0) and is_equal_approx(scale.z, 1.0):
		return

	var scaled_size := Vector2(
		ground_size.x * absf(scale.x),
		ground_size.y * absf(scale.z)
	)
	_applying_scale = true
	ground_size = scaled_size
	scale = Vector3.ONE
	_applying_scale = false


func _sync_ground() -> void:
	if not is_inside_tree():
		return

	var collision := get_node_or_null("GroundBody/CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.position.y = floor_y - collision_thickness * 0.5
		if collision.shape is BoxShape3D:
			(collision.shape as BoxShape3D).size = Vector3(ground_size.x, collision_thickness, ground_size.y)

	var mesh_instance := get_node_or_null("FloorMesh") as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.visible = visible_floor
		mesh_instance.position.y = floor_y + 0.002
		if mesh_instance.mesh is PlaneMesh:
			(mesh_instance.mesh as PlaneMesh).size = ground_size
		_sync_floor_material(mesh_instance)


func _sync_floor_material(mesh_instance: MeshInstance3D) -> void:
	var material := _get_floor_material(mesh_instance)
	if material == null:
		return

	material.albedo_texture = floor_texture
	material.normal_enabled = floor_normal_texture != null
	material.normal_texture = floor_normal_texture

	var tile_size := maxf(floor_texture_tile_size, 0.05)
	material.uv1_scale = Vector3(
		ground_size.x / tile_size,
		ground_size.y / tile_size,
		1.0
	)


func _get_floor_material(mesh_instance: MeshInstance3D) -> StandardMaterial3D:
	if _floor_material != null:
		return _floor_material

	var source := mesh_instance.get_surface_override_material(0)
	if source == null:
		source = mesh_instance.get_active_material(0)
	if not source is StandardMaterial3D:
		return null

	_floor_material = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
	_floor_material.resource_local_to_scene = true
	mesh_instance.set_surface_override_material(0, _floor_material)
	return _floor_material
