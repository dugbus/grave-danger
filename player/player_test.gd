extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player.gd")
const SUBJECT_PATH := "res://player/player.gd"
const PLAYER_SCENE := preload("res://player/player.tscn")
const VISIBILITY_SCRIPT := preload("res://player/visibility/player_occlusion_silhouette.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	expect(
		player.get_node_or_null("PlaythroughPositionCapture") == null,
		"Reusable player instances cannot capture frontend playback as a live playthrough."
	)
	var collision_shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var capsule := collision_shape.shape as CapsuleShape3D if collision_shape != null else null
	var headlamp := player.get_node_or_null("Pivot/PlayerHeadlampLight") as SpotLight3D
	var fill_light := player.get_node_or_null("Pivot/PlayerLight") as OmniLight3D
	var new_character := player.get_node_or_null("Pivot/Character/NewCharacter") as Node3D
	var legacy_character := player.get_node_or_null("Pivot/Character/LegacyCharacter") as Node3D
	var animation_controller := player.get_node_or_null("PlayerAnimation") as GDPlayerAnimation
	var visibility := player.get_node_or_null("PlayerOcclusionSilhouette") as VISIBILITY_SCRIPT
	expect_equal(
		new_character.scene_file_path if new_character != null else "",
		"res://player/andy_rigged.tscn",
		"The shared player scene uses the replacement character model."
	)
	expect(
		(
			legacy_character != null
			and legacy_character.scene_file_path == "res://Assets/kenney-graveyard/character-keeper.glb"
		),
		"The shared player keeps the legacy character available for missing animations."
	)
	expect(
		(
			animation_controller != null
			and animation_controller.get_node_or_null(animation_controller.character_path) == new_character
			and animation_controller.get_node_or_null(animation_controller.fallback_character_path) == legacy_character
		),
		"The animation controller resolves the new and legacy character models explicitly."
	)
	expect(
		visibility != null and visibility.player_visual_root_path == ^"../Pivot/Character",
		"Every shared player instance owns the configured obstruction silhouette component."
	)
	expect(
		capsule != null and headlamp != null and absf(headlamp.position.z) < capsule.radius,
		"The headlamp source stays inside the player hull instead of entering nearby terrain first."
	)
	expect(
		capsule != null and fill_light != null and absf(fill_light.position.z) < capsule.radius,
		"The fill-light source stays inside the player hull instead of leaking through nearby terrain."
	)
	player.free()
	_test_zombie_damage_reaction()
	await _test_stagger_blocks_physics_movement(tree)


class AnimationSpy:
	extends GDPlayerAnimation
	var stagger_count := 0

	func play_stagger(_attacker_position: Vector3 = Vector3.INF) -> void:
		stagger_count += 1


# Flow: Only positive zombie damage to a surviving player requests the stagger reaction.
func _test_zombie_damage_reaction() -> void:
	var player := SUBJECT.new() as GDPlayer
	var death := GDPlayerDeath.new()
	var animation := AnimationSpy.new()
	player.death_controller = death
	player.animation_controller = animation
	player.apply_zombie_damage(12.0)
	expect_equal(death.flame_energy, 88.0, "Zombie punches drain the existing health pool.")
	expect_equal(animation.stagger_count, 1, "Surviving a punch triggers stagger.")
	player.apply_zombie_damage(0.0)
	player.apply_zombie_damage(-1.0)
	death.is_dead = true
	player.apply_zombie_damage(12.0)
	expect_equal(animation.stagger_count, 1, "Zero damage and dead players do not stagger.")
	player.free()
	death.free()
	animation.free()


class PhysicsAnimationStub:
	extends GDPlayerAnimation
	var advanced := false

	func update_movement(_displacement: Vector3, _delta: float, _grounded: bool) -> void:
		advanced = true
		playback_state = PlaybackState.Locomotion


class DeathStub:
	extends Node
	var is_dead := false


# Flow: A moving player hit by a zombie cannot travel while the reaction owns facing.
func _test_stagger_blocks_physics_movement(tree: SceneTree) -> void:
	var player := SUBJECT.new() as GDPlayer
	player.set_physics_process(false)
	var movement := GDPlayerMovement.new()
	movement.name = "PlayerMovement"
	player.add_child(movement)
	var animation := PhysicsAnimationStub.new()
	animation.name = "PlayerAnimation"
	player.add_child(animation)
	var death := DeathStub.new()
	death.name = "PlayerDeath"
	player.add_child(death)
	for child_name in ["PlayerInventory", "PlayerAttention"]:
		var child := Node.new()
		child.name = child_name
		player.add_child(child)
	tree.root.add_child(player)
	player.set_physics_process(false)
	await tree.process_frame
	animation.playback_state = GDPlayerAnimation.PlaybackState.Stagger
	player.velocity = Vector3(5.0, 0.0, 5.0)
	Input.action_press(&"move_down", 1.0)
	var before := player.position
	player._physics_process(0.1)
	Input.action_release(&"move_down")
	expect(
		Vector2(player.position.x - before.x, player.position.z - before.z).is_zero_approx(),
		"Held input and previous momentum cannot move the player during stagger."
	)
	expect(
		animation.advanced and not animation.is_staggering(),
		"Animation still advances to completion while movement is blocked."
	)
	player.free()
	await tree.process_frame
