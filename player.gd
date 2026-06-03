extends CharacterBody3D


# Player stays as the public API for other gameplay objects.
# Coins and flame areas still talk to this CharacterBody3D, while the actual
# behavior is split into focused child components below.
@onready var movement: Node = $PlayerMovement
@onready var gold_inventory: Node = $PlayerGoldInventory
@onready var animation_controller: Node = $PlayerAnimation
@onready var death_controller: Node = $PlayerDeath


func _ready() -> void:
	# Randomness is currently used by the pickup sound pitch/volume variation.
	randomize()
	add_to_group("flame_vulnerable")


func _physics_process(delta: float) -> void:
	# Death owns the top-level state gate. A dead player still falls and slides to
	# a stop, but input, pickup, dropping, and walk animation stop immediately.
	if death_controller.is_dead:
		movement.update_dead_motion(delta)
		move_and_slide()
		return

	# Keep the frame order explicit:
	# gravity/jump first, then repeatable drop input, then horizontal movement,
	# then animation from the final input strength.
	movement.apply_gravity_and_jump(delta, gold_inventory)
	gold_inventory.update_drop_input(delta)

	var input_strength: float = movement.update_walk(delta, gold_inventory)
	animation_controller.update_movement(input_strength, gold_inventory)

	move_and_slide()


func try_collect_gold_coin(gold_coin: Node3D) -> bool:
	# Gold coins call this on the player body. The inventory component decides
	# whether the coin is collectible, but death always rejects pickup first.
	if death_controller.is_dead:
		return false

	return gold_inventory.try_collect_gold_coin(gold_coin)


func spend_carried_gold_coin() -> bool:
	if death_controller.is_dead:
		return false

	return gold_inventory.spend_carried_gold_coin()


func get_carried_gold_coins() -> int:
	return gold_inventory.get_carried_gold_coins()


func is_dead() -> bool:
	return death_controller != null and death_controller.is_dead


func die_from_flames() -> void:
	# FlameBoundary calls this on any body that exposes the method.
	death_controller.die_from_flames()


func apply_flame_damage(amount: float) -> void:
	death_controller.apply_flame_damage(amount)


func drain_flame_energy() -> void:
	death_controller.drain_flame_energy()
