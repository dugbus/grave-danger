@tool
class_name GDBatNest
extends Node3D
## Spawns a clustered bat roost that swarms around the player before scattering upward.


enum BatNestState {
    ROOSTING,
    SWARMING,
    FLYING_OFF,
    FINISHED,
}

const DEFAULT_BAT_SCENE := preload("res://Assets/environment/blender/batty.blend")
const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")
const PLAYER_GROUP: StringName = &"player"
const COMBINED_FLAP_ANIMATION: StringName = &"combined_flap"
const DEFAULT_FLAP_SOUND_PATH := "res://Assets/audio/bat-flap.mp3"
const DEFAULT_SQUEAK_SOUND_PATHS: Array[String] = [
    "res://Assets/audio/bat-squeek-1.mp3",
    "res://Assets/audio/bat-squeek-2.mp3",
]
const MIN_BAT_COUNT := 1
const MAX_BAT_COUNT := 80
const MIN_SPEED := 0.05

## Imported bat scene used for every bat in this nest.
@export var bat_scene: PackedScene = DEFAULT_BAT_SCENE:
    set(value):
        bat_scene = value
        _rebuild_roost()
## Number of bats clustered in the nest.
@export_range(MIN_BAT_COUNT, MAX_BAT_COUNT, 1) var bat_count := 18:
    set(value):
        bat_count = clampi(value, MIN_BAT_COUNT, MAX_BAT_COUNT)
        _rebuild_roost()
## Radius of the resting bat cluster around the nest origin.
@export_range(0.05, 6.0, 0.05, "suffix:m") var cluster_radius := 0.75:
    set(value):
        cluster_radius = maxf(value, 0.05)
        _rebuild_roost()
## Vertical spread used by the resting bat cluster.
@export_range(0.0, 4.0, 0.05, "suffix:m") var cluster_height := 0.65:
    set(value):
        cluster_height = maxf(value, 0.0)
        _rebuild_roost()
## Scale applied to each spawned bat model.
@export_range(0.05, 5.0, 0.01) var bat_scale := 0.35:
    set(value):
        bat_scale = maxf(value, 0.05)
        _rebuild_roost()
