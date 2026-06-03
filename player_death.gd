extends Node


# Death is isolated so hazards only need one public Player method while the
# component owns the one-way transition into the death state.

@export var animation_controller_path: NodePath = ^"../PlayerAnimation"
@export var title_scene := "res://title_screen.tscn"
@export var return_delay := 1.5
@export var fade_out_duration := 0.8
@export var max_flame_energy := 100.0

@onready var player := get_parent() as CharacterBody3D
@onready var animation_controller: Node = get_node_or_null(animation_controller_path)

var is_dead := false
var returning_to_title := false
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

	_return_to_title_after_death()


func _return_to_title_after_death() -> void:
	if returning_to_title:
		return

	returning_to_title = true
	await get_tree().create_timer(return_delay).timeout

	var fade := _create_fade_overlay()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_out_duration)
	await tween.finished

	get_tree().change_scene_to_file(title_scene)


func _create_fade_overlay() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "DeathFadeLayer"
	layer.layer = 100
	add_child(layer)

	var fade := ColorRect.new()
	fade.name = "DeathFade"
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(fade)

	return fade
