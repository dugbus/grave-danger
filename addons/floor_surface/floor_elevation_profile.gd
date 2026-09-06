@tool
class_name FloorElevationProfile
extends Resource

## Shared conversion between integer authored elevation and absolute world height.

## World metres represented by one integer elevation unit.
@export_range(0.01, 10.0, 0.01, "or_greater", "suffix:m") var elevation_unit := 0.25


## Converts integer authored elevation into absolute world-space Y.
func elevation_to_world(elevation: int) -> float:
	return float(elevation) * maxf(elevation_unit, 0.01)


## Reports configuration problems without silently replacing authored tuning.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if elevation_unit <= 0.0:
		errors.append("Elevation unit must be greater than zero metres.")
	return errors
