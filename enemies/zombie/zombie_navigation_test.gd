extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie/zombie_navigation.gd")
const SUBJECT_PATH := "res://enemies/zombie/zombie_navigation.gd"
const ZOMBIE := preload("res://enemies/zombie.tscn")
const LAYOUT := preload("res://levels/close-escape/authored_layout.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var layout := LAYOUT.instantiate() as Node3D
	var zombie := ZOMBIE.instantiate() as GDZombiePath
	tree.root.add_child(layout)
	tree.root.add_child(zombie)
	zombie.set_physics_process(false)
	var grid := layout.get_node(^"WallGridMap") as GridMap
	zombie.set_navigation_grid_maps([grid])
	var destination := Vector3(16, 0, 8)
	for height in [-0.00000002980232238, 0.0, 0.00000002980232238]:
		zombie.zombie_body.global_position = Vector3(13.47, height, 8)
		destination.y = height
		var waypoint := zombie._get_grid_navigation_next_position(destination)
		expect(waypoint.z < 7.5, "Tiny floor contact offsets still route the vault zombie north around the wall.")
		expect(zombie._has_grid_blocker_between(zombie.zombie_body.global_position, destination), "Wall detection uses the same floor layer as route selection.")
	for height in [-1.25, -0.25, 0.25, 1.25]:
		var point := grid.to_global(Vector3(2.25, height, 3.75))
		expect(zombie._get_navigation_cell(grid, point) == grid.local_to_map(grid.to_local(point)), "Real lower and upper levels retain their existing cell mapping.")
	grid.position = Vector3(4, 2, -3)
	grid.rotation.y = PI * 0.5
	grid.cell_size = Vector3(2, 2, 2)
	var transformed_point := grid.to_global(Vector3(3, -0.00000003, 5))
	expect(zombie._get_navigation_cell(grid, transformed_point) == Vector3i(1, 0, 2), "Floor correction respects translated, rotated grids and non-unit cells.")
	zombie.free()
	layout.free()
