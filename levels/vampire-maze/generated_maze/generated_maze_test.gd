extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_maze.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_maze.gd"
const SUBJECT_SCENE := preload(
	"res://levels/vampire-maze/generated_maze/generated_maze.tscn"
)
const FloorRoute := preload(
	"res://levels/vampire-maze/generated_maze/generated_floor_route.gd"
)


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var generated_maze := SUBJECT_SCENE.instantiate() as Node3D
	expect(
		(generated_maze.get("vampire_path") as NodePath).is_empty(),
		"Reusable generated mazes do not point at an optional missing Vampire node."
	)
	tree.root.add_child(generated_maze)
	generated_maze.set(
		"configuration",
		(generated_maze.get("configuration") as Resource).duplicate(true)
	)
	var configuration := generated_maze.get("configuration") as Resource
	generated_maze.set("floor_tile_route_destination", FloorRoute.Destination.GateKey)
	generated_maze.set("floor_tile_route_percent", 30.0)
	var key_result := generated_maze.call(
		"generate_from_config",
		configuration,
		1730
	) as Dictionary
	var key_route := key_result.get("floor_tile_route", []) as Array
	var key_route_band := key_result.get("floor_tile_route_band", []) as Array
	var routed_cells := key_result.get("routed_floor_cells", []) as Array
	var layout := generated_maze.get_node("Layout") as Node3D
	var wall_grid_map := layout.get_node("PNGGridMap") as GridMap
	var road_item_id := wall_grid_map.mesh_library.find_item_by_name("Road")
	var road_cells := wall_grid_map.get_used_cells_by_item(road_item_id)
	var routed_cells_use_authored_road_mesh := road_cells.size() == routed_cells.size()
	var road_mesh_bottom_world_y := -INF
	for routed_cell_value in road_cells:
		var routed_cell := routed_cell_value as Vector3i
		var routed_item_id := wall_grid_map.get_cell_item(routed_cell)
		if wall_grid_map.mesh_library.get_item_name(routed_item_id) != "Road":
			routed_cells_use_authored_road_mesh = false
			break
		var road_mesh := wall_grid_map.mesh_library.get_item_mesh(routed_item_id)
		if road_mesh != null:
			road_mesh_bottom_world_y = wall_grid_map.position.y \
				+ road_mesh.get_aabb().position.y
	var wall_repair_settings := configuration.get("wall_repair_settings") as Resource
	var wall_mapping := wall_repair_settings.get("color_mappings")[0] as Resource
	var wall_rotation_offsets_are_current := int(wall_mapping.get("end_rotation_offset")) == 0 \
		and int(wall_mapping.get("corner_rotation_offset")) == 1 \
		and int(wall_mapping.get("tee_rotation_offset")) == 0
	var gold_key_cell := Vector2i(-1, -1)
	var content_plan := key_result.get("content_plan", {}) as Dictionary
	for key_value in content_plan.get("keys", []):
		var key := key_value as Dictionary
		if key.get("item_type") == &"key":
			gold_key_cell = key.get("cell") as Vector2i
			break
	var structural_floor_grid_map := layout.get_node("PNGFloorGridMap") as GridMap
	var generated_content := layout.get_node("GeneratedContent")
	var generated_grass := generated_content.get_node_or_null("GeneratedGrass") \
		as MultiMeshInstance3D
	var grass_result := content_plan.get("grass", {}) as Dictionary
	var grass_cells := grass_result.get("cells", []) as Array
	var grass_avoids_main_route := true
	for main_path_cell_value in content_plan.get("main_path", []):
		if grass_cells.has(main_path_cell_value as Vector2i):
			grass_avoids_main_route = false
			break
	var generated_gold_key := generated_content.get_node_or_null("GeneratedGoldKey01") \
		as Node3D
	var generated_gold_key_model := generated_gold_key.get_node_or_null(^"KeyModel") \
		as Node3D if generated_gold_key != null else null
	var expected_key_position := structural_floor_grid_map.to_global(
		structural_floor_grid_map.map_to_local(
			Vector3i(gold_key_cell.x, 0, gold_key_cell.y)
		)
	) + Vector3.UP * 0.08
	var has_road_beside_centreline := false
	for routed_cell_value in routed_cells:
		if not key_route.has(routed_cell_value as Vector2i):
			has_road_beside_centreline = true
			break
	expect(
		not key_route.is_empty() \
			and key_route[-1] == gold_key_cell \
			and key_route_band.size() > key_route.size() \
			and not routed_cells.is_empty() \
			and routed_cells.size() < key_route_band.size() \
			and routed_cells.has(gold_key_cell) \
			and has_road_beside_centreline \
			and road_cells.size() == routed_cells.size() \
			and routed_cells_use_authored_road_mesh \
			and road_mesh_bottom_world_y < 0.0 \
			and road_mesh_bottom_world_y > -0.02 \
			and generated_gold_key != null \
			and generated_gold_key.global_position.is_equal_approx(expected_key_position) \
			and generated_gold_key_model != null \
			and generated_gold_key_model.scale.is_equal_approx(
				Vector3.ONE * 0.08
			) \
			and generated_gold_key.get_node_or_null(^"EditorGateKeyMarker") == null \
			and generated_grass != null \
			and generated_grass.scene_file_path.is_empty() \
			and generated_grass.multimesh.instance_count \
				== int(grass_result.get("instance_count", 0)) \
			and generated_grass.multimesh.instance_count > 0 \
			and generated_grass.multimesh.buffer.size() \
				== generated_grass.multimesh.instance_count * 12 \
			and grass_avoids_main_route,
		"GeneratedMaze places persistent visible grass and Level 1-style Road cells in its wall GridMap."
	)
	expect(
		int(generated_maze.get("floor_tile_route_destination")) \
			== FloorRoute.Destination.GateKey \
			and is_equal_approx(
				float(generated_maze.get("floor_tile_route_percent")),
				30.0
			),
		"GeneratedMaze exposes its route target and density directly in the Inspector."
	)
	expect(
		wall_rotation_offsets_are_current,
		"GeneratedMaze uses the corrected directional rotations for Graveyard wall meshes."
	)

	generated_maze.set("floor_tile_route_destination", FloorRoute.Destination.Gate)
	var layout_instance_id_before_seed_change := layout.get_instance_id()
	var walls_before_seed_change := wall_grid_map.get_used_cells()
	walls_before_seed_change.sort()
	var generated_seeds: Array[int] = []
	var generation_results: Array[Dictionary] = []
	generated_maze.connect(
		&"maze_generated",
		func(seed_value: int, result: Dictionary) -> void:
			generated_seeds.append(seed_value)
			generation_results.append(result)
	)
	generated_maze.set("_generation_queued", false)
	generated_maze.set("maze_seed", 1731)
	var seed_change_queued := bool(generated_maze.get("_generation_queued"))
	generated_maze.set("_last_regeneration_request_milliseconds", 0)
	generated_maze.call("_run_queued_regeneration")
	var rebuilt_layout := generated_maze.get_node("Layout") as Node3D
	var rebuilt_wall_grid_map := rebuilt_layout.get_node("PNGGridMap") as GridMap
	var walls_after_seed_change := rebuilt_wall_grid_map.get_used_cells()
	walls_after_seed_change.sort()
	var gate_result := generation_results[0] if not generation_results.is_empty() else {}
	var gate_route := gate_result.get("floor_tile_route", []) as Array
	var gate_cell_3d := gate_result.get("end_gate_cell", Vector3i(-1, 0, -1)) as Vector3i
	expect(
		seed_change_queued \
			and rebuilt_layout.get_instance_id() != layout_instance_id_before_seed_change \
			and rebuilt_layout.has_node("PNGGridMap") \
			and rebuilt_layout.has_node("PNGFloorGridMap") \
			and not rebuilt_layout.has_node("RoutedFloorGridMap") \
			and rebuilt_layout.has_node("GeneratedContent") \
			and generated_seeds == ([1731] as Array[int]) \
			and walls_before_seed_change != walls_after_seed_change \
			and not gate_route.is_empty() \
			and gate_route[-1] == Vector2i(gate_cell_3d.x, gate_cell_3d.z),
		"Changing GeneratedMaze parameters replaces one complete inspectable Layout."
	)
	generated_maze.free()
