extends SubViewportContainer
class_name GDLevelRunPlayback

## Loads and displays a lightweight replay behind level details.

const RUN_RECORDING := preload("res://game/run_recording.gd")
const PlaybackFrame := preload("res://ui/screens/level_run_playback_frame.gd")
const PlaybackPreview := preload("res://ui/screens/level_run_playback_preview.gd")
const PlaybackDrift := preload("res://ui/screens/level_run_playback_drift.gd")
const MUTED_AUDIO_BUS: StringName = PlaybackPreview.MUTED_AUDIO_BUS
const WALK_ANIMATION_CANDIDATES: Array[String] = ["walk", "sprint", "move-forward"]
const IDLE_ANIMATION_CANDIDATES: Array[String] = ["idle", "static"]
const DEATH_ANIMATION_CANDIDATES: Array[String] = ["death", "die", "fall"]
const PREVIEW_DWELL_SECONDS := 0.18
const FLASK_COLLECTION_DISTANCE := 0.8
const RUN_PLAYBACK_SESSION_GROUP: StringName = &"run_playback_session"

enum LoadState {
    Idle,
    WaitingForSave,
    ReadingRecording,
    Playing,
}

@onready var playback_viewport := get_node(^"PlaybackViewport") as SubViewport

var load_state := LoadState.Idle
var request_generation := 0
var active_generation := 0
var active_level_id := ""
var active_scene_path := ""
var pending_level_id := ""
var pending_scene_path := ""
var recording_save_task_id := RUN_RECORDING.INVALID_TASK_ID
var recording_thread: Thread
var recording: Dictionary = {}
var active_level_scene: PackedScene
var playback_session_root: Node3D
var playback_level: Node3D
var playback_player: Node3D
var playback_pivot: Node3D
var playback_camera: Camera3D
var animation_player: AnimationPlayer
var walk_animation := ""
var idle_animation := ""
var death_animation := ""
var current_animation := ""
var playback_time := 0.0
var request_delay_remaining := 0.0
var drift_checkpoint_index := 0
var drift_warned_paths: Dictionary = {}


func _ready() -> void:
    visible = false
    PlaybackPreview.ensure_muted_audio_bus()
    get_tree().node_added.connect(_on_tree_node_added)
    playback_viewport.own_world_3d = true
    playback_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    set_process(true)


func show_level_run(level_id: String, scene_path: String) -> void:
    request_generation += 1
    _release_recording_save_task()
    pending_level_id = level_id
    pending_scene_path = scene_path
    request_delay_remaining = PREVIEW_DWELL_SECONDS
    drift_warned_paths.clear()
    _clear_preview()
    set_process(true)


## Clears replay presentation without starting any first-run file or scene loading.
func clear_level_run() -> void:
    request_generation += 1
    _release_recording_save_task()
    pending_level_id = ""
    pending_scene_path = ""
    request_delay_remaining = 0.0
    _clear_preview()
    set_process(false)


func stop_for_scene_change() -> void:
    request_generation += 1
    _release_recording_save_task()
    pending_level_id = ""
    pending_scene_path = ""
    request_delay_remaining = 0.0
    _clear_preview()
    set_process(false)
    await _finish_recording_read()
    active_scene_path = ""


func _process(delta: float) -> void:
    request_delay_remaining = maxf(request_delay_remaining - delta, 0.0)
    _poll_recording_read()
    _poll_recording_save()
    if load_state == LoadState.Idle and recording_thread == null \
            and request_delay_remaining <= 0.0 and not pending_level_id.is_empty():
        _start_recording_read()
    if load_state == LoadState.Playing:
        _advance_playback(delta)


func _exit_tree() -> void:
    request_generation += 1
    _release_recording_save_task()
    if recording_thread != null and recording_thread.is_started():
        recording_thread.wait_to_finish()
    recording_thread = null


func _start_recording_read() -> void:
    if pending_level_id.is_empty() or pending_scene_path.is_empty():
        load_state = LoadState.Idle
        return

    active_generation = request_generation
    active_level_id = pending_level_id
    active_scene_path = pending_scene_path
    pending_level_id = ""
    pending_scene_path = ""
    var level_selection := get_node_or_null("/root/LevelSelection") as GDLevelSelection
    if level_selection != null:
        recording_save_task_id = level_selection.take_run_recording_save_task(active_level_id)
    if recording_save_task_id != RUN_RECORDING.INVALID_TASK_ID:
        if not WorkerThreadPool.is_task_completed(recording_save_task_id):
            load_state = LoadState.WaitingForSave
            return
        WorkerThreadPool.wait_for_task_completion(recording_save_task_id)
        recording_save_task_id = RUN_RECORDING.INVALID_TASK_ID
    _start_recording_thread()


func _start_recording_thread() -> void:
    recording_thread = Thread.new()
    var callable := Callable(RUN_RECORDING, &"load_for_level").bind(active_level_id)
    var start_error := recording_thread.start(callable)
    if start_error != OK:
        recording_thread = null
        load_state = LoadState.Idle
        return
    load_state = LoadState.ReadingRecording


