extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/ground_enemy_orientation.gd")
const SUBJECT_PATH := "res://enemies/ground_enemy_orientation.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_upright_basis_preserves_scale()
	_test_make_upright_ignores_parent_orientation(tree)


func _test_upright_basis_preserves_scale() -> void:
	var scale := Vector3(1.25, 0.8, 1.5)
	var rotated_basis := Basis.from_euler(Vector3(0.35, 1.1, -0.2)).scaled(scale)
	var upright_basis := SUBJECT.upright_basis(rotated_basis) as Basis
	expect(
		upright_basis.is_equal_approx(
			Basis.IDENTITY.scaled(rotated_basis.get_scale())
		),
		"The upright basis removes every rotation while preserving scale."
	)


func _test_make_upright_ignores_parent_orientation(tree: SceneTree) -> void:
	var path_root := Node3D.new()
	var enemy_carrier := Node3D.new()
	path_root.add_child(enemy_carrier)
	tree.root.add_child(path_root)
	path_root.rotation = Vector3(0.4, -1.25, 0.3)
	enemy_carrier.scale = Vector3(0.9, 1.1, 1.2)
	var original_position := Vector3(2.0, 0.25, -3.0)
	enemy_carrier.global_position = original_position

	expect(SUBJECT.make_upright(enemy_carrier), "An in-tree enemy carrier is corrected.")
	expect(
		enemy_carrier.global_basis.is_equal_approx(
			Basis.IDENTITY.scaled(Vector3(0.9, 1.1, 1.2))
		),
		"The enemy carrier remains upright beneath a fully rotated path."
	)
	expect(
		enemy_carrier.global_position.is_equal_approx(original_position),
		"Correcting orientation leaves the enemy's world position unchanged."
	)
	path_root.free()
