extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/editor/floor_surface_gridmap_paint.gd")

enum Item { Fence, Wall }


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/editor/floor_surface_gridmap_paint.gd")
	_test_slopes_and_existing_cells()
	_test_holes_manual_layers_and_invalid_transforms()
	_test_erase_and_vertical_limits()
	_test_repainting_saved_fence()
	_test_real_fence_footprint_and_rotation()
	_test_lower_support_inside_a_wide_footprint()
	_test_floor_reflow_holes_and_occupied_heights()


func _fixture() -> Node3D:
	var root := Node3D.new()
	var surface := FloorSurface.new()
	surface.name = "Floor"
	surface.floor_map = FloorMap.new()
	surface.floor_map.dimensions = Vector2i(5, 3)
	surface.floor_map.default_present = true
	surface.elevation_profile = FloorElevationProfile.new()
	for z in range(3):
		surface.floor_map.set_cell_elevation(Vector2i(4, z), 4)
		for x in range(1, 4):
			surface.floor_map.set_cell_transition(Vector2i(x, z), FloorMap.Transition.Ramp, FloorMap.LowEdge.West)
	root.add_child(surface)
	var grid := GridMap.new()
	grid.name = "Grid"
	grid.cell_size = Vector3(1, 0.01, 1)
	grid.cell_center_y = false
	root.add_child(grid)
	return root


func _test_slopes_and_existing_cells() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	grid.set_cell_item(Vector3i(4, 0, 0), Item.Wall)
	var before := SUBJECT.snapshot(grid)
	var floor_before := surface.floor_map.get_shape_snapshot()
	var elevations_before := surface.floor_map.get_elevation_snapshot()
	var facing := grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, PI * 0.5))
	for x in range(1, 4):
		grid.set_cell_item(Vector3i(x, 0, 0), Item.Fence, facing)
	var result := SUBJECT.plan(grid, surface, before, 0)
	var changes := result["changes"] as Array[Dictionary]
	expect((result["errors"] as Array[String]).is_empty(), "A valid multi-cell slope can be grounded.")
	expect_equal(changes.size(), 2, "Only newly brushed cells above their lowest support are adjusted.")
	var targets: Array[int] = []
	for change in changes:
		var target := change["target"] as Vector3i
		targets.append(target.y)
		expect_equal(
			change["painted"], Vector2i(Item.Fence, facing), "Grounding preserves the selected piece and heading."
		)
		expect_equal(
			target.x, (change["source"] as Vector3i).x, "Grounding preserves the painted horizontal coordinate."
		)
	targets.sort()
	expect_equal(
		targets, [33, 66] as Array[int], "Pieces anchor to the lower slope edge and round downward to grid precision."
	)
	expect_equal(
		grid.get_cell_item(Vector3i(4, 0, 0)), Item.Wall, "Planning never moves an existing manually placed wall."
	)
	expect_equal(surface.floor_map.get_shape_snapshot(), floor_before, "Grounding never changes floor occupancy.")
	expect_equal(
		surface.floor_map.get_elevation_snapshot(), elevations_before, "Grounding never changes authored heights."
	)
	root.free()


func _test_holes_manual_layers_and_invalid_transforms() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	surface.floor_map.set_floor_present(Vector2i.ZERO, false)
	grid.set_cell_item(Vector3i.ZERO, Item.Fence)
	grid.set_cell_item(Vector3i(1, 12, 0), Item.Fence)
	var empty: Dictionary[Vector3i, Vector2i] = {}
	var result := SUBJECT.plan(grid, surface, empty, 0)
	expect((result["changes"] as Array).is_empty(), "Holes and manual height layers remain untouched.")
	expect_equal(
		(result["errors"] as Array[String]).size(), 1, "Missing floor reports why the piece cannot be grounded."
	)
	grid.rotation.y = 0.3
	result = SUBJECT.plan(grid, surface, empty, 0)
	expect((result["changes"] as Array).is_empty(), "Rotated placement grids are rejected without changing cells.")
	expect(
		not (result["errors"] as Array[String]).is_empty(), "An unsupported grid transform has actionable diagnostics."
	)
	grid.rotation = Vector3.ZERO
	root.position.y = 2
	result = SUBJECT.plan(grid, surface, empty, 0)
	expect((result["changes"] as Array).is_empty(), "Unsupported ancestor transforms are also rejected off-tree.")
	expect(
		not (result["errors"] as Array[String]).is_empty(), "An offset floor is reported rather than mis-sampling it."
	)
	root.free()


func _test_erase_and_vertical_limits() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	var target := Vector3i(2, 50, 0)
	grid.set_cell_item(target, Item.Fence)
	var before := SUBJECT.snapshot(grid)
	var result := SUBJECT.plan(grid, surface, before, 0, [Vector3i(2, 0, 0)])
	var changes := result["changes"] as Array[Dictionary]
	expect_equal(changes.size(), 1, "Erasing a native base-layer cell also finds the grounded fence.")
	expect_equal(changes[0]["target"], target, "The eraser targets the actual slope height.")
	expect_equal(
		(changes[0]["painted"] as Vector2i).x, GridMap.INVALID_CELL_ITEM, "The correction removes the raised item."
	)
	surface.floor_map.set_cell_elevation(Vector2i(4, 0), 10000)
	grid.set_cell_item(Vector3i(4, 0, 0), Item.Wall)
	result = SUBJECT.plan(grid, surface, before, 0)
	expect((result["changes"] as Array).is_empty(), "Out-of-range height never wraps a native GridMap coordinate.")
	expect(not (result["errors"] as Array[String]).is_empty(), "Excessive height is reported to the editor.")
	root.free()


