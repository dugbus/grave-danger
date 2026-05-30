extends Node


# Death is isolated so hazards only need one public Player method while the
# component owns the one-way transition into the death state.

@export var animation_controller_path: NodePath = ^"../PlayerAnimation"

@onready var player := get_parent() as CharacterBody3D
@onready var animation_controller: Node = get_node_or_null(animation_controller_path)

var is_dead := false


func die_from_flames() -> void:
	# Multiple flame areas can report the body in the same frame, so death must
	# be idempotent.
	if is_dead:
		return

	is_dead = true

	if player != null:
		# Stop active movement immediately; movement component will handle later
		# gravity/deceleration while the player remains dead.
		player.velocity = Vector3.ZERO

	if animation_controller != null:
		animation_controller.play_death()

	# The camera owns the actual death close-up. This component only requests it
	# when the current camera supports that optional method.
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.has_method("focus_on_dead_player"):
		camera.focus_on_dead_player(player)
