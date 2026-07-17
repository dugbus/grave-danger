@tool
extends "res://placeables/collectibles/flask_base.gd"
class_name GDFlaskPoison


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"poison"
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("apply_temporary_poison_damage"):
		return false

	return body.apply_temporary_poison_damage(
		FLASK_PROPERTIES.poison_damage_points,
		FLASK_PROPERTIES.poison_duration
	)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.poison_duration
