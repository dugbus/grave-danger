extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_support.gd")
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_support.gd")
	var owner := Node3D.new()
	owner.position = Vector3(4.0, 2.0, 3.0)
	tree.root.add_child(owner)
	var geometry := GEOMETRY.shared(GEOMETRY) as GEOMETRY
	var size := Vector3(2.0, 0.25, 3.0)
	var blocks := geometry.describe_blocks(size)
	var support := SUBJECT.new()
	support.configure(owner.get_world_3d().space, owner.get_instance_id(), owner.global_transform, size, blocks)
	expect_equal(
		PhysicsServer3D.body_get_shape_count(support.body), 1, "An untouched tile needs one native support shape."
	)
	expect_equal(owner.get_child_count(), 0, "Support never adds collision nodes to the scene tree.")
	expect_equal(
		PhysicsServer3D.body_get_collision_layer(support.body),
		GEOMETRY.PhysicsLayer.Floor,
		"Support retains the floor layer."
	)
	expect_equal(
		PhysicsServer3D.body_get_collision_mask(support.body),
		GEOMETRY.PhysicsLayer.None,
		"Static support does not query other bodies."
	)
	await _settle(tree)
	expect(_has_support(owner, blocks[0]), "An elevated, resized tile provides actual physics support.")
	support.set_enabled(false)
	await _settle(tree)
	expect(not _has_support(owner, blocks[0]), "Disabling support removes it from physics without freeing the owner.")
	support.set_enabled(true)
	await _settle(tree)
	expect(_has_support(owner, blocks[0]), "Re-enabling support restores its original shapes.")
	support.remove_block(0)
	expect_equal(
		PhysicsServer3D.body_get_shape_count(support.body),
		blocks.size(),
		"Individual shapes exist only during breakup."
	)
	await _settle(tree)
	expect(not _has_support(owner, blocks[0]), "Releasing a block opens a real hole in its position.")
	expect(_has_support(owner, blocks.back()), "Other blocks still support the player during breakup.")
	var previous := owner.global_position
	owner.position += Vector3(5.0, 1.0, 0.0)
	support.update_transform(owner.global_transform)
	await _settle(tree)
	expect(_has_support(owner, blocks.back()), "Moving an elevated tile also moves its native support.")
	expect(
		not _ray_hit(owner, previous + blocks.back().get_center()), "Moving support leaves no stale collider behind."
	)
	support.clear()
	await _settle(tree)
	expect(not support.body.is_valid(), "Clearing support releases its physics-server handle.")
	expect(not _has_support(owner, blocks.back()), "Clearing support leaves an actual opening.")
	# A helper dropped outside the tile lifecycle still owns and releases its native body.
	support.configure(owner.get_world_3d().space, owner.get_instance_id(), owner.global_transform, size, blocks)
	support = null
	await _settle(tree)
	expect(not _has_support(owner, blocks.back()), "Dropping the final support owner releases its collider.")
	owner.free()
	await tree.process_frame


func _settle(tree: SceneTree) -> void:
	await tree.physics_frame
	await tree.process_frame


func _has_support(owner: Node3D, bounds: AABB) -> bool:
	return _ray_hit(owner, owner.to_global(bounds.get_center()))


func _ray_hit(owner: Node3D, centre: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		centre + Vector3.UP, centre + Vector3.DOWN, GEOMETRY.PhysicsLayer.Floor
	)
	var hit := owner.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == owner
