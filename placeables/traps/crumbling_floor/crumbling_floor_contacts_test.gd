extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")
const SCENE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.tscn")
const TILE_COUNT := 256
const ROCK_SCENE := preload("res://placeables/pushables/rolling_rock_pushable.tscn")
const MILLSTONE_SCENE := preload("res://placeables/pushables/millstone.tscn")
const PLAYER_SCENE := preload("res://player/player.tscn")
const ENEMY_SCENES: Array[PackedScene] = [preload("res://enemies/zombie.tscn"), preload("res://enemies/skeleton.tscn")]

enum StoneApproach { Rolling, Landing, Resting, Side, Airborne }
enum EnemyApproach { Walking, Landing, Resting, Side, Airborne, Hidden, Dead, WaitingToSpawn, Disabled }


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://placeables/traps/crumbling_floor/crumbling_floor_contacts.gd")
	for scene in ENEMY_SCENES:
		for approach in EnemyApproach.values():
			await _test_enemy_contact(tree, scene, approach as EnemyApproach)
		await _test_enemy_tracking(tree, scene)
		for approach in [
			EnemyApproach.Walking,
			EnemyApproach.Landing,
			EnemyApproach.Resting,
			EnemyApproach.Side,
			EnemyApproach.Airborne
		]:
			await _test_enemy_contact(tree, scene, approach, 2.0)
		for height in [0.0, 2.0]:
			await _test_enemy_falls_through_collapse(tree, scene, height)
	for scene in [ROCK_SCENE, MILLSTONE_SCENE]:
		for approach in [
			StoneApproach.Rolling,
			StoneApproach.Landing,
			StoneApproach.Resting,
			StoneApproach.Side,
			StoneApproach.Airborne
		]:
			await _test_stone_contact(tree, scene, approach)
		for approach in [StoneApproach.Rolling, StoneApproach.Landing, StoneApproach.Resting]:
			await _test_stone_contact(tree, scene, approach, 2.0)
	await _test_elevated_player_contact(tree)
	await _test_rolling_body_tracking(tree)
	await _test_unrelated_rigid_body(tree)
	await _test_shared_monitor(tree)


