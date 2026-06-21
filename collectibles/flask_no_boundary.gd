@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskNoBoundary


@export_range(0.05, 5.0, 0.05, "suffix:s") var sink_seconds := 1.0
@export_range(0.1, 20.0, 0.1, "suffix:m") var sink_distance := 3.0


func _apply_effect(_body: Node3D) -> bool:
	var kill_boundary := _get_kill_boundary()
	if kill_boundary == null or not kill_boundary.has_method("remove_for_level"):
		return false

	return kill_boundary.remove_for_level(sink_seconds, sink_distance)