## Player distance that causes the nest to take flight.
@export_range(0.1, 20.0, 0.1, "suffix:m") var trigger_radius := 4.0
## Group used to find the player at runtime.
@export var player_group: StringName = PLAYER_GROUP
## Height above the player where bats appear when triggered.
@export_range(0.0, 4.0, 0.05, "suffix:m") var player_spawn_height := 1.15
## Horizontal radius around the player where bats appear when triggered.
@export_range(0.0, 3.0, 0.05, "suffix:m") var player_spawn_radius := 0.55
## Seconds spent harassing the player before the bats scatter.
@export_range(0.0, 15.0, 0.05, "suffix:s") var swarm_seconds := 3.6
## Seconds spent flying away before the runtime bat nodes are removed.
@export_range(0.1, 20.0, 0.05, "suffix:s") var fly_off_seconds := 3.2
## Seconds used to bank from swarm movement into the fly-away direction.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fly_off_turn_seconds := 0.55
## Target height above the player while bats are swarming.
@export_range(0.0, 8.0, 0.05, "suffix:m") var swarm_height := 2.0
## Width of the overhead swarm around the player.
@export_range(0.1, 10.0, 0.05, "suffix:m") var swarm_radius := 1.55
## Maximum bat movement speed during the swarm.
@export_range(0.1, 30.0, 0.1, "suffix:m/s") var swarm_speed := 8.0
## Maximum bat movement speed while flying away.
@export_range(0.1, 40.0, 0.1, "suffix:m/s") var fly_off_speed := 9.5
## Upward velocity added while bats fly away.
@export_range(0.0, 20.0, 0.1, "suffix:m/s") var fly_off_rise_speed := 3.4
## Maximum sideways spread from the shared group fly-off direction.
@export_range(0.0, 90.0, 0.5, "suffix:deg") var fly_off_spread_degrees := 18.0
## Strength used to pull bats toward their local flock center.
@export_range(0.0, 20.0, 0.05) var cohesion_weight := 0.55
## Strength used to align each bat with nearby bat velocity.
@export_range(0.0, 20.0, 0.05) var alignment_weight := 0.25
## Strength used to keep bats from visually stacking in one spot.
@export_range(0.0, 20.0, 0.05) var separation_weight := 2.6
## Distance where separation starts pushing bats apart.
@export_range(0.05, 5.0, 0.05, "suffix:m") var separation_distance := 0.65
## Strength used to pull bats toward erratic targets above the player.
@export_range(0.0, 30.0, 0.05) var player_attraction_weight := 12.0
## Strength of the sideways darting that makes the swarm feel irritating.
@export_range(0.0, 20.0, 0.05) var orbit_weight := 2.2
## Strength of the uneven motion used to avoid a clean circular orbit.
@export_range(0.0, 20.0, 0.05) var annoyance_weight := 5.5
## Animation playback speed used for frantic wing flapping.
@export_range(0.1, 8.0, 0.05) var flap_animation_speed_scale := 3.0
@export_group("Audio")
## Bat wing flap one-shot sample used by the nest.
@export_file("*.mp3", "*.wav", "*.ogg") var flap_sound_path := DEFAULT_FLAP_SOUND_PATH
## Volume for each bat flap one-shot.
@export var flap_sound_volume_db := 4.0
## Lowest random pitch used for bat flap sounds.
@export_range(0.1, 3.0, 0.01) var flap_sound_pitch_min := 0.9
## Highest random pitch used for bat flap sounds.
@export_range(0.1, 3.0, 0.01) var flap_sound_pitch_max := 1.16
## Shortest delay between bat flap one-shot triggers.
@export_range(0.01, 2.0, 0.01, "suffix:s") var flap_sound_interval_min := 0.08
## Longest delay between bat flap one-shot triggers.
@export_range(0.01, 3.0, 0.01, "suffix:s") var flap_sound_interval_max := 0.16
## Distance where bat flap audio fades out.
@export_range(1.0, 120.0, 0.5, "suffix:m") var flap_sound_max_distance := 42.0
## Distance scale for 3D attenuation; higher values keep flaps audible from the follow camera.
@export_range(0.1, 30.0, 0.1, "suffix:m") var flap_sound_unit_size := 8.0
## Maximum bat flap one-shots allowed to overlap for this nest.
@export_range(1, 8, 1) var flap_sound_max_concurrent := 3
## Bat squeak one-shot samples randomly played by the nest.
@export var squeak_sound_paths: Array[String] = DEFAULT_SQUEAK_SOUND_PATHS
## Volume for each bat squeak one-shot.
@export var squeak_sound_volume_db := 2.0
## Lowest random pitch used for bat squeaks.
@export_range(0.1, 3.0, 0.01) var squeak_sound_pitch_min := 0.92
## Highest random pitch used for bat squeaks.
@export_range(0.1, 3.0, 0.01) var squeak_sound_pitch_max := 1.12
## Shortest delay between bat squeak trigger attempts.
@export_range(0.03, 5.0, 0.01, "suffix:s") var squeak_sound_interval_min := 0.08
## Longest delay between bat squeak trigger attempts.
@export_range(0.03, 8.0, 0.01, "suffix:s") var squeak_sound_interval_max := 0.22
## Chance that each squeak trigger attempt actually plays a sample.
@export_range(0.0, 100.0, 1.0, "suffix:%") var squeak_sound_chance_percent := 95.0
## Distance where bat squeak audio fades out.
@export_range(1.0, 120.0, 0.5, "suffix:m") var squeak_sound_max_distance := 42.0
## Distance scale for 3D attenuation; higher values keep squeaks audible from the follow camera.
@export_range(0.1, 30.0, 0.1, "suffix:m") var squeak_sound_unit_size := 8.0
## Maximum bat squeak one-shots allowed to overlap for this nest.
@export_range(1, 8, 1) var squeak_sound_max_concurrent := 4
## Seconds after fly-off starts for bat sounds to fade out.
@export_range(0.0, 10.0, 0.05, "suffix:s") var fly_off_audio_fade_seconds := 1.35
@export_group("")
@export_group("Camera Scare")
## Percent chance that one bat flies toward the active camera when the nest triggers.
@export_range(0.0, 100.0, 1.0, "suffix:%") var camera_scare_chance_percent := 18.0
## Seconds the scare bat spends rushing toward the camera.
@export_range(0.1, 3.0, 0.05, "suffix:s") var camera_scare_duration := 0.75
## Distance in front of the camera where the scare bat aims.
@export_range(0.05, 5.0, 0.05, "suffix:m") var camera_scare_distance := 1.15
## Movement speed used by the scare bat while it rushes the camera.
@export_range(0.1, 50.0, 0.1, "suffix:m/s") var camera_scare_speed := 16.0
## Scale multiplier used to make the scare bat loom larger near the camera.
@export_range(1.0, 12.0, 0.1) var camera_scare_scale_multiplier := 4.0
@export_group("")