# Flow: Actual zombie and skeleton scenes activate their supporting tile on footfall or landing only.
func _test_enemy_contact(tree: SceneTree, scene: PackedScene, approach: EnemyApproach, height: float = 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(4.0, height, 3.0)
	var tile := SCENE.instantiate() as TILE
	tile.collapse_delay = 1.0
	var lower_tile := _add_lower_tile(holder, height)
	var enemy := _make_enemy(scene, approach)
	if approach == EnemyApproach.Walking:
		enemy.position = Vector3.LEFT
		var floor := StaticBody3D.new()
		floor.position = Vector3(-1.0, -0.125, 0.0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.0, 0.25, 1.0)
		collision.shape = shape
		floor.add_child(collision)
		holder.add_child(floor)
	elif approach in [EnemyApproach.Landing, EnemyApproach.Airborne]:
		enemy.position.y = 2.0
	elif approach == EnemyApproach.Side:
		enemy.position = Vector3(0.64, -0.2, 0.0)
	# Discover enemies already present when the first tile registers its monitor.
	holder.add_child(enemy)
	holder.add_child(tile)
	tree.root.add_child(holder)
	_prepare_enemy(enemy, approach)
	await _frames(tree, 8)
	var label := "%s / %s / %.1fm" % [enemy.name, EnemyApproach.keys()[approach], height]
	expect_equal(
		tile.state,
		TILE.State.Warning if approach == EnemyApproach.Resting else TILE.State.Intact,
		"Only an active enemy already standing on the tile triggers immediately: " + label
	)
	if approach in [EnemyApproach.Walking, EnemyApproach.Landing, EnemyApproach.Resting]:
		await _frames(tree, 40)
		expect_equal(tile.state, TILE.State.Warning, "Grounded enemy support starts the usual warning: " + label)
		if lower_tile != null:
			expect_equal(
				lower_tile.state, TILE.State.Intact, "Enemy support does not reach a tile two metres below: " + label
			)
		await _frames(tree, 90)
		expect_equal(tile.state, TILE.State.Collapsed, "Enemy footfall triggers the complete collapse: " + label)
	else:
		expect_equal(tile.state, TILE.State.Intact, "Unsupported or inactive enemies leave the tile intact: " + label)
	holder.free()
	await tree.process_frame


# Flow: Both enemy scenes lose real tile support, fall through the opening, and land on a lower floor.
func _test_enemy_falls_through_collapse(tree: SceneTree, scene: PackedScene, height: float) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(4.0, height, 3.0)
	var tile := SCENE.instantiate() as TILE
	tile.collapse_delay = 0.3
	holder.add_child(tile)
	var lower_floor := StaticBody3D.new()
	lower_floor.position.y = -3.125
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.0, 0.25, 4.0)
	collision.shape = shape
	lower_floor.add_child(collision)
	holder.add_child(lower_floor)
	var enemy := _make_enemy(scene, EnemyApproach.Resting)
	holder.add_child(enemy)
	tree.root.add_child(holder)
	_prepare_enemy(enemy, EnemyApproach.Resting)
	tile._crack_sound = null
	var feet: Node3D
	if enemy is GDZombiePath:
		feet = (enemy as GDZombiePath).zombie_body
	else:
		feet = (enemy as GDSkeletonPath).path_follow
	var label := "%s / %.1fm" % [enemy.name, height]
	await _frames(tree, 8)
	expect(absf(feet.global_position.y - height) < 0.02, "The enemy rests on the real tile surface: " + label)
	expect_equal(tile.state, TILE.State.Warning, "Enemy footfall starts the warning before collapse: " + label)
	await _frames(tree, 45)
	expect_equal(tile.state, TILE.State.Collapsed, "The supporting tile completes its collapse: " + label)
	expect(not tile._support.body.is_valid(), "Collapse removes the enemy's supporting physics geometry: " + label)
	expect(feet.global_position.y < height - 0.2, "The enemy actually falls through the opening: " + label)
	await _frames(tree, 60)
	expect(
		absf(feet.global_position.y - (height - 3.0)) < 0.02,
		"The enemy lands on the lower floor without returning to its original elevation: " + label
	)
	if enemy is GDZombiePath:
		var zombie := enemy as GDZombiePath
		expect(zombie.zombie_body.is_on_floor(), "The zombie regains real floor contact after falling: " + label)
		expect(
			zombie.drop_pivot.global_position.is_equal_approx(feet.global_position),
			"The visible zombie follows its collision body into the hole: " + label
		)
	else:
		expect((enemy as GDSkeletonPath).has_landed, "The skeleton regains support after falling: " + label)
	holder.free()
	await tree.process_frame


# Flow: A real player stands on a tile at 2m, triggers only that height, and falls as its support disappears.
func _test_elevated_player_contact(tree: SceneTree) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(4.0, 2.0, 3.0)
	var lower_tile := _add_lower_tile(holder, 2.0)
	var tile := SCENE.instantiate() as TILE
	tile.collapse_delay = 1.0
	holder.add_child(tile)
	var player := PLAYER_SCENE.instantiate() as GDPlayer
	player.position.y = 0.01
	holder.add_child(player)
	tree.root.add_child(holder)
	await _frames(tree, 8)
	expect(player.is_on_floor(), "The player has real physics support on the raised crumbling floor.")
	expect(absf(player.global_position.y - 2.0) < 0.02, "The player's feet rest at the tile's 2m surface.")
	expect_equal(tile.state, TILE.State.Warning, "The player triggers the raised tile's normal warning.")
	expect_equal(lower_tile.state, TILE.State.Intact, "The raised player does not activate the tile at ground level.")
	await _frames(tree, 90)
	expect_equal(tile.state, TILE.State.Collapsed, "The elevated tile completes its progressive collapse.")
	expect(not tile._support.body.is_valid(), "The elevated tile removes its real support after collapse.")
	expect(player.global_position.y < 1.9, "The player falls below the raised surface when support disappears.")
	holder.free()
	await tree.process_frame


