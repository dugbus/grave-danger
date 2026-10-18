extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")
const TILE_COUNT := 256
const ROCK_SCENE := preload("res://placeables/pushables/rolling_rock_pushable.tscn")
const MILLSTONE_SCENE := preload("res://placeables/pushables/millstone.tscn")

enum StoneApproach { Rolling, Landing, Resting, Side, Airborne }


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
	for scene in [ROCK_SCENE, MILLSTONE_SCENE]:
		for approach in [
			StoneApproach.Rolling,
			StoneApproach.Landing,
			StoneApproach.Resting,
			StoneApproach.Side,
			StoneApproach.Airborne
		]:
			await _test_stone_contact(tree, scene, approach)
	await _test_rolling_body_tracking(tree)
	await _test_unrelated_rigid_body(tree)
	await _test_shared_monitor(tree)


func _test_shared_monitor(tree: SceneTree) -> void:
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


func _make_stone(scene: PackedScene) -> RollingRock:
	var body := scene.instantiate() as RollingRock
	# Keep production collision and movement behavior while avoiding queued native audio in the dummy driver.
	body.get_node(^"RollingRockAudio").free()
	return body


func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame


func _test_stone_contact(tree: SceneTree, scene: PackedScene, approach: StoneApproach) -> void:
	var holder := Node3D.new()
	var body := _make_stone(scene)
	var tile := SCENE.instantiate() as TILE
	tile.collapse_delay = 1.0
	match approach:
		StoneApproach.Rolling:
			body.position = Vector3(-1.0, 0.5, 0.0)
			var floor := StaticBody3D.new()
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.0, 0.25, 1.0)
			collision.shape = shape
			floor.position = Vector3(-1.0, -0.125, 0.0)
			floor.add_child(collision)
			holder.add_child(floor)
		StoneApproach.Landing:
			body.position = Vector3(0.0, 2.0, 0.0)
			body.constrain_to_starting_height = false
		StoneApproach.Resting:
			body.position = Vector3(0.0, 0.5, 0.0)
		StoneApproach.Side:
			body.position = Vector3(0.95, -0.1, 0.0)
			body.constrain_to_starting_height = true
		StoneApproach.Airborne:
			body.position = Vector3(-0.8, 2.0, 0.0)
			body.constrain_to_starting_height = true
	# Add the body first to cover stones that already exist when a floor creates its monitor.
	holder.add_child(body)
	holder.add_child(tile)
	tree.root.add_child(holder)
	await _frames(tree, 8)
	var label := "%s / %s" % [body.name, StoneApproach.keys()[approach]]
	expect_equal(
		tile.state,
		TILE.State.Warning if approach == StoneApproach.Resting else TILE.State.Intact,
		"Only a stone already resting on the tile triggers it immediately: " + label
	)
	if approach == StoneApproach.Rolling or approach == StoneApproach.Airborne:
		body.sleeping = false
		body.linear_velocity = Vector3.RIGHT * 2.0
	await _frames(tree, 40)
	if approach in [StoneApproach.Rolling, StoneApproach.Landing, StoneApproach.Resting]:
		expect_equal(tile.state, TILE.State.Warning, "Supporting the stone starts collapse: " + label)
		await _frames(tree, 90)
		expect_equal(tile.state, TILE.State.Collapsed, "The stone triggers the complete progressive collapse: " + label)
	else:
		expect_equal(
			tile.state, TILE.State.Intact, "Side contact and airborne movement cannot trigger the tile: " + label
		)
	holder.free()
	await tree.process_frame


func _test_rolling_body_tracking(tree: SceneTree) -> void:
	var holder := Node3D.new()
	var tile := SCENE.instantiate() as TILE
	holder.add_child(tile)
	tree.root.add_child(holder)
	await _frames(tree, 2)
	var monitor := tile._contact_monitor as SUBJECT
	var body := _make_stone(MILLSTONE_SCENE)
	body.position = Vector3(20.0, 2.0, 0.0)
	holder.add_child(body)
	await _frames(tree, 2)
	expect(monitor._rolling_bodies.has(body), "Stones added after the monitor are tracked automatically.")
	monitor._track_rolling_body(body.get_instance_id())
	expect_equal(monitor._rolling_bodies.size(), 1, "Repeated discovery cannot duplicate a rolling body.")
	holder.remove_child(body)
	expect(monitor._rolling_bodies.is_empty(), "Removing a rolling body clears the shared monitor reference.")
	body.free()
	var other_world := SubViewport.new()
	other_world.own_world_3d = true
	holder.add_child(other_world)
	var other_stone := _make_stone(ROCK_SCENE)
	other_stone.position.y = 0.5
	other_world.add_child(other_stone)
	await _frames(tree, 3)
	expect(monitor._rolling_bodies.is_empty(), "Stones in another physics world cannot activate this world's tiles.")
	holder.free()
	await tree.process_frame


func _test_unrelated_rigid_body(tree: SceneTree) -> void:
	var holder := Node3D.new()
	var tile := SCENE.instantiate() as TILE
	var body := RigidBody3D.new()
	body.position.y = 0.5
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	collision.shape = sphere
	body.add_child(collision)
	body.add_to_group(&"pushable")
	holder.add_child(body)
	holder.add_child(tile)
	tree.root.add_child(holder)
	await _frames(tree, 20)
	expect_equal(tile.state, TILE.State.Intact, "Unrelated rigid bodies do not gain stone-trigger behavior.")
	holder.free()
	await tree.process_frame
