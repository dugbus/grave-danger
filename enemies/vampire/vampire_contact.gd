extends Area3D
class_name GDVampireContact


## Collision shape expanded to match the doubled Vampire's visible body.
@export var collision_shape_path: NodePath = ^"CollisionShape3D"
## World and player layers tested so instant-kill contact remains blocked by walls.
@export_flags_3d_physics var contact_occlusion_mask := 3

@onready var collision_shape := get_node_or_null(collision_shape_path) as CollisionShape3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Applies the shared Vampire contact radius without mutating the authored shape resource.
func configure(settings: Resource) -> void:
	if collision_shape == null or settings == null:
		return
	var authored_capsule := collision_shape.shape as CapsuleShape3D
	if authored_capsule == null:
		return
	var contact_capsule := authored_capsule.duplicate() as CapsuleShape3D
	contact_capsule.radius = float(settings.instant_kill_contact_radius)
	collision_shape.shape = contact_capsule


## Rechecks current overlaps after movement so a fast pass cannot rely on signal timing.
func check_contacts() -> void:
	for overlapping_body in get_overlapping_bodies():
		_try_kill_body(overlapping_body)


## Resolves a solid-body slide contact even if the Area entered signal arrived between frames.
func kill_touching_body(body: Node3D) -> void:
	_try_kill_body(body)


func _on_body_entered(body: Node3D) -> void:
	_try_kill_body(body)


func _try_kill_body(body: Node3D) -> void:
	var vampire := get_parent()
	if vampire != null \
			and vampire.has_method(&"is_disabled_for_testing") \
			and bool(vampire.call(&"is_disabled_for_testing")):
		return
	if body == null or not body.is_in_group(&"player"):
		return
	if body.has_method("is_dead") and body.is_dead():
		return
	if body.has_method("die_from_vampire") and _has_clear_contact_line(body):
		body.die_from_vampire()


func _has_clear_contact_line(body: Node3D) -> bool:
	if not is_inside_tree() or body == null:
		return false
	var vampire := get_parent() as CollisionObject3D
	var exclude: Array[RID] = []
	if vampire != null:
		exclude.append(vampire.get_rid())
	var origin := global_position + Vector3.UP * 0.4
	var target := body.global_position + Vector3.UP * 0.4
	if origin.is_equal_approx(target):
		return true
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		contact_occlusion_mask,
		exclude
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	while collider != null:
		if collider == body:
			return true
		collider = collider.get_parent()
	return false