var state := BatNestState.ROOSTING
var bats: Array[BatState] = []
var player: Node3D
var elapsed_state_seconds := 0.0
var fly_off_group_direction := Vector3.FORWARD
var scare_bat: BatState
var scare_camera: Camera3D
var scare_elapsed_seconds := 0.0
var camera_scare_active := false
var flap_sound: AudioStream
var squeak_sounds: Array[AudioStream] = []
var active_flap_audio_players: Array[AudioStreamPlayer3D] = []
var active_squeak_audio_players: Array[AudioStreamPlayer3D] = []
var flap_sound_timer := 0.0
var squeak_sound_timer := 0.0
var rng := RandomNumberGenerator.new()


class BatState:
    extends RefCounted

    var node: Node3D
    var velocity := Vector3.ZERO
    var roost_offset := Vector3.ZERO
    var orbit_angle := 0.0
    var orbit_radius := 0.0
    var fly_direction := Vector3.FORWARD
    var fly_start_direction := Vector3.FORWARD
    var is_camera_scare := false
    var animation_players: Array[AnimationPlayer] = []
    var animation_names: Dictionary = {}


func _ready() -> void:
    rng.seed = DETERMINISTIC_SEED.from_node(self, 0, &"bat_nest")
    _load_flap_sound()
    _load_squeak_sounds()
    _randomize_next_flap_sound()
    _randomize_next_squeak_sound()
    _rebuild_roost()


func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    match state:
        BatNestState.ROOSTING:
            _update_roosting()
        BatNestState.SWARMING:
            _update_swarming(delta)
        BatNestState.FLYING_OFF:
            _update_flying_off(delta)
        BatNestState.FINISHED:
            pass

    _update_bat_animations()
    _update_flap_audio(delta)
    _update_squeak_audio(delta)


func force_take_flight(target_player: Node3D = null) -> void:
    if state != BatNestState.ROOSTING:
        return

    if target_player != null:
        player = target_player

    _start_swarm()


func get_bat_nest_state() -> BatNestState:
    return state


func get_runtime_bat_count() -> int:
    return bats.size()


func _rebuild_roost() -> void:
    if not is_inside_tree():
        return

    _clear_bats()
    if bat_scene == null:
        return

    for bat_index in bat_count:
        var bat_node := bat_scene.instantiate() as Node3D
        if bat_node == null:
            continue

        bat_node.name = "Bat%02d" % [bat_index + 1]
        bat_node.scale = Vector3.ONE * bat_scale
        bat_node.position = _get_roost_offset(bat_index)
        bat_node.rotation.y = _get_roost_angle(bat_index) + PI
        bat_node.visible = Engine.is_editor_hint()
        add_child(bat_node, false, Node.INTERNAL_MODE_FRONT)

        var bat_state := BatState.new()
        bat_state.node = bat_node
        bat_state.roost_offset = bat_node.position
        bat_state.velocity = Vector3.ZERO
        bat_state.orbit_angle = _get_roost_angle(bat_index)
        bat_state.orbit_radius = swarm_radius * rng.randf_range(0.65, 1.15)
        bat_state.animation_players = _find_animation_players(bat_node)
        _resolve_animation_names(bat_state)
        bats.append(bat_state)
        _play_bat_animations(bat_state)


func _clear_bats() -> void:
    _stop_flap_audio()
    _stop_squeak_audio()
    for bat_state in bats:
        if bat_state.node != null:
            if Engine.is_editor_hint():
                bat_state.node.free()
            else:
                bat_state.node.queue_free()

    bats.clear()


func _get_roost_offset(bat_index: int) -> Vector3:
    var ring := float((bat_index % 7) + 1) / 7.0
    var angle := _get_roost_angle(bat_index)
    var radius := cluster_radius * (0.25 + ring * 0.75)
    var y_offset := sin(float(bat_index) * 2.399963) * cluster_height * 0.5
    return Vector3(cos(angle) * radius, y_offset, sin(angle) * radius)


func _get_roost_angle(bat_index: int) -> float:
    return float(bat_index) * 2.399963


func _update_roosting() -> void:
    _resolve_player()
    if player == null:
        return

    if global_position.distance_to(player.global_position) <= trigger_radius:
        _start_swarm()