func _poll_recording_save() -> void:
    if load_state != LoadState.WaitingForSave \
            or recording_save_task_id == RUN_RECORDING.INVALID_TASK_ID \
            or not WorkerThreadPool.is_task_completed(recording_save_task_id):
        return

    WorkerThreadPool.wait_for_task_completion(recording_save_task_id)
    recording_save_task_id = RUN_RECORDING.INVALID_TASK_ID
    if active_generation != request_generation:
        load_state = LoadState.Idle
        return
    _start_recording_thread()


func _release_recording_save_task() -> void:
    if recording_save_task_id == RUN_RECORDING.INVALID_TASK_ID:
        return
    if WorkerThreadPool.is_task_completed(recording_save_task_id):
        WorkerThreadPool.wait_for_task_completion(recording_save_task_id)
    else:
        var level_selection := get_node_or_null("/root/LevelSelection") as GDLevelSelection
        if level_selection != null and not active_level_id.is_empty():
            level_selection.register_run_recording_save_task(
                active_level_id,
                recording_save_task_id
            )
    recording_save_task_id = RUN_RECORDING.INVALID_TASK_ID


func _poll_recording_read() -> void:
    if recording_thread == null or recording_thread.is_alive():
        return

    var loaded_recording: Variant = recording_thread.wait_to_finish()
    recording_thread = null
    if active_generation == request_generation and loaded_recording is Dictionary \
            and not loaded_recording.is_empty():
        recording = loaded_recording
        _load_active_level_scene()
    else:
        load_state = LoadState.Idle

    if not pending_level_id.is_empty() and request_delay_remaining <= 0.0:
        _start_recording_read()


func _load_active_level_scene() -> bool:
    var level_scene := load(active_scene_path) as PackedScene
    if level_scene == null:
        load_state = LoadState.Idle
        return false
    _create_preview(level_scene)
    return load_state == LoadState.Playing


func _finish_recording_read() -> void:
    while recording_thread != null and recording_thread.is_alive():
        await get_tree().process_frame
    if recording_thread != null and recording_thread.is_started():
        recording_thread.wait_to_finish()
    recording_thread = null


func _create_preview(level_scene: PackedScene) -> void:
    _remove_preview_world()
    active_level_scene = level_scene
    playback_level = level_scene.instantiate() as Node3D
    if playback_level == null:
        load_state = LoadState.Idle
        return

    playback_player = playback_level.get_node_or_null(^"Player") as Node3D
    if playback_player == null:
        playback_level.free()
        playback_level = null
        _clear_preview()
        return
    playback_session_root = Node3D.new()
    playback_session_root.name = "PlaybackSession"
    playback_session_root.add_to_group(RUN_PLAYBACK_SESSION_GROUP)
    playback_viewport.add_child(playback_session_root)
    _prepare_preview_tree(playback_level)
    _configure_playback_player(playback_player)
    playback_session_root.add_child(playback_level)
    _configure_playback_player(playback_player)
    _isolate_preview_state(playback_level)
    _apply_recorded_run_settings()
    _start_preview_runtime(playback_level)
    playback_pivot = playback_player.get_node_or_null(^"Pivot") as Node3D
    playback_camera = Camera3D.new()
    playback_camera.name = "PlaybackCamera"
    playback_camera.current = true
    playback_camera.fov = float(recording.get("camera_fov", 34.0))
    playback_session_root.add_child(playback_camera)
    animation_player = _find_animation_player(playback_player)
    if animation_player != null:
        walk_animation = _find_animation(animation_player, WALK_ANIMATION_CANDIDATES)
        idle_animation = _find_animation(animation_player, IDLE_ANIMATION_CANDIDATES)
        death_animation = _find_animation(animation_player, DEATH_ANIMATION_CANDIDATES)
        animation_player.process_mode = Node.PROCESS_MODE_DISABLED

    playback_time = 0.0
    drift_checkpoint_index = 0
    _apply_frame(0, 0.0)
    playback_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    visible = true
    load_state = LoadState.Playing


func _advance_playback(delta: float) -> void:
    var duration := float(recording.get("duration", 0.0))
    var frame_times := recording.get("frame_times", PackedFloat32Array()) as PackedFloat32Array
    var frame_deltas := recording.get("frame_deltas", PackedFloat32Array()) as PackedFloat32Array
    if duration <= 0.0 or frame_times.is_empty() or frame_deltas.is_empty():
        return

    if playback_time + delta >= duration:
        _restart_preview()
        return

    playback_time += delta
    var frame_index := _find_frame_index(frame_times, playback_time)
    var interpolation := clampf(
        (playback_time - frame_times[frame_index]) / frame_deltas[frame_index],
        0.0,
        1.0
    )
    _apply_frame(frame_index, interpolation)
    _update_animation(delta, frame_index)
    _collect_preview_flasks()
    _report_playback_drift()


func _apply_frame(frame_index: int, interpolation: float) -> void:
    PlaybackFrame.apply(
        recording,
        playback_player,
        playback_pivot,
        playback_camera,
        frame_index,
        interpolation
    )


