class_name GDGeneratedBatNoise
extends Node3D

## Turns a generated bat-nest state change into one player-location noise event.

signal noise_triggered(noise_origin: Vector3)

enum WatchedBatState {
    Roosting,
    Swarming,
    FlyingOff,
    Finished,
}

## Bat nest whose first take-off triggers the generated dungeon noise.
@export var bat_nest_path: NodePath = ^"BatNest"

var _previous_state := WatchedBatState.Roosting
var _noise_emitted := false

@onready var _bat_nest := get_node_or_null(bat_nest_path)


func _physics_process(_delta: float) -> void:
    if _noise_emitted or _bat_nest == null or not _bat_nest.has_method("get_bat_nest_state"):
        return
    var current_state := int(_bat_nest.call("get_bat_nest_state")) as WatchedBatState
    if _previous_state == WatchedBatState.Roosting and current_state != WatchedBatState.Roosting:
        _noise_emitted = true
        noise_triggered.emit(global_position)
    _previous_state = current_state
