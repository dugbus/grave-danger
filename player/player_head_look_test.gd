extends "res://tests/test_case.gd"

const CHARACTER := preload("res://player/andy_rigged.tscn")


# Flow: Rigged attention adds yaw to the animated head without accumulating or moving legs.
func run(tree: SceneTree) -> void:
	var character := CHARACTER.instantiate() as Node3D
	tree.root.add_child(character)
	await tree.process_frame
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var look := character.find_child("HeadLook", true, false) as SkeletonModifier3D
	var animator := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	var head := skeleton.find_bone("DEF-spine.006")
	var knee := skeleton.find_bone("DEF-shin.L")
	var authored := skeleton.get_bone_global_pose(head).basis
	var knee_pose := skeleton.get_bone_pose(knee)
	var observed: Array[Basis] = []
	look.modification_processed.connect(func() -> void: observed.append(skeleton.get_bone_global_pose(head).basis))
	look.set("head_yaw", 0.5)
	skeleton.advance(0.0)
	await tree.process_frame
	skeleton.advance(0.0)
	await tree.process_frame
	expect(observed.size() == 2, "Manual gait updates also apply head attention.")
	if observed.size() == 2:
		expect(
			observed[0].is_equal_approx(Basis(Vector3.UP, 0.5) * authored),
			"Head yaw is added to the authored pose in skeleton space."
		)
		expect(observed[0].is_equal_approx(observed[1]), "Head turns do not accumulate.")
	expect(skeleton.get_bone_pose(knee).is_equal_approx(knee_pose), "Attention preserves legs.")
	look.set("head_yaw", 0.0)
	skeleton.advance(0.0)
	await tree.process_frame
	expect(observed.back().is_equal_approx(authored), "Returning restores the authored head pose.")
	character.free()
