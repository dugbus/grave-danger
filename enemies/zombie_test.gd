extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie.gd")
const SUBJECT_PATH := "res://enemies/zombie.gd"
const ZOMBIE_SCENE := preload("res://enemies/zombie.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_rotated_path_keeps_zombie_upright(tree)


func _test_rotated_path_keeps_zombie_upright(tree: SceneTree) -> void:
	var zombie := ZOMBIE_SCENE.instantiate() as Node3D
	zombie.rotation = Vector3(-0.3, -1.15, 0.2)
	tree.root.add_child(zombie)
	var zombie_body := zombie.get_node(^"ZombieBody") as CharacterBody3D
	expect(
		zombie_body.global_basis.is_equal_approx(Basis.IDENTITY),
		"A rotated patrol path does not tilt or turn the zombie body."
	)
	zombie.free()
