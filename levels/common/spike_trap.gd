extends Node3D
class_name GDSpikeTrap


enum SpikeTrapState {
    READY,
    ARMING,
    RISING,
    ACTIVE,
    RESETTING,
}

const PLAYER_COLLISION_LAYER := 2
const ZOMBIE_COLLISION_LAYER := 8
const DEFAULT_TRIGGER_SOUND_PATH := "res://Assets/audio/spike-trigger.mp3"
const DEFAULT_HIT_SOUND_PATH := "res://Assets/audio/spike-trigger-hits.mp3"
const DEFAULT_RESET_SOUND_PATH := "res://Assets/audio/spike-going-back-down.mp3"

@export var spikes_pivot_path: NodePath = ^"SpikesPivot"
@export var trigger_area_path: NodePath = ^"TriggerArea"
@export var strike_area_path: NodePath = ^"StrikeArea"

@export_group("Targeting")
@export_flags_3d_physics var target_collision_mask := PLAYER_COLLISION_LAYER | ZOMBIE_COLLISION_LAYER
@export var target_groups: Array[StringName] = [&"player", &"smart_zombie", &"skeleton"]
@export var trigger_area_size := Vector3(1.4, 1.2, 1.4)
@export var strike_area_size := Vector3(1.05, 1.4, 1.05)
@export var target_vertical_min := -0.25
@export var target_vertical_max := 1.9

@export_group("Damage")
@export_range(0.0, 100.0, 0.5, "suffix:%") var damage_percent_of_max_energy := 25.0
@export var enemy_spike_damage_enabled := true

@export_group("Timing")
@export_range(0.0, 2.0, 0.01, "suffix:s") var arming_delay := 0.24
@export_range(0.0, 5.0, 0.01, "suffix:s") var raised_hold_seconds := 1.5
@export_range(0.01, 2.0, 0.01, "suffix:s") var rise_seconds := 0.18
@export_range(0.0, 1.0, 0.01, "suffix:s") var bounce_seconds := 0.12
@export_range(0.0, 1.0, 0.01, "suffix:s") var reset_tension_seconds := 0.42
@export_range(0.01, 4.0, 0.01, "suffix:s") var reset_seconds := 1.8

@export_group("Motion")
@export var hidden_position_y := 0.0
@export var raised_position_y := 1.0
@export var rise_bounce_height := 0.13
@export var reset_tension_lift := 0.08

@export_group("Audio")
@export_file("*.mp3", "*.wav", "*.ogg") var trigger_sound_path := DEFAULT_TRIGGER_SOUND_PATH
@export_file("*.mp3", "*.wav", "*.ogg") var hit_sound_path := DEFAULT_HIT_SOUND_PATH
@export_file("*.mp3", "*.wav", "*.ogg") var reset_sound_path := DEFAULT_RESET_SOUND_PATH
@export var trigger_volume_db := 0.0
@export var hit_volume_db := 1.5
@export var reset_volume_db := -1.5

@onready var spikes_pivot := get_node_or_null(spikes_pivot_path) as Node3D
@onready var trigger_area := get_node_or_null(trigger_area_path) as Area3D
@onready var strike_area := get_node_or_null(strike_area_path) as Area3D

var state := SpikeTrapState.READY
var motion_tween: Tween
var trigger_sound: AudioStream
var hit_sound: AudioStream
var reset_sound: AudioStream


func _ready() -> void:
    add_to_group("spike_trap")
    _load_sounds()
    _configure_area(trigger_area)
    _configure_area(strike_area)

    if trigger_area != null:
        trigger_area.body_entered.connect(_on_trigger_area_body_entered)

    if spikes_pivot != null:
        spikes_pivot.position.y = hidden_position_y


func _physics_process(_delta: float) -> void:
    if state != SpikeTrapState.READY:
        return

    if not _get_targets_in_box(trigger_area_size).is_empty():
        trigger()


func trigger() -> void:
    if state != SpikeTrapState.READY:
        return

    state = SpikeTrapState.ARMING
    _run_cycle.call_deferred()


func get_spike_trap_state() -> SpikeTrapState:
    return state


func is_ready() -> bool:
    return state == SpikeTrapState.READY


func _run_cycle() -> void:
    if state != SpikeTrapState.ARMING:
        return

    await get_tree().create_timer(maxf(arming_delay, 0.0)).timeout
    if not is_inside_tree():
        return

    state = SpikeTrapState.RISING
    var hit_count := _damage_targets_in_strike_area()
    if hit_count > 0:
        _play_sound(hit_sound, "SpikeTrapHitAudio", hit_volume_db)
    else:
        _play_sound(trigger_sound, "SpikeTrapTriggerAudio", trigger_volume_db)

    _animate_rise()

    await get_tree().create_timer(maxf(rise_seconds + bounce_seconds, 0.01)).timeout
    if not is_inside_tree():
        return

    state = SpikeTrapState.ACTIVE
    await get_tree().create_timer(maxf(raised_hold_seconds, 0.0)).timeout
    if not is_inside_tree():
        return

    state = SpikeTrapState.RESETTING
    _play_sound(reset_sound, "SpikeTrapResetAudio", reset_volume_db)
    await _animate_reset()
    if not is_inside_tree():
        return

    state = SpikeTrapState.READY


func _damage_targets_in_strike_area() -> int:
    var damaged_count := 0
    for target in _get_targets_in_box(strike_area_size):
        if _damage_target(target):
            damaged_count += 1

    return damaged_count


func _damage_target(target: Node) -> bool:
    if not _is_live_target(target):
        return false

    if target.has_method("apply_spike_trap_damage"):
        target.call("apply_spike_trap_damage", damage_percent_of_max_energy)
        return true

    if enemy_spike_damage_enabled and target.has_method("die_from_spike_trap"):
        target.call("die_from_spike_trap")
        return true

    if target.has_method("die_from_flames"):
        target.call("die_from_flames")
        return true

    return false


