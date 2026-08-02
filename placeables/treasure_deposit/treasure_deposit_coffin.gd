class_name GDTreasureDepositCoffin
extends "res://placeables/physics_placeable.gd"

## Physics-capable placeable root for the coffin and its nested deposit behavior.


const COFFIN_LANDING_SOUND_PATH := "res://Assets/audio/coffin-landing.mp3"
const LANDING_AUDIO_NAME := "CoffinLandingAudio"
const LANDING_AUDIO_MAX_DISTANCE := 64.0
const LANDING_AUDIO_UNIT_SIZE := 16.0
const LANDING_AUDIO_VOLUME_DB := 4.0
const MINIMUM_AUDIBLE_LANDING_SPEED := 1.5
const WORLD_COLLISION_LAYER := 1

var landing_sound: AudioStream
var previous_linear_velocity := Vector3.ZERO
var has_played_landing_sound := false


func _ready() -> void:
    landing_sound = GDAudio.load_stream(COFFIN_LANDING_SOUND_PATH)
    previous_linear_velocity = linear_velocity
    body_entered.connect(_on_landing_body_entered)
    super._ready()


func _physics_process(_delta: float) -> void:
    previous_linear_velocity = linear_velocity


func _on_landing_body_entered(body: Node) -> void:
    if has_played_landing_sound \
            or landing_sound == null \
            or -previous_linear_velocity.y < MINIMUM_AUDIBLE_LANDING_SPEED \
            or not _is_world_collision_body(body):
        return

    has_played_landing_sound = true
    GDAudio.play_one_shot_3d(
        self,
        landing_sound,
        LANDING_AUDIO_NAME,
        LANDING_AUDIO_VOLUME_DB,
        1.0,
        LANDING_AUDIO_MAX_DISTANCE,
        LANDING_AUDIO_UNIT_SIZE
    )


func _is_world_collision_body(body: Node) -> bool:
    if body == null:
        return false

    var body_collision_layer: Variant = body.get("collision_layer")
    if body_collision_layer == null:
        return false

    return (int(body_collision_layer) & WORLD_COLLISION_LAYER) != 0
