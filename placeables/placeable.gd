class_name GDPlaceable
extends Node3D

## Common map-item base for authored Node3D placeables.


@warning_ignore("unused_signal")
signal placeable_spawned

const SPAWN_CONTROLLER := preload("res://placeables/placeable_spawn_controller.gd")
const MAP_PLACEABLE_GROUP: StringName = &"map_placeable"

@export_group("Spawn")
## Seconds after level start before this item appears; zero means it was already present.
@export_range(0.0, 300.0, 0.05, "suffix:s") var spawn_time := 0.0
@export_group("")

var placeable_spawn_controller: Node


func _ready() -> void:
    _initialize_placeable_spawn()


func is_placeable_spawned() -> bool:
    return placeable_spawn_controller == null or placeable_spawn_controller.is_spawned()


func _uses_custom_placeable_spawn() -> bool:
    return false


func _get_placeable_spawn_root() -> Node3D:
    return self


func _initialize_placeable_spawn() -> void:
    var spawn_root := _get_placeable_spawn_root()
    if spawn_root != null:
        spawn_root.add_to_group(MAP_PLACEABLE_GROUP)
    if Engine.is_editor_hint() or _uses_custom_placeable_spawn() or spawn_time <= 0.0:
        return

    placeable_spawn_controller = SPAWN_CONTROLLER.new() as Node
    placeable_spawn_controller.name = "PlaceableSpawnController"
    add_child(placeable_spawn_controller)
    placeable_spawn_controller.configure(self, spawn_root, spawn_time, 0.0, false)
