extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/close-escape/level.tscn")
const REFERENCE := preload("res://levels/1/level.tscn")
const FLOOR_REFERENCE := preload("res://levels/tutorial-1/level.tscn")


func run(_tree: SceneTree) -> void:
	_check_editor_access()
	var level := LEVEL.instantiate() as Node3D
	var reference := REFERENCE.instantiate() as Node3D
	var layout := level.get_node(^"AuthoredLayout") as Node3D
	var walls := layout.get_node(^"WallGridMap") as GridMap
	var floor_grid := level.get_node(^"FloorGridMap") as GridMap
	var reference_floor := (
		reference.get_node(^"Tiled Floor/StaticBody3D/MeshInstance3D") as MeshInstance3D
	)
	var reference_material := reference_floor.get_surface_override_material(0) as ShaderMaterial
	var floor_reference := FLOOR_REFERENCE.instantiate() as Node3D
	var tutorial_grid := floor_reference.get_node(^"Layout/PNGFloorGridMap") as GridMap
	var floor_material := (
		floor_grid.mesh_library.get_item_mesh(0).surface_get_material(0) as StandardMaterial3D
	)
	expect(
		floor_material.albedo_texture == reference_material.get_shader_parameter(&"tiled_texture"),
		"The floor grid uses Level 1's dirt texture."
	)
	expect(
		(
			floor_grid.get_used_cells().size() == 35 * 29
			and floor_grid.collision_layer == tutorial_grid.collision_layer
			and floor_grid.cell_size == tutorial_grid.cell_size
			and floor_grid.cell_center_y == tutorial_grid.cell_center_y
			and floor_grid.transform == walls.transform
			and level.get_node_or_null(^"Floor") == null
		),
		"Tutorial-style floor tiles cover the level with no separate slab underneath."
	)
	_check_floor_phases(floor_grid, tutorial_grid)
	# Navigation currently selects the first covering grid, so keep the wall grid first.
	expect(
		layout.get_index() < floor_grid.get_index(),
		"The floor does not take precedence over the zombie wall grid."
	)
	var wall_count := 0
	var road_count := 0
	var roads_are_flat := true
	for cell in walls.get_used_cells():
		var item := walls.get_cell_item(cell)
		if walls.mesh_library.get_item_name(item) == "Road":
			road_count += 1
			var basis := walls.get_basis_with_orthogonal_index(
				walls.get_cell_item_orientation(cell)
			)
			roads_are_flat = roads_are_flat and basis.y.is_equal_approx(Vector3.UP)
			roads_are_flat = roads_are_flat and walls.mesh_library.get_item_shapes(item).is_empty()
		else:
			wall_count += 1
	expect(
		wall_count == 297, "All 297 authored wall cells remain; paving does not replace barriers."
	)
	expect(
		road_count >= 100 and road_count < 180 and roads_are_flat,
		"Roads are sparse, upright, non-colliding accents, not blanket paving."
	)
	var grass := level.get_node(^"PaintedGrass") as Node3D
	var reference_grass := reference.get_node(^"SimpleGrassTextured") as MultiMeshInstance3D
	var total := 0
	var matching_technique := true
	var clear_placements := true
	var occupied_cells: Dictionary[Vector3i, bool] = {}
	var serialized_buffers := _read_painted_buffers()
	for child in grass.get_children():
		var patch := child as MultiMeshInstance3D
		matching_technique = (
			matching_technique and patch.get_script() == reference_grass.get_script()
		)
		matching_technique = (
			matching_technique and patch.multimesh.mesh == reference_grass.multimesh.mesh
		)
		var texture := patch.get(&"texture_albedo") as GradientTexture2D
		var reference_texture := reference_grass.get(&"texture_albedo") as GradientTexture2D
		matching_technique = (
			matching_technique and texture.gradient.colors == reference_texture.gradient.colors
		)
		total += patch.multimesh.instance_count
		# The dummy renderer discards MultiMesh transforms. Validate the authored
		# buffer directly so the same placement checks also run in headless CI.
		var buffer := serialized_buffers[patch.name] as PackedFloat32Array
		expect(
			buffer.size() == patch.multimesh.instance_count * 12,
			"%s has a complete painted transform buffer." % patch.name
		)
		for index in patch.multimesh.instance_count:
			var offset := index * 12
			var point := Vector3(buffer[offset + 3], buffer[offset + 7], buffer[offset + 11])
			var cell := walls.local_to_map(point - walls.position)
			occupied_cells[cell] = true
			clear_placements = (
				clear_placements and walls.get_cell_item(cell) == GridMap.INVALID_CELL_ITEM
			)
			clear_placements = clear_placements and _keeps_objectives_clear(level, point)
	expect(
		matching_technique and grass.get_child_count() == 4,
		"Grass uses Level 1's paintable MultiMesh, mesh and gradient in four editable groups."
	)
	expect(
		total > 350 and total < 650 and occupied_cells.size() < 120,
		"Grass forms local pockets with broad areas of exposed dirt."
	)
	expect(
		clear_placements,
		"Painted grass stays off road and wall cells and leaves hazards, rewards and doorways visible."
	)
	expect(
		(grass.get_node(^"VaultSeamTufts") as MultiMeshInstance3D).multimesh.instance_count < 25,
		"The spike vault remains deliberately bare."
	)
	for hazard in level.get_node(^"Hazards").get_children():
		if not String(hazard.name).contains("Spike"):
			continue
		var point := (hazard as Node3D).position
		var cell := walls.local_to_map(point - walls.position)
		expect(
			walls.get_cell_item(cell) == GridMap.INVALID_CELL_ITEM,
			"Road stones do not cover %s." % hazard.name
		)
	level.free()
	reference.free()
	floor_reference.free()


