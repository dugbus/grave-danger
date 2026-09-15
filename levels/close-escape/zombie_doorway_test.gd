extends "res://tests/test_case.gd"

const LEVEL := preload("res://levels/close-escape/level.tscn")
const ZOMBIE := preload("res://enemies/zombie.tscn")

# Exercise existing locomotion from recorded positions against real walls and the
# runtime navigation region. This is not a replay of the complete crowd AI state.


func run(tree: SceneTree) -> void:
	var level := LEVEL.instantiate() as Node3D
	var harness := Node3D.new()
	harness.add_child(level.get_node(^"AuthoredLayout").duplicate())
	harness.add_child(level.get_node(^"FloorSurface").duplicate())
	tree.root.add_child(harness)
	GDNavigationBootstrap._ensure_navigation_region(harness)
	var zombies: Array[GDZombiePath] = []
	for position in [Vector3(-2.46738, 0.001, 7.34218), Vector3(-2.45577, 0.001, 6.85784), Vector3(13.47, -0.00000002980232238, 8)]:
		var zombie := ZOMBIE.instantiate() as GDZombiePath
		zombie.ai_enabled_on_ready = false
		harness.add_child(zombie)
		zombie.set_physics_process(false)
		zombie.zombie_body.global_position = position
		zombies.append(zombie)
	# Use real discovery, including the editable floor surface. It must not hide
	# the wall grid and make zombies choose straight paths through room dividers.
	GDNavigationBootstrap._set_zombie_navigation_grid_maps(harness)
	await tree.physics_frame
	await tree.physics_frame
	for tick in 300:
		for zombie in zombies:
			var target := Vector3(16, 0, 8) if zombie == zombies[2] else Vector3(3.16, 0, 2.75)
			zombie._follow_navigation_target(target, 1.0 / 60.0, false, 1.5)
		await tree.physics_frame
	expect(zombies[0].zombie_body.global_position.z < 5.0, "Following zombie can navigate onward from the recorded doorway position.")
	expect(zombies[1].zombie_body.global_position.z < 5.0, "Leading zombie can navigate onward from the recorded doorway position.")
	expect(zombies[2].zombie_body.global_position.x > 15.0, "Vault zombie routes through the opening beside its patrol wall.")
	harness.free()
	level.free()
