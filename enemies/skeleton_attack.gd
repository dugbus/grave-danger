extends Node
class_name GDSkeletonAttack

## Coordinates the lethal contact presentation without moving either character's carrier.

enum AttackState { Idle, Playing }

# The owning script preloads this component. Keep the parent as Node to avoid
# a circular script dependency while accessing its existing presentation API.
@onready var skeleton := get_parent()

var state := AttackState.Idle
var victim: GDPlayer
var attack_animation := ""


func is_attacking() -> bool:
	return state == AttackState.Playing


func try_start(player: GDPlayer) -> bool:
	if is_attacking() or skeleton.is_dead:
		return false
	var animation := skeleton.animation_player as AnimationPlayer
	attack_animation = GDEnemyPresentation.resolve_animation_name(animation, "attack")
	if attack_animation.is_empty() or not player.begin_skeleton_attack(skeleton.path_follow):
		return false
	victim = player
	state = AttackState.Playing
	skeleton._reset_footstep_phase()
	var pivot := skeleton.pivot as Node3D
	var direction := pivot.get_parent_node_3d().to_local(player.global_position) - pivot.position
	if Vector2(direction.x, direction.z).length_squared() > 0.000001:
		pivot.rotation.y = atan2(direction.x, direction.z)
	if not animation.animation_finished.is_connected(_on_animation_finished):
		animation.animation_finished.connect(_on_animation_finished)
	animation.speed_scale = 1.0
	skeleton.current_animation = attack_animation
	animation.play(attack_animation, 0.1)
	return true


## Interrupted animations and removed victims must never leave a surviving player locked in place.
func update_attack() -> void:
	var animation := skeleton.animation_player as AnimationPlayer
	if (
		not is_instance_valid(victim)
		or not victim.is_inside_tree()
		or animation.assigned_animation != attack_animation
		or not animation.is_playing()
	):
		finish_attack()


func finish_attack() -> void:
	if not is_attacking():
		return
	state = AttackState.Idle
	var player := victim
	victim = null
	if is_instance_valid(player) and player.is_inside_tree():
		player.finish_skeleton_attack()


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == attack_animation:
		finish_attack()
