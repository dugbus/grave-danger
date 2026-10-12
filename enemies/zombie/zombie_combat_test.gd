extends "res://tests/test_case.gd"

const SUBJECT := preload("res://enemies/zombie/zombie_combat.gd")
const SUBJECT_PATH := "res://enemies/zombie/zombie_combat.gd"


# Flow: Landed punches select zombie-specific damage instead of the shared hazard reaction.
func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var target := DamageTarget.new()
	var combat := CombatHarness.new()
	combat.target = target
	combat.attack_damage = 12.0
	expect(combat._apply_attack_damage(), "Punch reports a landed hit.")
	expect_equal(target.zombie_damage, 12.0, "Punch selects zombie-specific damage.")
	expect_equal(target.legacy_damage, 0.0, "Punch does not also trigger generic hit damage.")
	expect_equal(target.attacker_position, Vector3(2.0, 0.0, 3.0), "Punch passes the zombie body position for facing.")
	combat.free()
	target.free()
	_test_attack_reach(tree)


class DamageTarget:
	extends Node3D
	var zombie_damage := 0.0
	var legacy_damage := 0.0
	var attacker_position := Vector3.ZERO

	func apply_zombie_damage(amount: float, position_of_attacker: Vector3) -> void:
		zombie_damage += amount
		attacker_position = position_of_attacker

	func apply_flame_damage(amount: float) -> void:
		legacy_damage += amount


class CombatHarness:
	extends SUBJECT
	var target: Node

	func _get_body_position() -> Vector3:
		return Vector3(2.0, 0.0, 3.0)

	func _get_attack_damage_targets() -> Array[Node]:
		return [target]

	func _is_live_player_body(_body: Node) -> bool:
		return true

	func _play_punch_hit_sound() -> void:
		pass


# Flow: Zombies close to arm reach and distant broad-phase overlaps cannot deal damage.
func _test_attack_reach(tree: SceneTree) -> void:
	var target := DamageTarget.new()
	var combat := ReachHarness.new()
	tree.root.add_child(target)
	tree.root.add_child(combat)
	combat.set_physics_process(false)
	combat.player = target
	combat.overlap_target = target
	target.position.z = 0.6
	expect(combat._can_start_attack(), "An arm-reach player allows a punch.")
	expect(combat._get_attack_damage_targets().has(target), "An arm-reach player can be hit.")
	target.position.z = 0.61
	expect(not combat._can_start_attack(), "The zombie closes the remaining gap before punching.")
	expect(combat._can_continue_attack(), "A small retreat does not flicker attack state.")
	expect(
		combat._get_attack_damage_targets().is_empty(), "Retreat beyond reach avoids damage even inside a broad hitbox."
	)
	target.position.z = 0.95
	expect(not combat._can_start_attack(), "The old attack distance now requires chasing.")
	expect(not combat._can_continue_attack(), "The zombie chases when the player leaves reach.")
	target.free()
	combat.free()


class ReachHarness:
	extends SUBJECT
	var overlap_target: Node

	func _get_body_position() -> Vector3:
		return Vector3.ZERO

	func _get_attack_hitbox_targets(_hitbox: Area3D) -> Array[Node]:
		return [overlap_target]

	func _is_live_player_body(_body: Node) -> bool:
		return true

	func _is_touching_player_collision(_include_slide_collisions := true) -> bool:
		return false
