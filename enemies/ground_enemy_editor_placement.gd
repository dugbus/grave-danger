@tool
extends Node
class_name GDGroundEnemyEditorPlacement

## Keeps a ground-enemy scene instance on nearby walkable geometry while it is placed in the editor.

const GROUND_SPAWN := preload("res://enemies/ground_spawn.gd")
const EDITOR_SNAP_RETRY_FRAMES := 30

## Node whose world position marks the enemy's intended contact point with the floor.
@export_node_path("Node3D") var floor_sample_path := NodePath()
## Physics layers treated as walkable editor geometry.
@export_flags_3d_physics var collision_mask := 1
## Minimum upward surface normal accepted as walkable ground.
@export_range(0.0, 1.0, 0.01) var minimum_floor_normal_y := 0.65

var _last_placement_position := Vector3(INF, INF, INF)
var _remaining_retry_frames := 0


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	if Engine.is_editor_hint():
		_remaining_retry_frames = EDITOR_SNAP_RETRY_FRAMES


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	var placement_node := get_parent() as Node3D
	if placement_node == null or not placement_node.is_inside_tree():
		return

	if not placement_node.global_position.is_equal_approx(_last_placement_position):
		_last_placement_position = placement_node.global_position
		_remaining_retry_frames = EDITOR_SNAP_RETRY_FRAMES

	if _remaining_retry_frames <= 0:
		return

	_remaining_retry_frames -= 1
	if snap_parent_to_ground():
		_last_placement_position = placement_node.global_position
		_remaining_retry_frames = 0


## Places the owning enemy scene on nearby ground and reports whether a floor was found.
func snap_parent_to_ground() -> bool:
	var placement_node := get_parent() as Node3D
	var floor_sample_node := get_node_or_null(floor_sample_path) as Node3D
	if placement_node == null or floor_sample_node == null \
			or not placement_node.is_inside_tree():
		return false

	return GROUND_SPAWN.snap_to_nearby_floor(
		placement_node,
		floor_sample_node,
		placement_node,
		collision_mask,
		minimum_floor_normal_y
	)
