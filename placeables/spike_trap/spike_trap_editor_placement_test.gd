extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/spike_trap/spike_trap_editor_placement.gd")
const SUBJECT_PATH := "res://placeables/spike_trap/spike_trap_editor_placement.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_socket_plane_uses_fixed_height(tree)


func _test_socket_plane_uses_fixed_height(tree: SceneTree) -> void:
	var spike_trap := Node3D.new()
	spike_trap.position = Vector3(0.0, 1.0, 0.0)
	var subject: Variant = SUBJECT.new()
	spike_trap.add_child(subject as Node)
	tree.root.add_child(spike_trap)

	expect(
		subject.apply_fixed_height(),
		"The editor placement helper can correct a floating spike trap."
	)
	expect(
		is_equal_approx(spike_trap.position.y, subject.fixed_height),
		"The editor placement helper puts the spike-trap socket plane at its fixed height."
	)

	spike_trap.free()
