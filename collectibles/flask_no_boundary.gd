@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskNoBoundary


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("remove_for_level"):
		return false

	return kill_boundary.remove_for_level()
