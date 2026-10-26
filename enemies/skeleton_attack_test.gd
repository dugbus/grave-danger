extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/skeleton_attack.gd")
const SKELETON := preload("res://enemies/skeleton.tscn")
const PLAYER := preload("res://player/player.tscn")
const PREVIEW_PLAYER := preload("res://ui/screens/level_run_playback_player.gd")
const PREVIEW := preload("res://ui/screens/level_run_playback.gd")

enum Interruption { Killed, Removed, Freed, ReplacedAnimation, StoppedAnimation, RemovedVictim }


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://enemies/skeleton_attack.gd")
	var host := GDAudio.PLAYBACK_HOST
	var previous_executor := host.executor
	host.executor = func(_audio: Node) -> void: pass
	await _test_confirmed_contact_sequence(tree)
	for interruption in Interruption.values():
		await _test_interrupted_attack(tree, interruption as Interruption)
	_test_missing_attack_falls_back_to_death(tree)
	_test_preview_attack_stays_inside_preview(tree)
	host.executor = previous_executor


# Flow: Real contact locks both carriers, faces the actors, plays the complete attack, then starts death once.
func _test_confirmed_contact_sequence(tree: SceneTree) -> void:
	var fixture := _create_fixture(tree)
	var enemy := fixture.get_node(^"Skeleton") as GDSkeletonPath
	var player := fixture.get_node(^"Player") as GDPlayer
	var death := player.death_controller as DeathHarness
	var animation := player.animation_controller as GDPlayerAnimation
	player.rotation.y = 0.6
	animation.play_stagger(enemy.path_follow.global_position)
	player.velocity = Vector3(2.0, 3.0, 4.0)
	await tree.physics_frame
	await tree.process_frame
	await tree.physics_frame
	var before_player := player.global_transform
	var before_enemy := enemy.path_follow.global_transform
	enemy._update_kill_overlaps(enemy.kill_confirmation_time * 0.5)
	expect(not enemy.attack_controller.is_attacking(), "Brief contact retains the existing confirmation interval.")
	enemy._update_kill_overlaps(enemy.kill_confirmation_time * 0.5)
	expect(enemy.attack_controller.is_attacking(), "Confirmed physics overlap starts the skeleton attack.")
	expect(death.is_waiting_for_enemy_attack() and player.is_dead(), "Lethal contact reserves the player immediately.")
	expect(player.velocity.is_zero_approx(), "Capture immediately removes horizontal and vertical momentum.")
	expect(not animation.is_staggering(), "Capture replaces a prior stagger with the waiting pose.")
	expect((player.attention as GDPlayerAttention).tracking_stopped, "Live head glances release the captured facing.")
	expect_equal(enemy.animation_player.assigned_animation, "attack", "Contact selects the animated attack clip.")
	player.die_from_flames()
	player.apply_spike_trap_damage(100.0)
	expect(death.is_waiting_for_enemy_attack(), "Other hazards cannot interrupt the reserved lethal contact.")
	_expect_facing(animation.pivot, enemy.path_follow.global_position, "The player faces the attacking skeleton.")
	_expect_facing(enemy.pivot, player.global_position, "The skeleton faces its victim.")

	var second_enemy := SKELETON.instantiate() as GDSkeletonPath
	second_enemy.name = "SecondSkeleton"
	fixture.add_child(second_enemy)
	second_enemy.set_physics_process(false)
	expect(not second_enemy.attack_controller.try_start(player), "A second skeleton cannot claim the captured player.")
	Input.action_press(&"move_down")
	Input.action_press(&"jump")
	Input.action_press(&"drop_carried")
	for tick in 20:
		player._physics_process(1.0 / 60.0)
		enemy._physics_process(1.0 / 60.0)
	Input.action_release(&"move_down")
	Input.action_release(&"jump")
	Input.action_release(&"drop_carried")
	expect_equal(player.global_transform, before_player, "Input, gravity and momentum cannot move the captured player.")
	expect_equal(enemy.path_follow.global_transform, before_enemy, "The skeleton remains at its contact position.")
	expect_equal((player.inventory as GDPlayerInventory).drop_hold_time, 0.0, "Capture also blocks held drop input.")
	expect(not player.increase_inventory_space(1), "Pickups cannot alter the captured player's inventory.")
	_expect_facing(animation.pivot, enemy.path_follow.global_position, "Held input cannot turn the player away.")

	var clip := enemy.animation_player.get_animation(&"attack")
	enemy.animation_player.advance(clip.length - 0.01)
	expect(death.is_waiting_for_enemy_attack(), "The player waits through the entire attack animation.")
	expect_equal(death.scream_count, 0, "The death scream waits until the attack finishes.")
	expect_equal(death.lose_count, 0, "The lose-screen countdown cannot obscure the attack.")
	expect_equal(animation.playback_state, GDPlayerAnimation.PlaybackState.Locomotion, "The player still holds idle.")
	enemy.animation_player.advance(0.02)
	expect(not enemy.attack_controller.is_attacking(), "Animation completion releases the skeleton's attack state.")
	expect_equal(
		animation.playback_state, GDPlayerAnimation.PlaybackState.Death, "Player death follows attack completion."
	)
	expect_equal(death.scream_count, 1, "Attack completion starts the normal death scream once.")
	expect_equal(death.lose_count, 1, "The normal lose-screen countdown starts after the player death pose.")
	death.finish_enemy_attack()
	enemy.attack_controller.finish_attack()
	expect_equal(death.lose_count, 1, "Repeated completion cannot restart the death flow.")
	fixture.free()
	await tree.process_frame


