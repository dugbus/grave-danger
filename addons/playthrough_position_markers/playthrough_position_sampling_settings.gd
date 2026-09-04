extends Resource
class_name GDPlaythroughPositionSamplingSettings

## Seconds between player-position samples sent to the editor during a debug playthrough.
@export_range(0.1, 60.0, 0.1, "or_greater") var sample_interval_seconds := 2.0