func _update_animation(delta: float, frame_index: int) -> void:
    if animation_player == null:
        return
    var movement_inputs := recording.get("movement_inputs", PackedVector2Array()) \
        as PackedVector2Array
    var movement_strength := movement_inputs[frame_index].length() \
        if frame_index < movement_inputs.size() else 0.0
    var playback_actor := playback_player as GDLevelRunPlaybackPlayer
    var is_dead := playback_actor != null and playback_actor.is_dead()
    var requested_animation := death_animation if is_dead \
        else walk_animation if movement_strength > 0.05 else idle_animation
    if not requested_animation.is_empty() and requested_animation != current_animation:
        animation_player.play(requested_animation)
        current_animation = requested_animation
    if not current_animation.is_empty():
        animation_player.speed_scale = 0.5 if is_dead \
            else lerpf(0.45, 1.0, clampf(movement_strength, 0.0, 1.0))
        animation_player.advance(delta)


func _find_frame_index(frame_times: PackedFloat32Array, time: float) -> int:
    return PlaybackFrame.find_frame_index(frame_times, time)


func _prepare_preview_tree(node: Node) -> void:
    PlaybackPreview.prepare_tree(node)


func _configure_playback_player(player_node: Node3D) -> void:
    PlaybackPreview.configure_player(player_node)


func _isolate_preview_state(node: Node) -> void:
    PlaybackPreview.isolate_state(node)


func _start_preview_runtime(node: Node) -> void:
    PlaybackPreview.start_runtime(node)


func _disable_preview_area(area: Area3D, stop_monitoring: bool = true) -> void:
    PlaybackPreview.disable_area(area, stop_monitoring)


func _collect_preview_flasks() -> void:
    if playback_level == null or playback_player == null:
        return
    if playback_player.has_method("is_dead") and playback_player.is_dead():
        return
    for flask_node in get_tree().get_nodes_in_group(&"flask_pickup"):
        var flask := flask_node as GDFlaskBase
        if flask == null or not playback_level.is_ancestor_of(flask):
            continue
        if flask.global_position.distance_to(playback_player.global_position) \
                <= FLASK_COLLECTION_DISTANCE:
            flask._try_collect(playback_player)


func _apply_recorded_run_settings() -> void:
    if playback_player == null:
        return
    var run_metadata := recording.get("run_metadata", {}) as Dictionary
    var settings := run_metadata.get("settings", {}) as Dictionary
    if playback_player.has_method("apply_recorded_run_settings"):
        playback_player.call("apply_recorded_run_settings", settings)
    else:
        playback_player.set_meta(&"recorded_run_settings", settings.duplicate(true))


func _report_playback_drift() -> void:
    drift_checkpoint_index = PlaybackDrift.report_due(
        recording,
        playback_level,
        playback_time,
        drift_checkpoint_index,
        drift_warned_paths
    )


func _report_checkpoint_drift(checkpoint: Dictionary, recorded_level_id: String) -> void:
    PlaybackDrift._report_checkpoint(
        playback_level,
        checkpoint,
        recorded_level_id,
        drift_warned_paths
    )


func _array_to_vector3(value: Variant) -> Vector3:
    return PlaybackDrift._array_to_vector3(value)


func _mute_audio_node(node: Node) -> void:
    PlaybackPreview.mute_audio_node(node)


func _on_tree_node_added(node: Node) -> void:
    if playback_level == null or not playback_level.is_ancestor_of(node):
        return
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
        _mute_audio_node(node)


func _find_animation_player(node: Node) -> AnimationPlayer:
    return PlaybackPreview.find_animation_player(node)


func _find_animation(
    player_node: AnimationPlayer,
    candidates: Array[String]
) -> String:
    return PlaybackPreview.find_animation(player_node, candidates)


func _vector_to_quaternion(value: Vector4) -> Quaternion:
    return PlaybackFrame.vector_to_quaternion(value)


func _restart_preview() -> void:
    if active_level_scene == null:
        return
    _create_preview(active_level_scene)


func _remove_preview_world() -> void:
    playback_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    var previous_session := playback_session_root
    var previous_level := playback_level
    var previous_camera := playback_camera
    playback_session_root = null
    animation_player = null
    playback_player = null
    playback_pivot = null
    playback_level = null
    playback_camera = null
    walk_animation = ""
    idle_animation = ""
    death_animation = ""
    current_animation = ""
    playback_time = 0.0
    drift_checkpoint_index = 0

    if previous_session != null and is_instance_valid(previous_session):
        previous_session.free()
    else:
        if previous_level != null and is_instance_valid(previous_level):
            previous_level.free()
        if previous_camera != null and is_instance_valid(previous_camera):
            previous_camera.free()


func _clear_preview() -> void:
    load_state = LoadState.Idle
    visible = false
    playback_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    playback_time = 0.0
    current_animation = ""
    death_animation = ""
    recording = {}
    active_level_scene = null
    _remove_preview_world()
