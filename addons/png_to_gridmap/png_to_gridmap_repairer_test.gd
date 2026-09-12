extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_repairer.gd"
const SETTINGS := preload("res://addons/png_to_gridmap/png_to_gridmap_settings.gd")
const COLOR_MAPPING := preload("res://addons/png_to_gridmap/png_to_gridmap_color_mapping.gd")

enum TestMeshItem {
	Wall,
	WallSolo,
	WallEnd,
}


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_repair_connects_walls_across_small_height_changes()


func _test_repair_connects_walls_across_small_height_changes() -> void:
	var settings := SETTINGS.new()
	settings.autotile_vertical_connection_metres = 0.3
	var mapping := COLOR_MAPPING.new()
	mapping.autotile_enabled = true
	mapping.base_item_ref = "Wall"
	mapping.solo_item_ref = "WallSolo"
	mapping.end_item_ref = "WallEnd"
	settings.color_mappings = [mapping] as Array[Resource]

	var library := MeshLibrary.new()
	_add_library_item(library, TestMeshItem.Wall, "Wall")
	_add_library_item(library, TestMeshItem.WallSolo, "WallSolo")
	_add_library_item(library, TestMeshItem.WallEnd, "WallEnd")
	var grid_map := GridMap.new()
	grid_map.mesh_library = library
	grid_map.cell_size = Vector3(1.0, 0.25, 1.0)
	for step in range(6):
		grid_map.set_cell_item(Vector3i(step, step, 0), TestMeshItem.Wall)

	var repairer := SUBJECT.new()
	var plan: Dictionary = repairer.build_plan(settings, grid_map, {})
	expect_equal(plan["errors"], [], "Stepped wall correction has no configuration errors.")
	for change: Dictionary in plan["changes"]:
		grid_map.set_cell_item(
			change["cell"] as Vector3i,
			int(change["item_id"]),
			int(change["orientation"])
		)

	expect_equal(
		grid_map.get_cell_item(Vector3i(0, 0, 0)),
		TestMeshItem.WallEnd,
		"GridMap correction calculates an end piece at the low end of a gradient."
	)
	expect_equal(
		grid_map.get_cell_item(Vector3i(5, 5, 0)),
		TestMeshItem.WallEnd,
		"GridMap correction calculates an end piece at the high end of a gradient."
	)
	for step in range(1, 5):
		expect_equal(
			grid_map.get_cell_item(Vector3i(step, step, 0)),
			TestMeshItem.Wall,
			"GridMap correction retains straight pieces inside a gradient run."
		)
	expect(
		grid_map.get_cell_item_orientation(Vector3i(0, 0, 0))
			!= grid_map.get_cell_item_orientation(Vector3i(5, 5, 0)),
		"The calculated end pieces face opposite directions."
	)
	var corrected_plan: Dictionary = repairer.build_plan(settings, grid_map, {})
	expect_equal(
		corrected_plan["changes"],
		[],
		"Running GridMap correction again leaves the calculated gradient wall unchanged."
	)
	grid_map.free()


func _add_library_item(library: MeshLibrary, item_id: TestMeshItem, item_name: String) -> void:
	library.create_item(item_id)
	library.set_item_name(item_id, item_name)
