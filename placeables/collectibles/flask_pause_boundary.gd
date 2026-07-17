@tool
extends "res://placeables/collectibles/flask_base.gd"
class_name GDFlaskPauseBoundary


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"pause_boundary"
	super._ready()


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("pause_runtime_for"):
		return false

	return kill_boundary.pause_runtime_for(FLASK_PROPERTIES.pause_boundary_seconds)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.pause_boundary_seconds
