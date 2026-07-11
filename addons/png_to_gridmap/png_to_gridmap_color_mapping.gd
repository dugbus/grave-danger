@tool
class_name PNGToGridMapColorMapping
extends Resource

## Maps one PNG colour to the MeshLibrary pieces and orientation rules it represents.
## Mapping resources keep import, export, and repair behavior editable as reusable profile data.

@export var colour: Color = Color.WHITE
@export var display_name := ""
@export var base_item_ref := ""
@export_range(0, 3, 1) var base_rotation_offset := 0
@export var autotile_enabled := false
## Optional connection group; matching groups repair as one connected autotile type.
@export var autotile_connectivity_group := ""
@export var solo_item_ref := ""
@export_range(0, 3, 1) var solo_rotation_offset := 0
@export var end_item_ref := ""
@export_range(0, 3, 1) var end_rotation_offset := 0
@export var corner_item_ref := ""
@export_range(0, 3, 1) var corner_rotation_offset := 0
@export var tee_item_ref := ""
@export_range(0, 3, 1) var tee_rotation_offset := 0
@export var cross_item_ref := ""
@export_range(0, 3, 1) var cross_rotation_offset := 0
## Placed decorative variants recognised by repair but never selected as repair output.
@export var autotile_alternatives: Array[Resource] = []
