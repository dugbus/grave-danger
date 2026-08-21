class_name BreakableWall
extends Node3D

## Plays a single spatial collapse sound once this wall's rigid bricks are genuinely dislodged.


@export_group("Collapse Detection")
## Minimum distance a brick must leave its settled position before the wall counts as breaking.
@export_range(0.0, 1.0, 0.005, "suffix:m") var minimum_collapse_displacement := 0.025
## Minimum brick speed required to distinguish a collapse from a slow nudge or physics jitter.
@export_range(0.0, 10.0, 0.05, "suffix:m/s") var minimum_collapse_speed := 0.5
## Time allowed for the stacked bricks to settle before collapse detection begins.
@export_range(0.0, 5.0, 0.05, "suffix:s") var settling_delay_seconds := 0.75

@export_group("Audio")
## Spatial audio player used for the one-shot collapse sound.
@export var collapse_audio_player_path: NodePath = ^"CollapseAudioPlayer"
@export_group("")

@onready var collapse_audio_player := (
	get_node_or_null(collapse_audio_player_path) as AudioStreamPlayer3D
)

var tracked_bricks: Array[RigidBody3D] = []
var settled_brick_positions: Array[Vector3] = []
var settling_time_remaining := 0.0
var has_played_collapse_audio := false


func _ready() -> void:
	_collect_rigid_bricks()
	settling_time_remaining = settling_delay_seconds
	_snapshot_brick_positions()
	set_physics_process(not tracked_bricks.is_empty())


func _physics_process(delta: float) -> void:
	if has_played_collapse_audio:
		set_physics_process(false)
		return

	if settling_time_remaining > 0.0:
		settling_time_remaining = maxf(settling_time_remaining - delta, 0.0)
		if settling_time_remaining <= 0.0:
			_snapshot_brick_positions()
		return

	for brick_index in tracked_bricks.size():
		var brick := tracked_bricks[brick_index]
		if not is_instance_valid(brick):
			continue

		var displacement := brick.position.distance_to(settled_brick_positions[brick_index])
		if is_collapse_motion(displacement, brick.linear_velocity.length()):
			_play_collapse_audio()
			return


func is_collapse_motion(displacement: float, speed: float) -> bool:
	return (
		displacement >= minimum_collapse_displacement
		and speed >= minimum_collapse_speed
	)


func _collect_rigid_bricks() -> void:
	tracked_bricks.clear()
	for child: Node in get_children():
		if child is RigidBody3D:
			tracked_bricks.append(child as RigidBody3D)


func _snapshot_brick_positions() -> void:
	settled_brick_positions.clear()
	for brick in tracked_bricks:
		settled_brick_positions.append(brick.position)


func _play_collapse_audio() -> void:
	has_played_collapse_audio = true
	if collapse_audio_player != null:
		collapse_audio_player.play()
	set_physics_process(false)
