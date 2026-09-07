@tool
class_name FloorStyle
extends Resource

## Reusable visual palette entry kept independent from authored floor topology.

## Material rendered across walkable top surfaces.
@export var top_material: Material
## Material rendered on height ledges, hole walls and outer floor boundaries.
@export var edge_material: Material
## Material reserved for optional visual pit bottoms in later milestones.
@export var pit_bottom_material: Material
## Provisional visible depth of exposed sides; M5 will also use it for authored pits.
@export_range(0.0, 100.0, 0.05, "or_greater", "suffix:m") var pit_depth := 2.0


## Reports settings required by the currently implemented top and exposed-side geometry.
func validate_flat_top() -> Array[String]:
	var errors: Array[String] = []
	if top_material == null:
		errors.append("FloorStyle needs a top material for flat floor generation.")
	if pit_depth <= 0.0:
		errors.append("FloorStyle needs a positive exposed-side depth.")
	return errors
