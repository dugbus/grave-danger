@tool
extends Resource

## Shared elevator tuning; travel and boarding choices remain per-instance settings.

## Vertical travel speed in metres per second.
@export_range(0.01, 5.0, 0.01, "suffix:m/s") var speed := 0.75
## Seconds spent at each landing in pausing and player-activated modes.
@export_range(0.0, 10.0, 0.05, "suffix:s") var landing_pause := 1.0
## Thickness below the walkable top of the slab.
@export_range(0.01, 1.0, 0.01, "suffix:m") var thickness := 0.25
## Maximum clearance used to confirm that an item is resting on the platform.
@export_range(0.01, 0.2, 0.005, "suffix:m") var support_margin := 0.06
## Small separation retained before an obstruction to avoid penetration.
@export_range(0.001, 0.02, 0.001, "suffix:m") var collision_margin := 0.002
