class_name FloorSurfaceTestPlayerSettings
extends Resource

## Shared movement tuning for the isolated floor-surface playground player.

@export_group("Horizontal Movement")
## Fastest horizontal movement speed reached at full input.
@export_range(0.1, 20.0, 0.1, "or_greater", "suffix:m/s") var movement_speed := 5.0
## Horizontal speed gained each second while movement input is held.
@export_range(0.1, 50.0, 0.1, "or_greater", "suffix:m/s²") var acceleration := 18.0
## Horizontal speed lost each second after movement input is released.
@export_range(0.1, 50.0, 0.1, "or_greater", "suffix:m/s²") var deceleration := 24.0

@export_group("Vertical Movement")
## Downward acceleration used by the standalone controller.
@export_range(0.1, 100.0, 0.1, "or_greater", "suffix:m/s²") var gravity := 24.0
## Peak height reached by a jump from a flat standing start.
@export_range(0.05, 10.0, 0.05, "or_greater", "suffix:m") var jump_height := 0.8
## Distance used to keep the player attached to gently descending surfaces.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:m") var floor_snap_length := 0.25
## Provisional vertical rise that later floor fixtures should treat as a walkable step.
@export_range(0.0, 2.0, 0.01, "or_greater", "suffix:m") var maximum_step_height := 0.25
## Steepest provisional surface that the standalone controller treats as floor.
@export_range(0.0, 89.0, 0.5, "suffix:°") var maximum_floor_angle_degrees := 45.0
## World height below which the player returns to the labelled reset point.
@export_range(-100.0, -0.1, 0.1, "or_less", "suffix:m") var fall_reset_y := -3.0


## Returns the upward speed needed to reach the configured jump height.
func get_jump_velocity() -> float:
	return sqrt(2.0 * maxf(gravity, 0.001) * maxf(jump_height, 0.0))


## Returns the CharacterBody floor angle in radians.
func get_maximum_floor_angle_radians() -> float:
	return deg_to_rad(clampf(maximum_floor_angle_degrees, 0.0, 89.0))
