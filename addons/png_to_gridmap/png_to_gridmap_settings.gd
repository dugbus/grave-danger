@tool
class_name PNGToGridMapSettings
extends Resource

## Stores the complete reusable configuration for importing, exporting, repairing, and flooring a PNG layout.
## Keeping workflow intent in a resource makes editor operations repeatable across scenes and sessions.

@export var png_path := ""
@export var export_png_path := ""
@export var target_gridmap_path: NodePath
@export var mesh_library_path := ""
@export var gridmap_name := "PNGGridMap"
@export var cell_size := 1.0
## Repairs connected wall pieces shortly after painting stops in the selected GridMap.
@export var auto_repair := false
@export var export_origin := Vector2i.ZERO
@export var export_size := Vector2i.ZERO
@export var color_mappings: Array[Resource] = []
## Generated floor GridMap path used to rebuild the same node on later runs.
@export var floor_gridmap_path: NodePath
## Material applied to every generated floor tile for this level.
@export_file("*.material", "*.tres") var floor_material_path := ""
## Global folder scanned for floor materials shown by the converter.
@export_dir var floor_materials_folder := "res://Assets/environment/floors"
