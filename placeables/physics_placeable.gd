class_name GDPhysicsPlaceable
extends RigidBody3D

## Rigid-body map-item base that releases delayed items from a configurable height.


@warning_ignore("unused_signal")
signal placeable_spawned

const SPAWN_CONTROLLER := preload("res://placeables/placeable_spawn_controller.gd")
const MAP_PLACEABLE_GROUP: StringName = &"map_placeable"

@export_group("Spawn")
## Seconds after level start before this item drops in; zero means it was already present.
@export_range(0.0, 300.0, 0.05, "suffix:s") var spawn_time := 0.0
## Height above the authored position from which a delayed physics item is released.
@export_range(0.0, 20.0, 0.05, "suffix:m") var spawn_drop_height := 3.2
## Initial angular speed applied around a deterministic varied axis when this item drops in.
@export_range(0.0, 30.0, 0.1, "suffix:rad/s") var spawn_spin_speed := 0.0
@export_group("")

var placeable_spawn_controller: Node


func _ready() -> void:
    add_to_group(MAP_PLACEABLE_GROUP)
    if Engine.is_editor_hint() or spawn_time <= 0.0:
        return
    placeable_spawn_controller = SPAWN_CONTROLLER.new() as Node
    placeable_spawn_controller.name = "PlaceableSpawnController"
    add_child(placeable_spawn_controller)
    placeable_spawn_controller.configure(
        self,
        self,
        spawn_time,
        spawn_drop_height,
        true,
        spawn_spin_speed
    )


func is_placeable_spawned() -> bool:
    return placeable_spawn_controller == null or placeable_spawn_controller.is_spawned()
