@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskPickupRadius


@export_range(0.0, 500.0, 0.5, "or_greater", "suffix:%") var pickup_radius_percent := 50.0


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("increase_pickup_radius_percent"):
		return false

	return body.increase_pickup_radius_percent(pickup_radius_percent)
