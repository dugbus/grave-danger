extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/playthrough_position_markers/plugin.gd")
const SUBJECT_PATH := "res://addons/playthrough_position_markers/plugin.gd"
const SAMPLE_SCENE := preload("res://addons/floor_surface/floor_surface.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_selection_snapshot()
	var scene_source_hash := SUBJECT.SceneSourceHasher.calculate("res://ui/screens") as int
	expect(
		scene_source_hash != 0,
		"Export customization hashes source scenes so inherited layout changes invalidate caches."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("SceneSourceHasher.calculate()"),
		"The export customization cache key includes the complete scene-source hash."
	)
	var edited_scene := SAMPLE_SCENE.instantiate()
	expect(
		SUBJECT.edited_scene_matches_level(edited_scene, edited_scene.scene_file_path) \
			and not SUBJECT.edited_scene_matches_level(edited_scene, "res://other_level.tscn") \
			and not SUBJECT.edited_scene_matches_level(null, edited_scene.scene_file_path),
		"Marker application reuses only the matching already-loaded editor scene."
	)
	edited_scene.free()


func _test_selection_snapshot() -> void:
	var scene_root := Node3D.new()
	scene_root.scene_file_path = "res://levels/test_level.tscn"
	var selected_parent := Node3D.new()
	selected_parent.name = "SelectedParent"
	scene_root.add_child(selected_parent)
	var selected_child := Node3D.new()
	selected_child.name = "SelectedChild"
	selected_parent.add_child(selected_child)
	var unrelated_node := Node3D.new()

	var selected_nodes: Array[Node] = [selected_parent, selected_child, unrelated_node]
	var selected_paths := SUBJECT.capture_selection_paths(scene_root, selected_nodes) \
		as Array[NodePath]
	expect_equal(
		SUBJECT.resolve_selection_paths(
			scene_root, scene_root.scene_file_path, selected_paths
		),
		[selected_parent, selected_child],
		"A playthrough selection snapshot restores selected nodes in their original order."
	)

	selected_child.free()
	var replacement_child := Node3D.new()
	replacement_child.name = "SelectedChild"
	selected_parent.add_child(replacement_child)
	expect_equal(
		SUBJECT.resolve_selection_paths(
			scene_root, scene_root.scene_file_path, selected_paths
		),
		[selected_parent, replacement_child],
		"Selection restoration follows a selected path rebuilt during marker replacement."
	)

	replacement_child.free()
	expect_equal(
		SUBJECT.resolve_selection_paths(
			scene_root, scene_root.scene_file_path, selected_paths
		),
		[selected_parent],
		"Selection restoration skips selected paths that no longer exist."
	)

	var other_scene_root := Node3D.new()
	other_scene_root.scene_file_path = "res://levels/other_level.tscn"
	expect(
		SUBJECT.resolve_selection_paths(
			other_scene_root, scene_root.scene_file_path, selected_paths
		).is_empty(),
		"A selection snapshot cannot select nodes in a different edited scene."
	)

	unrelated_node.free()
	other_scene_root.free()
	scene_root.free()
