extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_animation.gd")
const CHARACTER := preload("res://player/andy_rigged.tscn")
const FOOT_PLANT := preload("res://player/player_foot_plant.gd")
const SUBJECT_PATH := "res://player/player_animation.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _test_new_clips_replace_legacy_one_state_at_a_time(tree)
	await _test_empty_new_character_uses_t_pose_for_idle(tree)
	await _test_imported_legs_keep_authored_motion_with_attention(tree)
	await _test_distance_driven_playback(tree)
	await _test_full_speed_plants(tree)
	await _test_alternating_transfers_and_replay(tree)
	await _test_idle_preserves_authored_feet(tree)
	await _test_stagger_lifecycle(tree)
	await _test_stagger_interrupt_window(tree)


func _test_new_clips_replace_legacy_one_state_at_a_time(tree: SceneTree) -> void:
	var fixture := _create_fixture([&"walk"])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var new_character := fixture.get_node("Pivot/Character/NewCharacter") as Node3D
	var legacy_character := fixture.get_node("Pivot/Character/LegacyCharacter") as Node3D

	expect(
		not new_character.visible and legacy_character.visible and controller.current_animation == "idle",
		"A missing new idle clip uses the legacy idle after any new clip exists."
	)
	controller.update_movement(Vector3(0.0, 0.0, 0.4), 1.0, true)
	expect(
		(
			new_character.visible
			and not legacy_character.visible
			and controller.current_animation == "walk"
			and controller.animation_player == controller.primary_animation_player
			and is_equal_approx(controller.animation_player.speed_scale, 1.0)
		),
		"An available new walk clip replaces the legacy walk state at its measured travel cadence."
	)
	controller.play_death()
	expect(
		(
			not new_character.visible
			and legacy_character.visible
			and controller.current_animation == "die"
			and controller.animation_player == controller.fallback_animation_player
		),
		"A missing new death clip swaps back to the legacy death animation."
	)
	fixture.free()
	await tree.process_frame


func _test_empty_new_character_uses_t_pose_for_idle(tree: SceneTree) -> void:
	var fixture := _create_fixture([])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var new_character := fixture.get_node("Pivot/Character/NewCharacter") as Node3D
	var legacy_character := fixture.get_node("Pivot/Character/LegacyCharacter") as Node3D

	expect(
		(
			controller.idle_uses_t_pose
			and new_character.visible
			and not legacy_character.visible
			and controller.animation_player == null
			and controller.current_animation.is_empty()
		),
		"A new character with no authored clips remains in its T-pose while idle."
	)
	controller.update_movement(Vector3(0.0, 0.0, 0.4), 1.0, true)
	expect(
		not new_character.visible and legacy_character.visible and controller.current_animation == "walk",
		"Movement still uses the legacy walk while the new character has no clips."
	)
	controller.update_movement(Vector3.ZERO, 1.0, true)
	expect(
		new_character.visible and not legacy_character.visible and controller.current_animation.is_empty(),
		"Stopping returns from the legacy walk to the new character's T-pose."
	)
	fixture.free()
	await tree.process_frame


func _create_fixture(primary_animation_names: Array[StringName]) -> Node3D:
	var fixture := Node3D.new()
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	fixture.add_child(pivot)
	var character_container := Node3D.new()
	character_container.name = "Character"
	pivot.add_child(character_container)
	var new_character := Node3D.new()
	new_character.name = "NewCharacter"
	character_container.add_child(new_character)
	if not primary_animation_names.is_empty():
		new_character.add_child(_create_animation_player(primary_animation_names))
	var legacy_character := Node3D.new()
	legacy_character.name = "LegacyCharacter"
	character_container.add_child(legacy_character)
	legacy_character.add_child(_create_animation_player([&"idle", &"walk", &"die"]))
	var controller := SUBJECT.new() as GDPlayerAnimation
	controller.name = "PlayerAnimation"
	fixture.add_child(controller)
	return fixture


func _create_animation_player(animation_names: Array[StringName]) -> AnimationPlayer:
	var animation_player := AnimationPlayer.new()
	var animation_library := AnimationLibrary.new()
	for animation_name in animation_names:
		animation_library.add_animation(animation_name, Animation.new())
	animation_player.add_animation_library(&"", animation_library)
	return animation_player


