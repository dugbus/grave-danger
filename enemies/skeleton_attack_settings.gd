extends Resource

## Shared animation tuning for every skeleton's lethal contact attack.

## Playback multiplier for the attack; higher values shorten the player's frozen wait.
@export_range(0.1, 10.0, 0.1) var playback_speed := 1.0
