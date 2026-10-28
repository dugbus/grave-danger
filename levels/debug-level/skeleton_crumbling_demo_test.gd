extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/debug-level/level.tscn")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")


# Flow: The spawn-side skeleton collapses the raised tile and falls through the opening without a player.
func run(tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var station := level.get_node(^"Objects/SkeletonCrumblingDemo") as Node3D
	var skeleton := station.get_node(^"Skeleton") as GDSkeletonPath
	var tile := station.get_node(^"CrumblingFloor") as TILE
	var coins: Array[GDGoldCoin] = []
	for coin in station.get_node(^"Coins").get_children():
		coins.append(coin as GDGoldCoin)
	expect_equal(coins.size(), 3, "The visible collapse demonstration includes three real physical coins.")
	var player := level.get_node(^"Player") as GDPlayer
	var surface := level.get_node(^"FloorSurface") as FloorSurface
	var grid := level.get_node(^"PNGGridMap") as GridMap
	var player_xz := Vector2(player.position.x, player.position.z)
	var tile_xz := Vector2(station.position.x, station.position.z)
	var landing := surface.sample_surface(player.position)
	expect(
		landing.valid and is_zero_approx(landing.world_height), "The demo preserves the player's ground-level landing."
	)
	_test_spawn_camera(tree, Vector3(player.position.x, landing.world_height, player.position.z), station.position)
	expect(
		player_xz.distance_to(tile_xz) < 4.0, "The cracked tile is within four metres of the player's landing point."
	)
	expect_equal(surface.validate_configuration(), [] as Array[String], "The authored floor remains valid.")
	var hole := surface.world_to_cell(station.position)
	expect(not surface.has_floor(hole), "The cracked tile sits over a real hole in the floor.")
	expect_equal(
		surface.floor_map.get_authored_cell_elevation(hole), 8, "The hole retains the platform's 2m elevation intent."
	)
	expect(tile.floor_surface == surface and tile.floor_grid_map == grid, "The tile retains editable floor references.")
	expect(
		not skeleton.loop_patrol and skeleton.reverse_at_path_ends,
		"The demonstration patrol reverses without wrapping."
	)
	expect(skeleton.spawn_time >= 4.0, "The player has time to land and look before the skeleton appears.")
	for x in range(243, 246):
		for z in range(8, 11):
			var cell := Vector2i(x, z)
			if cell != hole:
				expect(
					is_equal_approx(surface.sample_surface(surface.cell_to_local(cell)).world_height, 2.0),
					"The skeleton's approach and surroundings stay level at 2m."
				)
			expect_equal(
				grid.get_cell_item(Vector3i(x, 0, z)), GridMap.INVALID_CELL_ITEM, "The demo has no GridMap blockers."
			)
	# Retain the actual authored geometry and encounter, removing unrelated hazards and the player.
	# With no player or other actors present, only this skeleton can activate the tile.
	for child in level.get_children():
		if child.name not in [&"FloorSurface", &"PNGGridMap", &"Objects"]:
			child.free()
	for child in level.get_node(^"Objects").get_children():
		if child != station:
			child.free()
	tree.root.add_child(level)
	skeleton.footstep_sounds.clear()
	skeleton.landing_sound = null
	# Audio is covered by the trap suite; avoid native audio queues in this headless scene test.
	tile._crack_sound = null
	var triggered_at := -1.0
	var collapsed := false
	var starting_frame := Engine.get_physics_frames()
	var coins_rested_on_tile := false
	for frame in 540:
		await tree.physics_frame
		await tree.process_frame
		if frame == 120:
			coins_rested_on_tile = true
			for coin in coins:
				coins_rested_on_tile = coins_rested_on_tile and coin.global_position.y > station.global_position.y
		if tile.state != TILE.State.Intact and triggered_at < 0.0:
			triggered_at = float(Engine.get_physics_frames() - starting_frame) / float(Engine.physics_ticks_per_second)
			expect(
				(
					Vector2(skeleton.drop_pivot.global_position.x, skeleton.drop_pivot.global_position.z).distance_to(
						tile_xz
					)
					< 0.6
				),
				"The skeleton reaches the cracked tile before activating it."
			)
			expect(is_equal_approx(tile.global_position.y, 2.0), "The tile is actually elevated to 2m at activation.")
		if tile.state == TILE.State.Collapsed:
			collapsed = true
			break
	expect(
		triggered_at >= 4.0 and triggered_at <= 8.0, "The skeleton triggers the tile within eight seconds of starting."
	)
	expect(collapsed, "The skeleton completes the raised tile's collapse without player contact.")
	expect(coins_rested_on_tile, "The coins visibly rest on the raised tile before the skeleton arrives.")
	expect(not tile._support.body.is_valid(), "Collapse opens the actual supporting physics geometry.")
	for frame in 60:
		await tree.physics_frame
		await tree.process_frame
	expect(
		skeleton.path_follow.global_position.y < tile.global_position.y - 1.0,
		"The skeleton falls at least a metre into the opening after the raised tile collapses."
	)
	expect(
		(
			Vector2(skeleton.path_follow.global_position.x, skeleton.path_follow.global_position.z).distance_to(tile_xz)
			< 0.6
		),
		"The skeleton falls into the opening instead of continuing its patrol across the gap."
	)
	expect(
		skeleton.skeleton_body.global_position.is_equal_approx(skeleton.drop_pivot.global_position),
		"The skeleton's blocking body follows its visible carrier into the hole."
	)
	for coin in coins:
		expect(
			not is_instance_valid(coin) or coin.global_position.y < tile.global_position.y - 1.0,
			"Each demonstration coin falls through the opening after the floor collapses."
		)
	level.free()
	await tree.process_frame
	await tree.process_frame


func _test_spawn_camera(tree: SceneTree, landing: Vector3, tile_position: Vector3) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.own_world_3d = true
	var target := Node3D.new()
	target.name = "Player"
	target.position = landing
	viewport.add_child(target)
	var camera := GDFollowCamera.new()
	viewport.add_child(camera)
	tree.root.add_child(viewport)
	camera.set_physics_process(false)
	var visible_area := Rect2(Vector2.ZERO, Vector2(viewport.size)).grow(-80.0)
	for point in [tile_position, tile_position + Vector3.UP * 0.85]:
		expect(
			not camera.is_position_behind(point) and visible_area.has_point(camera.unproject_position(point)),
			"The raised tile and skeleton's head fit inside the default spawn camera with a visible margin."
		)
	viewport.free()