# Flow: Imported starting poses and both walking knees remain owned by the rig,
# including after idle transitions and late head-look processing.
func _test_imported_legs_keep_authored_motion_with_attention(tree: SceneTree) -> void:
	var character_scene := CHARACTER
	var imported_scene := load("res://player/andy_rigged.glb") as PackedScene
	var character := character_scene.instantiate() as Node3D
	var imported := imported_scene.instantiate() as Node3D
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var imported_skeleton := imported.find_child("Skeleton3D", true, false) as Skeleton3D
	var poses_match := true
	for bone in skeleton.get_bone_count():
		poses_match = (
			poses_match and skeleton.get_bone_pose(bone).is_equal_approx(imported_skeleton.get_bone_pose(bone))
		)
	expect(poses_match, "The character scene inherits the imported pose without saved bone overrides.")
	imported.free()
	var fixture := _create_fixture([])
	var container := fixture.get_node("Pivot/Character") as Node3D
	container.get_node("NewCharacter").free()
	character.name = "NewCharacter"
	container.add_child(character)
	var attention := (load("res://player/player_attention.gd") as GDScript).new() as GDPlayerAttention
	fixture.add_child(attention)
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	controller.prepare_replay()
	var left_knee := skeleton.find_bone("DEF-shin.L")
	var right_knee := skeleton.find_bone("DEF-shin.R")
	for cycle in range(2):
		controller.update_replay(0.0, false, 0.2)
		# Finish the idle-to-walk blend before measuring the authored knee motion.
		fixture.position.z += 0.4
		controller.update_replay(1.0, false, 1.6)
		var left_start := skeleton.get_bone_pose_rotation(left_knee)
		var right_start := skeleton.get_bone_pose_rotation(right_knee)
		var left_motion := 0.0
		var right_motion := 0.0
		for frame in range(40):
			fixture.position.z += 0.0125
			controller.update_replay(1.0, false, 0.05)
			attention.current_head_yaw = sin(float(frame)) * 0.5
			attention._process(0.05)
			left_motion = maxf(left_motion, left_start.angle_to(skeleton.get_bone_pose_rotation(left_knee)))
			right_motion = maxf(right_motion, right_start.angle_to(skeleton.get_bone_pose_rotation(right_knee)))
		expect(left_motion > 0.3, "The left knee bends during walking with head glances, cycle %s." % cycle)
		expect(right_motion > 0.3, "The right knee bends during walking with head glances, cycle %s." % cycle)
	fixture.free()
	await tree.process_frame


# Flow: Actual travel owns acceleration, slowdown, blocking, braking and replay cadence.
func _test_distance_driven_playback(tree: SceneTree) -> void:
	var fixture := _create_fixture([&"walk", &"idle"])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	controller.update_movement(Vector3(0.0, 0.0, 0.025), 0.1, true)
	var full_speed := controller.animation_player.speed_scale
	controller.update_movement(Vector3(0.0, 0.0, 0.0125), 0.1, true)
	expect(
		is_equal_approx(controller.animation_player.speed_scale, full_speed * 0.5),
		"Weight, squeezing and acceleration all slow cadence in proportion to actual travel."
	)
	controller.update_movement(Vector3.ZERO, 0.1, true)
	expect_equal(controller.current_animation, "idle", "Holding input into a wall cannot keep walking in place.")
	controller.update_movement(Vector3(0.0, 0.0, 0.005), 0.1, true)
	expect_equal(controller.current_animation, "walk", "Braking still animates until actual travel stops.")
	controller.prepare_replay()
	fixture.position.z += 0.025
	controller.update_replay(0.0, false, 0.1)
	expect(
		controller.current_animation == "walk" and is_equal_approx(controller.animation_player.speed_scale, full_speed),
		"Replay follows recorded displacement even after input is released."
	)
	controller.update_replay(1.0, false, 0.1)
	expect_equal(
		controller.current_animation, "idle", "Replay wall collisions do not advance a walk despite recorded input."
	)
	controller.update_replay(0.0, true, 0.1)
	var death_position := controller.animation_player.current_animation_position
	controller.update_dead_animation(0.1)
	expect(
		controller.animation_player.current_animation_position > death_position,
		"Manually advanced death clips continue as the body settles."
	)
	fixture.free()
	await tree.process_frame