func _start_swarm() -> void:
    state = BatNestState.SWARMING
    elapsed_state_seconds = 0.0
    var center := _get_player_swarm_center()
    for bat_index in bats.size():
        var bat_state := bats[bat_index]
        if bat_state.node == null:
            continue

        bat_state.node.global_position = _get_player_spawn_position(bat_index)
        bat_state.node.visible = true
        var harass_offset := _get_harass_offset_at(bat_state, bat_index, 0.0)
        var harass_position := center + harass_offset
        var dart_direction := _get_harass_direction(bat_state, bat_index, 0.0)
        var target_direction := harass_position - bat_state.node.global_position
        var launch_direction := (dart_direction * 0.85) + (target_direction.normalized() * 0.35) + (Vector3.UP * 0.4)
        bat_state.velocity = launch_direction.normalized() * rng.randf_range(swarm_speed * 0.45, swarm_speed * 0.7)

    _try_start_camera_scare()
    flap_sound_timer = 0.0
    squeak_sound_timer = 0.0


func _update_swarming(delta: float) -> void:
    elapsed_state_seconds += delta
    if elapsed_state_seconds >= swarm_seconds:
        _start_flying_off()
        return

    var center := _get_flock_center()
    var average_velocity := _get_average_velocity()
    var player_center := _get_player_swarm_center()

    for bat_index in bats.size():
        var bat_state := bats[bat_index]
        if bat_state.node == null:
            continue

        if bat_state.is_camera_scare:
            _update_camera_scare_bat(bat_state, delta)
            continue

        var position := bat_state.node.global_position
        var target_position := player_center + _get_harass_offset(bat_state, bat_index)
        var desired_to_target := target_position - position
        var dart_direction := _get_harass_direction(bat_state, bat_index, elapsed_state_seconds)
        var desired_velocity := Vector3.ZERO
        var acceleration := Vector3.ZERO

        if desired_to_target.length_squared() > 0.001:
            desired_velocity += desired_to_target * player_attraction_weight

        var cohesion := center - position
        if cohesion.length_squared() > 0.001:
            acceleration += cohesion.normalized() * cohesion_weight

        if average_velocity.length_squared() > 0.001:
            acceleration += (average_velocity.normalized() * swarm_speed - bat_state.velocity) * alignment_weight

        desired_velocity += dart_direction * swarm_speed * 0.55
        acceleration += (desired_velocity - bat_state.velocity) * orbit_weight
        acceleration += _get_annoyance_acceleration(bat_state, bat_index) * annoyance_weight
        acceleration += _get_separation(position, bat_state) * separation_weight

        bat_state.velocity += acceleration * delta
        bat_state.velocity = _limit_velocity(bat_state.velocity, swarm_speed)
        _move_bat(bat_state, delta)


func _start_flying_off() -> void:
    state = BatNestState.FLYING_OFF
    elapsed_state_seconds = 0.0
    var origin := _get_player_swarm_center()
    fly_off_group_direction = _get_fly_off_group_direction(origin)
    camera_scare_active = false

    for bat_index in bats.size():
        var bat_state := bats[bat_index]
        if bat_state.node == null:
            continue

        bat_state.is_camera_scare = false
        bat_state.node.scale = Vector3.ONE * bat_scale
        var spread_radians := deg_to_rad(fly_off_spread_degrees)
        var spread_ratio := 0.0 if bats.size() <= 1 else (float(bat_index) / float(bats.size() - 1)) * 2.0 - 1.0
        var random_spread := rng.randf_range(-spread_radians * 0.35, spread_radians * 0.35)
        var spread := spread_ratio * spread_radians + random_spread
        bat_state.fly_direction = fly_off_group_direction.rotated(Vector3.UP, spread).normalized()
        bat_state.fly_start_direction = _get_horizontal_direction_or_fallback(bat_state.velocity, bat_state.fly_direction)


func _update_flying_off(delta: float) -> void:
    elapsed_state_seconds += delta
    var center := _get_flock_center()
    var turn_ratio := _get_fly_off_turn_ratio()
    for bat_state in bats:
        if bat_state.node == null:
            continue

        var rise_velocity := Vector3.UP * fly_off_rise_speed
        var cohesion := center - bat_state.node.global_position
        var cohesion_velocity := Vector3.ZERO
        if cohesion.length_squared() > 0.001:
            cohesion_velocity = cohesion.normalized() * cohesion_weight

        var turn_direction := _slerp_horizontal_direction(
            bat_state.fly_start_direction,
            bat_state.fly_direction,
            turn_ratio
        )
        bat_state.velocity = _limit_velocity(
            (turn_direction * fly_off_speed) + rise_velocity + cohesion_velocity,
            fly_off_speed + fly_off_rise_speed
        )
        _move_bat(bat_state, delta)

    if elapsed_state_seconds >= fly_off_seconds:
        _clear_bats()
        state = BatNestState.FINISHED


