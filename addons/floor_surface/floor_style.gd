@tool
class_name FloorStyle
extends Resource

## Reusable visual palette entry kept independent from authored floor topology.

## Material rendered across walkable top surfaces.
@export var top_material: Material
## Material reserved for exposed ledges and pit walls in later milestones.
@export var edge_material: Material
## Material reserved for optional visual pit bottoms in later milestones.
@export var pit_bottom_material: Material
## Visible depth below a pit's rim, reserved for later pit generation.
@export_range(0.0, 100.0, 0.05, "or_greater", "suffix:m") var pit_depth := 2.0


## Reports material omissions needed by the currently implemented flat-top stage.
func validate_flat_top() -> Array[String]:
	var errors: Array[String] = []
	if top_material == null:
		errors.append("FloorStyle needs a top material for flat floor generation.")
	return errors
