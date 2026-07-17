@tool
extends "res://placeables/collectibles/flask_base.gd"
class_name GDHealthFlask


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"health_flask"
	add_to_group("health_flask")
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("try_collect_health_flask"):
		return false

	return body.try_collect_health_flask(
		self,
		FLASK_PROPERTIES.health_heal_percent_of_max,
		FLASK_PROPERTIES.health_heal_duration
	)


func _get_hud_countdown_seconds() -> float:
	return FLASK_PROPERTIES.health_heal_duration
