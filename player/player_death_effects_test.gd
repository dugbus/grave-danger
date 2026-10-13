extends "res://tests/test_case.gd"

const PLAYER_SCENE := preload("res://player/player.tscn")
const SUBJECT := preload("res://player/player_death_effects.gd")
const ANDY_FACE_SETTINGS := preload("res://player/andy_face_settings.tres")
const SUBJECT_PATH := "res://player/player_death_effects.gd"


# Flow: Face effects follow a falling animated head rather than the standing player origin.
func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("Head")
	var rest := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.8, 0))
	skeleton.set_bone_rest(0, rest)
	skeleton.set_bone_pose_position(0, rest.origin)
	skeleton.set_bone_pose_rotation(0, rest.basis.get_rotation_quaternion())
	var head := BoneAttachment3D.new()
	head.bone_name = "Head"
	skeleton.add_child(head)
	tree.root.add_child(skeleton)
	await tree.process_frame
	var effects := SUBJECT.new() as GDPlayerDeathEffects
	effects.head = head
	effects._cache_head_binding()
	expect(
		effects._face_transform().basis.is_equal_approx(Basis.IDENTITY),
		"Face offsets use character axes independently of imported bone rest axes."
	)
	var fallen := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.15, -0.5))
	skeleton.set_bone_pose_position(0, fallen.origin)
	skeleton.set_bone_pose_rotation(0, (fallen.basis * rest.basis).get_rotation_quaternion())
	skeleton.force_update_all_bone_transforms()
	await tree.process_frame
	var face := effects._face_transform()
	expect(
		face.origin.distance_to(fallen.origin) < 0.0001, "Blood follows the animated head down and away from the feet."
	)
	expect(face.basis.is_equal_approx(fallen.basis), "Blood rotates with the face when the body lies down.")
	var fallback := Node3D.new()
	fallback.transform = Transform3D(Basis(Vector3.UP, 0.4), Vector3(1.0, 0.7, 2.0))
	tree.root.add_child(fallback)
	effects.head = fallback
	effects._cache_head_binding()
	expect(
		effects._face_transform().is_equal_approx(fallback.global_transform),
		"Selecting a fallback head clears the previous rig correction and references."
	)
	fallback.free()
	effects.free()
	skeleton.free()
	await tree.process_frame
	await _test_rigged_death_face(tree)
	_test_blood_stays_in_front_of_silhouette()
	_test_fire_death_leaves_motion_to_animation()


# Flow: All continuous facial blood draws in red and masks the through-scenery outline.
func _test_blood_stays_in_front_of_silhouette() -> void:
	var player := PLAYER_SCENE.instantiate() as GDPlayer
	for emitter_name in [&"MouthBlood", &"NoseBlood", &"LeftEyeBlood", &"RightEyeBlood"]:
		var emitter := player.get_node(NodePath("PlayerDeathEffects/" + emitter_name)) as GPUParticles3D
		var material := emitter.draw_pass_1.surface_get_material(0) as StandardMaterial3D
		var blocker := material.next_pass as ShaderMaterial
		expect(
			(
				material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
				and material.albedo_color.r > material.albedo_color.g * 10.0
			),
			"%s keeps its authored red colour independently of lighting." % emitter_name
		)
		expect(
			(
				blocker != null
				and blocker.render_priority < 0
				and blocker.shader.resource_path == PlayerOcclusionBlocker.BLOCKER_SHADER_PATH
			),
			"%s masks gold silhouette passes before they can paint over blood." % emitter_name
		)
	player.free()


