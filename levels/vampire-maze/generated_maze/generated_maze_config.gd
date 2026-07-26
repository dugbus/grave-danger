@tool
class_name GDGeneratedMazeConfig
extends Resource

## Reusable dimensions and generation rules for a seeded GridMap maze.
## Keeping these values in a resource lets runtime dungeon creation use the same
## generator as the authored Vampire Maze scene.

## Number of GridMap cells generated along the local X axis.
@export_range(7, 257, 1) var width := 31:
    set(value):
        if width == value:
            return
        width = value
        emit_changed()
## Number of GridMap cells generated along the local Z axis.
@export_range(7, 257, 1) var height := 31:
    set(value):
        if height == value:
            return
        height = value
        emit_changed()
## Width, in tiles, of every carved room and connecting passage.
@export_range(1, 8, 1) var hallway_width := 2:
    set(value):
        if hallway_width == value:
            return
        hallway_width = value
        emit_changed()
## Percentage of closed internal connections opened to create size-scaled escape loops.
@export_range(0.0, 100.0, 1.0, "suffix:%") var internal_connection_percent := 15.0:
    set(value):
        if is_equal_approx(internal_connection_percent, value):
            return
        internal_connection_percent = value
        emit_changed()
## Optional development corridor along the player's map edge; normally disabled.
@export var carve_spawn_sightline := false:
    set(value):
        if carve_spawn_sightline == value:
            return
        carve_spawn_sightline = value
        emit_changed()
## When enabled, a bottom-row passage opens through a straight border run for the end gate.
@export var carve_end_gate_opening := true:
    set(value):
        if carve_end_gate_opening == value:
            return
        carve_end_gate_opening = value
        emit_changed()
## PNG-to-GridMap repair profile used to turn base wall cells into joins and ends.
@export var wall_repair_settings: Resource:
    set(value):
        if wall_repair_settings == value:
            return
        wall_repair_settings = value
        emit_changed()
## Strategic treasure, coffin, key, door, and bat budgets generated into the maze.
@export var content_configuration: Resource:
    set(value):
        if content_configuration == value:
            return
        content_configuration = value
        emit_changed()
