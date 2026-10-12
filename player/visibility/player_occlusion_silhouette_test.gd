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
		silhouette.get_silhouette_mesh_count(), 1, "One authoritative player mesh receives the extra render passes."
	)
	expect(
		silhouette.get_parent() == player,
		"The visibility renderer remains a removable component owned by the shared player."
	)
	var applied_overlay := source_mesh.material_overlay
	expect(
		(
			applied_overlay != null
			and applied_overlay != authored_overlay
			and authored_overlay.next_pass == null
			and character.get_node_or_null("BodyOcclusionSilhouette") == null
		),
		"The renderer extends a private overlay copy without duplicating skinned geometry."
	)
	var mask_material := applied_overlay.next_pass as ShaderMaterial
	var outline_material := mask_material.next_pass as ShaderMaterial
	var fill_material := outline_material.next_pass as ShaderMaterial
	expect(
		(
			mask_material != null
			and outline_material != null
			and fill_material != null
			and mask_material.render_priority < outline_material.render_priority
			and outline_material.render_priority < fill_material.render_priority
		),
		"The visible-player mask precedes the expanded outline and dark interior fill."
	)
	expect(silhouette.is_silhouette_active(), "The depth-only overlay starts armed.")
	silhouette.set_visibility_enabled(false)
	expect(
		not silhouette.is_silhouette_active() and source_mesh.material_overlay == authored_overlay,
		"Comparison mode restores the exact authored overlay."
	)
	silhouette.set_visibility_enabled(true)
	expect(
		source_mesh.material_overlay == applied_overlay,
		"Re-enabling restores the prepared passes on the authoritative mesh."
	)

	var fill_source := FileAccess.get_file_as_string("res://player/visibility/player_occlusion_fill.gdshader")
	var mask_source := FileAccess.get_file_as_string("res://player/visibility/player_occlusion_mask.gdshader")
	var outline_source := FileAccess.get_file_as_string("res://player/visibility/player_occlusion_outline.gdshader")
	expect(
		(
			mask_source.contains("stencil_mode write, compare_always, 37")
			and mask_source.contains("depth_test_default")
			and mask_source.contains("VERTEX += NORMAL * outline_width")
			and mask_source.contains("visible_surface_bias + outline_width")
			and mask_source.contains("ALPHA = 0.0;")
		),
		"The visible-player mask covers its expanded edge without self-occlusion fringing."
	)
	expect(
		(
			fill_source.contains("depth_test_inverted")
			and fill_source.contains("stencil_mode read, compare_not_equal, 37")
			and fill_source.contains("view_position.z += occlusion_depth_bias")
			and fill_source.contains("ALPHA = 1.0;")
			and not fill_source.contains("ALPHA = 0.")
		),
		"The solid fill passes only behind ordinary scene depth with a visible-surface bias."
	)
	expect(
		(
			outline_source.contains("depth_test_inverted")
			and outline_source.contains("stencil_mode read, compare_not_equal, 37")
			and outline_source.contains("cull_back")
			and outline_source.contains("VERTEX += NORMAL * outline_width")
			and outline_source.contains("ALPHA = 1.0;")
		),
		"The bright border expands opaque front faces without exposing the rear hull."
	)

	silhouette.queue_free()
	await tree.process_frame
	expect(
		(
			character.get_node_or_null("BodyOcclusionSilhouette") == null
			and source_mesh.material_overlay == authored_overlay
		),
		"Removing the optional component restores the exact authored player overlay."
	)
	root.queue_free()
	await tree.process_frame
	if DisplayServer.get_name() != "headless":
		await _test_rendered_visibility(tree)


