extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_resource_catalog.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_resource_catalog.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_grid_map_paths_reflect_current_scene_tree()
	_test_resource_notification_path_matching()


func _test_grid_map_paths_reflect_current_scene_tree() -> void:
	var root := Node3D.new()
	var group := Node3D.new()
	group.name = "Walls"
	root.add_child(group)
	var grid_map := GridMap.new()
	grid_map.name = "MainGrid"
	group.add_child(grid_map)
	expect_equal(
		SUBJECT.collect_grid_map_paths(root),
		["Walls/MainGrid"] as Array[String],
		"GridMap choices use the current nested scene path."
	)
	group.name = "RenamedWalls"
	expect_equal(
		SUBJECT.collect_grid_map_paths(root),
		["RenamedWalls/MainGrid"] as Array[String],
		"GridMap choices reflect unsaved parent renames."
	)
	group.remove_child(grid_map)
	expect(
		SUBJECT.collect_grid_map_paths(root).is_empty(),
		"GridMap choices stop showing nodes removed from the edited scene."
	)
	grid_map.free()
	root.free()


func _test_resource_notification_path_matching() -> void:
	var resources := PackedStringArray([
		"res://levels/1/level.png",
		"res://Assets/environment/walls.tres",
	])
	expect(
		SUBJECT.resources_include_path(resources, "res://levels/1/level.png"),
		"Live refresh recognises the current PNG in a resource notification."
	)
	expect(
		not SUBJECT.resources_include_path(resources, "res://levels/2/level.png"),
		"Live refresh ignores unrelated resource paths."
	)
	expect(
		not SUBJECT.resources_include_path(resources, ""),
		"An empty configured path never matches a resource notification."
	)
