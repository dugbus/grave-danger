extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_foot_plant.gd")
const CHARACTER := preload("res://player/andy_rigged.tscn")


# Flow: Both planted ankles remain fixed while their body travels, turns, stops and jumps.
func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/player_foot_plant.gd")
	var character := CHARACTER.instantiate() as Node3D
	tree.root.add_child(character)
	await tree.process_frame
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var player := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var plant := skeleton.get_node("FootPlant") as SUBJECT
	var result := skeleton.get_node("FootRotation") as SUBJECT
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var clip := player.get_animation("walk")
	clip.loop_mode = Animation.LOOP_LINEAR
	player.play("walk", 0.0)
	var left_samples := 0
	var right_samples := 0
	var largest_error := 0.0
	var largest_rotation_error := 0.0
	var previous_left := Vector3.ZERO
	var previous_right := Vector3.ZERO
	var largest_step := 0.0
	var blended_samples := 0
	for frame in range(220):
		character.rotation.y += 0.004
		character.position += character.basis.z * 0.0025
		player.advance(clip.length / 100.0)
		plant.set_motion(true, true, player.current_animation_position / clip.length)
		plant.sample_contacts()
		skeleton.advance(0.0)
		await tree.process_frame
		if frame > 0:
			largest_step = maxf(largest_step, previous_left.distance_to(result.left_rendered.origin))
			largest_step = maxf(largest_step, previous_right.distance_to(result.right_rendered.origin))
		previous_left = result.left_rendered.origin
		previous_right = result.right_rendered.origin
		if (
			plant.left_ik.influence > 0.0 and plant.left_ik.influence < 1.0
			or plant.right_ik.influence > 0.0 and plant.right_ik.influence < 1.0
		):
			blended_samples += 1
		if plant.left_planted and plant.left_ik.influence >= 0.99999:
			left_samples += 1
			largest_error = maxf(largest_error, result.left_rendered.origin.distance_to(plant.left_anchor.origin))
			largest_rotation_error = maxf(
				largest_rotation_error,
				result.left_rendered.basis.get_rotation_quaternion().angle_to(
					plant.left_anchor.basis.get_rotation_quaternion()
				)
			)
		if plant.right_planted and plant.right_ik.influence >= 0.99999:
			right_samples += 1
			largest_error = maxf(largest_error, result.right_rendered.origin.distance_to(plant.right_anchor.origin))
			largest_rotation_error = maxf(
				largest_rotation_error,
				result.right_rendered.basis.get_rotation_quaternion().angle_to(
					plant.right_anchor.basis.get_rotation_quaternion()
				)
			)
	expect(left_samples > 20 and right_samples > 20, "Both feet are measured through multiple actual stance windows.")
	expect(largest_error < 0.00001, "Planted ankle translation remains fixed in world space while moving and turning.")
	expect(largest_rotation_error < 0.001, "Planted ankle rotation remains fixed while the visual pivot turns.")
	expect(blended_samples > 10, "Actual IK poses ease in and out of both contact windows.")
	expect(largest_step < 0.04, "Contact transitions cannot snap a foot by several centimetres in one sample.")
	plant.set_motion(false, true, 0.0)
	plant.sample_contacts()
	skeleton.advance(0.0)
	await tree.process_frame
	expect(
		(
			not plant.left_planted
			and not plant.right_planted
			and plant.left_ik.influence == 0.0
			and plant.right_ik.influence == 0.0
		),
		"Stopping releases both feet so idle can use its authored pose."
	)
	var left_stationary := plant.left_anchor
	var right_stationary := plant.right_anchor
	player.advance(0.1)
	plant.sample_contacts()
	skeleton.advance(0.0)
	await tree.process_frame
	expect(
		plant.left_anchor.is_equal_approx(left_stationary) and plant.right_anchor.is_equal_approx(right_stationary),
		"Idle does not recapture walking anchors."
	)
	plant.set_motion(true, false, 0.4)
	plant.sample_contacts()
	expect(not plant.left_planted and not plant.right_planted, "Airborne motion releases both feet.")
	expect(
		plant.left_ik.influence == 0.0 and plant.right_ik.influence == 0.0,
		"Released feet cannot leave an IK correction active."
	)
	plant.set_motion(false, true, 0.0)
	plant.sample_contacts()
	plant.reset()
	expect(not plant.left_planted and not plant.right_planted, "Death and replay resets clear all planted contacts.")
	character.free()
	await tree.process_frame
