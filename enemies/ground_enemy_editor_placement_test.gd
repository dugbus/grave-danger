extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/ground_enemy_editor_placement.gd")
const SUBJECT_PATH := "res://enemies/ground_enemy_editor_placement.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _test_snap_parent_to_ground(tree)


func _test_snap_parent_to_ground(tree: SceneTree) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(4.0, 0.2, 4.0)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.1
	floor_body.add_child(floor_collision)
	tree.root.add_child(floor_body)

	var placement_node := Node3D.new()
	placement_node.position = Vector3(0.0, 2.0, 0.0)
	var floor_sample := Marker3D.new()
	floor_sample.name = "FloorSample"
	placement_node.add_child(floor_sample)
	var subject := SUBJECT.new() as GDGroundEnemyEditorPlacement
	subject.floor_sample_path = ^"../FloorSample"
	placement_node.add_child(subject)
	tree.root.add_child(placement_node)
	await tree.physics_frame

	expect(
		subject.snap_parent_to_ground(),
		"The editor placement helper finds walkable ground beneath an airborne enemy."
	)
	expect(
		absf(placement_node.global_position.y) <= 0.001,
		"The editor placement helper moves the whole enemy scene onto the floor."
	)

	placement_node.free()
	floor_body.free()
