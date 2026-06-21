extends Node
class_name GDPlayerDeath

const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const WILHELM_SCREAM := preload("res://Assets/audio/wilhelm-scream.mp3")


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
var active_heal_tweens: Array[Tween] = []


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


func can_receive_healing() -> bool:
	return not is_dead and flame_energy < max_flame_energy


func heal_percent_over_time(percent_of_max: float, duration: float) -> bool:
	if not can_receive_healing() or max_flame_energy <= 0.0:
		return false

	var heal_amount := max_flame_energy * maxf(percent_of_max, 0.0) * 0.01
	if heal_amount <= 0.0:
		return false

	var previous_applied_amount := [0.0]
	var tween := create_tween()
	var apply_heal := func(applied_amount: float) -> void:
		var delta_amount := applied_amount - float(previous_applied_amount[0])
		previous_applied_amount[0] = applied_amount
		flame_energy = minf(flame_energy + delta_amount, max_flame_energy)

	active_heal_tweens.append(tween)
	tween.tween_method(apply_heal, 0.0, heal_amount, maxf(duration, 0.01))
	tween.finished.connect(func() -> void: active_heal_tweens.erase(tween))
	return true


func apply_temporary_damage(amount: float, restore_after_seconds: float) -> bool:
	if is_dead:
		return false

	var damage_amount := minf(maxf(amount, 0.0), flame_energy)
	if damage_amount <= 0.0:
		return false

	flame_energy = maxf(flame_energy - damage_amount, 0.0)
	if flame_energy <= 0.0:
		die_from_flames()
		return true

	_restore_temporary_damage_after(damage_amount, restore_after_seconds)
	return true


func die_from_flames() -> void:
	# Multiple flame areas can report the body in the same frame, so death must
	# be idempotent.
	if is_dead:
		return

	is_dead = true
	for tween in active_heal_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	active_heal_tweens.clear()
	_play_death_scream()

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


func _play_death_scream() -> void:
	var sound_player := AudioStreamPlayer.new()
	sound_player.name = "DeathScreamAudio"
	sound_player.stream = WILHELM_SCREAM
	sound_player.volume_db = 2.0
	sound_player.finished.connect(sound_player.queue_free)

	var audio_parent: Node = get_tree().current_scene
	if audio_parent == null:
		if player != null:
			audio_parent = player
		else:
			audio_parent = self
	audio_parent.add_child(sound_player)
	sound_player.play()


func _show_lose_screen_after_death() -> void:
	if showing_lose_screen:
		return

	showing_lose_screen = true
	await get_tree().create_timer(return_delay).timeout

	var tween := SCREEN_FADE.fade_out(self, "DeathFade", fade_out_duration, "DeathFadeLayer")
	await tween.finished

	get_tree().change_scene_to_file(lose_scene)


func _restore_temporary_damage_after(amount: float, seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds, 0.01)).timeout
	if not is_dead:
		flame_energy = minf(flame_energy + amount, max_flame_energy)
