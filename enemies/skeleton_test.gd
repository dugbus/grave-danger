extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton.gd")
const SUBJECT_PATH := "res://enemies/skeleton.gd"
const SKELETON_SCENE := preload("res://enemies/skeleton.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_rotated_path_keeps_skeleton_upright(tree)


func _test_rotated_path_keeps_skeleton_upright(tree: SceneTree) -> void:
	var skeleton := SKELETON_SCENE.instantiate() as Node3D
	skeleton.rotation = Vector3(0.35, 1.2, -0.25)
	tree.root.add_child(skeleton)
	var drop_pivot := skeleton.get_node(^"PathFollow3D/DropPivot") as Node3D
	expect(
		drop_pivot.global_basis.is_equal_approx(Basis.IDENTITY),
		"A rotated patrol path does not tilt or turn the skeleton carrier."
	)
	skeleton.free()
