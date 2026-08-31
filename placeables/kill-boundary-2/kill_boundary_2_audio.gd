@tool
class_name GDKillBoundary2Audio
extends AudioStreamPlayer

## Boundary proximity audio whose distance queries use canonical geometry.

const NEAR_FLAMES_SOUND_PATH := "res://Assets/audio/near-the-flames.mp3"
const GHOST_BOUNDARY_SOUND_PATH := "res://Assets/audio/ghost-boundary.mp3"
const GHOST_VOLUME_BOOST_DB := 8.0
const FLAME_VULNERABLE_GROUP: StringName = &"flame_vulnerable"

var settings: GDKillBoundary2Settings
var geometry: GDKillBoundary2Geometry
var render_effect := GDKillBoundary2Settings.RenderEffect.Flame
var effects_enabled := true


func configure(
	new_settings: GDKillBoundary2Settings,
	new_geometry: GDKillBoundary2Geometry,
	new_effect: GDKillBoundary2Settings.RenderEffect
) -> void:
	settings = new_settings
	geometry = new_geometry
	bus = &"SFX"
	set_render_effect(new_effect)


func set_render_effect(value: GDKillBoundary2Settings.RenderEffect) -> void:
	render_effect = value
	var audio_path := (
		GHOST_BOUNDARY_SOUND_PATH
		if value == GDKillBoundary2Settings.RenderEffect.Ghost
		else NEAR_FLAMES_SOUND_PATH
	)
	var loaded_stream := GDAudio.load_stream(audio_path)
	if loaded_stream != null:
		stream = loaded_stream.duplicate() as AudioStream
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
	if settings != null:
		volume_db = _adjusted_volume(settings.near_flame_audio_min_db)
	if is_inside_tree() and stream != null and not Engine.is_editor_hint():
		play()
	elif Engine.is_editor_hint():
		stop()


func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	stream_paused = not value
	if not value and settings != null:
		volume_db = _adjusted_volume(settings.near_flame_audio_min_db)


func update_proximity(delta: float) -> void:
	if Engine.is_editor_hint() \
			or not effects_enabled \
			or settings == null \
			or geometry == null \
			or not is_inside_tree():
		return
	var closest_distance := INF
	for body_value in get_tree().get_nodes_in_group(FLAME_VULNERABLE_GROUP):
		var body := body_value as Node3D
		if body == null or not is_instance_valid(body):
			continue
		var signed_distance := geometry.get_signed_distance_world(body.global_position)
		closest_distance = minf(closest_distance, maxf(signed_distance, 0.0))
	var target_volume := settings.near_flame_audio_min_db
	if closest_distance < INF:
		var closeness := (
			1.0
			- clampf(closest_distance / maxf(settings.near_flame_audio_distance, 0.001), 0.0, 1.0)
		)
		closeness = pow(closeness, settings.near_flame_audio_curve)
		target_volume = lerpf(
			settings.near_flame_audio_min_db, settings.near_flame_audio_max_db, closeness
		)
	var ratio := 1.0 - exp(-settings.near_flame_audio_lag * maxf(delta, 0.0))
	volume_db = lerpf(volume_db, _adjusted_volume(target_volume), ratio)


func _adjusted_volume(value: float) -> float:
	return (
		value + GHOST_VOLUME_BOOST_DB
		if render_effect == GDKillBoundary2Settings.RenderEffect.Ghost
		else value
	)