func _load_flap_sound() -> void:
    if Engine.is_editor_hint():
        return

    flap_sound = GDAudio.load_stream(flap_sound_path)


func _load_squeak_sounds() -> void:
    if Engine.is_editor_hint():
        return

    squeak_sounds = GDAudio.load_streams(squeak_sound_paths)


func _update_flap_audio(delta: float) -> void:
    _prune_finished_flap_audio_players()
    _apply_audio_fade(active_flap_audio_players, flap_sound_volume_db)
    if flap_sound == null:
        return

    if state == BatNestState.ROOSTING or state == BatNestState.FINISHED or bats.is_empty():
        _stop_flap_audio()
        return

    var center := _get_flock_center()
    flap_sound_timer -= delta
    if flap_sound_timer > 0.0:
        return

    if _is_fly_off_audio_faded_out():
        return

    if active_flap_audio_players.size() >= flap_sound_max_concurrent:
        _randomize_next_flap_sound()
        return

    var flap_audio_player := AudioStreamPlayer3D.new()
    flap_audio_player.name = "BatFlapOneShotAudio"
    flap_audio_player.stream = flap_sound
    flap_audio_player.volume_db = _get_faded_audio_volume_db(flap_sound_volume_db)
    flap_audio_player.pitch_scale = rng.randf_range(
        minf(flap_sound_pitch_min, flap_sound_pitch_max),
        maxf(flap_sound_pitch_min, flap_sound_pitch_max)
    )
    flap_audio_player.max_distance = flap_sound_max_distance
    flap_audio_player.unit_size = flap_sound_unit_size
    flap_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    flap_audio_player.finished.connect(_on_flap_audio_finished.bind(flap_audio_player))
    add_child(flap_audio_player)
    flap_audio_player.global_position = center
    active_flap_audio_players.append(flap_audio_player)
    flap_audio_player.play()
    _randomize_next_flap_sound()


func _update_squeak_audio(delta: float) -> void:
    _prune_finished_squeak_audio_players()
    _apply_audio_fade(active_squeak_audio_players, squeak_sound_volume_db)
    if squeak_sounds.is_empty():
        return

    if state == BatNestState.ROOSTING or state == BatNestState.FINISHED or bats.is_empty():
        _stop_squeak_audio()
        return

    squeak_sound_timer -= delta
    if squeak_sound_timer > 0.0:
        return

    if _is_fly_off_audio_faded_out():
        return

    if active_squeak_audio_players.size() >= squeak_sound_max_concurrent:
        _randomize_next_squeak_sound()
        return

    if rng.randf() * 100.0 > squeak_sound_chance_percent:
        _randomize_next_squeak_sound()
        return

    var stream := squeak_sounds[rng.randi_range(0, squeak_sounds.size() - 1)]
    var squeak_audio_player := AudioStreamPlayer3D.new()
    squeak_audio_player.name = "BatSqueakOneShotAudio"
    squeak_audio_player.stream = stream
    squeak_audio_player.volume_db = _get_faded_audio_volume_db(squeak_sound_volume_db)
    squeak_audio_player.pitch_scale = rng.randf_range(
        minf(squeak_sound_pitch_min, squeak_sound_pitch_max),
        maxf(squeak_sound_pitch_min, squeak_sound_pitch_max)
    )
    squeak_audio_player.max_distance = squeak_sound_max_distance
    squeak_audio_player.unit_size = squeak_sound_unit_size
    squeak_audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    squeak_audio_player.finished.connect(_on_squeak_audio_finished.bind(squeak_audio_player))
    add_child(squeak_audio_player)
    squeak_audio_player.global_position = _get_flock_center()
    active_squeak_audio_players.append(squeak_audio_player)
    squeak_audio_player.play()
    _randomize_next_squeak_sound()


func _randomize_next_flap_sound() -> void:
    flap_sound_timer = rng.randf_range(
        minf(flap_sound_interval_min, flap_sound_interval_max),
        maxf(flap_sound_interval_min, flap_sound_interval_max)
    )


func _randomize_next_squeak_sound() -> void:
    squeak_sound_timer = rng.randf_range(
        minf(squeak_sound_interval_min, squeak_sound_interval_max),
        maxf(squeak_sound_interval_min, squeak_sound_interval_max)
    )


func _apply_audio_fade(audio_players: Array[AudioStreamPlayer3D], base_volume_db: float) -> void:
    var faded_volume_db := _get_faded_audio_volume_db(base_volume_db)
    for audio_player in audio_players:
        if audio_player == null:
            continue

        audio_player.volume_db = faded_volume_db


