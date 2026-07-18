extends GDPlayer
class_name GDLevelRunPlaybackPlayer

## Pickup-capable player used only inside a level-select run preview.

var playback_dead := false
var playback_flame_energy := 100.0


func _ready() -> void:
    super._ready()
    if death_controller != null:
        playback_flame_energy = death_controller.max_flame_energy


func _physics_process(_delta: float) -> void:
    pass


func try_collect_health_flask(
    _health_flask: Node3D,
    _heal_percent_of_max: float,
    _heal_duration: float
) -> bool:
    return true


func apply_temporary_poison_damage(_damage_points: float, _restore_after_seconds: float) -> bool:
    return true


func show_flask_effect_countdown(
    _effect_id: StringName,
    _liquid_color: Color,
    _duration: float
) -> void:
    pass


func die_from_flames() -> void:
    _playback_die()


func die_from_fall() -> void:
    _playback_die()


func is_dead() -> bool:
    return playback_dead


func apply_flame_damage(amount: float) -> void:
    if playback_dead:
        return
    playback_flame_energy = maxf(playback_flame_energy - maxf(amount, 0.0), 0.0)
    if playback_flame_energy <= 0.0:
        _playback_die()


func apply_spike_trap_damage(percent_of_max: float) -> void:
    if playback_dead:
        return
    var maximum_energy: float = death_controller.max_flame_energy \
        if death_controller != null else 100.0
    apply_flame_damage(maximum_energy * maxf(percent_of_max, 0.0) * 0.01)


func can_be_hit_by_spike_trap() -> bool:
    return not playback_dead


func drain_flame_energy() -> void:
    _playback_die()


func _playback_die() -> void:
    if playback_dead:
        return
    playback_dead = true
    playback_flame_energy = 0.0
    velocity = Vector3.ZERO
    if animation_controller != null:
        animation_controller.play_death()
