@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskPauseBoundary


@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var pause_seconds := 5.0


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"pause_boundary"
	super._ready()


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("pause_runtime_for"):
		return false

	return kill_boundary.pause_runtime_for(pause_seconds)


func _get_hud_countdown_seconds() -> float:
	return pause_seconds
