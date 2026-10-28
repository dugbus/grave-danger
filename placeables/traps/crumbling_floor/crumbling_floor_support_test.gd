extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_support.gd")
const GEOMETRY := preload("res://placeables/traps/crumbling_floor/crumbling_floor_geometry.gd")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")
const TILE_SCRIPT := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const ITEM_PATHS: Array[String] = [
	"res://placeables/treasure/gold_coin.tscn",
	"res://placeables/treasure/gold_bar.tscn",
	"res://placeables/treasure/gems/amethyst.tscn",
	"res://placeables/treasure/gems/diamond.tscn",
	"res://placeables/treasure/gems/emerald.tscn",
	"res://placeables/treasure/gems/ruby.tscn",
	"res://placeables/treasure/gems/sapphire.tscn",
	"res://placeables/collectibles/flask_bigger_sack.tscn",
	"res://placeables/collectibles/flask_breathing_space.tscn",
	"res://placeables/collectibles/flask_no_boundary.tscn",
	"res://placeables/collectibles/flask_pause_boundary.tscn",
	"res://placeables/collectibles/flask_pickup_radius.tscn",
	"res://placeables/collectibles/flask_poison.tscn",
	"res://placeables/collectibles/health_flask.tscn",
	"res://inventory/key.tscn",
	"res://inventory/silver_key.tscn",
	"res://placeables/treasure_deposit/treasure_deposit_coffin.tscn",
	"res://placeables/pushables/rolling_rock_pushable.tscn",
	"res://placeables/pushables/millstone.tscn",
	"res://placeables/pushables/hay_bale_pushable.tscn",
]

enum FixturePhysicsLayer { Floor = 1, Pickup = 4 }


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
	await _test_all_loose_items_fall(tree)
	await _test_dense_pile_and_unaffected_items(tree)


# Flow: Actual pickup and pushable scenes rest on an intact tile, then fall through its real collapsing support.
func _test_all_loose_items_fall(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	var grid := GridMap.new()
	grid.cell_size = Vector3(2.0, 1.0, 2.0)
	viewport.add_child(grid)
	var tiles: Array[TILE_SCRIPT] = []
	var items: Array[Node3D] = []
	for index in ITEM_PATHS.size():
		var tile := TILE.instantiate() as TILE_SCRIPT
		tile.name = "Tile%d" % index
		tile.position = Vector3(index * 4.0, 3.0, 0.0)
		tile.floor_grid_map = grid
		tile.collapse_delay = 100.0
		tile.block_release_interval = 0.01
		tile.debris_lifetime = 0.05
		viewport.add_child(tile)
		tiles.append(tile)
		var item := (load(ITEM_PATHS[index]) as PackedScene).instantiate() as Node3D
		item.position = tile.position + Vector3.UP * (_bottom_clearance(item) + 0.01)
		viewport.add_child(item)
		items.append(item)
	var host := GDAudio.PLAYBACK_HOST
	var previous_executor := host.executor
	host.executor = func(_audio: Node) -> void: pass
	tree.root.add_child(viewport)
	for tile in tiles:
		tile._crack_sound = null
	for tick in 60:
		await _settle(tree)
	for index in items.size():
		var item := items[index]
		var label := ITEM_PATHS[index].get_file()
		expect(item.position.y >= 2.9, label + " rests above the intact floor.")
		if item is RigidBody3D and not (item as RigidBody3D).freeze:
			(item as RigidBody3D).sleeping = true
		if item is GDInventoryPickup or item is GDFlaskBase:
			expect_equal(tiles[index].state, TILE_SCRIPT.State.Intact, label + " does not activate the trap by itself.")
		tiles[index].collapse_delay = 0.0
		tiles[index]._activate_from_support()
	for tick in 60:
		await _settle(tree)
	for index in items.size():
		var item := items[index]
		var label := ITEM_PATHS[index].get_file()
		expect_equal(tiles[index].state, TILE_SCRIPT.State.Collapsed, label + " loses the real floor collider.")
		expect(item.position.y < 2.0, label + " falls at least a metre after support disappears.")
		if item is RigidBody3D:
			expect(not (item as RigidBody3D).freeze, label + " is released from its frozen or sleeping presentation.")
		if item is GDFlaskBase:
			var flask := item as GDFlaskBase
			expect(
				is_equal_approx(flask.visual.position.y, flask.visual_base_y), label + " stops bobbing while falling."
			)
	host.executor = previous_executor
	viewport.free()
	await tree.process_frame
	await tree.process_frame


# Flow: Every object in a dense pile wakes, while airborne, neighboring, paused and not-yet-spawned items stay put.
func _test_dense_pile_and_unaffected_items(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var geometry := GEOMETRY.shared(GEOMETRY) as GEOMETRY
	var size := Vector3(2.0, 0.25, 2.0)
	var blocks := geometry.describe_blocks(size)
	var support := SUBJECT.new() as SUBJECT
	support.configure(viewport.find_world_3d().space, viewport.get_instance_id(), Transform3D.IDENTITY, size, blocks)
	var foot := blocks[0].get_center()
	foot.y = 0.01
	var pile: Array[GDPhysicsPlaceable] = []
	for index in 70:
		pile.append(_add_frozen_item(viewport, foot))
	var neighbor := _add_frozen_item(viewport, Vector3(0.8, 0.01, 0.8))
	var airborne := _add_frozen_item(viewport, foot + Vector3.UP)
	var paused := _add_frozen_item(viewport, foot)
	paused.process_mode = Node.PROCESS_MODE_DISABLED
	var delayed := _add_frozen_item(viewport, foot, 100.0)
	await _settle(tree)
	await _settle(tree)
	support.remove_block(0)
	for item in pile:
		expect(not item.freeze and item.has_lost_floor_support, "Dense piles release beyond the query result cap.")
	for item in [neighbor, airborne, paused, delayed]:
		expect(item.freeze and not item.has_lost_floor_support, "Only active items touching the released block wake.")
	support.clear()
	viewport.free()
	await tree.process_frame


func _add_frozen_item(parent: Node, at: Vector3, spawn_time: float = 0.0) -> GDPhysicsPlaceable:
	var item := GDPhysicsPlaceable.new()
	item.position = at
	item.freeze = true
	item.spawn_time = spawn_time
	item.collision_layer = FixturePhysicsLayer.Pickup
	item.collision_mask = FixturePhysicsLayer.Floor
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.01
	collision.shape = sphere
	item.add_child(collision)
	parent.add_child(item)
	return item


func _bottom_clearance(item: Node3D) -> float:
	var bottom := INF
	for child in item.get_children():
		if child is CollisionShape3D:
			var collision := child as CollisionShape3D
			var bounds := collision.transform * collision.shape.get_debug_mesh().get_aabb()
			bottom = minf(bottom, bounds.position.y)
	return -bottom


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
