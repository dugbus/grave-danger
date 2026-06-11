@tool
class_name PNGToGridMapSettings
extends Resource

@export var png_path := ""
@export var export_png_path := ""
@export var target_gridmap_path: NodePath
@export var mesh_library_path := ""
@export var gridmap_name := "PNGGridMap"
@export var cell_size := 1.0
@export var center_cells := true
@export var flip_y_to_world_negative_z := true
@export var ignore_fully_transparent := true
@export var export_origin := Vector2i.ZERO
@export var export_size := Vector2i.ZERO
@export var color_mappings: Array[Resource] = []
