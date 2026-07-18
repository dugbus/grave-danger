class_name GDAudio
extends RefCounted


enum FootstepSoundProfile {
    Player,
    Enemy,
}

const ENEMY_FOOTSTEP_MAX_DISTANCE := 28.0
const ENEMY_FOOTSTEP_UNIT_SIZE := 8.0
const PLAYER_FOOTSTEP_MAX_DISTANCE := 0.0
const PLAYER_FOOTSTEP_UNIT_SIZE := 10.0
const FOOTSTEP_ANIMATION_PHASES: Array[float] = [0.25, 0.75]
const SFX_BUS := &"SFX"


static func load_stream(sound_path: String) -> AudioStream:
    if sound_path.is_empty():
        return null

    if ResourceLoader.exists(sound_path):
        return load(sound_path) as AudioStream

    if sound_path.to_lower().ends_with(".mp3") and FileAccess.file_exists(sound_path):
        var stream := AudioStreamMP3.new()
        stream.data = FileAccess.get_file_as_bytes(sound_path)
        return stream

    return null


static func load_streams(sound_paths: Array[String]) -> Array[AudioStream]:
    var streams: Array[AudioStream] = []
    for sound_path in sound_paths:
        var stream := load_stream(sound_path)
        if stream != null:
            streams.append(stream)

    return streams


static func play_one_shot(
    parent: Node,
    stream: AudioStream,
    sound_name: String,
    volume_db: float = 0.0,
    pitch_scale: float = 1.0
) -> AudioStreamPlayer:
    if parent == null or stream == null:
        return null

    var sound_player := AudioStreamPlayer.new()
    sound_player.name = sound_name
    sound_player.stream = stream
    sound_player.volume_db = volume_db
    sound_player.pitch_scale = pitch_scale
    sound_player.bus = SFX_BUS
    sound_player.finished.connect(sound_player.queue_free)
    parent.add_child(sound_player)
    sound_player.play()
    return sound_player


static func play_one_shot_3d(
    parent: Node,
    stream: AudioStream,
    sound_name: String,
    volume_db: float = 0.0,
    pitch_scale: float = 1.0,
    max_distance: float = 0.0,
    unit_size: float = 10.0,
    attenuation_model := AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
) -> AudioStreamPlayer3D:
    if parent == null or stream == null:
        return null

    var sound_player := AudioStreamPlayer3D.new()
    sound_player.name = sound_name
    sound_player.stream = stream
    sound_player.volume_db = volume_db
    sound_player.pitch_scale = pitch_scale
    sound_player.bus = SFX_BUS
    if max_distance > 0.0:
        sound_player.max_distance = max_distance
    sound_player.unit_size = unit_size
    sound_player.attenuation_model = attenuation_model
    sound_player.finished.connect(sound_player.queue_free)
    parent.add_child(sound_player)
    sound_player.play()
    return sound_player


static func play_random_footstep_3d(
    parent: Node,
    streams: Array[AudioStream],
    sound_name: String,
    horizontal_speed: float,
    speed_threshold: float,
    max_speed: float,
    volume_min_db: float,
    volume_max_db: float,
    pitch_min: float,
    pitch_max: float,
    rng: RandomNumberGenerator = null,
    volume_variance_db: float = 1.0,
    footstep_profile := FootstepSoundProfile.Player
) -> AudioStreamPlayer3D:
    var stream := _pick_stream(streams, rng)
    if stream == null:
        return null

    var speed_volume_boost := clampf(
        (horizontal_speed - speed_threshold) / maxf(max_speed - speed_threshold, 0.001),
        0.0,
        1.0
    )
    var volume_db := lerpf(volume_min_db, volume_max_db, speed_volume_boost)
    var variance := maxf(volume_variance_db, 0.0)
    volume_db += _randf_range(-variance, variance, rng)
    var profile_settings := _get_footstep_profile_settings(footstep_profile)
    var max_distance := profile_settings.max_distance as float
    var unit_size := profile_settings.unit_size as float

    return play_one_shot_3d(
        parent,
        stream,
        sound_name,
        volume_db,
        _randf_range(pitch_min, pitch_max, rng),
        max_distance,
        unit_size,
        AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    )


static func _get_footstep_profile_settings(footstep_profile: FootstepSoundProfile) -> Dictionary:
    match footstep_profile:
        FootstepSoundProfile.Enemy:
            return {
                max_distance = ENEMY_FOOTSTEP_MAX_DISTANCE,
                unit_size = ENEMY_FOOTSTEP_UNIT_SIZE,
            }
        _:
            return {
                max_distance = PLAYER_FOOTSTEP_MAX_DISTANCE,
                unit_size = PLAYER_FOOTSTEP_UNIT_SIZE,
            }


static func did_cross_footstep_animation_phase(previous_phase: float, current_phase: float) -> bool:
    if previous_phase < 0.0:
        return false

    var normalized_previous := wrapf(previous_phase, 0.0, 1.0)
    var normalized_current := wrapf(current_phase, 0.0, 1.0)
    for footstep_phase in FOOTSTEP_ANIMATION_PHASES:
        if normalized_current >= normalized_previous:
            if normalized_previous < footstep_phase and normalized_current >= footstep_phase:
                return true
        elif normalized_previous < footstep_phase or normalized_current >= footstep_phase:
            return true

    return false


static func _pick_stream(streams: Array[AudioStream], rng: RandomNumberGenerator) -> AudioStream:
    if streams.is_empty():
        return null

    if rng != null:
        return streams[rng.randi_range(0, streams.size() - 1)]

    return streams[0]


static func _randf_range(
    min_value: float,
    max_value: float,
    rng: RandomNumberGenerator
) -> float:
    if rng != null:
        return rng.randf_range(min_value, max_value)

    return (min_value + max_value) * 0.5
