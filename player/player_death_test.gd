extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_death.gd")
const SUBJECT_PATH := "res://player/player_death.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect(
		(SUBJECT as Script).get_source_code().contains("scene_loader.request_scene(lose_scene)"),
		"The lose screen is prepared before a player death transition needs it."
	)
	_test_enemy_death_stops_attention(tree)


# Flow: Lethal enemy damage releases a live glance before starting the death pose.
func _test_enemy_death_stops_attention(tree: SceneTree) -> void:
	var player := CharacterBody3D.new()
	var attention := GDPlayerAttention.new()
	var look := (load("res://player/player_head_look.gd") as GDScript).new() as SkeletonModifier3D
	attention.head_look = look
	attention.current_head_yaw = 0.5
	look.set("head_yaw", 0.5)
	var animation := DeathAnimationProbe.new()
	animation.attention = attention
	var death := DeathHarness.new()
	player.add_child(death)
	tree.root.add_child(player)
	death.player = player
	death.attention = attention
	death.animation_controller = animation
	death.die_from_enemy()
	expect(death.is_dead, "Enemy damage enters the dead state.")
	expect(animation.started_without_tracking, "Death playback begins after clearing the live head turn.")
	player.free()
	animation.free()
	attention.free()
	look.free()


class DeathHarness:
	extends SUBJECT

	func _ready() -> void:
		pass

	func _play_death_scream() -> void:
		pass

	func _show_lose_screen_after_death() -> void:
		pass


class DeathAnimationProbe:
	extends Node
	var attention: GDPlayerAttention
	var started_without_tracking := false

	func play_death() -> void:
		started_without_tracking = attention.tracking_stopped and is_zero_approx(attention.head_look.head_yaw)
