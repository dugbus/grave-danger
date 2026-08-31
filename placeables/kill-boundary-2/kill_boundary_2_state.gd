class_name GDKillBoundary2State
extends RefCounted

## Reused evaluated state passed between composed boundary components.

var position := Vector3.ZERO
var yaw_radians := 0.0
var size := Vector2(8.0, 8.0)
var rounding := 0.0


func set_values(
	state_position: Vector3, state_yaw_radians: float, state_size: Vector2, state_rounding: float
) -> void:
	position = state_position
	yaw_radians = state_yaw_radians
	size = state_size
	rounding = state_rounding
