extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skellie/skellie.gd")
const MODEL := preload("res://enemies/skellie/skellie.tscn")
const IMPORTED_MODEL := preload("res://enemies/skellie/skellie.glb")
const ENEMY := preload("res://enemies/skeleton.tscn")
const LEGACY_WALK_DURATION := 2.0 / 3.0
const LEGACY_WALK_SPEED := 0.45
const DEATH_DURATION := 2.0 / 3.0


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/skellie/skellie.gd")
	_test_animation_adaptation_is_local(tree)
	_test_walk_and_idle_animate_without_moving_carrier(tree)
	await _test_death_disables_contact_and_disappears(tree)


# Flow: Each model exposes the old animation names without changing the imported asset or other instances.
func _test_animation_adaptation_is_local(tree: SceneTree) -> void:
	var imported := IMPORTED_MODEL.instantiate() as Node3D
	var source := GDEnemyPresentation.find_animation_player(imported)
	var original_library := source.get_animation_library(&"")
	var model := MODEL.instantiate() as SUBJECT
	var second := MODEL.instantiate() as SUBJECT
	tree.root.add_child(model)
	tree.root.add_child(second)
	var player := model.animation_player
	expect(player.get_animation(&"idle") == player.get_animation(&"rest"), "Idle uses the authored rest animation.")
	for clip in [&"walk", &"rest", &"attack", &"walkreal", &"restreal", &"attackreal", &"die"]:
		expect(player.has_animation(clip), "The integrated model retains animation %s." % clip)
	expect(not source.has_animation(&"idle") and not source.has_animation(&"die"), "Imported clips stay read-only.")
	expect(
		(
			player.get_animation_library(&"") != original_library
			and player.get_animation_library(&"") != second.animation_player.get_animation_library(&"")
		),
		"Animation aliases belong to each model instance."
	)
	expect(
		model.position.is_zero_approx() and model.rotation.is_zero_approx(),
		"The visual stays centred on the original patrol position and faces the original forward direction."
	)
	model.free()
	second.free()
	imported.free()


# Flow: The new rig really walks and idles while locomotion timing and the carrier transform stay unchanged.
func _test_walk_and_idle_animate_without_moving_carrier(tree: SceneTree) -> void:
	var enemy := ENEMY.instantiate() as GDSkeletonPath
	enemy.position = Vector3(7.0, 2.0, -3.0)
	tree.root.add_child(enemy)
	enemy.set_physics_process(false)
	var player := enemy.animation_player
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var rig := enemy.character.get_node(^"rig_deform/Skeleton3D") as Skeleton3D
	var leg := rig.find_bone("DEF-thigh.L")
	expect(leg >= 0, "The replacement has the expected animated leg bone.")
	var before := enemy.path_follow.global_transform
	enemy._update_animation(enemy.shuffle_speed)
	player.advance(0.0)
	var first_rotation := rig.get_bone_pose_rotation(leg)
	player.advance(0.35)
	expect(
		not first_rotation.is_equal_approx(rig.get_bone_pose_rotation(leg)),
		"Walking uses the animated walk clip rather than the static walkreal pose."
	)
	expect(
		is_equal_approx(player.current_animation_length / player.speed_scale, LEGACY_WALK_DURATION / LEGACY_WALK_SPEED),
		"The longer walk clip preserves the previous stride and footstep period."
	)
	for tick in 240:
		enemy._update_animation(enemy.shuffle_speed)
		player.advance(1.0 / 60.0)
	expect_equal(enemy.path_follow.global_transform, before, "Repeated walk cycles never move the patrol carrier.")
	expect(enemy.character.position.is_zero_approx(), "Walking never adds a visual root offset along the patrol.")
	enemy._update_animation(0.0)
	player.advance(0.2)
	expect_equal(player.current_animation, "idle", "Stopping selects the adapted rest clip.")
	var spine := rig.find_bone("DEF-spine")
	var first_position := rig.get_bone_pose_position(spine)
	player.advance(0.3)
	expect(
		not first_position.is_equal_approx(rig.get_bone_pose_position(spine)),
		"Rest uses the animated breathing pose rather than static restreal."
	)
	expect_equal(enemy.path_follow.global_transform, before, "Resting also leaves the patrol carrier untouched.")
	enemy.free()


# Flow: A lethal trap plays a visual fall, disables contact, then uses the existing sink and fade lifecycle.
func _test_death_disables_contact_and_disappears(tree: SceneTree) -> void:
	var host := GDAudio.PLAYBACK_HOST
	var previous_executor := host.executor
	host.executor = func(_audio: Node) -> void: pass
	var enemy := ENEMY.instantiate() as GDSkeletonPath
	enemy.death_disappear_delay = 0.1
	enemy.death_disappear_duration = 0.05
	tree.root.add_child(enemy)
	enemy.set_physics_process(false)
	var player := enemy.animation_player
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var before := enemy.path_follow.global_transform
	enemy.die_from_spike_trap()
	player.advance(DEATH_DURATION)
	var visual := enemy.character.get_node(^"rig_deform") as Node3D
	expect(enemy.is_dead, "The replacement still enters the existing dead state.")
	expect_equal(player.assigned_animation, "die", "Trap deaths select the editable fall animation.")
	expect(
		is_equal_approx(visual.rotation.x, PI / 2.0),
		"The model falls to the floor instead of remaining standing or playing an attack."
	)
	expect_equal(
		enemy.path_follow.global_transform, before, "The death animation does not displace the patrol carrier."
	)
	await tree.physics_frame
	expect(not enemy.kill_area.monitoring, "A dead skeleton cannot kill the player.")
	expect_equal(enemy.skeleton_body.collision_layer, 0, "A dead skeleton no longer blocks enemies.")
	await tree.create_timer(0.25).timeout
	expect(not enemy.drop_pivot.visible, "The replacement disappears after the existing sink and fade.")
	host.executor = previous_executor
	enemy.free()