func _check_editor_access() -> void:
	# Use the same instance edit state as the editor, not just a runtime load.
	var editable_level := LEVEL.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE) as Node3D
	var layout := editable_level.get_node(^"AuthoredLayout") as Node3D
	var floor_grid := editable_level.get_node(^"FloorGridMap") as GridMap
	expect(
		editable_level.is_editable_instance(layout)
		and floor_grid.owner == editable_level
		and floor_grid.get_parent() == editable_level
		and floor_grid.visible
		and layout.visible
		and floor_grid.get_used_cells().size() == 35 * 29,
		"The populated floor GridMap is owned directly by the main level, not a nested scene."
	)
	expect(
		editable_level.is_editable_instance(editable_level.get_node(^"PaintedGrass")),
		"Grass paint groups are also exposed in the main level editor."
	)
	editable_level.free()


func _check_floor_phases(floor_grid: GridMap, tutorial_grid: GridMap) -> void:
	var library := floor_grid.mesh_library
	expect(
		library.get_item_list().size() == 4, "Floor library has Tutorial 1's four texture phases."
	)
	for item in library.get_item_list():
		var material := library.get_item_mesh(item).surface_get_material(0) as StandardMaterial3D
		var reference_mesh := tutorial_grid.mesh_library.get_item_mesh(item) as PlaneMesh
		var reference_material := reference_mesh.material as StandardMaterial3D
		var shapes := library.get_item_shapes(item)
		expect(
			(
				material.albedo_texture == reference_material.albedo_texture
				and material.uv1_scale == reference_material.uv1_scale
				and material.uv1_offset == reference_material.uv1_offset
				and (library.get_item_mesh(item) as PlaneMesh).size == reference_mesh.size
				and shapes.size() == 2
				and (shapes[0] as BoxShape3D).size == Vector3(1, 0.5, 1)
				and (shapes[1] as Transform3D).origin == Vector3(0, -0.25, 0)
			),
			"Floor phase %d matches Tutorial 1's UVs and flush tile collision." % item
		)
	var phases_match := true
	for cell in floor_grid.get_used_cells():
		phases_match = (
			phases_match
			and floor_grid.get_cell_item(cell) == posmod(cell.x, 2) + posmod(cell.z, 2) * 2
		)
	expect(phases_match, "Floor texture phases alternate continuously across cell edges.")


func _read_painted_buffers() -> Dictionary:
	var result: Dictionary = {}
	var resource_id := ""
	var source := FileAccess.get_file_as_string("res://levels/close-escape/painted_grass.tscn")
	for line in source.split("\n"):
		if line.begins_with('[sub_resource type="MultiMesh"'):
			resource_id = line.get_slice('id="', 1).get_slice('"', 0)
		elif line.begins_with("buffer = PackedFloat32Array("):
			var values := line.trim_prefix("buffer = PackedFloat32Array(").trim_suffix(")").split(
				","
			)
			var buffer := PackedFloat32Array()
			for value in values:
				buffer.append(float(value))
			result[StringName(resource_id)] = buffer
	return result


func _keeps_objectives_clear(level: Node3D, point: Vector3) -> bool:
	for group_path in [^"Progression", ^"Hazards", ^"Treasure", ^"Deposits", ^"Supplies"]:
		for child in level.get_node(group_path).get_children():
			var objective := child as Node3D
			var distance := Vector2(point.x, point.z).distance_to(
				Vector2(objective.position.x, objective.position.z)
			)
			var clearance := 1.0
			if String(objective.name).contains("Spike"):
				clearance = 1.3
			elif String(objective.name).contains("Door") or objective.name == &"FinalGate":
				clearance = 1.35
			if distance < clearance:
				return false
	return true
