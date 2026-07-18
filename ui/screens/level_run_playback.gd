extends SubViewportContainer
class_name GDLevelRunPlayback

## Loads and displays a lightweight replay behind level details.

const RUN_RECORDING := preload("res://game/run_recording.gd")
const PLAYBACK_PLAYER_SCRIPT := preload("res://ui/screens/level_run_playback_player.gd")
const WALK_ANIMATION_CANDIDATES: Array[String] = ["walk", "sprint", "move-forward"]
const IDLE_ANIMATION_CANDIDATES: Array[String] = ["idle", "static"]
const DEATH_ANIMATION_CANDIDATES: Array[String] = ["death", "die", "fall"]
const PREVIEW_DWELL_SECONDS := 0.18
const MUTED_AUDIO_BUS: StringName = &"RunPlaybackMuted"
const FLASK_COLLECTION_DISTANCE := 0.8

enum LoadState {
    Idle,
    ReadingRecording,
    LoadingLevel,
    Playing,
}

@onready var playback_viewport := get_node(^"PlaybackViewport") as SubViewport

var load_state := LoadState.Idle
var request_generation := 0
var active_generation := 0
var active_scene_path := ""
var pending_level_id := ""
var pending_scene_path := ""
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


func _ready() -> void:
    visible = false
    _ensure_muted_audio_bus()
    get_tree().node_added.connect(_on_tree_node_added)
    playback_viewport.own_world_3d = true
    playback_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
    set_process(true)


func show_level_run(level_id: String, scene_path: String) -> void:
    request_generation += 1
    pending_level_id = level_id
    pending_scene_path = scene_path
    request_delay_remaining = PREVIEW_DWELL_SECONDS
    _clear_preview()


func stop_for_scene_change() -> void:
    request_generation += 1
    pending_level_id = ""
    pending_scene_path = ""
    request_delay_remaining = 0.0
    _clear_preview()


func _process(delta: float) -> void:
    request_delay_remaining = maxf(request_delay_remaining - delta, 0.0)
    _poll_recording_read()
    _poll_level_load()
    if load_state == LoadState.Idle and recording_thread == null \
            and request_delay_remaining <= 0.0 and not pending_level_id.is_empty():
        _start_recording_read()
    if load_state == LoadState.Playing:
        _advance_playback(delta)


func _exit_tree() -> void:
    if recording_thread != null and recording_thread.is_started():
        recording_thread.wait_to_finish()
    recording_thread = null


func _start_recording_read() -> void:
    if pending_level_id.is_empty() or pending_scene_path.is_empty():
        load_state = LoadState.Idle
        return

    active_generation = request_generation
    active_scene_path = pending_scene_path
    var level_id := pending_level_id
    pending_level_id = ""
    pending_scene_path = ""
    recording_thread = Thread.new()
    var callable := Callable(RUN_RECORDING, &"load_for_level").bind(level_id)
    var start_error := recording_thread.start(callable)
    if start_error != OK:
        recording_thread = null
        load_state = LoadState.Idle
        return
    load_state = LoadState.ReadingRecording


func _poll_recording_read() -> void:
    if recording_thread == null or recording_thread.is_alive():
        return

    var loaded_recording: Variant = recording_thread.wait_to_finish()
    recording_thread = null
    if active_generation == request_generation and loaded_recording is Dictionary \
            and not loaded_recording.is_empty():
        recording = loaded_recording
        var load_error := ResourceLoader.load_threaded_request(
            active_scene_path,
            "PackedScene",
            true
        )
        load_state = LoadState.LoadingLevel if load_error == OK else LoadState.Idle
    else:
        load_state = LoadState.Idle

    if not pending_level_id.is_empty() and request_delay_remaining <= 0.0:
        _start_recording_read()


func _poll_level_load() -> void:
    if load_state != LoadState.LoadingLevel:
        return
    if active_generation != request_generation:
        load_state = LoadState.Idle
        if recording_thread == null and not pending_level_id.is_empty() \
                and request_delay_remaining <= 0.0:
            _start_recording_read()
        return

    var status := ResourceLoader.load_threaded_get_status(active_scene_path)
    if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        return
    if status != ResourceLoader.THREAD_LOAD_LOADED:
        load_state = LoadState.Idle
        return

    var level_scene := ResourceLoader.load_threaded_get(active_scene_path) as PackedScene
    if level_scene == null:
        load_state = LoadState.Idle
        return
    _create_preview(level_scene)


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
    playback_viewport.add_child(playback_session_root)
    _prepare_preview_tree(playback_level)
    _configure_playback_player(playback_player)
    playback_session_root.add_child(playback_level)
    _configure_playback_player(playback_player)
    _isolate_preview_state(playback_level)
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


