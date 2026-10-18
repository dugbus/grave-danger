extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")
	var geometry := SUBJECT.shared(SUBJECT) as SUBJECT
	var root := Node3D.new()
	tree.root.add_child(root)
	var visual := MultiMeshInstance3D.new()
	root.add_child(visual)
	var material := StandardMaterial3D.new()
	var size := Vector3(2.0, 0.25, 3.0)
	geometry.populate_visual(visual, size, material)
	var blocks := geometry.describe_blocks(size)
	expect_equal(blocks.size(), 16, "The pulled flagstone still determines the sixteen block positions.")
	expect_equal(visual.get_child_count(), 0, "A batched visual never creates per-block mesh nodes.")
	expect_equal(visual.multimesh.instance_count, blocks.size(), "One MultiMesh draws all authored blocks.")
	expect_equal(visual.material_override, material, "Authored floor materials remain editable per tile.")
	expect(is_same(blocks, geometry.describe_blocks(size)), "Equal cell dimensions share the cached layout.")
	expect(blocks.is_read_only(), "One tile cannot mutate another tile's shared layout.")
	var bounds := blocks[0]
	var total_volume := 0.0
	for index in blocks.size():
		bounds = bounds.merge(blocks[index])
		total_volume += blocks[index].get_volume()
	# The headless dummy renderer discards instance transforms; layout and physics checks cover positions.
	expect(
		bounds.size.is_equal_approx(size) and is_zero_approx(bounds.end.y),
		"The batched visual fits the cell with its top at the floor plane."
	)
	expect(is_equal_approx(total_volume, size.x * size.y * size.z), "The block layout exactly covers the tile volume.")
	var first := Node3D.new()
	var second := Node3D.new()
	root.add_child(first)
	root.add_child(second)
	for index in blocks.size():
		geometry.release_fragment(first, blocks[index], material, 7, index, 0.5, 2.0)
		geometry.release_fragment(second, blocks[index], material, 7, index, 0.5, 2.0)
	expect_equal(first.get_child_count(), blocks.size(), "Falling physics is created only when requested.")
	for index in first.get_child_count():
		var body := first.get_child(index) as RigidBody3D
		var repeat := second.get_child(index) as RigidBody3D
		var mesh := body.get_child(0) as MeshInstance3D
		var shape := (body.get_child(1) as CollisionShape3D).shape as BoxShape3D
		expect_equal(mesh.mesh, visual.multimesh.mesh, "Idle tiles and falling pieces share one box mesh.")
		expect_equal(
			shape, (repeat.get_child(1) as CollisionShape3D).shape, "Debris reuses cached primitive shape resources."
		)
		expect(
			(mesh.transform * mesh.mesh.get_aabb()).size.is_equal_approx(shape.size),
			"Fragment rendering still fits its collision."
		)
		expect_equal(body.collision_layer, 0, "Falling pieces cannot obstruct players or one another.")
		expect_equal(body.collision_mask, 1, "Falling pieces retain environment collisions.")
		expect(
			body.angular_velocity.is_equal_approx(repeat.angular_velocity),
			"Equal seeds retain identical starting spin."
		)
		expect(
			body.position.is_equal_approx(blocks[index].get_center()), "Debris starts in the original block position."
		)
	root.free()
	await tree.process_frame
