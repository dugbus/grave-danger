extends RefCounted

## Local support checks and reusable sweeps; overlap alone never boards or carries an object.
const SUPPORT_SAMPLES: Array[Vector2] = [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var bodies: Array[PhysicsBody3D] = []
var exclusions: Array[RID] = []
var occupied := false
var _ray := PhysicsRayQueryParameters3D.new()
var _motion := PhysicsTestMotionParameters3D.new()
var _result := PhysicsTestMotionResult3D.new()
var _bounds: Dictionary[Shape3D, AABB] = {}
var _ray_exclusions: Array[RID] = [RID()]


func gather(platform: AnimatableBody3D, sensor: Area3D, margin: float) -> void:
	bodies.clear()
	exclusions.clear()
	exclusions.append(platform.get_rid())
	occupied = false
	for candidate in sensor.get_overlapping_bodies():
		var body := candidate as PhysicsBody3D
		if body == null or body == platform or not body.can_process() or not body.is_visible_in_tree():
			continue
		if body is GDPhysicsPlaceable and not (body as GDPhysicsPlaceable).is_placeable_spawned():
			continue
		if (
			(body is GDInventoryPickup and (body as GDInventoryPickup).is_being_collected)
			or (body is GDFlaskBase and (body as GDFlaskBase).is_being_collected)
		):
			continue
		if not _supported(body, platform, margin):
			continue
		bodies.append(body)
		exclusions.append(body.get_rid())
		if body is CharacterBody3D and body.is_in_group(&"player"):
			occupied = true


func _supported(body: PhysicsBody3D, platform: AnimatableBody3D, margin: float) -> bool:
	if body is CharacterBody3D:
		var character := body as CharacterBody3D
		if not character.is_on_floor() or character.velocity.y > 0.01:
			return false
	var bottom := INF
	var footprint := AABB()
	for child in body.get_children():
		var collision := child as CollisionShape3D
		if collision == null or collision.disabled or collision.shape == null:
			continue
		if not _bounds.has(collision.shape):
			_bounds[collision.shape] = _shape_bounds(collision.shape)
		var bounds := collision.global_transform * _bounds[collision.shape]
		footprint = bounds if bottom == INF else footprint.merge(bounds)
		bottom = minf(bottom, bounds.position.y)
	if bottom == INF or absf(bottom - platform.global_position.y) > margin:
		return false
	var foot := footprint.get_center()
	foot.y = bottom
	_ray_exclusions[0] = body.get_rid()
	_ray.exclude = _ray_exclusions
	_ray.collision_mask = platform.collision_layer
	# Rim support still counts when the body's centre has crossed the tile edge.
	for sample in SUPPORT_SAMPLES:
		var offset := Vector3(sample.x * footprint.size.x, 0.0, sample.y * footprint.size.z) * 0.35
		_ray.from = foot + offset + Vector3.UP * margin
		_ray.to = foot + offset - Vector3.UP * margin
		var hit := body.get_world_3d().direct_space_state.intersect_ray(_ray)
		if hit.get("rid", RID()) == platform.get_rid():
			return true
	return false


## Read collision geometry directly; creating debug meshes here allocates rendering resources during play.
func _shape_bounds(shape: Shape3D) -> AABB:
	var size := Vector3.ZERO
	if shape is BoxShape3D:
		size = (shape as BoxShape3D).size
	elif shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		size = Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0)
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		size = Vector3(cylinder.radius * 2.0, cylinder.height, cylinder.radius * 2.0)
	elif shape is SphereShape3D:
		size = Vector3.ONE * (shape as SphereShape3D).radius * 2.0
	elif shape is ConvexPolygonShape3D:
		var points := (shape as ConvexPolygonShape3D).points
		if points.is_empty():
			return AABB()
		var bounds := AABB(points[0], Vector3.ZERO)
		for point in points:
			bounds = bounds.expand(point)
		return bounds
	return AABB(-size * 0.5, size)


func blocked(platform: AnimatableBody3D, displacement: Vector3, margin: float) -> bool:
	_motion.from = platform.global_transform
	_motion.motion = displacement
	_motion.margin = margin
	_motion.exclude_bodies = exclusions
	if PhysicsServer3D.body_test_motion(platform.get_rid(), _motion, _result):
		return true
	for body in bodies:
		_motion.from = body.global_transform
		if PhysicsServer3D.body_test_motion(body.get_rid(), _motion, _result):
			return true
	return false


## Dynamic passengers use physics. Frozen presentation items need explicit transport and swept collision.
func carry_frozen(displacement: Vector3) -> void:
	for body in bodies:
		if body is RigidBody3D:
			var rigid := body as RigidBody3D
			if rigid.freeze:
				# Keep the authored freeze mode: changing it queues a stale physics transform
				# which can undo an external placement or collection move on the next tick.
				rigid.global_position += displacement
			else:
				rigid.sleeping = false
