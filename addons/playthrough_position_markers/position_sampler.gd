extends Node
class_name GDPlaythroughPositionSampler

## Reports a position without knowing how the authoring tool will transport or display it.
signal position_sampled(level_scene_path: String, elapsed_seconds: float, local_position: Vector3)

const DEFAULT_SETTINGS := preload(
	"res://addons/playthrough_position_markers/playthrough_position_sampling_settings.tres"
)
const SamplingSettings := preload(
	"res://addons/playthrough_position_markers/playthrough_position_sampling_settings.gd"
)

## Shared authoring configuration controlling how often the player position is sampled.
@export var settings: SamplingSettings = DEFAULT_SETTINGS

var tracked_node: Node3D
var level_root: Node3D
var elapsed_seconds := 0.0
var interval_accumulator := 0.0
var sampling := false


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	advance(delta)


## Starts a fresh sample timeline for an explicit tracked node and level root.
func start(new_tracked_node: Node3D, new_level_root: Node3D) -> bool:
	if new_tracked_node == null or new_level_root == null \
			or new_level_root.scene_file_path.is_empty():
		return false

	tracked_node = new_tracked_node
	level_root = new_level_root
	elapsed_seconds = 0.0
	interval_accumulator = 0.0
	sampling = true
	set_physics_process(true)
	_emit_current_sample(0.0)
	return true


## Advances the authoring timeline and emits every sample interval crossed this frame.
func advance(delta: float) -> void:
	if not sampling or not is_instance_valid(tracked_node) or not is_instance_valid(level_root):
		return

	var safe_delta := maxf(delta, 0.0)
	elapsed_seconds += safe_delta
	interval_accumulator += safe_delta
	var sample_interval := maxf(settings.sample_interval_seconds, 0.1) \
		if settings != null else 2.0
	while interval_accumulator >= sample_interval:
		interval_accumulator -= sample_interval
		_emit_current_sample(elapsed_seconds - interval_accumulator)
func _emit_current_sample(sample_time: float) -> void:
	var local_position := level_root.to_local(tracked_node.global_position)
	position_sampled.emit(level_root.scene_file_path, sample_time, local_position)
