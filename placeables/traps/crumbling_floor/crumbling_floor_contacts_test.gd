extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")
const TILE_COUNT := 256


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
	var holder := Node3D.new()
	tree.root.add_child(holder)
	for index in TILE_COUNT:
		var tile := SCENE.instantiate() as TILE
		tile.position = Vector3(index % 16, 0.0, index / 16) * 2.0
		holder.add_child(tile)
	await tree.process_frame
	await tree.process_frame
	var first := holder.get_child(0) as TILE
	var monitor := first._contact_monitor as SUBJECT
	var cache := weakref(first._geometry) as WeakRef
	expect_equal(
		tree.get_nodes_in_group(SUBJECT.MONITOR_GROUP).size(), 1, "Hundreds of tiles share one contact monitor."
	)
	expect_equal(monitor._callbacks.size(), TILE_COUNT, "The shared monitor tracks every intact tile.")
	var all_compact := true
	var all_idle := true
	var all_shared := true
	var all_single_shape := true
	for child in holder.get_children():
		var tile := child as TILE
		all_compact = all_compact and tile.get_child_count() == 0
		all_idle = all_idle and not tile.is_physics_processing() and not tile.is_processing()
		all_shared = (
			all_shared
			and tile._contact_monitor == monitor
			and tile.multimesh.mesh == first.multimesh.mesh
			and is_same(tile._blocks, first._blocks)
		)
		all_single_shape = all_single_shape and PhysicsServer3D.body_get_shape_count(tile._support.body) == 1
	expect(all_compact, "Every untouched tile remains a single render node without a child hierarchy.")
	expect(all_idle, "Untouched tiles do not run per-tile frame or physics callbacks.")
	expect(all_shared, "All equal-sized tiles reuse the monitor, mesh and immutable layout.")
	expect(all_single_shape, "Every untouched tile has exactly one native support shape.")
	first.free()
	await tree.process_frame
	expect_equal(monitor._callbacks.size(), TILE_COUNT - 1, "Removing one tile unregisters only its own collider.")
	expect(not monitor.is_queued_for_deletion(), "The monitor remains available for surviving tiles.")
	holder.free()
	await tree.process_frame
	await tree.process_frame
	expect(not is_instance_valid(monitor), "Removing the final tile frees the shared monitor.")
	expect_equal(
		tree.get_nodes_in_group(SUBJECT.MONITOR_GROUP).size(), 0, "Level teardown leaves no stale monitor behind."
	)
	expect(cache.get_ref() == null, "Level teardown releases cached source material, meshes and shapes.")
	# Deferred registration must also tolerate removing a tile before its first idle frame.
	var transient := SCENE.instantiate() as TILE
	tree.root.add_child(transient)
	transient.free()
	await tree.process_frame
	expect_equal(
		tree.get_nodes_in_group(SUBJECT.MONITOR_GROUP).size(),
		0,
		"A tile removed immediately cannot strand a deferred monitor."
	)