func _get_faded_audio_volume_db(base_volume_db: float) -> float:
    var fade := _get_fly_off_audio_fade()
    if fade >= 1.0:
        return base_volume_db

    return base_volume_db + linear_to_db(maxf(fade, 0.001))


func _get_fly_off_audio_fade() -> float:
    if state != BatNestState.FLYING_OFF:
        return 1.0

    var fade_seconds := minf(maxf(fly_off_audio_fade_seconds, 0.0), maxf(fly_off_seconds, 0.001))
    if fade_seconds <= 0.0:
        return 0.0

    return 1.0 - clampf(elapsed_state_seconds / fade_seconds, 0.0, 1.0)


func _is_fly_off_audio_faded_out() -> bool:
    return state == BatNestState.FLYING_OFF and _get_fly_off_audio_fade() <= 0.02


func _stop_flap_audio() -> void:
    for flap_audio_player in active_flap_audio_players.duplicate():
        if flap_audio_player == null:
            continue

        flap_audio_player.stop()
        flap_audio_player.queue_free()

    active_flap_audio_players.clear()


func _stop_squeak_audio() -> void:
    for squeak_audio_player in active_squeak_audio_players.duplicate():
        if squeak_audio_player == null:
            continue

        squeak_audio_player.stop()
        squeak_audio_player.queue_free()

    active_squeak_audio_players.clear()


func _prune_finished_flap_audio_players() -> void:
    for index in range(active_flap_audio_players.size() - 1, -1, -1):
        var flap_audio_player := active_flap_audio_players[index]
        if flap_audio_player == null or not is_instance_valid(flap_audio_player):
            active_flap_audio_players.remove_at(index)


func _prune_finished_squeak_audio_players() -> void:
    for index in range(active_squeak_audio_players.size() - 1, -1, -1):
        var squeak_audio_player := active_squeak_audio_players[index]
        if squeak_audio_player == null or not is_instance_valid(squeak_audio_player):
            active_squeak_audio_players.remove_at(index)


func _on_flap_audio_finished(flap_audio_player: AudioStreamPlayer3D) -> void:
    active_flap_audio_players.erase(flap_audio_player)
    if flap_audio_player != null:
        flap_audio_player.queue_free()


func _on_squeak_audio_finished(squeak_audio_player: AudioStreamPlayer3D) -> void:
    active_squeak_audio_players.erase(squeak_audio_player)
    if squeak_audio_player != null:
        squeak_audio_player.queue_free()


func _get_flock_center() -> Vector3:
    if bats.is_empty():
        return global_position

    var center := Vector3.ZERO
    var active_count := 0
    for bat_state in bats:
        if bat_state.node == null:
            continue

        center += bat_state.node.global_position
        active_count += 1

    return center / float(maxi(active_count, 1))


func _get_average_velocity() -> Vector3:
    if bats.is_empty():
        return Vector3.ZERO

    var average := Vector3.ZERO
    var active_count := 0
    for bat_state in bats:
        average += bat_state.velocity
        active_count += 1

    return average / float(maxi(active_count, 1))


func _get_fly_off_turn_ratio() -> float:
    if fly_off_turn_seconds <= 0.0:
        return 1.0

    return clampf(elapsed_state_seconds / fly_off_turn_seconds, 0.0, 1.0)


func _get_horizontal_direction_or_fallback(source_velocity: Vector3, fallback_direction: Vector3) -> Vector3:
    var horizontal_direction := Vector3(source_velocity.x, 0.0, source_velocity.z)
    if horizontal_direction.length_squared() > 0.001:
        return horizontal_direction.normalized()

    horizontal_direction = Vector3(fallback_direction.x, 0.0, fallback_direction.z)
    if horizontal_direction.length_squared() > 0.001:
        return horizontal_direction.normalized()

    return Vector3.FORWARD


func _slerp_horizontal_direction(from_direction: Vector3, to_direction: Vector3, ratio: float) -> Vector3:
    var from_horizontal := _get_horizontal_direction_or_fallback(from_direction, to_direction)
    var to_horizontal := _get_horizontal_direction_or_fallback(to_direction, from_horizontal)
    var blended := from_horizontal.slerp(to_horizontal, clampf(ratio, 0.0, 1.0))
    if blended.length_squared() <= 0.001:
        return to_horizontal

    return blended.normalized()


func _get_separation(position: Vector3, current_bat: BatState) -> Vector3:
    var separation := Vector3.ZERO
    for other_bat in bats:
        if other_bat == current_bat or other_bat.node == null:
            continue

        var offset := position - other_bat.node.global_position
        var distance := offset.length()
        if distance <= 0.001 or distance >= separation_distance:
            continue

        separation += offset.normalized() * ((separation_distance - distance) / separation_distance)

    return separation


