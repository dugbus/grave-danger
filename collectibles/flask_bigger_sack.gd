@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskBiggerSack


@export_range(1, 999, 1, "or_greater") var extra_inventory_space := 25


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("increase_inventory_space"):
		return false

	return body.increase_inventory_space(extra_inventory_space)