# Flow: Full movement speed cannot skip a stance boundary between physics frames.
func _test_full_speed_plants(tree: SceneTree) -> void:
	var fixture := _create_fixture([])
	var container := fixture.get_node("Pivot/Character") as Node3D
	container.get_node("NewCharacter").free()
	var character := (CHARACTER).instantiate() as Node3D
	character.name = "NewCharacter"
	container.add_child(character)
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var plant := controller.foot_plant
	var result := controller.gait_skeleton.get_node("FootRotation") as FOOT_PLANT
	var largest_error := 0.0
	var planted_samples := 0
	for frame in range(60):
		var displacement := Vector3(0.0, 0.0, GDPlayerMovement.SPEED / 60.0)
		fixture.position += displacement
		controller.update_movement(displacement, 1.0 / 60.0, true)
		await tree.process_frame
		if plant.left_planted and plant.left_ik.influence >= 0.99999:
			planted_samples += 1
			largest_error = maxf(largest_error, result.left_rendered.origin.distance_to(plant.left_anchor.origin))
		if plant.right_planted and plant.right_ik.influence >= 0.99999:
			planted_samples += 1
			largest_error = maxf(largest_error, result.right_rendered.origin.distance_to(plant.right_anchor.origin))
	expect(planted_samples > 2, "Full movement speed still samples actual left and right stances.")
	expect(largest_error < 0.00001, "Substeps keep full-speed rendered contacts fixed at their world anchors.")
	expect(
		(
			Vector2(character.position.x, character.position.z).is_equal_approx(Vector2.ZERO)
			and is_equal_approx(character.position.y, controller.gait_lift)
		),
		"Visual substeps preserve horizontal placement and apply only the current transfer lift."
	)
	fixture.free()
	await tree.process_frame