func _get_targets_in_box(box_size: Vector3) -> Array[Node]:
    var targets: Array[Node] = []

    if trigger_area != null:
        for body in trigger_area.get_overlapping_bodies():
            _append_target_if_inside(targets, body, box_size)

    if strike_area != null:
        for body in strike_area.get_overlapping_bodies():
            _append_target_if_inside(targets, body, box_size)

    var tree := get_tree()
    if tree == null:
        return targets

    for target_group in target_groups:
        for node in tree.get_nodes_in_group(target_group):
            _append_target_if_inside(targets, node, box_size)

    return targets


func _append_target_if_inside(targets: Array[Node], candidate: Object, box_size: Vector3) -> void:
    var target := _resolve_target_node(candidate)
    if target == null or targets.has(target) or not _is_live_target(target):
        return

    var target_position := _get_target_world_position(target)
    if _is_position_inside_local_box(target_position, box_size):
        targets.append(target)


func _resolve_target_node(candidate: Object) -> Node:
    if candidate == null or not candidate is Node:
        return null

    var node := candidate as Node
    while node != null:
        if _can_damage_node(node):
            return node
        node = node.get_parent()

    return null


func _can_damage_node(node: Node) -> bool:
    return (
        node.has_method("apply_spike_trap_damage")
        or node.has_method("die_from_spike_trap")
        or node.has_method("die_from_flames")
    )


func _is_live_target(target: Node) -> bool:
    if target == null:
        return false

    if target.has_method("can_be_hit_by_spike_trap"):
        return bool(target.call("can_be_hit_by_spike_trap"))

    if target.has_method("is_dead"):
        return not bool(target.call("is_dead"))

    return _can_damage_node(target)


func _get_target_world_position(target: Node) -> Vector3:
    if target.has_method("get_spike_trap_position"):
        var target_position: Variant = target.call("get_spike_trap_position")
        if target_position is Vector3:
            return target_position

    if target is Node3D:
        return (target as Node3D).global_position

    return Vector3.INF


func _is_position_inside_local_box(world_position: Vector3, box_size: Vector3) -> bool:
    var local_position := global_transform.affine_inverse() * world_position
    var half_size := box_size * 0.5

    return (
        absf(local_position.x) <= half_size.x
        and absf(local_position.z) <= half_size.z
        and local_position.y >= target_vertical_min
        and local_position.y <= target_vertical_max
    )


func _animate_rise() -> void:
    _stop_motion_tween()
    if spikes_pivot == null:
        return

    spikes_pivot.position.y = hidden_position_y
    motion_tween = create_tween()
    motion_tween.set_trans(Tween.TRANS_QUART)
    motion_tween.set_ease(Tween.EASE_OUT)
    motion_tween.tween_property(
        spikes_pivot,
        "position:y",
        raised_position_y + maxf(rise_bounce_height, 0.0),
        maxf(rise_seconds, 0.01)
    )
    motion_tween.set_trans(Tween.TRANS_SINE)
    motion_tween.set_ease(Tween.EASE_IN_OUT)
    motion_tween.tween_property(
        spikes_pivot,
        "position:y",
        raised_position_y,
        maxf(bounce_seconds, 0.01)
    )


func _animate_reset() -> void:
    _stop_motion_tween()
    if spikes_pivot == null:
        return

    motion_tween = create_tween()
    motion_tween.set_trans(Tween.TRANS_SINE)
    motion_tween.set_ease(Tween.EASE_IN_OUT)
    motion_tween.tween_property(
        spikes_pivot,
        "position:y",
        raised_position_y + maxf(reset_tension_lift, 0.0),
        maxf(reset_tension_seconds, 0.0)
    )
    motion_tween.set_trans(Tween.TRANS_QUAD)
    motion_tween.set_ease(Tween.EASE_IN)
    motion_tween.tween_property(
        spikes_pivot,
        "position:y",
        hidden_position_y,
        maxf(reset_seconds, 0.01)
    )
    await motion_tween.finished


func _stop_motion_tween() -> void:
    if motion_tween != null and motion_tween.is_valid():
        motion_tween.kill()
    motion_tween = null


func _configure_area(area: Area3D) -> void:
    if area == null:
        return

    area.collision_layer = 0
    area.collision_mask = target_collision_mask
    area.monitoring = true
    area.monitorable = false


func _load_sounds() -> void:
    trigger_sound = _load_audio_stream(trigger_sound_path)
    hit_sound = _load_audio_stream(hit_sound_path)
    reset_sound = _load_audio_stream(reset_sound_path)


func _load_audio_stream(sound_path: String) -> AudioStream:
    if sound_path.is_empty():
        return null

    if ResourceLoader.exists(sound_path):
        return load(sound_path) as AudioStream

    if sound_path.to_lower().ends_with(".mp3") and FileAccess.file_exists(sound_path):
        var stream := AudioStreamMP3.new()
        stream.data = FileAccess.get_file_as_bytes(sound_path)
        return stream

    return null


func _play_sound(stream: AudioStream, sound_name: String, volume_db: float) -> void:
    if stream == null:
        return

    var sound_player := AudioStreamPlayer3D.new()
    sound_player.name = sound_name
    sound_player.stream = stream
    sound_player.volume_db = volume_db
    sound_player.finished.connect(sound_player.queue_free)
    add_child(sound_player)
    sound_player.play()


func _on_trigger_area_body_entered(body: Node3D) -> void:
    if state != SpikeTrapState.READY:
        return

    var target := _resolve_target_node(body)
    if target != null and _is_position_inside_local_box(_get_target_world_position(target), trigger_area_size):
        trigger()
