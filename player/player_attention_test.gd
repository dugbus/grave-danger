extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_attention.gd")
const SUBJECT_PATH := "res://player/player_attention.gd"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	await _test_rigged_attention(tree)
	await _test_steady_walking_headlamp(tree)
	await _test_treasure_priority(tree)
	await _test_treasure_visibility(tree)
	await _test_treasure_loses_visibility(tree)


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
	lamp.rotation = Vector3(deg_to_rad(-35.0), PI, 0.0)
	var lamp_rest_basis := lamp.basis
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
		attention.headlamp.global_position.is_equal_approx((attention._rigged_head_transform() * lamp_offset).origin),
		"The lamp stays attached to the turned head while the player travels."
	)
	expect(
		attention.headlamp.global_basis.is_equal_approx(pivot.global_basis * Basis(Vector3.UP, 0.5) * lamp_rest_basis),
		"The lamp follows deliberate head yaw while preserving its authored tilt."
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


# Flow: A full authored walk cycle moves the head without wobbling the beam, even after travel turns.
func _test_steady_walking_headlamp(tree: SceneTree) -> void:
	var fixture := AttentionFixture.new()
	fixture.rotation.y = 0.4
	fixture.position = Vector3(3.0, 0.0, -2.0)
	tree.root.add_child(fixture)
	var attention := fixture.attention
	var lamp := attention.headlamp
	var rest_basis := lamp.global_basis
	var animation := fixture.player.get_node("PlayerAnimation") as GDPlayerAnimation
	var head_basis := attention._rigged_head_transform().basis
	var head_animation_changed := false
	var lamp_stayed_steady := true
	var lamp_stayed_attached := true
	for frame in range(60):
		fixture.player.position.z += 0.04
		animation.update_movement(Vector3(0.0, 0.0, 0.04), 1.0 / 30.0, true)
		await tree.process_frame
		attention._process(0.0)
		var animated_head := attention._rigged_head_transform()
		head_animation_changed = head_animation_changed or not animated_head.basis.is_equal_approx(head_basis)
		lamp_stayed_steady = lamp_stayed_steady and lamp.global_basis.is_equal_approx(rest_basis)
		lamp_stayed_attached = (
			lamp_stayed_attached
			and lamp.global_position.is_equal_approx((animated_head * attention.headlamp_head_offset).origin)
		)
	expect(head_animation_changed, "The regression exercises the imported walk animation's head motion.")
	expect(lamp_stayed_steady, "Animated head pitch, roll and yaw do not wobble the walking beam.")
	expect(lamp_stayed_attached, "The stabilized beam still originates at the animated head attachment.")
	fixture.pivot.rotation.y = -0.8
	attention.current_head_yaw = 0.3
	attention._process(0.0)
	expect(
		lamp.global_basis.is_equal_approx(Basis(Vector3.UP, -0.8 + 0.3) * rest_basis),
		"Travel turns and deliberate glances both turn the steady beam under a rotated parent."
	)
	fixture.free()
	await tree.process_frame


# Flow: Treasure interrupts idle scanning, enemies take priority, and treasure follows a lost enemy.
func _test_treasure_priority(tree: SceneTree) -> void:
	var fixture := AttentionFixture.new()
	tree.root.add_child(fixture)
	var attention := fixture.attention
	attention.update_attention(0.2)
	expect_equal(attention.phase, SUBJECT.AttentionPhase.WanderingGlance, "The resting player is scanning.")
	var coin := fixture.add_coin(Vector3(1.5, 0.0, 2.0))
	await tree.physics_frame
	attention.update_attention(0.2, 1.0)
	expect_equal(attention.get_target_collectible(), coin, "Visible treasure interrupts scanning even at full pace.")
	expect(
		(
			attention.get_current_head_yaw() > deg_to_rad(8.0)
			and attention.get_current_head_yaw() <= attention.get_maximum_head_turn_radians()
		),
		"Treasure gets a deliberate head turn within the safe limit while walking."
	)
	expect(fixture.pivot.rotation.is_zero_approx(), "Looking at treasure preserves travel facing.")
	_expect_lamp_follows_glance(fixture, "The steady beam follows the treasure glance.")
	attention.update_attention(1.0, 1.0)
	attention.update_attention(1.0, 1.0)
	expect_equal(attention.get_target_collectible(), null, "Acknowledged treasure does not hold attention forever.")
	coin.free()

	var enemy := Node3D.new()
	enemy.position = Vector3(-1.0, 0.0, 2.0)
	enemy.add_to_group(SUBJECT.ENEMY_GROUP)
	fixture.add_child(enemy)
	coin = fixture.add_coin(Vector3(1.5, 0.0, 2.0))
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_enemy(), enemy, "A visible enemy takes priority over visible treasure.")
	_expect_lamp_follows_glance(fixture, "The steady beam follows the enemy to the other side.")
	expect_equal(attention.get_target_collectible(), null, "Treasure waits while an enemy holds attention.")
	enemy.hide()
	attention.update_attention(0.1)
	expect_equal(attention.get_target_enemy(), null, "An unavailable enemy releases attention.")
	expect_equal(attention.get_target_collectible(), coin, "Treasure takes over immediately after the enemy is lost.")
	enemy.show()
	attention.update_attention(0.1)
	expect_equal(attention.get_target_enemy(), enemy, "A returning enemy interrupts a treasure glance.")
	expect_equal(attention.get_target_collectible(), null, "Enemy tracking clears the treasure target.")
	fixture.free()
	await tree.process_frame


