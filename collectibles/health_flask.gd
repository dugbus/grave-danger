@tool
extends "res://collectibles/flask_base.gd"
class_name GDHealthFlask


const HEAL_PERCENT_SETTING := "gameplay/health_flask_heal_percent"
const DEFAULT_HEAL_PERCENT := 25.0

@export var heal_duration := 2.0
@export var heal_percent_of_max := -1.0


func _ready() -> void:
	show_hud_countdown = true
	hud_effect_id = &"health_flask"
	add_to_group("health_flask")
	super._ready()


func _apply_effect(body: Node3D) -> bool:
	if not body.has_method("try_collect_health_flask"):
		return false

	var heal_percent := heal_percent_of_max
	if heal_percent < 0.0:
		heal_percent = float(ProjectSettings.get_setting(HEAL_PERCENT_SETTING, DEFAULT_HEAL_PERCENT))
	return body.try_collect_health_flask(self, heal_percent, heal_duration)


func _get_hud_countdown_seconds() -> float:
	return heal_duration