# Flow: Bounded steps push off into a small lift, land alternately and clear on interruption.
func _test_alternating_transfers_and_replay(tree: SceneTree) -> void:
	var fixture := _create_imported_fixture()
	var replay_fixture := _create_imported_fixture()
	tree.root.add_child(fixture)
	tree.root.add_child(replay_fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var replay := replay_fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	replay.prepare_replay()
	var settings := controller.GAIT_SETTINGS
	var peak_lift := 0.0
	var unexpected_contact := false
	var replay_matches := true
	var cadence_is_bounded := true
	var touchdown_sides: Array[bool] = []
	var previous_left := false
	var previous_right := false
	for frame in range(100):
		var displacement := Vector3(0.0, 0.0, GDPlayerMovement.SPEED * 0.01)
		fixture.position += displacement
		replay_fixture.position += displacement
		controller.update_movement(displacement, 0.01, true)
		replay.update_replay(1.0, false, 0.01)
		await tree.process_frame
		peak_lift = maxf(peak_lift, controller.gait_lift)
		var plant := controller.foot_plant
		if controller.gait_lift > 0.000001:
			unexpected_contact = unexpected_contact or plant.left_planted or plant.right_planted
		if plant.left_planted and not previous_left:
			touchdown_sides.append(true)
		if plant.right_planted and not previous_right:
			touchdown_sides.append(false)
		previous_left = plant.left_planted
		previous_right = plant.right_planted
		replay_matches = (
			replay_matches
			and is_equal_approx(controller.gait_lift, replay.gait_lift)
			and plant.left_planted == replay.foot_plant.left_planted
			and plant.right_planted == replay.foot_plant.right_planted
		)
		cadence_is_bounded = (
			cadence_is_bounded
			and (
				controller.animation_player.speed_scale
				<= (
					(settings.maximum_cycles_per_second * controller.animation_player.get_animation("walk").length)
					+ 0.000001
				)
			)
		)
	expect(cadence_is_bounded, "Walking stays within the complete-cycle rate cap.")
	expect(peak_lift > settings.transfer_height * 0.9, "The character visibly lifts between successive foot contacts.")
	expect(not unexpected_contact, "Neither foot remains planted during a weight-transfer hop.")
	var alternating := touchdown_sides.size() >= 4
	for contact in range(1, touchdown_sides.size()):
		alternating = alternating and touchdown_sides[contact] != touchdown_sides[contact - 1]
	expect(alternating, "Push-off lands on the opposite foot through several complete cycles.")
	expect(replay_matches, "Recorded position playback reproduces the same transfer lift and alternating contacts.")
	await _advance_to_transfer(fixture, controller)
	controller.update_movement(Vector3.ZERO, 0.01, true)
	expect(
		controller.gait_lift == 0.0 and (controller.character as Node3D).position.is_equal_approx(Vector3.ZERO),
		"Stopping during a hop restores the authored visual height immediately."
	)
	await _advance_to_transfer(fixture, controller)
	controller.update_movement(Vector3(0.0, 0.02, 0.01), 0.01, false)
	expect(
		(
			controller.gait_lift == 0.0
			and not controller.foot_plant.left_planted
			and not controller.foot_plant.right_planted
		),
		"A real jump owns vertical motion and releases both feet without gait lift."
	)
	await _advance_to_transfer(fixture, controller)
	controller.play_death()
	expect_equal(controller.gait_lift, 0.0, "Death clears the transfer lift before swapping animation models.")
	controller.prepare_replay()
	await _advance_to_transfer(fixture, controller)
	controller.prepare_replay()
	expect_equal(controller.gait_lift, 0.0, "Replay restart cannot retain a previous transfer offset.")
	fixture.free()
	replay_fixture.free()
	await tree.process_frame


func _advance_to_transfer(fixture: Node3D, controller: GDPlayerAnimation) -> void:
	for frame in range(100):
		var displacement := Vector3(0.0, 0.0, GDPlayerMovement.SPEED * 0.01)
		fixture.position += displacement
		controller.update_movement(displacement, 0.01, true)
		if controller.gait_lift > 0.01:
			return
	expect(false, "A moving grounded character reaches a transfer within one cycle.")


func _create_imported_fixture() -> Node3D:
	var fixture := _create_fixture([])
	var container := fixture.get_node("Pivot/Character") as Node3D
	container.get_node("NewCharacter").free()
	var character := CHARACTER.instantiate() as Node3D
	character.name = "NewCharacter"
	container.add_child(character)
	return fixture


# Flow: Fresh idle and stops at different walk phases preserve the authored foot poses.
func _test_idle_preserves_authored_feet(tree: SceneTree) -> void:
	var fixture := _create_imported_fixture()
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	expect_equal(controller.idle_animation, "idle", "The replacement rig selects its authored animated idle clip.")
	for frame in range(24):
		controller.update_movement(Vector3.ZERO, 1.0 / 60.0, true)
		await tree.process_frame
	_expect_authored_idle(controller, "Fresh idle")
	for walking_frames in [1, 6, 12, 17, 24, 30, 40, 53]:
		for frame in range(walking_frames):
			var displacement := Vector3(0.0, 0.0, GDPlayerMovement.SPEED / 60.0)
			fixture.position += displacement
			controller.update_movement(displacement, 1.0 / 60.0, true)
			await tree.process_frame
		controller.update_movement(Vector3.ZERO, 1.0 / 60.0, true)
		expect(
			not controller.foot_plant.left_planted and not controller.foot_plant.right_planted,
			"Stopping releases walking targets before blending into the authored idle."
		)
		for frame in range(24):
			controller.update_movement(Vector3.ZERO, 1.0 / 60.0, true)
			await tree.process_frame
		_expect_authored_idle(controller, "Stopping after %s walk frames" % walking_frames)
	fixture.free()
	await tree.process_frame


func _expect_authored_idle(controller: GDPlayerAnimation, context: String) -> void:
	var skeleton := controller.gait_skeleton
	var result := skeleton.get_node("FootRotation") as GDPlayerFootPlant
	var left_toe := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("DEF-toe.L"))
	var right_toe := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("DEF-toe.R"))
	expect(
		result.left_toe_rendered.is_equal_approx(left_toe) and result.right_toe_rendered.is_equal_approx(right_toe),
		"%s renders both authored toe poses without grounding corrections." % context
	)
	expect(
		controller.current_animation == "idle" and controller.gait_lift == 0.0,
		"%s uses the authored idle without gait lift." % context
	)


