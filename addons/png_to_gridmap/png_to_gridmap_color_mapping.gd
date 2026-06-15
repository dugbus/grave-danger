@tool
class_name PNGToGridMapColorMapping
extends Resource

@export var colour: Color = Color.WHITE
@export var display_name := ""
@export var base_item_ref := ""
@export_range(0, 3, 1) var base_rotation_offset := 0
@export var autotile_enabled := false
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