# Flow: Blood uses the final rendered head throughout the imported falling death clip.
func _test_rigged_death_face(tree: SceneTree) -> void:
	var character := (load("res://player/andy_rigged.tscn") as PackedScene).instantiate() as Node3D
	tree.root.add_child(character)
	await tree.process_frame
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var animator := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var look := skeleton.get_node("HeadLook") as SkeletonModifier3D
	var effects := SUBJECT.new() as GDPlayerDeathEffects
	effects.head = skeleton.get_node("DeathEffectHead") as Node3D
	effects._cache_head_binding()
	expect(effects.face_settings == ANDY_FACE_SETTINGS, "The rigged head selects its model-owned face settings.")
	var bone := skeleton.find_bone("DEF-spine.006")
	var rendered: Array[Transform3D] = []
	look.modification_processed.connect(func() -> void: rendered.append(skeleton.get_bone_global_pose(bone)))
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_test_face_mark_near_cheek(character, skeleton, bone)
	look.set("head_yaw", 0.5)
	skeleton.advance(0.0)
	await tree.process_frame
	effects._place_player_splatter()
	look.set("head_yaw", 0.0)
	animator.play("die", 0.0)
	for step in range(6):
		animator.advance(0.2)
		skeleton.advance(0.0)
		await tree.process_frame
		var expected := (
			skeleton.global_transform
			* (rendered.back() as Transform3D)
			* Transform3D(skeleton.get_bone_global_rest(bone).basis.inverse(), Vector3.ZERO)
		)
		expect(
			(
				effects.player_splatter.global_position.distance_to(
					effects._face_transform() * effects.face_settings.splatter_offset
				)
				< 0.0001
			),
			"The bloody face mark stays on the rendered head at step %s." % step
		)
		expect(
			effects._face_transform().is_equal_approx(expected),
			"Blood follows the final rendered death head at step %s." % step
		)
	effects.free()
	character.free()
	await tree.process_frame


# Flow: The model-authored facial decal volume reaches the actual cheek mesh.
func _test_face_mark_near_cheek(character: Node3D, skeleton: Skeleton3D, bone: int) -> void:
	var mesh := character.find_child("andy", true, false) as MeshInstance3D
	expect(mesh != null, "The current rig supplies the mesh used to check bloody-face placement.")
	if mesh == null:
		return
	var rest := skeleton.get_bone_global_rest(bone)
	var face := skeleton.global_transform * Transform3D(Basis.IDENTITY, rest.origin)
	var mark_position := face * (ANDY_FACE_SETTINGS.splatter_offset as Vector3)
	var direction := face.basis.z.normalized()
	var ray_start := mesh.to_local(mark_position + direction)
	var ray_end := mesh.to_local(mark_position - direction)
	var triangles := mesh.mesh.get_faces()
	var nearest_surface := Vector3.INF
	var nearest_distance := INF
	for index in range(0, triangles.size(), 3):
		var hit: Variant = Geometry3D.segment_intersects_triangle(
			ray_start, ray_end, triangles[index], triangles[index + 1], triangles[index + 2]
		)
		if hit == null:
			continue
		var surface := hit as Vector3
		var distance := ray_start.distance_squared_to(surface)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_surface = surface
	expect(nearest_surface.is_finite(), "The face projector crosses the current cheek geometry.")
	if nearest_surface.is_finite():
		expect(
			(
				mesh.to_global(nearest_surface).distance_to(mark_position)
				< GDBloodSplatterDecal.PLAYER_PROJECTION_DEPTH * 0.5
			),
			"The facial decal projection reaches the actual cheek surface."
		)


# Flow: Fire keeps its visual effects while leaving body motion to the authored death animation.
func _test_fire_death_leaves_motion_to_animation() -> void:
	var player := PLAYER_SCENE.instantiate() as GDPlayer
	var effects := player.get_node("PlayerDeathEffects") as GDPlayerDeathEffects
	var pivot := player.get_node("Pivot") as Node3D
	var initial_rotation := Vector3(0.1, 0.4, -0.2)
	pivot.rotation = initial_rotation
	effects.player = player
	effects.visual_pivot = pivot
	effects.character = player.get_node("Pivot/Character") as Node3D
	effects.fire_particles = effects.get_node("FireParticles") as GPUParticles3D
	effects.fire_light = effects.get_node("FireLight") as OmniLight3D
	effects.play_death_throes(GDPlayerDeath.DeathCause.Fire)
	expect(effects.throe_tween == null, "Fire death creates no procedural body-motion tween.")
	expect(pivot.rotation.is_equal_approx(initial_rotation), "Fire death preserves the animation pivot rotation.")
	expect(effects.fire_particles.visible and effects.fire_light.visible, "Fire death retains flames and light.")
	for descendant in effects.character.find_children("*", "MeshInstance3D", true, false):
		var mesh := descendant as MeshInstance3D
		expect(mesh.material_overlay == effects.blackened_material, "Fire death retains the charred appearance.")
	expect(not effects.uses_blood_effects, "Fire death does not start the non-fire presentation.")
	player.free()
