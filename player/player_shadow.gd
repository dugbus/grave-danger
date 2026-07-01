extends MeshInstance3D
class_name GDPlayerShadow


## Node used as the world-space source for the projected contact shadow.
@export var source_path: NodePath = ^".."
## Physics layers treated as ground by the contact shadow probe.
@export_flags_3d_physics var ground_collision_mask := 1
## World-space footprint size of the projected contact shadow.
@export var shadow_size := Vector2(1.0, 1.0)
## Height above the player origin where the ground probe starts.
@export var probe_up_distance := 1.25
## Distance below the player origin searched for ground.
@export var probe_down_distance := 4.0
## Small offset that keeps the fake shadow visibly above the floor surface.
@export var surface_offset := 0.035
## Local offset applied after the shadow is projected onto the floor.
@export var projected_local_offset := Vector3(0.0, 0.0, 0.06)
## Lowest world-space height used when no floor is found by the probe.
@export var fallback_height_offset := 0.025

@onready var source := get_node_or_null(source_path) as Node3D


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update_projected_shadow()


func _physics_process(_delta: float) -> void:
	_update_projected_shadow()


func _update_projected_shadow() -> void:
	if source == null:
		return

	var projected_position := _get_projected_position()
	var shadow_basis := Basis.IDENTITY.scaled(Vector3(
		maxf(shadow_size.x, 0.01),
		1.0,
		maxf(shadow_size.y, 0.01)
	))
	global_transform = Transform3D(shadow_basis, projected_position)


func _get_projected_position() -> Vector3:
	var origin := source.global_position + Vector3.UP * probe_up_distance
	var target := source.global_position + Vector3.DOWN * probe_down_distance
	var ground_position: Variant = _probe_ground(origin, target)
	var projected_offset := source.global_transform.basis * projected_local_offset

	if ground_position != null:
		return (ground_position as Vector3) + Vector3.UP * surface_offset + projected_offset

	return source.global_position + Vector3.UP * fallback_height_offset + projected_offset


func _probe_ground(origin: Vector3, target: Vector3) -> Variant:
	var world := source.get_world_3d()
	if world == null:
		return null

	var excluded_rids: Array[RID] = []
	if source is CollisionObject3D:
		excluded_rids.append((source as CollisionObject3D).get_rid())

	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		ground_collision_mask,
		excluded_rids
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	return hit["position"] as Vector3
