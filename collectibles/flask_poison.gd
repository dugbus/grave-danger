@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskPoison


@export_range(0.1, 999.0, 0.1, "or_greater") var poison_damage_points := 25.0
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var poison_duration := 6.0


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"poison"
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("apply_temporary_poison_damage"):
		return false

	return body.apply_temporary_poison_damage(poison_damage_points, poison_duration)


func _get_hud_countdown_seconds() -> float:
	return poison_duration
