extends Node3D
class_name GDVampireMaze


const RUN_PLAYBACK_SESSION_GROUP: StringName = &"run_playback_session"
const MAXIMUM_GENERATED_CONTENT_STARTUP_FRAMES := 120

## Player whose successful pickups alert the vampire in this level.
@export var player_path: NodePath = ^"Player"
## Vampire boss that receives last-heard noise targets in this level.
@export var vampire_path: NodePath = ^"Vampire"
## Level-completion gate used by the vampire when it searches after losing the player.
@export var end_gate_path: NodePath = ^"GeneratedMaze/Layout/GeneratedContent/GeneratedLockedGate"
## Generated dungeon content that reports bat disturbances at the player's position.
@export var generated_content_path: NodePath = ^"GeneratedMaze/Layout/GeneratedContent"
## Wall GridMap explicitly used for Vampire navigation and sight occlusion.
@export var wall_grid_map_path: NodePath = ^"GeneratedMaze/Layout/PNGGridMap"

@onready var player := get_node_or_null(player_path) as Node3D
@onready var vampire: Node = get_node_or_null(vampire_path)
@onready var end_gate := get_node_or_null(end_gate_path) as Node3D
@onready var generated_content := get_node_or_null(generated_content_path)

var _runtime_configured := false
var _startup_configuration_frames := 0


func _ready() -> void:
	# Replay previews omit generated runtime content and never run enemy AI.
	if _is_run_playback_preview():
		set_process(false)
		return
	generated_content = get_node_or_null(generated_content_path)
	var generated_maze := get_node_or_null(^"GeneratedMaze")
	if generated_maze != null \
			and generated_maze.has_signal(&"maze_generated") \
			and not generated_maze.maze_generated.is_connected(_on_maze_generated):
		generated_maze.maze_generated.connect(_on_maze_generated)
	# GeneratedMaze may replace its gate during a queued startup regeneration.
	# Keep checking until that deterministic generation pass has completed.
	set_process(not _configure_runtime_if_available())


func _process(_delta: float) -> void:
	if _configure_runtime_if_available():
		set_process(false)
		return
	_startup_configuration_frames += 1
	if _startup_configuration_frames < MAXIMUM_GENERATED_CONTENT_STARTUP_FRAMES:
		return
	# A generator that finished without a gate produces one consolidated dependency
	# diagnostic instead of leaving the Vampire silently inert.
	_configure_runtime()
	set_process(false)


func _configure_runtime_if_available() -> bool:
	if _runtime_configured:
		return true
	var resolved_gate := get_node_or_null(end_gate_path) as Node3D
	if resolved_gate != null:
		_configure_runtime()
		return _runtime_configured
	var current_generated_content := get_node_or_null(generated_content_path)
	var generated_plan: Dictionary = current_generated_content.get_last_plan() \
		if current_generated_content != null \
			and current_generated_content.has_method(&"get_last_plan") \
		else {}
	var generated_gate := current_generated_content.get_end_gate() as Node3D \
		if current_generated_content != null \
		and current_generated_content.has_method(&"get_end_gate") \
		else null
	if generated_gate == null and generated_plan.is_empty():
		return false
	_configure_runtime()
	return _runtime_configured


func _configure_runtime() -> void:
	if _runtime_configured:
		return
	player = get_node_or_null(player_path) as Node3D
	vampire = get_node_or_null(vampire_path)
	end_gate = get_node_or_null(end_gate_path) as Node3D
	generated_content = get_node_or_null(generated_content_path)
	if end_gate == null \
			and generated_content != null \
			and generated_content.has_method(&"get_end_gate"):
		end_gate = generated_content.get_end_gate() as Node3D
	var wall_grid_map := get_node_or_null(wall_grid_map_path) as GridMap
	if vampire != null:
		if not vampire.validate_configuration(player, end_gate, wall_grid_map):
			return
		vampire.configure_navigation(wall_grid_map)
		if generated_content != null \
				and generated_content.has_method("get_vampire_layout_landmarks"):
			vampire.configure_layout_knowledge(
				generated_content.get_vampire_layout_landmarks() as Array[Dictionary]
			)
		if player != null:
			vampire.configure_hunt(player, end_gate, player.global_position)
	else:
		push_error("Vampire Maze configuration invalid; missing: vampire")
		return
	_runtime_configured = true
	if player != null and player.has_signal("pickup_noise_emitted"):
		player.connect(&"pickup_noise_emitted", _on_player_pickup_noise)
	if generated_content != null and generated_content.has_signal("bat_noise_triggered"):
		generated_content.connect(&"bat_noise_triggered", _on_bat_noise)
	if generated_content != null \
			and generated_content.has_signal("vampire_layout_landmarks_changed"):
		generated_content.connect(
			&"vampire_layout_landmarks_changed",
			_on_vampire_layout_landmarks_changed
		)

	for deposit in find_children("*", "Node", true, false):
		if deposit.has_signal("treasure_item_absorbed"):
			deposit.connect(
				&"treasure_item_absorbed",
				_on_coffin_treasure_absorbed.bind(deposit as Node3D)
			)
			if vampire != null \
					and vampire.has_method(&"add_passthrough_obstacle"):
				vampire.add_passthrough_obstacle(deposit.get_parent())


func _on_maze_generated(_seed: int, _generation_result: Dictionary) -> void:
	_configure_runtime()
	if _runtime_configured:
		set_process(false)


func _is_run_playback_preview() -> bool:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.is_in_group(RUN_PLAYBACK_SESSION_GROUP):
			return true
		ancestor = ancestor.get_parent()
	return false


func _on_player_pickup_noise(noise_position: Vector3) -> void:
	if vampire != null:
		vampire.hear_landmark_noise(noise_position)


func _on_bat_noise(noise_position: Vector3) -> void:
	if vampire != null:
		vampire.hear_noise(noise_position)


func _on_coffin_treasure_absorbed(
		_item_type: StringName,
		_value: int,
		deposit: Node3D
) -> void:
	if vampire != null and deposit != null:
		vampire.hear_landmark_noise(deposit.global_position)


func _on_vampire_layout_landmarks_changed(
		layout_landmarks: Array[Dictionary]
) -> void:
	if vampire != null:
		vampire.configure_layout_knowledge(layout_landmarks)


func get_minimap_target() -> Node3D:
	if vampire != null:
		return vampire as Node3D
	return get_node_or_null(vampire_path) as Node3D
