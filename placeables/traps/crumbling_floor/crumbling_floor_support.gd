extends RefCounted

## Owns a static physics-server body without adding collision nodes to the authored scene.
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")

var body := RID()
var _blocks: Array[AABB] = []
var _split := false
var _space := RID()

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
	PhysicsServer3D.body_set_space(body, _space)
	_blocks = blocks
	_split = false


func update_transform(world: Transform3D) -> void:
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
