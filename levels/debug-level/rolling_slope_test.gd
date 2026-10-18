extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/debug-level/level.tscn")
const TILE := preload("res://placeables/traps/crumbling_floor/crumbling_floor.gd")


func run(tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var surface := level.get_node(^"FloorSurface") as FloorSurface
	var grid := level.get_node(^"PNGGridMap") as GridMap
	var station := level.get_node(^"Objects/RollingSlope") as Node3D
	_test_layout(surface, grid, station)
	# Exercise the authored level geometry and instances without unrelated debug enemies,
	# pickups, boundary or player. No scene resources or imported assets are rewritten.
	for child in level.get_children():
		if child.name not in [&"FloorSurface", &"PNGGridMap", &"Objects"]:
			child.free()
	for child in level.get_node(^"Objects").get_children():
		if child != station:
			child.free()
	var boulder := station.get_node(^"Boulder") as RollingRock
	var millstone := station.get_node(^"Millstone") as Millstone
	var stones: Array[RollingRock] = [boulder, millstone]
	for stone in stones:
		# Retain production physics, avoiding native audio queues in the headless driver.
		stone.get_node(^"RollingRockAudio").free()
	tree.root.add_child(level)
	await _frames(tree, 8)
	expect(not boulder.axis_lock_linear_y, "The demo boulder is free to descend with gravity.")
	expect(not millstone.axis_lock_linear_y, "The demo millstone is free to descend with gravity.")
	var initial_visuals: Array[Transform3D] = []
	for stone in stones:
		initial_visuals.append(stone.visual_rock.transform)
	var peak_speeds: Array[float] = [0.0, 0.0]
	var descended: Array[bool] = [false, false]
	var reached_landing: Array[bool] = [false, false]
	var fell: Array[bool] = [false, false]
	for frame in 360:
		for stone in stones:
			# Simulate the normal character push only on the flat pad. Once the
			# stone reaches the slope it must continue using gravity alone.
			if stone.position.x >= 107.5:
				stone.push_from_character(Vector3.LEFT, Vector3.RIGHT, 1.0 / Engine.physics_ticks_per_second)
		await _frames(tree, 1)
		for index in stones.size():
			var stone := stones[index]
			if stone.position.x > 101.5 and stone.position.x < 107.5:
				peak_speeds[index] = maxf(peak_speeds[index], -stone.linear_velocity.x)
				descended[index] = descended[index] or stone.position.y < 1.0
			reached_landing[index] = reached_landing[index] or stone.position.x < 101.5
			fell[index] = fell[index] or stone.position.y < -0.5
	for index in stones.size():
		var label := String(stones[index].name)
		expect(peak_speeds[index] > 1.5, label + " accelerates downhill after the initial shove.")
		expect(descended[index], label + " follows the actual sloping floor downward.")
		expect(reached_landing[index], label + " reaches the lower landing.")
		expect(fell[index], label + " falls through the collapsing landing.")
		expect(stones[index].visual_rock.transform != initial_visuals[index], label + " visibly rotates while rolling.")
		var triggered := false
		for child in station.get_node(^"CrumblingLanding").get_children():
			var tile := child as TILE
			if is_equal_approx(tile.position.z, -5.0 + index):
				triggered = triggered or tile.state != TILE.State.Intact
		expect(triggered, label + " triggers crumbling floor in its own lane.")
	level.queue_free()
	await tree.process_frame
	await tree.process_frame


func _test_layout(surface: FloorSurface, grid: GridMap, station: Node3D) -> void:
	expect_equal(surface.validate_configuration(), [] as Array[String], "The authored slopes resolve without errors.")
	for z in [-5, -4]:
		for x in range(102, 108):
			var cell := surface.world_to_cell(Vector3(x, 0.0, z))
			expect_equal(surface.floor_map.get_cell_transition(cell), FloorMap.Transition.Ramp, "Both lanes use ramps.")
			expect_equal(surface.floor_map.get_cell_low_edge(cell), FloorMap.LowEdge.West, "Both lanes descend west.")
			expect_equal(
				grid.get_cell_item(Vector3i(cell.x, 0, cell.y)),
				GridMap.INVALID_CELL_ITEM,
				"The slope is clear of GridMap obstacles."
			)
			expect(
				is_equal_approx(surface.sample_surface(Vector3(x, 0.0, z)).world_height, (x - 101.5) * 0.25),
				"Ramp height is continuous along both lanes."
			)
		for x in [99, 100]:
			expect(
				not surface.has_floor(surface.world_to_cell(Vector3(x, 0.0, z))),
				"No ordinary floor supports the crumbling landing."
			)
		var landing_cell := surface.world_to_cell(Vector3(101, 0.0, z))
		expect_equal(
			surface.floor_map.get_cell_transition(landing_cell),
			FloorMap.Transition.Flat,
			"A flat apron joins the ramp to the crumbling floor."
		)
	for x in [110, 111]:
		for z in [-3, -2, -1]:
			var cell := surface.world_to_cell(Vector3(x, 0.0, z))
			expect_equal(
				surface.floor_map.get_cell_low_edge(cell),
				FloorMap.LowEdge.South,
				"The side approach climbs from the main corridor."
			)
	expect_equal(
		station.get_node(^"CrumblingLanding").get_child_count(), 4, "Four crumbling tiles fill the two-wide landing."
	)
	for child in station.get_node(^"CrumblingLanding").get_children():
		var tile := child as TILE
		expect(
			tile.floor_surface == surface and tile.floor_grid_map == grid,
			"Landing tiles retain their authoring references."
		)
	var millstone := station.get_node(^"Millstone") as Millstone
	expect(
		absf(millstone._get_world_roll_direction().dot(Vector3.LEFT)) > 0.99,
		"The millstone rolls along the slope axis."
	)


func _frames(tree: SceneTree, count: int) -> void:
	for frame in count:
		await tree.physics_frame
		await tree.process_frame