func _get_player_swarm_center() -> Vector3:
    if player == null:
        return global_position + Vector3.UP * swarm_height

    return player.global_position + Vector3.UP * swarm_height


func _get_player_spawn_position(bat_index: int) -> Vector3:
    var spawn_center := global_position + Vector3.UP * player_spawn_height
    if player != null:
        spawn_center = player.global_position + Vector3.UP * player_spawn_height

    var angle := _get_roost_angle(bat_index)
    var radius_ratio := 0.15 + (float((bat_index % 5) + 1) / 5.0) * 0.85
    var radius := player_spawn_radius * radius_ratio
    var height_offset := sin(float(bat_index) * 1.731) * player_spawn_radius * 0.35
    return spawn_center + Vector3(cos(angle) * radius, height_offset, sin(angle) * radius)


func _try_start_camera_scare() -> void:
    scare_bat = null
    scare_camera = null
    scare_elapsed_seconds = 0.0
    camera_scare_active = false

    if camera_scare_chance_percent <= 0.0 or bats.is_empty():
        return

    if rng.randf() * 100.0 > camera_scare_chance_percent:
        return

    var viewport := get_viewport()
    if viewport == null:
        return

    var camera := viewport.get_camera_3d()
    if camera == null:
        return

    var selected_bat := bats[rng.randi_range(0, bats.size() - 1)]
    if selected_bat.node == null:
        return

    scare_bat = selected_bat
    scare_camera = camera
    scare_bat.is_camera_scare = true
    camera_scare_active = true


func _update_camera_scare_bat(bat_state: BatState, delta: float) -> void:
    if not camera_scare_active or scare_camera == null or not is_instance_valid(scare_camera):
        bat_state.is_camera_scare = false
        return

    scare_elapsed_seconds += delta
    var target_position := _get_camera_scare_target_position(scare_camera)
    var to_target := target_position - bat_state.node.global_position
    if to_target.length_squared() > 0.001:
        bat_state.velocity = to_target.normalized() * camera_scare_speed

    _move_bat(bat_state, delta)
    var scare_ratio := clampf(scare_elapsed_seconds / maxf(camera_scare_duration, 0.001), 0.0, 1.0)
    var scale_multiplier := lerpf(1.0, camera_scare_scale_multiplier, ease(scare_ratio, -2.0))
    bat_state.node.scale = Vector3.ONE * bat_scale * scale_multiplier

    if scare_elapsed_seconds >= camera_scare_duration:
        bat_state.is_camera_scare = false
        camera_scare_active = false


func _get_camera_scare_target_position(camera: Camera3D) -> Vector3:
    var camera_basis := camera.global_transform.basis
    var camera_forward := -camera_basis.z.normalized()
    return camera.global_position + camera_forward * maxf(camera_scare_distance, camera.near + 0.05)


func _get_fly_off_group_direction(origin: Vector3) -> Vector3:
    var group_direction := _get_flock_center() - origin
    group_direction.y = 0.0
    if group_direction.length_squared() > 0.001:
        return group_direction.normalized()

    group_direction = global_position - origin
    group_direction.y = 0.0
    if group_direction.length_squared() > 0.001:
        return group_direction.normalized()

    var random_angle := rng.randf_range(-PI, PI)
    return Vector3(cos(random_angle), 0.0, sin(random_angle)).normalized()


func _get_harass_offset(bat_state: BatState, bat_index: int) -> Vector3:
    return _get_harass_offset_at(bat_state, bat_index, elapsed_state_seconds)


func _get_harass_offset_at(bat_state: BatState, bat_index: int, seconds: float) -> Vector3:
    var angle := bat_state.orbit_angle + seconds * (2.0 + float(bat_index % 5) * 0.27)
    var cross_angle := bat_state.orbit_angle * 1.7 + seconds * (3.1 - float(bat_index % 4) * 0.19)
    var radius := maxf(bat_state.orbit_radius, 0.1)
    var x_radius := radius * (0.22 + absf(sin(cross_angle * 0.73)) * 0.52)
    var z_radius := radius * (0.18 + absf(cos(angle * 0.61)) * 0.46)
    var height_offset := sin(angle * 2.2 + float(bat_index)) * 0.34 + cos(cross_angle * 1.4) * 0.22
    return Vector3(cos(angle) * x_radius, height_offset, sin(cross_angle) * z_radius)


