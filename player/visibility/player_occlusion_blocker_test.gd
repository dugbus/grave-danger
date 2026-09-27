extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/visibility/player_occlusion_blocker.gd")
const SUBJECT_SCENE := preload("res://player/visibility/player_occlusion_blocker.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/visibility/player_occlusion_blocker.gd")
	var root := Node3D.new()
	var pivot := Node3D.new()
	var character := Node3D.new()
	character.name = "Character"
	var source_mesh := MeshInstance3D.new()
	source_mesh.mesh = BoxMesh.new()
	var authored_overlay := StandardMaterial3D.new()
	source_mesh.material_overlay = authored_overlay
	character.add_child(source_mesh)
	pivot.add_child(character)
	var blocker := SUBJECT_SCENE.instantiate() as SUBJECT
	pivot.add_child(blocker)
	root.add_child(pivot)
	tree.root.add_child(root)
	await tree.process_frame

	expect_equal(
		blocker.get_blocked_mesh_count(),
		1,
		"The occluding character mesh receives a silhouette-blocking pass."
	)
	var applied_overlay := source_mesh.material_overlay
	var blocker_material := applied_overlay.next_pass as ShaderMaterial
	expect(
		applied_overlay != authored_overlay \
			and authored_overlay.next_pass == null \
			and blocker_material != null \
			and blocker_material.render_priority == SUBJECT.BLOCKER_RENDER_PRIORITY,
		"The blocker extends a private overlay copy before the player silhouette renders."
	)
	expect(blocker.is_blocking_active(), "Silhouette blocking starts active.")
	blocker.set_blocking_enabled(false)
	expect(
		not blocker.is_blocking_active() \
			and source_mesh.material_overlay == authored_overlay,
		"Disabling blocking restores the exact authored overlay."
	)
	blocker.set_blocking_enabled(true)
	expect(
		source_mesh.material_overlay == applied_overlay,
		"Re-enabling restores the prepared blocker pass."
	)

	var blocker_source := FileAccess.get_file_as_string(
		"res://player/visibility/player_occlusion_blocker.gdshader"
	)
	expect(
		blocker_source.contains("stencil_mode write, compare_always, 37") \
			and blocker_source.contains("depth_test_default") \
			and blocker_source.contains("ALPHA = 0.0;"),
		"Visible enemy depth writes an invisible stencil value shared by the player silhouette."
	)

	blocker.queue_free()
	await tree.process_frame
	expect(
		source_mesh.material_overlay == authored_overlay,
		"Removing the component restores the exact authored overlay."
	)
	root.queue_free()
	await tree.process_frame
