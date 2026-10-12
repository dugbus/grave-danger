extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_run_playback_player.gd")
const SUBJECT_PATH := "res://ui/screens/level_run_playback_player.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_zombie_damage_isolated()


# Flow: Preview punches stagger survivors and kill only the preview actor at zero health.
func _test_zombie_damage_isolated() -> void:
	var player := SUBJECT.new() as GDLevelRunPlaybackPlayer
	var death := GDPlayerDeath.new()
	var animation := AnimationProbe.new()
	player.death_controller = death
	player.animation_controller = animation
	var attacker := Vector3(2.0, 0.0, 3.0)
	player.apply_zombie_damage(12.0, attacker)
	expect_equal(player.playback_flame_energy, 88.0, "Punches drain preview health.")
	expect_equal(animation.stagger_count, 1, "A surviving preview actor staggers.")
	expect_equal(animation.attacker_position, attacker, "Preview stagger faces its attacker.")
	player.apply_zombie_damage(0.0)
	player.apply_zombie_damage(-1.0)
	expect_equal(animation.stagger_count, 1, "Nonpositive punches do not stagger the preview.")
	expect_equal(player.playback_flame_energy, 88.0, "Nonpositive punches leave health unchanged.")
	player.apply_zombie_damage(88.0, attacker)
	expect(player.is_dead(), "A lethal punch kills the preview actor.")
	expect_equal(animation.death_count, 1, "A lethal preview punch plays death once.")
	expect_equal(animation.stagger_count, 1, "Lethal damage does not stagger the corpse.")
	player.apply_zombie_damage(12.0, attacker)
	expect_equal(animation.death_count, 1, "Further punches cannot repeat preview death.")
	expect(
		not death.is_dead and death.flame_energy == 100.0,
		"Preview punches never reach the real health controller or its lose-screen transition."
	)
	player.free()
	death.free()
	animation.free()


class AnimationProbe:
	extends GDPlayerAnimation
	var stagger_count := 0
	var death_count := 0
	var attacker_position := Vector3.ZERO

	func play_stagger(position_of_attacker: Vector3 = Vector3.INF) -> void:
		stagger_count += 1
		attacker_position = position_of_attacker

	func play_death() -> void:
		death_count += 1
