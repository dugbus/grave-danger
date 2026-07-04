class_name GDAudio
extends RefCounted


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
    sound_player.finished.connect(sound_player.queue_free)
    parent.add_child(sound_player)
    sound_player.play()
    return sound_player


static func play_one_shot_3d(
    parent: Node,
    stream: AudioStream,
    sound_name: String,
    volume_db: float = 0.0,
    pitch_scale: float = 1.0
) -> AudioStreamPlayer3D:
    if parent == null or stream == null:
        return null

    var sound_player := AudioStreamPlayer3D.new()
    sound_player.name = sound_name
    sound_player.stream = stream
    sound_player.volume_db = volume_db
    sound_player.pitch_scale = pitch_scale
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
    rng: RandomNumberGenerator = null
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
    volume_db += _randf_range(-1.0, 1.0, rng)

    return play_one_shot_3d(
        parent,
        stream,
        sound_name,
        volume_db,
        _randf_range(pitch_min, pitch_max, rng)
    )


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