func _test_repainting_saved_fence() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	var source := Vector3i(2, 0, 0)
	grid.set_cell_item(source, Item.Fence)
	var before := SUBJECT.snapshot(grid)
	var result := SUBJECT.plan(grid, surface, before, 0, [source])
	var changes := result["changes"] as Array[Dictionary]
	expect_equal(changes.size(), 1, "Repainting an unchanged legacy fence still requests grounding.")
	expect_equal(
		changes[0]["source_before"], Vector2i(Item.Fence, 0), "Repaint undo retains the old fixed-height fence."
	)
	root.free()


func _test_real_fence_footprint_and_rotation() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	# Read the production mesh and its authored origin; the binary library stays unchanged.
	var library := load("res://Assets/environment/graveyard.res") as MeshLibrary
	grid.mesh_library = library
	var fence_id := GridMap.INVALID_CELL_ITEM
	for item in library.get_item_list():
		if library.get_item_name(item) == "Fence":
			fence_id = item
	if not expect(fence_id != GridMap.INVALID_CELL_ITEM, "The production library exposes its fence mesh."):
		root.free()
		return
	var mesh := library.get_item_mesh(fence_id)
	var mesh_transform := library.get_item_mesh_transform(fence_id)
	var source := Vector3i(2, 0, 1)
	var empty: Dictionary[Vector3i, Vector2i] = {}
	var orientations: Array[int] = [
		grid.get_orthogonal_index_from_basis(Basis.IDENTITY),
		grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, PI * 0.5)),
	]
	var anchor_heights: Array[int] = []
	for orientation in orientations:
		grid.clear()
		grid.set_cell_item(source, fence_id, orientation)
		var result := SUBJECT.plan(grid, surface, empty, 0)
		var changes := result["changes"] as Array[Dictionary]
		if not expect(changes.size() == 1, "The authored fence has a grounded placement in each heading."):
			continue
		var target := changes[0]["target"] as Vector3i
		anchor_heights.append(target.y)
		var rotation := grid.get_basis_with_orthogonal_index(orientation)
		var bounds := (Transform3D(rotation, Vector3.ZERO) * mesh_transform) * mesh.get_aabb()
		var centre := grid.map_to_local(target)
		var base_height := centre.y + bounds.position.y
		var lowest := INF
		for x in [bounds.position.x, bounds.end.x]:
			for z in [bounds.position.z, bounds.end.z]:
				var support := surface.sample_surface(Vector3(centre.x + x, 0, centre.z + z))
				expect(support.valid, "The production fence's footprint has floor support.")
				lowest = minf(lowest, support.world_height)
				expect(
					base_height <= support.world_height + 0.000001,
					"No part of the fence base floats over its slope support."
				)
		expect(
			base_height >= lowest - grid.cell_size.y - 0.000001,
			"The fence seats within one downward grid step of the lowest supporting point."
		)
	expect(
		anchor_heights[0] != anchor_heights[1],
		"Rotating a narrow fence changes which part of the slope supports its base."
	)
	root.free()


func _test_lower_support_inside_a_wide_footprint() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	surface.floor_map.default_elevation = 4
	for cell in surface.floor_map.get_present_cells():
		surface.floor_map.set_cell_transition(cell, FloorMap.Transition.Flat)
	surface.floor_map.set_cell_elevation(Vector2i(2, 1), -4)
	var library := MeshLibrary.new()
	library.create_item(Item.Fence)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3, 1, 0.2)
	library.set_item_mesh(Item.Fence, mesh)
	library.set_item_mesh_transform(Item.Fence, Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 0)))
	grid.mesh_library = library
	var source := Vector3i(2, 0, 1)
	grid.set_cell_item(source, Item.Fence)
	var empty: Dictionary[Vector3i, Vector2i] = {}
	var result := SUBJECT.plan(grid, surface, empty, 0)
	var changes := result["changes"] as Array[Dictionary]
	expect_equal(changes.size(), 1, "A wide item can anchor across multiple supporting floor cells.")
	expect_equal(
		changes[0]["target"],
		Vector3i(2, -100, 1),
		"A lower floor inside the footprint anchors the base even when its outer corners are higher."
	)
	root.free()


func _test_floor_reflow_holes_and_occupied_heights() -> void:
	var root := _fixture()
	var grid := root.get_node(^"Grid") as GridMap
	var surface := root.get_node(^"Floor") as FloorSurface
	var source := Vector3i(2, 33, 0)
	var occupied := Vector3i(2, 133, 0)
	grid.set_cell_item(source, Item.Fence)
	grid.set_cell_item(occupied, Item.Wall)
	var previous := SUBJECT.capture_surface(surface)
	var before_cells := SUBJECT.snapshot(grid)
	var elevations := surface.floor_map.get_elevation_snapshot()
	surface.floor_map.default_elevation += 4
	for cell in elevations:
		elevations[cell] += 4
	surface.floor_map.apply_elevation_snapshot(elevations)
	var result := SUBJECT.plan_floor_change(grid, previous, surface)
	expect(
		(result["changes"] as Array).is_empty(), "A manually occupied destination blocks automatic height adjustment."
	)
	expect(not (result["errors"] as Array[String]).is_empty(), "A blocked scenery height is reported.")
	expect_equal(SUBJECT.snapshot(grid), before_cells, "Planning never overwrites or drops either piece.")
	surface.floor_map.set_floor_present(Vector2i(2, 0), false)
	result = SUBJECT.plan_floor_change(grid, previous, surface)
	expect(
		(result["changes"] as Array).is_empty(), "Removing the supporting floor leaves scenery at its authored height."
	)
	expect(not (result["errors"] as Array[String]).is_empty(), "A piece over a new hole is reported.")
	expect(previous.has_floor(Vector2i(2, 0)), "The previous floor snapshot stays detached from live shape edits.")
	previous.free()
	root.free()
