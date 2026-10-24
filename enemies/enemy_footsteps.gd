extends RefCounted
class_name GDEnemyFootsteps

## Tracks authored animation contacts without advancing animation, patrol time, or random generators.

var previous_phase := -1.0


func did_cross_animation_phase(
	animation_player: AnimationPlayer, current_animation: String, walk_animation: String
) -> bool:
	if animation_player == null or current_animation != walk_animation or walk_animation.is_empty():
		reset()
		return false
	var animation := animation_player.get_animation(walk_animation)
	if animation == null or animation.length <= 0.0:
		reset()
		return false
	var current_phase := animation_player.current_animation_position / animation.length
	var crossed_phase := GDAudio.did_cross_footstep_animation_phase(previous_phase, current_phase)
	previous_phase = current_phase
	return crossed_phase


func reset() -> void:
	previous_phase = -1.0
