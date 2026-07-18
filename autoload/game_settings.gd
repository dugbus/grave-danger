class_name GDGameSettings
extends Node

## Persistent player-facing audio preferences.

const SETTINGS_PATH := "user://game_settings.json"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const DEFAULT_VOLUME_PERCENT := 80.0
const SETTINGS_SAVE_DELAY := 0.25

var music_volume_percent := DEFAULT_VOLUME_PERCENT
var sound_effect_volume_percent := DEFAULT_VOLUME_PERCENT
var persistence_enabled := true
var save_timer: Timer
var save_pending := false


func _ready() -> void:
    save_timer = Timer.new()
    save_timer.name = "SettingsSaveTimer"
    save_timer.one_shot = true
    save_timer.wait_time = SETTINGS_SAVE_DELAY
    save_timer.process_callback = Timer.TIMER_PROCESS_IDLE
    save_timer.timeout.connect(_save_settings)
    add_child(save_timer)
    _load_settings()
    _apply_audio_settings()


func set_music_volume_percent(value: float) -> void:
    music_volume_percent = clampf(value, 0.0, 100.0)
    _apply_bus_volume(MUSIC_BUS, music_volume_percent)
    _queue_settings_save()


func set_sound_effect_volume_percent(value: float) -> void:
    sound_effect_volume_percent = clampf(value, 0.0, 100.0)
    _apply_bus_volume(SFX_BUS, sound_effect_volume_percent)
    _queue_settings_save()


func flush_pending_save() -> void:
    if not save_pending:
        return
    if save_timer != null:
        save_timer.stop()
    _save_settings()


func _exit_tree() -> void:
    flush_pending_save()


func _apply_audio_settings() -> void:
    _apply_bus_volume(MUSIC_BUS, music_volume_percent)
    _apply_bus_volume(SFX_BUS, sound_effect_volume_percent)


func _apply_bus_volume(bus_name: StringName, volume_percent: float) -> void:
    var bus_index := AudioServer.get_bus_index(bus_name)
    if bus_index < 0:
        return

    var linear_volume := clampf(volume_percent / 100.0, 0.0, 1.0)
    AudioServer.set_bus_mute(bus_index, is_zero_approx(linear_volume))
    AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_volume, 0.0001)))


func _load_settings() -> void:
    if not FileAccess.file_exists(SETTINGS_PATH):
        return
    var settings_file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
    if settings_file == null:
        return
    var parsed: Variant = JSON.parse_string(settings_file.get_as_text())
    if not parsed is Dictionary:
        return
    music_volume_percent = clampf(
        float(parsed.get("music_volume_percent", DEFAULT_VOLUME_PERCENT)),
        0.0,
        100.0
    )
    sound_effect_volume_percent = clampf(
        float(parsed.get("sound_effect_volume_percent", DEFAULT_VOLUME_PERCENT)),
        0.0,
        100.0
    )


func _queue_settings_save() -> void:
    if not persistence_enabled:
        return
    save_pending = true
    if save_timer == null:
        _save_settings()
        return
    save_timer.start()


func _save_settings() -> void:
    if not persistence_enabled:
        save_pending = false
        return
    var settings_file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    if settings_file == null:
        push_warning("Could not write game settings file: %s" % SETTINGS_PATH)
        return
    settings_file.store_string(JSON.stringify({
        "music_volume_percent": music_volume_percent,
        "sound_effect_volume_percent": sound_effect_volume_percent,
    }, "\t"))
    save_pending = false
