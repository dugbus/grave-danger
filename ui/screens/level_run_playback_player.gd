extends GDPlayer
class_name GDLevelRunPlaybackPlayer

## Pickup-capable player used only inside a level-select run preview.

var playback_dead := false
var skeleton_attack_pending := false
var skeleton_attacker: Node3D
var playback_flame_energy := 100.0
var recorded_run_settings: Dictionary = {}


func _ready() -> void:
	super._ready()
	if death_controller != null:
		playback_flame_energy = death_controller.max_flame_energy


func _physics_process(_delta: float) -> void:
	pass


func apply_recorded_run_settings(settings: Dictionary) -> void:
	recorded_run_settings = settings.duplicate(true)


func try_collect_health_flask(_health_flask: Node3D, _heal_percent_of_max: float, _heal_duration: float) -> bool:
	return true


func apply_temporary_poison_damage(_damage_points: float, _restore_after_seconds: float) -> bool:
	return true


func show_flask_effect_countdown(_effect_id: StringName, _liquid_color: Color, _duration: float) -> void:
	pass


func die_from_flames() -> void:
	_playback_die()


func die_from_fall() -> void:
	_playback_die()


func die_from_enemy() -> void:
	_playback_die()


## Preview contacts own their waiting/death state and never start the live lose-screen flow.
func begin_skeleton_attack(attacker: Node3D) -> bool:
	if is_dead() or not is_instance_valid(attacker) or not attacker.is_inside_tree():
		return false
	skeleton_attack_pending = true
	skeleton_attacker = attacker
	velocity = Vector3.ZERO
	if attention is GDPlayerAttention:
		(attention as GDPlayerAttention).stop_tracking()
	if animation_controller != null:
		(animation_controller as GDPlayerAnimation).prepare_enemy_attack(attacker.global_position)
	return true


func finish_skeleton_attack() -> void:
	if not skeleton_attack_pending:
		return
	skeleton_attack_pending = false
	skeleton_attacker = null
	_playback_die()


func is_waiting_for_skeleton_attack() -> bool:
	return skeleton_attack_pending


func update_skeleton_attack_wait(delta: float) -> void:
	if not is_instance_valid(skeleton_attacker) or not skeleton_attacker.is_inside_tree():
		finish_skeleton_attack()
		return
	if animation_controller != null:
		(animation_controller as GDPlayerAnimation).update_movement(Vector3.ZERO, delta, false)


func is_dead() -> bool:
	return playback_dead or skeleton_attack_pending


func apply_flame_damage(amount: float) -> void:
	if is_dead():
		return
	playback_flame_energy = maxf(playback_flame_energy - maxf(amount, 0.0), 0.0)
	if playback_flame_energy <= 0.0:
		_playback_die()


## Replay punches use preview-only health and cannot start a real scene transition.
func apply_zombie_damage(amount: float, attacker_position: Vector3 = Vector3.INF) -> void:
	if is_dead() or amount <= 0.0:
		return
	apply_flame_damage(amount)
	if not playback_dead and animation_controller != null:
		(animation_controller as GDPlayerAnimation).play_stagger(attacker_position)


func apply_spike_trap_damage(percent_of_max: float) -> void:
	if is_dead():
		return
	var maximum_energy: float = death_controller.max_flame_energy if death_controller != null else 100.0
	apply_flame_damage(maximum_energy * maxf(percent_of_max, 0.0) * 0.01)


func can_be_hit_by_spike_trap() -> bool:
	return not is_dead()


func drain_flame_energy() -> void:
	_playback_die()


func _playback_die() -> void:
	if is_dead():
		return
	playback_dead = true
	playback_flame_energy = 0.0
	velocity = Vector3.ZERO
	if animation_controller != null:
		animation_controller.play_death()
