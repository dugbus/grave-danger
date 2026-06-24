@tool
extends "res://collectibles/flask_base.gd"
class_name GDFlaskPickupRadius


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"pickup_radius"
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("increase_pickup_radius_percent_for"):
		return false

	return body.increase_pickup_radius_percent_for(
		FLASK_PROPERTIES.pickup_radius_percent,
		FLASK_PROPERTIES.pickup_radius_seconds
	)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.pickup_radius_seconds
