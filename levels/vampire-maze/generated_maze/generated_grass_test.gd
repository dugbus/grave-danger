extends "res://tests/test_case.gd"

const SIMPLE_GRASS_SCRIPT := preload("res://addons/simplegrasstextured/grass.gd")
const SUBJECT := preload("res://levels/vampire-maze/generated_maze/generated_grass.gd")
const SUBJECT_PATH := "res://levels/vampire-maze/generated_maze/generated_grass.gd"
const SUBJECT_SCENE := preload(
	"res://levels/vampire-maze/generated_maze/generated_grass.tscn"
)
const TUTORIAL_SCENE_PATHS: Array[String] = [
	"res://levels/tutorial-1/level.tscn",
	"res://levels/tutorial-2/level.tscn",
]


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var off_tree_grass := SUBJECT.new() as MultiMeshInstance3D
	off_tree_grass.rotation = Vector3(0.0, 0.5, 0.0)
	off_tree_grass.set("disable_node_rotation", true)
	expect(
		off_tree_grass.rotation.is_zero_approx(),
		"Grass rotation locking is safe before the node enters the scene tree."
	)
	off_tree_grass.free()

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
	var grass_script := grass.get_script() as Script
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
			and grass_script != null \
			and grass_script.get_base_script() == SIMPLE_GRASS_SCRIPT \
			and grass.has_meta(&"SimpleGrassTextured") \
			and grass.has_method(&"add_grass") \
			and grass.has_method(&"erase") \
			and material != null \
			and material.shader.resource_path \
				== "res://addons/simplegrasstextured/shaders/grass.gdshader",
		"Generated grass uses editable addon grass with deterministic floor patches."
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
			and packed_grass.has_meta(&"SimpleGrassTextured") \
			and packed_grass.has_method(&"add_grass"),
		"Generated grass retains editable addon transforms when Layout is packed."
	)
	if packed_holder != null:
		packed_holder.free()
	holder.free()
	_expect_tutorial_grass_uses_addon()


func _expect_tutorial_grass_uses_addon() -> void:
	for tutorial_scene_path in TUTORIAL_SCENE_PATHS:
		var tutorial_scene := load(tutorial_scene_path) as PackedScene
		var tutorial_root := tutorial_scene.instantiate() as Node3D
		var grass := tutorial_root.get_node_or_null(
			^"Layout/GeneratedContent/GeneratedGrass"
		) as MultiMeshInstance3D
		var grass_script := grass.get_script() as Script if grass != null else null
		expect(
			grass != null \
				and grass_script != null \
				and grass_script.get_base_script() == SIMPLE_GRASS_SCRIPT \
				and grass.has_meta(&"SimpleGrassTextured") \
				and grass.has_method(&"add_grass") \
				and grass.has_method(&"erase"),
			"%s keeps its generated grass editable with the addon tools." \
				% tutorial_scene_path
		)
		tutorial_root.free()
