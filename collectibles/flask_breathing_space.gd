@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskBreathingSpace


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"breathing_space"
	super._ready()


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("expand_runtime_bounds_percent_for"):
		return false

	return kill_boundary.expand_runtime_bounds_percent_for(
		FLASK_PROPERTIES.breathing_space_expansion_percent,
		FLASK_PROPERTIES.breathing_space_seconds,
		FLASK_PROPERTIES.breathing_space_transition_seconds
	)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.breathing_space_seconds
