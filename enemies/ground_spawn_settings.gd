extends Resource
class_name GDGroundSpawnSettings

## Shared tuning for correcting ground enemies authored just beneath level geometry.

## Maximum distance above an enemy spawn checked for a nearby walkable floor.
@export var below_floor_search_distance := 0.35
## Small distance below the spawn included so exact floor contact is detected.
@export var floor_contact_epsilon := 0.001
