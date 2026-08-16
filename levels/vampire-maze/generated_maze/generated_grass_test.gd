extends "res://tests/test_case.gd"

const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_grass.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_grass.gd"
const SUBJECT_SCENE := preload(
	"res://levels/vampire-maze/generated_maze/generated_grass.tscn"
)


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var holder := Node3D.new()
	var floor_grid_map := GridMap.new()
	var floor_mesh_library := MeshLibrary.new()
	floor_mesh_library.create_item(0)
	floor_grid_map.mesh_library = floor_mesh_library
	var grass := SUBJECT_SCENE.instantiate() as MultiMeshInstance3D
	holder.add_child(floor_grid_map)
	holder.add_child(grass)
	grass.scene_file_path = ""
	floor_grid_map.owner = holder
	grass.owner = holder
	tree.root.add_child(holder)
	var floor_cells := {}
	for z_coordinate in 12:
		for x_coordinate in 12:
			floor_cells[Vector2i(x_coordinate, z_coordinate)] = true
			floor_grid_map.set_cell_item(Vector3i(x_coordinate, 0, z_coordinate), 0)
	# A logical floor entry without a corresponding floor tile must never
	# receive grass.
	floor_grid_map.set_cell_item(Vector3i(11, 0, 11), GridMap.INVALID_CELL_ITEM)
	var excluded_cells := {
		Vector2i(5, 5): true,
		Vector2i(6, 5): true,
	}
	var first_result := grass.call(
		&"populate",
		floor_cells,
		floor_grid_map,
		excluded_cells,
		4107,
		25.0,
		4.5,
		3
	) as Dictionary
	var first_cells := first_result.get("cells", []) as Array
	var first_blade_counts := first_result.get("blade_counts", {}) as Dictionary
	var cells_with_selected_neighbours := 0
	for cell_value in first_cells:
		var cell := cell_value as Vector2i
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if first_cells.has(cell + direction):
				cells_with_selected_neighbours += 1
				break
	var first_buffer := grass.multimesh.buffer.duplicate()
	var repeated_result := grass.call(
		&"populate",
		floor_cells,
		floor_grid_map,
		excluded_cells,
		4107,
		25.0,
		4.5,
		3
	) as Dictionary
	var repeated_buffer := grass.multimesh.buffer.duplicate()
	var changed_result := grass.call(
		&"populate",
		floor_cells,
		floor_grid_map,
		excluded_cells,
		4108,
		25.0,
		4.5,
		3
	) as Dictionary
	var material := grass.material_override as ShaderMaterial
	expect(
		(first_result.get("errors", []) as Array).is_empty() \
			and first_cells.size() == 35 \
			and cells_with_selected_neighbours >= 30 \
			and not first_cells.has(Vector2i(5, 5)) \
			and not first_cells.has(Vector2i(6, 5)) \
			and not first_cells.has(Vector2i(11, 11)) \
			and first_blade_counts.values().min() == 1 \
			and first_blade_counts.values().max() == 3 \
			and int(first_result.get("instance_count", 0)) > first_cells.size() \
			and int(first_result.get("instance_count", 0)) < first_cells.size() * 3 \
			and first_buffer.size() \
				== int(first_result.get("instance_count", 0)) * 12 \
			and repeated_result.get("cells", []) == first_cells \
			and repeated_buffer == first_buffer \
			and changed_result.get("cells", []) != first_cells \
			and grass.custom_aabb.size.x > 1.0 \
			and grass.custom_aabb.size.z > 1.0 \
			and grass.multimesh.mesh.resource_path \
				== "res://Assets/environment/grass-small.res" \
			and (grass.get("generated_transforms") as Array).size() \
				== grass.multimesh.instance_count \
			and material != null \
			and material.shader.resource_path \
				== "res://addons/simplegrasstextured/shaders/grass.gdshader",
		"Generated grass uses plasma-driven patch coverage and density only on floor tiles."
	)
	var expected_preview_buffer := grass.multimesh.buffer.duplicate()
	var empty_preview := MultiMesh.new()
	empty_preview.transform_format = MultiMesh.TRANSFORM_3D
	empty_preview.mesh = grass.multimesh.mesh
	grass.multimesh = empty_preview
	grass.call(&"_restore_editor_preview")
	expect(
		grass.multimesh.buffer == expected_preview_buffer,
		"Generated grass can restore an editor viewport from its serialized transforms."
	)
	var packed_holder_scene := PackedScene.new()
	var pack_error := packed_holder_scene.pack(holder)
	var packed_holder := packed_holder_scene.instantiate() as Node3D
	var packed_grass := packed_holder.get_node_or_null(^"GeneratedGrass") \
		as MultiMeshInstance3D if packed_holder != null else null
	expect(
		pack_error == OK \
			and packed_grass != null \
			and packed_grass.multimesh.instance_count \
				== grass.multimesh.instance_count \
			and packed_grass.multimesh.buffer == grass.multimesh.buffer \
			and (packed_grass.get("generated_transforms") as Array).size() \
				== grass.multimesh.instance_count,
		"Generated grass retains its visible MultiMesh transforms when Layout is packed."
	)
	if packed_holder != null:
		packed_holder.free()
	holder.free()
