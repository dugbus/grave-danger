@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskBreathingSpace


@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var expansion_percent := 25.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var expansion_seconds := 8.0
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:s") var transition_seconds := 1.0


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"breathing_space"
	super._ready()


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("expand_runtime_bounds_percent_for"):
		return false

	return kill_boundary.expand_runtime_bounds_percent_for(expansion_percent, expansion_seconds, transition_seconds)


func _get_hud_countdown_seconds() -> float:
	return expansion_seconds