# Flow: Exposed animated meshes and blood remain unchanged; walls still reveal the silhouette.
func _test_rendered_visibility(tree: SceneTree) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var holder := Node3D.new()
	viewport.add_child(holder)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.1, 0.1, 0.12)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 1.0
	environment.environment = settings
	holder.add_child(environment)
	var character := (load("res://player/andy_rigged.tscn") as PackedScene).instantiate() as Node3D
	character.name = "Character"
	holder.add_child(character)
	var silhouette := SUBJECT_SCENE.instantiate() as SUBJECT
	silhouette.player_visual_root_path = ^"../Character"
	holder.add_child(silhouette)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.4
	holder.add_child(camera)
	camera.current = true
	var animator := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var droplets := _add_stationary_blood(holder)
	animator.play("die", 0.0)
	for pose in [0.0, 0.3, 0.8]:
		animator.seek(pose, true)
		for angle in [0.0, 0.8, 1.6, 3.2]:
			camera.position = Vector3(sin(angle) * 2.0, 1.2, cos(angle) * 2.0)
			camera.look_at(Vector3(0.0, 0.4, 0.0))
			silhouette.set_visibility_enabled(false)
			var plain := await _render_frame(tree, viewport)
			silhouette.set_visibility_enabled(true)
			var outlined := await _render_frame(tree, viewport)
			expect_equal(
				_count_gold_changes(plain, outlined),
				0,
				"Exposed character has no gold fringe at pose %s, angle %s." % [pose, angle]
			)
			expect_equal(
				_count_recoloured_blood(plain, outlined), 0, "Blood stays red at pose %s, angle %s." % [pose, angle]
			)
	for blood in droplets:
		blood.free()
	# A wall well in front of the character must still expose the gold obstruction outline.
	animator.seek(0.0, true)
	camera.position = Vector3(0.0, 0.5, 2.0)
	camera.look_at(Vector3(0.0, 0.5, 0.0))
	_add_occluder(holder, &"Wall", Color(0.15, 0.15, 0.15), 0.6)
	silhouette.set_visibility_enabled(false)
	var hidden := await _render_frame(tree, viewport)
	silhouette.set_visibility_enabled(true)
	var revealed := await _render_frame(tree, viewport)
	expect(
		_count_gold_changes(hidden, revealed) > 30, "The gold border still reveals a character hidden behind scenery."
	)
	_add_occluder(holder, &"FrontEnemy", Color(0.0, 0.3, 0.0), 1.0)
	var blocker := PlayerOcclusionBlocker.new()
	blocker.occluder_visual_root_path = ^"../FrontEnemy"
	holder.add_child(blocker)
	silhouette.set_visibility_enabled(false)
	var enemy_plain := await _render_frame(tree, viewport)
	silhouette.set_visibility_enabled(true)
	var enemy_outlined := await _render_frame(tree, viewport)
	expect_equal(
		_count_gold_changes(enemy_plain, enemy_outlined),
		0,
		"An enemy in front still blocks the player's through-scenery outline."
	)
	viewport.free()
	await tree.process_frame


func _render_frame(tree: SceneTree, viewport: SubViewport) -> Image:
	for frame in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _count_gold_changes(plain: Image, outlined: Image) -> int:
	var count := 0
	for y in plain.get_height():
		for x in plain.get_width():
			var before := plain.get_pixel(x, y)
			var after := outlined.get_pixel(x, y)
			if after.r > 0.7 and after.g > 0.4 and after.b < 0.35 and after.g > before.g + 0.12:
				count += 1
	return count


func _count_recoloured_blood(plain: Image, outlined: Image) -> int:
	var count := 0
	for y in plain.get_height():
		for x in plain.get_width():
			var before := plain.get_pixel(x, y)
			var after := outlined.get_pixel(x, y)
			if (
				before.r > 0.2
				and before.r > before.g * 3.0
				and before.r > before.b * 3.0
				and (after.r < after.g * 3.0 or after.r < after.b * 3.0)
			):
				count += 1
	return count


func _add_stationary_blood(holder: Node3D) -> Array[GPUParticles3D]:
	# Keep droplets stationary so the enabled/disabled comparisons sample identical blood pixels.
	var player_scene := (load("res://player/player.tscn") as PackedScene).instantiate() as GDPlayer
	var facial_blood := player_scene.get_node("PlayerDeathEffects/MouthBlood") as GPUParticles3D
	var splatter := (
		(load("res://player/blood_splatter_decal.tscn") as PackedScene).instantiate() as GDBloodSplatterDecal
	)
	var impact_blood := splatter.get_node("ImpactBlood") as GPUParticles3D
	var droplets: Array[GPUParticles3D] = []
	for blood_mesh in [facial_blood.draw_pass_1, impact_blood.draw_pass_1]:
		var blood := GPUParticles3D.new()
		blood.amount = 8
		blood.lifetime = 60.0
		blood.explosiveness = 1.0
		blood.preprocess = 1.0
		blood.use_fixed_seed = true
		blood.seed = 1
		blood.draw_pass_1 = blood_mesh
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		process.emission_sphere_radius = 0.08
		process.gravity = Vector3.ZERO
		process.scale_min = 2.0
		process.scale_max = 2.0
		blood.process_material = process
		blood.position = Vector3(0.0, 0.7, 0.32)
		holder.add_child(blood)
		droplets.append(blood)
	player_scene.free()
	splatter.free()
	return droplets


func _add_occluder(holder: Node3D, node_name: StringName, colour: Color, depth: float) -> void:
	var occluder := MeshInstance3D.new()
	occluder.name = node_name
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 0.1)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	box.material = material
	occluder.mesh = box
	occluder.position = Vector3(0.0, 0.5, depth)
	holder.add_child(occluder)
