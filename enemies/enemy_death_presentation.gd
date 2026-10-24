extends RefCounted
class_name GDEnemyDeathPresentation

## Builds the existing parallel sink and fade; the enemy retains its death delay and visibility lifecycle.


static func create_disappear_tween(
	owner: Node,
	drop_pivot: Node3D,
	geometry: Array[GeometryInstance3D],
	duration: float,
	sink_depth: float,
	fade_start_ratio: float
) -> Tween:
	var disappear_duration := maxf(duration, 0.0)
	var fade_delay := disappear_duration * clampf(fade_start_ratio, 0.0, 1.0)
	var fade_duration := maxf(disappear_duration - fade_delay, 0.0)
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	if drop_pivot != null:
		tween.tween_property(drop_pivot, "position:y", drop_pivot.position.y - sink_depth, disappear_duration)
	for instance in geometry:
		tween.tween_property(instance, "transparency", 1.0, fade_duration).set_delay(fade_delay)
	return tween
