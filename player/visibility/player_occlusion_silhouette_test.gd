extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/visibility/player_occlusion_silhouette.gd")
const SUBJECT_SCENE := preload("res://player/visibility/player_occlusion_silhouette.tscn")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/visibility/player_occlusion_silhouette.gd")
	var root := Node3D.new()
	var player := Node3D.new()
	player.name = "Player"
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	var character := Node3D.new()
	character.name = "Character"
	var source_mesh := MeshInstance3D.new()
	source_mesh.name = "Body"
	source_mesh.mesh = BoxMesh.new()
	var authored_overlay := StandardMaterial3D.new()
	source_mesh.material_overlay = authored_overlay
	character.add_child(source_mesh)
	pivot.add_child(character)
	player.add_child(pivot)
	var silhouette := SUBJECT_SCENE.instantiate() as SUBJECT
	player.add_child(silhouette)
	root.add_child(player)
	tree.root.add_child(root)
	await tree.process_frame

	expect_equal(
		silhouette.get_silhouette_mesh_count(),
		1,
		"One authoritative player mesh receives the extra render passes."
	)
	expect(
		silhouette.get_parent() == player,
		"The visibility renderer remains a removable component owned by the shared player."
	)
	var applied_overlay := source_mesh.material_overlay
	expect(
		applied_overlay != null and applied_overlay != authored_overlay \
			and authored_overlay.next_pass == null \
			and character.get_node_or_null("BodyOcclusionSilhouette") == null,
		"The renderer extends a private overlay copy without duplicating skinned geometry."
	)
	var mask_material := applied_overlay.next_pass as ShaderMaterial
	var outline_material := mask_material.next_pass as ShaderMaterial
	var fill_material := outline_material.next_pass as ShaderMaterial
	expect(
		mask_material != null and outline_material != null and fill_material != null \
			and mask_material.render_priority < outline_material.render_priority \
			and outline_material.render_priority < fill_material.render_priority,
		"The visible-player mask precedes the expanded outline and dark interior fill."
	)
	expect(silhouette.is_silhouette_active(), "The depth-only overlay starts armed.")
	silhouette.set_visibility_enabled(false)
	expect(
		not silhouette.is_silhouette_active() \
			and source_mesh.material_overlay == authored_overlay,
		"Comparison mode restores the exact authored overlay."
	)
	silhouette.set_visibility_enabled(true)
	expect(
		source_mesh.material_overlay == applied_overlay,
		"Re-enabling restores the prepared passes on the authoritative mesh."
	)

	var fill_source := FileAccess.get_file_as_string(
		"res://player/visibility/player_occlusion_fill.gdshader"
	)
	var mask_source := FileAccess.get_file_as_string(
		"res://player/visibility/player_occlusion_mask.gdshader"
	)
	var outline_source := FileAccess.get_file_as_string(
		"res://player/visibility/player_occlusion_outline.gdshader"
	)
	expect(
		mask_source.contains("stencil_mode write, compare_always, 37") \
			and mask_source.contains("depth_test_default") \
			and mask_source.contains("ALPHA = 0.0;"),
		"An invisible first pass marks only player pixels that ordinary scene depth exposes."
	)
	expect(
		fill_source.contains("depth_test_inverted") \
			and fill_source.contains("stencil_mode read, compare_not_equal, 37") \
			and fill_source.contains("view_position.z += occlusion_depth_bias") \
			and fill_source.contains("ALPHA = 1.0;") \
			and not fill_source.contains("ALPHA = 0."),
		"The solid fill passes only behind ordinary scene depth with a visible-surface bias."
	)
	expect(
		outline_source.contains("depth_test_inverted") \
			and outline_source.contains("stencil_mode read, compare_not_equal, 37") \
			and outline_source.contains("cull_back") \
			and outline_source.contains("VERTEX += NORMAL * outline_width") \
			and outline_source.contains("ALPHA = 1.0;"),
		"The bright border expands opaque front faces without exposing the rear hull."
	)

	silhouette.queue_free()
	await tree.process_frame
	expect(
		character.get_node_or_null("BodyOcclusionSilhouette") == null \
			and source_mesh.material_overlay == authored_overlay,
		"Removing the optional component restores the exact authored player overlay."
	)
	root.queue_free()
	await tree.process_frame
