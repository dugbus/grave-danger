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
## Maximum per-channel 8-bit difference used to match PNG pixels to configured colours.
@export_range(0, 32, 1) var colour_match_tolerance := 2
## Repairs connected wall pieces shortly after painting stops in the selected GridMap.
@export var auto_repair := false
## Maximum vertical separation that still joins cardinal autotile neighbours on gently stepped ground.
@export_range(0.0, 10.0, 0.01, "or_greater", "suffix:m") var autotile_vertical_connection_metres := 0.0
@export var export_origin := Vector2i.ZERO
@export var export_size := Vector2i.ZERO
@export var color_mappings: Array[Resource] = []
## PNG colours deliberately removed from the shared mapping list by a level editor.
@export var ignored_colour_keys: Array[String] = []
## Editable FloorSurface path rebuilt by later PNG floor imports in this level.
@export var floor_surface_path: NodePath
## Optional top material applied without replacing the FloorSurface wall material.
@export_file("*.material", "*.tres") var floor_material_path := ""
## Shared project folder scanned for floor finishes shown by the converter.
@export_dir var floor_materials_folder := "res://Assets/environment/floors"
