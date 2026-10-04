extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_animation.gd")
const SUBJECT_PATH := "res://player/player_animation.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _test_new_clips_replace_legacy_one_state_at_a_time(tree)
	await _test_empty_new_character_uses_t_pose_for_idle(tree)


func _test_new_clips_replace_legacy_one_state_at_a_time(tree: SceneTree) -> void:
	var fixture := _create_fixture([&"walk"])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var new_character := fixture.get_node("Pivot/Character/NewCharacter") as Node3D
	var legacy_character := fixture.get_node("Pivot/Character/LegacyCharacter") as Node3D
	var inventory := InventoryStub.new()

	expect(
		not new_character.visible \
			and legacy_character.visible \
			and controller.current_animation == "idle",
		"A missing new idle clip uses the legacy idle after any new clip exists."
	)
	controller.update_movement(1.0, inventory)
	expect(
		new_character.visible \
			and not legacy_character.visible \
			and controller.current_animation == "walk" \
			and controller.animation_player == controller.primary_animation_player \
			and is_equal_approx(controller.animation_player.speed_scale, 2.0),
		"An available new walk clip replaces the legacy walk state at doubled playback speed."
	)
	controller.play_death()
	expect(
		not new_character.visible \
			and legacy_character.visible \
			and controller.current_animation == "die" \
			and controller.animation_player == controller.fallback_animation_player,
		"A missing new death clip swaps back to the legacy death animation."
	)
	inventory.free()
	fixture.free()
	await tree.process_frame


func _test_empty_new_character_uses_t_pose_for_idle(tree: SceneTree) -> void:
	var fixture := _create_fixture([])
	tree.root.add_child(fixture)
	await tree.process_frame
	var controller := fixture.get_node("PlayerAnimation") as GDPlayerAnimation
	var new_character := fixture.get_node("Pivot/Character/NewCharacter") as Node3D
	var legacy_character := fixture.get_node("Pivot/Character/LegacyCharacter") as Node3D
	var inventory := InventoryStub.new()

	expect(
		controller.idle_uses_t_pose \
			and new_character.visible \
			and not legacy_character.visible \
			and controller.animation_player == null \
			and controller.current_animation.is_empty(),
		"A new character with no authored clips remains in its T-pose while idle."
	)
	controller.update_movement(1.0, inventory)
	expect(
		not new_character.visible \
			and legacy_character.visible \
			and controller.current_animation == "walk",
		"Movement still uses the legacy walk while the new character has no clips."
	)
	controller.update_movement(0.0, inventory)
	expect(
		new_character.visible \
			and not legacy_character.visible \
			and controller.current_animation.is_empty(),
		"Stopping returns from the legacy walk to the new character's T-pose."
	)
	inventory.free()
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


class InventoryStub:
	extends Node


	func weight_multiplier(_normal: float, _minimum: float) -> float:
		return 1.0