# Flow: Removing either actor or interrupting the clip releases the attack without leaving a frozen player.
func _test_interrupted_attack(tree: SceneTree, interruption: Interruption) -> void:
	var fixture := _create_fixture(tree)
	var enemy := fixture.get_node(^"Skeleton") as GDSkeletonPath
	var player := fixture.get_node(^"Player") as GDPlayer
	var death := player.death_controller as DeathHarness
	enemy._kill_body_if_player(player)
	expect(enemy.attack_controller.is_attacking(), "The interruption fixture starts a real attack.")
	match interruption:
		Interruption.Killed:
			enemy.death_disappear_delay = 0.01
			enemy.death_disappear_duration = 0.01
			enemy.die_from_spike_trap()
			await tree.create_timer(0.05).timeout
		Interruption.Removed:
			fixture.remove_child(enemy)
			player._physics_process(1.0 / 60.0)
			enemy.free()
		Interruption.Freed:
			enemy.free()
			player._physics_process(1.0 / 60.0)
		Interruption.ReplacedAnimation:
			enemy.animation_player.play(&"idle")
			enemy._physics_process(1.0 / 60.0)
		Interruption.StoppedAnimation:
			enemy.animation_player.stop()
			enemy._physics_process(1.0 / 60.0)
		Interruption.RemovedVictim:
			player.free()
			enemy._physics_process(1.0 / 60.0)
			expect(not enemy.attack_controller.is_attacking(), "A removed victim releases the skeleton's attack.")
	if interruption != Interruption.RemovedVictim:
		expect(not death.is_waiting_for_enemy_attack(), "An interrupted attack releases the player's waiting phase.")
		expect_equal(death.lose_count, 1, "An interrupted lethal attack completes the death flow exactly once.")
	fixture.free()
	await tree.process_frame


# Flow: A model without an attack clip still completes ordinary enemy death instead of locking the player.
func _test_missing_attack_falls_back_to_death(tree: SceneTree) -> void:
	var fixture := _create_fixture(tree)
	var enemy := fixture.get_node(^"Skeleton") as GDSkeletonPath
	var player := fixture.get_node(^"Player") as GDPlayer
	var death := player.death_controller as DeathHarness
	enemy.animation_player.get_animation_library(&"").remove_animation(&"attack")
	enemy._kill_body_if_player(player)
	expect(not enemy.attack_controller.is_attacking(), "A missing clip cannot start an incomplete attack.")
	expect(not death.is_waiting_for_enemy_attack() and death.is_dead, "Missing animation falls back to ordinary death.")
	expect_equal(death.lose_count, 1, "The missing-animation fallback completes the death flow.")
	fixture.free()


# Flow: Preview animation holds idle through the attack and plays death without invoking a real scene transition.
func _test_preview_attack_stays_inside_preview(tree: SceneTree) -> void:
	var fixture := _create_fixture(tree, true)
	var enemy := fixture.get_node(^"Skeleton") as GDSkeletonPath
	var player := fixture.get_node(^"Player") as GDLevelRunPlaybackPlayer
	var death := player.death_controller as DeathHarness
	var animation := player.animation_controller as GDPlayerAnimation
	var preview := PREVIEW.new() as GDLevelRunPlayback
	preview.playback_player = player
	preview.animation_controller = animation
	enemy._kill_body_if_player(player)
	preview._update_animation(0.1, 0)
	expect(player.is_waiting_for_skeleton_attack() and player.is_dead(), "The preview reserves its own contact state.")
	expect_equal(animation.playback_state, GDPlayerAnimation.PlaybackState.Locomotion, "The preview waits in idle.")
	player.die_from_enemy()
	expect(player.is_waiting_for_skeleton_attack(), "Other preview damage cannot skip the attack.")
	enemy.animation_player.advance(enemy.animation_player.get_animation(&"attack").length + 0.01)
	preview._update_animation(0.1, 0)
	expect(
		not player.is_waiting_for_skeleton_attack() and player.playback_dead,
		"Attack completion kills only the preview."
	)
	expect_equal(
		animation.playback_state, GDPlayerAnimation.PlaybackState.Death, "The preview then shows player death."
	)
	expect(not death.is_dead, "The real death controller stays untouched throughout preview contact.")
	expect_equal(death.lose_count, 0, "Preview attacks cannot schedule a real lose-screen transition.")
	preview.free()
	fixture.free()


func _create_fixture(tree: SceneTree, preview: bool = false) -> SubViewport:
	var fixture := SubViewport.new()
	fixture.own_world_3d = true
	var player := PLAYER.instantiate() as GDPlayer
	if preview:
		player.set_script(PREVIEW_PLAYER)
	var original_death := player.get_node(^"PlayerDeath")
	player.remove_child(original_death)
	original_death.free()
	var death := DeathHarness.new()
	death.name = "PlayerDeath"
	player.add_child(death)
	fixture.add_child(player)
	var enemy := SKELETON.instantiate() as GDSkeletonPath
	enemy.position.z = 0.4
	fixture.add_child(enemy)
	tree.root.add_child(fixture)
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	death.death_effects = null
	enemy.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return fixture


func _expect_facing(pivot: Node3D, target: Vector3, message: String) -> void:
	var direction := target - pivot.global_position
	direction.y = 0.0
	expect(pivot.global_basis.z.normalized().dot(direction.normalized()) > 0.999, message)


class DeathHarness:
	extends GDPlayerDeath
	var scream_count := 0
	var lose_count := 0

	func _ready() -> void:
		pass

	func _play_death_scream() -> void:
		scream_count += 1

	func _show_lose_screen_after_death() -> void:
		lose_count += 1
