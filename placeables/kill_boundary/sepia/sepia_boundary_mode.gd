@tool
extends Node3D

## Runtime view of a kill boundary's selected safe side. The owning boundary supplies every perimeter point.
const GEOMETRY := preload("res://placeables/kill-boundary-2/kill_boundary_2_geometry.gd")
const CONTACT_SHAPE_META := &"sepia_contact_shape"
const REGISTRY_META := &"sepia_regions"
const MAX_REGIONS := 4
const POINTS_PER_REGION := 128

var enabled: bool:
	get:
		return is_instance_valid(boundary) and boundary.is_sepia_mode_active()

var inverted: bool:
	get:
		return is_instance_valid(boundary) and boundary.sepia_inverted

var boundary: Node
var _world_points := PackedVector2Array()
var _source_points := PackedVector3Array()
var _registered_world: World3D


func _ready() -> void:
	boundary = get_parent()
	refresh_mode()


## Mode changes affect registration and presentation, never the boundary's animation clock.
func refresh_mode() -> void:
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	if boundary == null:
		boundary = get_parent()
	var view := get_node(^"View")
	if not enabled:
		_unregister()
		view.deactivate()
		view.set_process(false)
		return
	if _registered_world == null:
		var world := get_world_3d()
		if not world.has_meta(REGISTRY_META):
			var regions: Array[Node3D] = []
			world.set_meta(REGISTRY_META, regions)
		var registry := world.get_meta(REGISTRY_META) as Array[Node3D]
		if registry.size() >= MAX_REGIONS:
			push_error("A world supports at most four sepia kill boundaries.")
			return
		registry.append(self)
		_registered_world = world
	view.set_process(true)


func _exit_tree() -> void:
	_unregister()


func _unregister() -> void:
	if _registered_world == null or not _registered_world.has_meta(REGISTRY_META):
		return
	var registry := _registered_world.get_meta(REGISTRY_META) as Array[Node3D]
	registry.erase(self)
	if registry.is_empty():
		_registered_world.remove_meta(REGISTRY_META)
	_registered_world = null


## No independent size, transform or shape: use the actual boundary's current canonical world perimeter.
func get_world_polygon() -> PackedVector2Array:
	if not enabled:
		return PackedVector2Array()
	var source: PackedVector3Array = boundary.get_boundary_world_points()
	if source != _source_points:
		_source_points = source
		_world_points.resize(source.size())
		for index in source.size():
			_world_points[index] = Vector2(source[index].x, source[index].z)
	return _world_points


## Shared by the visible veil; height and all transforms still come from the owning kill boundary.
func get_world_perimeter() -> PackedVector3Array:
	get_world_polygon()
	return _source_points


func contains_position(world_position: Vector3) -> bool:
	if not enabled:
		return false
	var distance := GEOMETRY.get_signed_distance(Vector2(world_position.x, world_position.z), get_world_polygon())
	return (-distance if inverted else distance) >= 0.0


func get_registration_root() -> Node:
	return boundary.owner if boundary.owner != null else boundary.get_parent()


static func is_sepia(context: Node3D, world_position: Vector3) -> bool:
	if context == null or not context.is_inside_tree():
		return false
	var world := context.get_world_3d()
	if world == null or not world.has_meta(REGISTRY_META):
		return false
	var registry := world.get_meta(REGISTRY_META) as Array[Node3D]
	for node in registry:
		if is_instance_valid(node) and node.contains_position(world_position):
			return true
	return false


## Uses the contact-side edge of the player's capsule, rather than switching the whole player.
## The source must also be exposed: an enlarged pickup/attack radius cannot reach through sepia.
static func allows_interaction(target: Node, source_position: Vector3) -> bool:
	var body := target as Node3D
	if body == null or not body.is_inside_tree():
		return true
	var contact := body.global_position
	if body.has_meta(CONTACT_SHAPE_META):
		var collision := body.get_meta(CONTACT_SHAPE_META) as CollisionShape3D
		if is_instance_valid(collision) and not collision.disabled and collision.shape is CapsuleShape3D:
			var capsule := collision.shape as CapsuleShape3D
			var direction := Vector3(source_position.x - contact.x, 0.0, source_position.z - contact.z)
			contact = collision.global_position + direction.limit_length(capsule.radius)
	return not is_sepia(body, source_position) and not is_sepia(body, contact)