func _get_harass_direction(bat_state: BatState, bat_index: int, seconds: float) -> Vector3:
    var offset := _get_harass_offset_at(bat_state, bat_index, seconds)
    var future_offset := _get_harass_offset_at(bat_state, bat_index, seconds + 0.16)
    var direction := future_offset - offset
    if direction.length_squared() <= 0.001:
        return Vector3.ZERO

    return direction.normalized()


func _get_annoyance_acceleration(bat_state: BatState, bat_index: int) -> Vector3:
    var phase := bat_state.orbit_angle + float(bat_index) * 0.41
    var x := sin(elapsed_state_seconds * 7.1 + phase)
    var y := sin(elapsed_state_seconds * 9.3 + phase * 1.3) * 0.45
    var z := cos(elapsed_state_seconds * 6.4 + phase * 1.7)
    var acceleration := Vector3(x, y, z)
    if acceleration.length_squared() <= 0.001:
        return Vector3.ZERO

    return acceleration.normalized()


func _limit_velocity(velocity: Vector3, max_speed: float) -> Vector3:
    var speed := velocity.length()
    if speed <= max_speed:
        return velocity

    if speed <= MIN_SPEED:
        return Vector3.ZERO

    return velocity / speed * max_speed


func _move_bat(bat_state: BatState, delta: float) -> void:
    if bat_state.node == null:
        return

    bat_state.node.global_position += bat_state.velocity * delta
    _face_velocity(bat_state)


func _face_velocity(bat_state: BatState) -> void:
    if bat_state.node == null or bat_state.velocity.length_squared() <= 0.001:
        return

    var look_target := bat_state.node.global_position + bat_state.velocity.normalized()
    bat_state.node.look_at(look_target, Vector3.UP, true)


func _resolve_player() -> void:
    if player != null and is_instance_valid(player):
        return

    var tree := get_tree()
    if tree == null:
        player = null
        return

    player = null
    for node: Node in tree.get_nodes_in_group(player_group):
        if node is Node3D:
            player = node as Node3D
            return


func _find_animation_players(root_node: Node) -> Array[AnimationPlayer]:
    var players: Array[AnimationPlayer] = []
    if root_node is AnimationPlayer:
        players.append(root_node as AnimationPlayer)

    for child: Node in root_node.get_children():
        players.append_array(_find_animation_players(child))

    return players


func _resolve_animation_names(bat_state: BatState) -> void:
    bat_state.animation_names.clear()
    for animation_player in bat_state.animation_players:
        var animation_list := animation_player.get_animation_list()
        if animation_list.is_empty():
            continue

        bat_state.animation_names[animation_player] = _get_flap_animation_name(animation_player, animation_list)


func _update_bat_animations() -> void:
    for bat_state in bats:
        _play_bat_animations(bat_state)


func _play_bat_animations(bat_state: BatState) -> void:
    for animation_player in bat_state.animation_players:
        if not bat_state.animation_names.has(animation_player):
            continue

        var animation_name := bat_state.animation_names[animation_player] as StringName
        animation_player.speed_scale = flap_animation_speed_scale
        if animation_player.current_animation != animation_name or not animation_player.is_playing():
            animation_player.play(animation_name, -1.0, flap_animation_speed_scale)


func _get_flap_animation_name(animation_player: AnimationPlayer, animation_list: PackedStringArray) -> StringName:
    if animation_list.size() == 1:
        return StringName(animation_list[0])

    if animation_player.has_animation(COMBINED_FLAP_ANIMATION):
        return COMBINED_FLAP_ANIMATION

    var combined_animation := Animation.new()
    combined_animation.resource_name = String(COMBINED_FLAP_ANIMATION)
    combined_animation.loop_mode = Animation.LOOP_LINEAR

    for animation_name in animation_list:
        var source_animation := animation_player.get_animation(animation_name)
        if source_animation == null:
            continue

        combined_animation.length = maxf(combined_animation.length, source_animation.length)
        for track_index in source_animation.get_track_count():
            source_animation.copy_track(track_index, combined_animation)

    if combined_animation.get_track_count() == 0:
        return StringName(animation_list[0])

    var animation_library := _get_or_create_default_animation_library(animation_player)
    animation_library.add_animation(COMBINED_FLAP_ANIMATION, combined_animation)
    return COMBINED_FLAP_ANIMATION


func _get_or_create_default_animation_library(animation_player: AnimationPlayer) -> AnimationLibrary:
    if animation_player.has_animation_library(&""):
        return animation_player.get_animation_library(&"")

    var animation_library := AnimationLibrary.new()
    animation_player.add_animation_library(&"", animation_library)
    return animation_library
