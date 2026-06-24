@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskNoBoundary


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"no_boundary"
	super._ready()


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("remove_for_level"):
		return false

	return kill_boundary.remove_for_level(
		FLASK_PROPERTIES.no_boundary_sink_seconds,
		FLASK_PROPERTIES.no_boundary_sink_distance
	)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.no_boundary_display_seconds