# Flow: Zombie stagger plays once, survives movement, keeps recovery progress on repeated hits, and yields to death.
func _test_stagger_lifecycle(tree: SceneTree) -> void:
	var fixture := _create_fixture([&"idle", &"walk", &"stagger", &"die"])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var clip := controller.primary_animation_player.get_animation("stagger")
	clip.length = 0.7
	clip.loop_mode = Animation.LOOP_LINEAR
	controller.play_stagger(fixture.global_position + Vector3.RIGHT)
	expect(absf(controller.pivot.rotation.y - PI / 2.0) < 0.0001, "Stagger faces the attacker.")
	controller.pivot.rotation.y = 0.0
	expect_equal(controller.current_animation, "stagger", "Zombie reaction selects stagger.")
	expect(controller.is_staggering(), "Gameplay movement is locked during stagger.")
	expect_equal(clip.loop_mode, Animation.LOOP_NONE, "Stagger is a one-shot clip.")
	controller.update_movement(Vector3(0, 0, 0.1), 0.2, true)
	expect_equal(controller.current_animation, "stagger", "Movement cannot replace active stagger.")
	expect(
		absf(controller.pivot.rotation.y - PI / 2.0) < 0.0001, "Movement cannot turn stagger away from the attacker."
	)
	expect_equal(controller.animation_player.speed_scale, 1.0, "Stagger uses authored timing.")
	var remaining := controller.stagger_remaining
	controller.play_stagger()
	expect_equal(controller.stagger_remaining, remaining, "Another hit cannot restart the recovery window.")
	controller.update_movement(Vector3.ZERO, 0.8, true)
	expect_equal(controller.current_animation, "idle", "Finished stagger returns to idle.")
	expect(not controller.is_staggering(), "Completing the clip releases the movement lock.")
	expect(
		absf(controller.pivot.rotation.y) < 0.0001, "Stopped stagger restores pre-hit facing even after another hit."
	)
	controller.play_stagger(fixture.global_position + Vector3.RIGHT)
	controller.update_movement(Vector3(0, 0, 0.1), 0.8, true)
	expect_equal(controller.current_animation, "walk", "Finished stagger resumes walking.")
	expect(absf(controller.pivot.rotation.y) < 0.0001, "Resumed walking faces actual travel immediately.")
	controller.play_stagger()
	controller.play_death()
	controller.play_stagger()
	expect_equal(controller.current_animation, "die", "Death interrupts and blocks stagger.")
	fixture.free()
	await tree.process_frame
	fixture = _create_fixture([&"idle", &"walk"])
	tree.root.add_child(fixture)
	await tree.process_frame
	controller = fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	controller.play_stagger()
	expect_equal(controller.current_animation, "idle", "Missing stagger keeps normal playback.")
	expect(controller.hit_reaction_tween != null, "Missing stagger uses the existing hit hop.")
	fixture.free()
	await tree.process_frame


# Flow: Held movement interrupts exactly at 25 percent, while no input and death cannot cancel.
func _test_stagger_interrupt_window(tree: SceneTree) -> void:
	var fixture := _create_fixture([&"idle", &"walk", &"stagger", &"die"])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	controller.primary_animation_player.get_animation("stagger").length = 2.0
	controller.play_stagger(fixture.global_position + Vector3.RIGHT)
	controller.update_movement(Vector3.ZERO, 0.49, true)
	expect(
		not controller.try_interrupt_stagger(Vector3.FORWARD),
		"Movement cannot interrupt before the first quarter of the clip."
	)
	controller.play_stagger()
	controller.update_movement(Vector3.ZERO, 0.01, true)
	expect(not controller.try_interrupt_stagger(Vector3.ZERO), "No movement intent keeps the reaction playing.")
	expect(
		controller.try_interrupt_stagger(Vector3.FORWARD),
		"Held movement interrupts at 25 percent even after another hit."
	)
	expect(not controller.is_staggering(), "Interrupt immediately releases the movement lock.")
	expect(
		absf(absf(controller.pivot.rotation.y) - PI) < 0.0001,
		"Interrupt faces the requested escape direction before locomotion."
	)
	controller.update_movement(Vector3.FORWARD * 0.01, 0.01, true)
	expect_equal(controller.current_animation, "walk", "Movement blends back into walking.")
	controller.play_death()
	expect(not controller.try_interrupt_stagger(Vector3.RIGHT), "Movement cannot interrupt death.")
	fixture.free()
	await tree.process_frame
