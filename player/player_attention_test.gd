extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_attention.gd")
const SUBJECT_PATH := "res://player/player_attention.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _test_rigged_attention(tree)


# Flow: Attention on the current player rig reaches the rendered head and moving lamp.
func _test_rigged_attention(tree: SceneTree) -> void:
	var player := CharacterBody3D.new()
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	player.add_child(pivot)
	var container := Node3D.new()
	container.name = "Character"
	pivot.add_child(container)
	var character := (load("res://player/andy_rigged.tscn") as PackedScene).instantiate() as Node3D
	character.name = "NewCharacter"
	container.add_child(character)
	var direction := Node3D.new()
	direction.name = "LookDirection"
	pivot.add_child(direction)
	var lamp := SpotLight3D.new()
	lamp.name = "PlayerHeadlampLight"
	pivot.add_child(lamp)
	var attention := SUBJECT.new() as GDPlayerAttention
	player.add_child(attention)
	tree.root.add_child(player)
	player.set_physics_process(false)
	await tree.process_frame
	var skeleton := attention.head_skeleton
	skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	attention.set_process(false)
	var look := attention.head_look
	expect(look != null, "The current character resolves a rigged head modifier.")
	var lamp_offset := attention.headlamp_head_offset
	attention.current_head_yaw = 0.5
	attention.update_attention(0.0)
	expect(is_equal_approx(look.head_yaw, 0.5), "Attention forwards its turn to the rig.")
	player.position.x += 2.0
	skeleton.advance(0.0)
	await tree.process_frame
	attention._process(0.0)
	expect(
		(attention._rigged_head_transform().affine_inverse() * attention.headlamp.global_transform).is_equal_approx(
			lamp_offset
		),
		"The lamp follows the turned head while the player travels."
	)
	attention.stop_tracking()
	expect(is_zero_approx(look.head_yaw), "Death clears the retained skeleton head turn.")
	attention.update_attention(1.0)
	expect(is_zero_approx(attention.current_head_yaw), "Dead attention cannot acquire a new glance.")
	expect(not attention.is_processing(), "Death stops live attention presentation.")
	skeleton.advance(0.0)
	await tree.process_frame
	var head_bone := skeleton.find_bone("DEF-spine.006")
	expect(
		look.head_transform.is_equal_approx(skeleton.get_bone_global_pose(head_bone)),
		"The dead head retains its authored pose without procedural enemy tracking."
	)
	player.free()
	await tree.process_frame