# Flow: Hidden, collected, distant, rearward, and wall-obscured treasure never attracts attention.
func _test_treasure_visibility(tree: SceneTree) -> void:
	var fixture := AttentionFixture.new()
	tree.root.add_child(fixture)
	var attention := fixture.attention
	var coin := fixture.add_coin(Vector3(0.0, 0.0, -2.0))
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Treasure behind the player is ignored.")
	coin.position = Vector3(0.0, 0.0, 4.0)
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Distant treasure is ignored.")
	coin.position = Vector3(1.5, 0.0, 2.0)
	var hidden_parent := Node3D.new()
	fixture.add_child(hidden_parent)
	coin.reparent(hidden_parent)
	hidden_parent.hide()
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Treasure under a hidden parent is ignored.")
	hidden_parent.show()
	coin.is_being_collected = true
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Treasure being collected is ignored.")
	coin.is_being_collected = false
	var wall := fixture.add_wall()
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "A wall blocks treasure attention.")
	wall.position.x = 10.0
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(
		attention.get_target_collectible(), coin, "Previously obscured treasure attracts attention once visible."
	)
	coin.free()
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Freed treasure safely releases attention.")
	fixture.free()
	await tree.process_frame


# Flow: A treasure glance ends immediately when a wall, travel turn, or collection hides the target.
func _test_treasure_loses_visibility(tree: SceneTree) -> void:
	var fixture := AttentionFixture.new()
	tree.root.add_child(fixture)
	var attention := fixture.attention
	var coin := fixture.add_coin(Vector3(1.5, 0.0, 2.0))
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), coin, "The clear treasure starts a glance.")
	fixture.add_wall()
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "A newly blocking wall releases the active treasure target.")
	coin.free()
	coin = fixture.add_coin(Vector3(-1.5, 0.0, 2.0))
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), coin, "Other visible treasure can interrupt the return to travel.")
	fixture.pivot.rotation.y = PI
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), null, "Turning away releases treasure outside the forward arc.")
	fixture.pivot.rotation.y = 0.0
	coin.free()
	coin = fixture.add_coin(Vector3(-1.0, 0.0, 2.0))
	await tree.physics_frame
	attention.update_attention(0.1)
	expect_equal(attention.get_target_collectible(), coin, "New visible treasure starts another glance.")
	coin.is_being_collected = true
	attention.update_attention(0.1)
	expect_equal(
		attention.get_target_collectible(), null, "Collection immediately releases the active treasure target."
	)
	fixture.free()
	await tree.process_frame


func _expect_lamp_follows_glance(fixture: AttentionFixture, message: String) -> void:
	fixture.attention._process(0.0)
	expect(
		fixture.attention.headlamp.global_basis.is_equal_approx(
			fixture.pivot.global_basis * Basis(Vector3.UP, fixture.attention.current_head_yaw) * fixture.lamp_rest_basis
		),
		message
	)


class AttentionFixture:
	extends Node3D

	var player := (load("res://player/player.tscn") as PackedScene).instantiate() as GDPlayer
	var attention := player.get_node("PlayerAttention") as GDPlayerAttention
	var pivot := player.get_node("Pivot") as Node3D
	var lamp_rest_basis := (player.get_node("Pivot/PlayerHeadlampLight") as SpotLight3D).basis

	func _ready() -> void:
		add_child(player)
		player.set_physics_process(false)
		attention.set_process(false)

	func add_coin(at: Vector3) -> GDInventoryPickup:
		var coin := (load("res://placeables/treasure/gold_coin.tscn") as PackedScene).instantiate() as GDInventoryPickup
		coin.position = at
		coin.freeze = true
		add_child(coin)
		coin.set_physics_process(false)
		return coin

	func add_wall() -> StaticBody3D:
		var wall := StaticBody3D.new()
		wall.position = Vector3(0.75, 0.5, 1.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 2.0, 0.2)
		shape.shape = box
		wall.add_child(shape)
		add_child(wall)
		return wall
