extends RefCounted

## Owns a static physics-server body without adding collision nodes to the authored scene.
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")
const SUPPORT_CONTACT_MARGIN := 0.04
const QUERY_BATCH_SIZE := 32

var body := RID()
var _blocks: Array[AABB] = []
var _split := false
var _space := RID()
var _transform := Transform3D.IDENTITY

var _geometry := GEOMETRY.shared(GEOMETRY) as GEOMETRY


func configure(space: RID, owner_id: int, world: Transform3D, size: Vector3, blocks: Array[AABB]) -> void:
	if not body.is_valid():
		body = PhysicsServer3D.body_create()
		PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
		PhysicsServer3D.body_set_collision_layer(body, GEOMETRY.PhysicsLayer.Floor)
		PhysicsServer3D.body_set_collision_mask(body, GEOMETRY.PhysicsLayer.None)
		PhysicsServer3D.body_attach_object_instance_id(body, owner_id)
	PhysicsServer3D.body_clear_shapes(body)
	PhysicsServer3D.body_add_shape(
		body, _geometry.box_shape(size).get_rid(), Transform3D(Basis.IDENTITY, Vector3(0.0, -size.y * 0.5, 0.0))
	)
	PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, world)
	_space = space
	_transform = world
	PhysicsServer3D.body_set_space(body, _space)
	_blocks = blocks
	_split = false


func update_transform(world: Transform3D) -> void:
	_transform = world
	if body.is_valid():
		PhysicsServer3D.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, world)


## Match scene lifecycle without freeing or rebuilding the tile's shapes.
func set_enabled(enabled: bool) -> void:
	if body.is_valid():
		PhysicsServer3D.body_set_space(body, _space if enabled else RID())


## Called by the tile's deferred release, outside the physics query flush.
func remove_block(index: int) -> void:
	if not _split:
		PhysicsServer3D.body_clear_shapes(body)
		for bounds in _blocks:
			PhysicsServer3D.body_add_shape(
				body, _geometry.box_shape(bounds.size).get_rid(), Transform3D(Basis.IDENTITY, bounds.get_center())
			)
		_split = true
	PhysicsServer3D.body_set_shape_disabled(body, index, true)
	_release_supported_items(_blocks[index])


## Only query during breakup. Resting pickups never add callbacks to intact tiles.
func _release_supported_items(bounds: AABB) -> void:
	var space := PhysicsServer3D.space_get_direct_state(_space)
	if space == null:
		return
	var contact_size := Vector3(bounds.size.x, SUPPORT_CONTACT_MARGIN * 2.0, bounds.size.z)
	var contact_center := Vector3(bounds.get_center().x, bounds.end.y, bounds.get_center().z)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _geometry.box_shape(contact_size)
	query.transform = _transform * Transform3D(Basis.IDENTITY, contact_center)
	# Page through dense piles so the physics query's result cap cannot leave coins asleep.
	while true:
		var hits := space.intersect_shape(query, QUERY_BATCH_SIZE)
		var excluded := query.exclude
		for hit: Dictionary in hits:
			excluded.append(hit["rid"] as RID)
			var collider := hit.get("collider") as Node
			if collider is GDPhysicsPlaceable:
				(collider as GDPhysicsPlaceable).release_floor_support()
			elif collider is GDBoxPushable:
				(collider as GDBoxPushable).release_floor_support()
			elif collider is RigidBody3D and collider.can_process():
				(collider as RigidBody3D).sleeping = false
		if hits.size() < QUERY_BATCH_SIZE:
			break
		query.exclude = excluded


func clear() -> void:
	if body.is_valid():
		PhysicsServer3D.free_rid(body)
		body = RID()
	_blocks = []
	_split = false
	_space = RID()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and body.is_valid():
		PhysicsServer3D.free_rid(body)
