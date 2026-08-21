@tool
extends Node
class_name GDSpikeTrapEditorPlacement

## Keeps the spike-trap socket plane at a deterministic height while it is edited.

## Local height used whenever a level editor adds or moves the owning spike trap.
@export var fixed_height := 0.03


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		apply_fixed_height()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	apply_fixed_height()


## Places the owning trap at its configured local height and reports whether it was available.
func apply_fixed_height() -> bool:
	var spike_trap := get_parent() as Node3D
	if spike_trap == null or not spike_trap.is_inside_tree():
		return false

	var placement_position := spike_trap.position
	placement_position.y = fixed_height
	spike_trap.position = placement_position
	return true
