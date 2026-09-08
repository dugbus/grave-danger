@tool
class_name FloorStyle
extends Resource

## Reusable visual palette entry kept independent from authored floor topology.

## Human-readable palette name shown by the viewport style painter.
@export var display_name := "Floor style":
	set(value):
		if display_name == value:
			return
		display_name = value
		emit_changed()
## World metres covered by one material UV repeat on tops, sides and pit bottoms.
@export_range(0.01, 100.0, 0.01, "or_greater", "suffix:m") var world_uv_metres := 1.0:
	set(value):
		if is_equal_approx(world_uv_metres, value):
			return
		world_uv_metres = value
		emit_changed()
## Material rendered across walkable top surfaces.
@export var top_material: Material:
	set(value):
		if top_material == value:
			return
		top_material = value
		emit_changed()
## Material rendered on height ledges, hole walls and outer floor boundaries.
@export var edge_material: Material:
	set(value):
		if edge_material == value:
			return
		edge_material = value
		emit_changed()
## Optional material rendered on bounded visual pit bottoms; null omits the bottom.
@export var pit_bottom_material: Material:
	set(value):
		if pit_bottom_material == value:
			return
		pit_bottom_material = value
		emit_changed()
## Minimum visible depth contributed by this style to a connected pit's shared datum.
@export_range(0.0, 100.0, 0.05, "or_greater", "suffix:m") var pit_depth := 2.0:
	set(value):
		if is_equal_approx(pit_depth, value):
			return
		pit_depth = value
		emit_changed()


## Reports settings required by top, exposed-side and optional pit-bottom geometry.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if display_name.strip_edges().is_empty():
		errors.append("FloorStyle needs a display name for the style painter.")
	if world_uv_metres <= 0.0:
		errors.append("FloorStyle world UV metres must be greater than zero.")
	if top_material == null:
		errors.append("FloorStyle needs a top material.")
	if edge_material == null:
		errors.append("FloorStyle needs an edge material for ledges and pit walls.")
	if pit_depth <= 0.0:
		errors.append("FloorStyle needs a positive exposed-side depth.")
	return errors