func _add_lower_tile(holder: Node3D, height: float) -> TILE:
	if is_zero_approx(height):
		return null
	var lower_tile := SCENE.instantiate() as TILE
	lower_tile.position.y = -height
	holder.add_child(lower_tile)
	return lower_tile


func _make_enemy(scene: PackedScene, approach: EnemyApproach) -> GDPathPlaceable:
	var enemy := scene.instantiate() as GDPathPlaceable
	enemy.spawn_time = 10.0 if approach == EnemyApproach.WaitingToSpawn else 0.0
	if enemy is GDZombiePath:
		var zombie := enemy as GDZombiePath
		zombie.ai_enabled_on_ready = approach == EnemyApproach.Walking
		zombie.spawn_floor_checked = true
	elif enemy is GDSkeletonPath:
		var skeleton := enemy as GDSkeletonPath
		skeleton.shuffle_speed = 1.5 if approach == EnemyApproach.Walking else 0.0
		skeleton.spawn_floor_checked = true
	return enemy


func _prepare_enemy(enemy: GDPathPlaceable, approach: EnemyApproach) -> void:
	# Keep authored movement and collision; these tests do not need queued native audio playback.
	if enemy is GDZombiePath:
		var zombie := enemy as GDZombiePath
		zombie.footstep_sounds.clear()
		zombie.landing_sound = null
		zombie.is_dead = approach == EnemyApproach.Dead
	elif enemy is GDSkeletonPath:
		var skeleton := enemy as GDSkeletonPath
		skeleton.footstep_sounds.clear()
		skeleton.landing_sound = null
		skeleton.is_dead = approach == EnemyApproach.Dead
	if approach == EnemyApproach.Hidden:
		enemy.hide()
	elif approach == EnemyApproach.Disabled:
		enemy.process_mode = Node.PROCESS_MODE_DISABLED


# Flow: Enemy registration handles later spawns, removal, repeat discovery, and separate physics worlds.
func _test_enemy_tracking(tree: SceneTree, scene: PackedScene) -> void:
	var holder := Node3D.new()
	var tile := SCENE.instantiate() as TILE
	holder.add_child(tile)
	tree.root.add_child(holder)
	await _frames(tree, 2)
	var monitor := tile._contact_monitor as SUBJECT
	var enemy := _make_enemy(scene, EnemyApproach.Resting)
	enemy.position = Vector3(20.0, 2.0, 0.0)
	holder.add_child(enemy)
	_prepare_enemy(enemy, EnemyApproach.Resting)
	await _frames(tree, 2)
	expect(monitor._enemies.has(enemy), "Enemies added after the monitor are discovered: " + enemy.name)
	monitor._track_enemy(enemy.get_instance_id())
	expect_equal(monitor._enemies.size(), 1, "Repeated discovery does not duplicate an enemy.")
	holder.remove_child(enemy)
	expect(monitor._enemies.is_empty(), "Removing an enemy clears the monitor reference.")
	enemy.free()
	var other_world := SubViewport.new()
	other_world.own_world_3d = true
	holder.add_child(other_world)
	enemy = _make_enemy(scene, EnemyApproach.Resting)
	other_world.add_child(enemy)
	_prepare_enemy(enemy, EnemyApproach.Resting)
	await _frames(tree, 2)
	expect(monitor._enemies.is_empty(), "Enemies in another physics world cannot trigger this world's tiles.")
	holder.free()
	await tree.process_frame


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


func _test_stone_contact(tree: SceneTree, scene: PackedScene, approach: StoneApproach, height: float = 0.0) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(4.0, height, 3.0)
	var lower_tile := _add_lower_tile(holder, height)
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
	var label := "%s / %s / %.1fm" % [body.name, StoneApproach.keys()[approach], height]
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
		if lower_tile != null:
			expect_equal(lower_tile.state, TILE.State.Intact, "A raised stone does not trigger a lower tile: " + label)
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
