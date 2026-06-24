@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskBiggerSack


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"bigger_sack"
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("increase_inventory_space"):
		return false

	return body.increase_inventory_space(FLASK_PROPERTIES.bigger_sack_extra_inventory_space)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.bigger_sack_display_seconds