func _apply_frame(frame_index: int, interpolation: float) -> void:
    if playback_player == null or playback_camera == null:
        return
    var positions := recording.get("player_positions", PackedVector3Array()) \
        as PackedVector3Array
    var yaws := recording.get("player_yaws", PackedFloat32Array()) as PackedFloat32Array
    var camera_positions := recording.get("camera_positions", PackedVector3Array()) \
        as PackedVector3Array
    var camera_rotations := recording.get("camera_rotations", PackedVector4Array()) \
        as PackedVector4Array
    if frame_index < 0 or frame_index >= positions.size():
        return

    var next_index := mini(frame_index + 1, positions.size() - 1)
    playback_player.global_position = positions[frame_index].lerp(
        positions[next_index],
        interpolation
    )
    if playback_pivot != null:
        playback_pivot.rotation.y = lerp_angle(
            yaws[frame_index],
            yaws[next_index],
            interpolation
        )
    playback_camera.global_position = camera_positions[frame_index].lerp(
        camera_positions[next_index],
        interpolation
    )
    var current_rotation := _vector_to_quaternion(camera_rotations[frame_index])
    var next_rotation := _vector_to_quaternion(camera_rotations[next_index])
    playback_camera.global_basis = Basis(current_rotation.slerp(next_rotation, interpolation))


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
    var low := 0
    var high := frame_times.size() - 1
    while low <= high:
        var middle := floori(float(low + high) * 0.5)
        if frame_times[middle] <= time:
            low = middle + 1
        else:
            high = middle - 1
    return clampi(high, 0, frame_times.size() - 1)


func _prepare_preview_tree(node: Node) -> void:
    if node is Camera3D:
        (node as Camera3D).current = false
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
        _mute_audio_node(node)
    for child in node.get_children():
        _prepare_preview_tree(child)


func _configure_playback_player(player_node: Node3D) -> void:
    if player_node.get_script() != PLAYBACK_PLAYER_SCRIPT:
        player_node.set_script(PLAYBACK_PLAYER_SCRIPT)
    player_node.set_process(false)
    player_node.set_physics_process(false)
    var collision_body := player_node as CollisionObject3D
    if collision_body != null:
        collision_body.collision_mask = 0


func _isolate_preview_state(node: Node) -> void:
    if node is GDTorch:
        node.set_physics_process(false)
    if node is GDTreasureDeposit:
        node.set_physics_process(false)
    if node is GDTextTrigger:
        node.process_mode = Node.PROCESS_MODE_DISABLED
        node.set_process_input(false)
        _disable_preview_area(node as Area3D, false)
    if node is GDFlaskBase:
        node.set_physics_process(false)
        _disable_preview_area(node.get_node_or_null(^"PickupArea") as Area3D)
    if node is GDLockableHingedPassage:
        var completion_path: NodePath = node.get("completion_area_path") as NodePath
        _disable_preview_area(node.get_node_or_null(completion_path) as Area3D)
    for child in node.get_children():
        _isolate_preview_state(child)


func _start_preview_runtime(node: Node) -> void:
    if node is GDKillBoundary3D:
        (node as GDKillBoundary3D).begin_runtime_animation()
    for child in node.get_children():
        _start_preview_runtime(child)


func _disable_preview_area(area: Area3D, stop_monitoring: bool = true) -> void:
    if area == null:
        return
    if stop_monitoring:
        area.set_deferred("monitoring", false)
        area.set_deferred("monitorable", false)
    area.collision_layer = 0
    area.collision_mask = 0


func _collect_preview_flasks() -> void:
    if playback_level == null or playback_player == null:
        return
    if playback_player.has_method("is_dead") and playback_player.is_dead():
        return
    for flask_node in get_tree().get_nodes_in_group(&"flask_pickup"):
        var flask := flask_node as Node3D
        if flask == null or not playback_level.is_ancestor_of(flask):
            continue
        if flask.global_position.distance_to(playback_player.global_position) \
                <= FLASK_COLLECTION_DISTANCE:
            flask.queue_free()


func _ensure_muted_audio_bus() -> void:
    if AudioServer.get_bus_index(MUTED_AUDIO_BUS) < 0:
        AudioServer.add_bus()
        var bus_index := AudioServer.bus_count - 1
        AudioServer.set_bus_name(bus_index, MUTED_AUDIO_BUS)
    AudioServer.set_bus_mute(AudioServer.get_bus_index(MUTED_AUDIO_BUS), true)


func _mute_audio_node(node: Node) -> void:
    node.set("autoplay", false)
    node.set("bus", MUTED_AUDIO_BUS)
    node.call("stop")


func _on_tree_node_added(node: Node) -> void:
    if playback_level == null or not playback_level.is_ancestor_of(node):
        return
    if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
        _mute_audio_node(node)


func _find_animation_player(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child in node.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null


func _find_animation(
    player_node: AnimationPlayer,
    candidates: Array[String]
) -> String:
    for candidate in candidates:
        for animation_name in player_node.get_animation_list():
            if animation_name.to_lower() == candidate:
                return animation_name
    return ""


func _vector_to_quaternion(value: Vector4) -> Quaternion:
    return Quaternion(value.x, value.y, value.z, value.w).normalized()


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
