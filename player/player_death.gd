extends Node

const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")


# Death is isolated so hazards only need one public Player method while the
# component owns the one-way transition into the death state.

## Node that receives death animation playback requests.
@export var animation_controller_path: NodePath = ^"../PlayerAnimation"
## Scene loaded after the death delay and fade complete.
@export var lose_scene := "res://ui/screens/lose_screen.tscn"
## Seconds to wait after death before starting the lose-screen fade.
@export var return_delay := 1.5
## Seconds used for the black fade before loading the lose screen.
@export var fade_out_duration := 0.8
## Flame energy available before the player dies.
@export var max_flame_energy := 100.0

@onready var player := get_parent() as CharacterBody3D
@onready var animation_controller: Node = get_node_or_null(animation_controller_path)

var is_dead := false
var showing_lose_screen := false
var flame_energy := 100.0


func _ready() -> void:
	flame_energy = max_flame_energy


func apply_flame_damage(amount: float) -> void:
	if is_dead:
		return

	flame_energy = maxf(flame_energy - maxf(amount, 0.0), 0.0)
	if flame_energy <= 0.0:
		die_from_flames()


func drain_flame_energy() -> void:
	if is_dead:
		return

	flame_energy = 0.0
	die_from_flames()


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

	_show_lose_screen_after_death()


func _show_lose_screen_after_death() -> void:
	if showing_lose_screen:
		return

	showing_lose_screen = true
	await get_tree().create_timer(return_delay).timeout

	var tween := SCREEN_FADE.fade_out(self, "DeathFade", fade_out_duration, "DeathFadeLayer")
	await tween.finished

	get_tree().change_scene_to_file(lose_scene)
