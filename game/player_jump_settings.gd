extends Resource
class_name GDPlayerJumpSettings


@export_group("Height")
## World-space height of the common cemetery wall used as the player jump reference.
@export_range(0.01, 20.0, 0.001, "or_greater", "suffix:m") var wall_height := 0.725
## Fraction of the wall height reached by an unloaded player jump.
@export_range(0.0, 2.0, 0.01, "or_greater") var jump_wall_height_multiplier := 0.5
## Lowest jump velocity multiplier applied when the player is carrying maximum weight.
@export_range(0.0, 1.0, 0.01) var min_weight_jump_multiplier := 0.4

@export_group("Audio")
## Audio sample played when the player starts a jump.
@export_file("*.mp3") var jump_sound_path := "res://Assets/audio/player-jump.mp3"
## Jump sound volume in decibels.
@export_range(-80.0, 24.0, 0.1, "suffix:dB") var jump_volume_db := -1.5
## Lowest random pitch scale used for each jump sound.
@export_range(0.1, 4.0, 0.01) var jump_pitch_min := 0.96
## Highest random pitch scale used for each jump sound.
@export_range(0.1, 4.0, 0.01) var jump_pitch_max := 1.04


func get_jump_height() -> float:
	return maxf(wall_height * jump_wall_height_multiplier, 0.0)


func get_jump_velocity(gravity_magnitude: float) -> float:
	return sqrt(2.0 * maxf(gravity_magnitude, 0.001) * get_jump_height())
