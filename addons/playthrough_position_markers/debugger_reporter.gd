extends Node
class_name GDPlaythroughPositionDebuggerReporter

const MESSAGE_NAME: StringName = &"playthrough_position_markers:sample"
const RUN_PLAYBACK_SESSION_GROUP: StringName = &"run_playback_session"
const PositionSampler := preload(
	"res://addons/playthrough_position_markers/position_sampler.gd"
)

## Sampler within the capture scene whose neutral sample signal is sent to the editor debugger.
@export var sampler_path := NodePath("Sampler")

@onready var sampler := get_node_or_null(sampler_path) as PositionSampler


func _ready() -> void:
	if sampler == null or not EngineDebugger.is_active():
		return
	sampler.position_sampled.connect(_on_position_sampled)


## Starts capture only for the live gameplay host's explicitly configured player and level.
func capture_playthrough_positions(tracked_node: Node3D, level_root: Node3D) -> bool:
	if is_frontend_playback(tracked_node) \
			or sampler == null or not EngineDebugger.is_active():
		return false
	return sampler.start(tracked_node, level_root)


## Identifies replay-preview descendants so recorded movement cannot overwrite live markers.
func is_frontend_playback(tracked_node: Node) -> bool:
	var ancestor := tracked_node
	while ancestor != null:
		if ancestor.is_in_group(RUN_PLAYBACK_SESSION_GROUP):
			return true
		ancestor = ancestor.get_parent()
	return false


func _on_position_sampled(
	level_scene_path: String,
	elapsed_seconds: float,
	local_position: Vector3
) -> void:
	EngineDebugger.send_message(
		MESSAGE_NAME,
		[level_scene_path, elapsed_seconds, local_position]
	)
