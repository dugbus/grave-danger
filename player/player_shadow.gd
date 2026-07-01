extends MeshInstance3D
class_name GDPlayerShadow


## Character body used as the world-space source for the projected contact shadow.
@export var player_path: NodePath = ^".."
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

@onready var player := get_node_or_null(player_path) as CharacterBody3D


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update_projected_shadow()


func _physics_process(_delta: float) -> void:
	_update_projected_shadow()


func _update_projected_shadow() -> void:
	if player == null:
		return

	var projected_position := _get_projected_position()
	global_transform = Transform3D(Basis.IDENTITY, projected_position)


func _get_projected_position() -> Vector3:
	var origin := player.global_position + Vector3.UP * probe_up_distance
	var target := player.global_position + Vector3.DOWN * probe_down_distance
	var ground_position: Variant = _probe_ground(origin, target)
	var projected_offset := player.global_transform.basis * projected_local_offset

	if ground_position != null:
		return (ground_position as Vector3) + Vector3.UP * surface_offset + projected_offset

	return player.global_position + Vector3.UP * fallback_height_offset + projected_offset


func _probe_ground(origin: Vector3, target: Vector3) -> Variant:
	var world := player.get_world_3d()
	if world == null:
		return null

	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		player.collision_mask,
		[player.get_rid()]
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null

	return hit["position"] as Vector3
