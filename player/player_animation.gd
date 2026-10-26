extends Node
class_name GDPlayerAnimation

signal footstep_phase_reached

enum PlaybackState { Locomotion, Stagger, Death }

# Animation owns imported-character setup and playback decisions. It searches
# the GLB subtree at runtime because imported scenes often nest AnimationPlayer
# nodes differently after asset updates.

# Cadence follows distance travelled rather than requested stick strength or weight.
const FOOT_PLANT := preload("res://player/player_foot_plant.gd")
const GAIT_SETTINGS := preload("res://player/player_gait_settings.tres")

# The character mesh is lit separately from the point light carried by the player.
const CHARACTER_LIGHT_LAYER = 2

# Names to search for in the imported character animation list.
# Prefer the authored idle without game-side pose corrections.
const IDLE_ANIMATION_CANDIDATES = ["idle", "static"]
const WALK_ANIMATION_CANDIDATES = ["walk", "sprint", "move-forward"]
const STAGGER_ANIMATION_CANDIDATES = ["stagger"]
const DEATH_ANIMATION_CANDIDATES = ["death", "die", "fall"]

## New character subtree preferred whenever it supplies the requested animation.
@export_storage var character_path: NodePath = ^"../Pivot/Character/NewCharacter"
## Legacy character subtree shown only when the new character lacks a requested animation.
@export_storage var fallback_character_path: NodePath = ^"../Pivot/Character/LegacyCharacter"
## Visual pivot used for quick hit reactions.
@export_storage var pivot_path: NodePath = ^"../Pivot"
## Local Y offset used for the non-physics hit hop.
@export var hit_reaction_height := 0.16
## Seconds used to lift the visual on hit.
@export var hit_reaction_up_seconds := 0.055
## Seconds used to settle the visual after a hit.
@export var hit_reaction_down_seconds := 0.09

@onready var character: Node = get_node_or_null(character_path)
@onready var fallback_character: Node = get_node_or_null(fallback_character_path)
@onready var pivot := get_node_or_null(pivot_path) as Node3D

var animation_player: AnimationPlayer
var primary_animation_player: AnimationPlayer
var fallback_animation_player: AnimationPlayer
var idle_animation_player: AnimationPlayer
var walk_animation_player: AnimationPlayer
var death_animation_player: AnimationPlayer
var idle_character: Node3D
var walk_character: Node3D
var death_character: Node3D
var active_character: Node3D
var idle_animation := ""
var walk_animation := ""
var death_animation := ""
var current_animation := ""
var playback_state := PlaybackState.Locomotion
var stagger_remaining := 0.0
var stagger_facing_yaw := 0.0
var pre_stagger_facing_yaw := 0.0
var stagger_animation := ""
var stagger_animation_player: AnimationPlayer
var stagger_character: Node3D
var primary_has_animations := false
var idle_uses_t_pose := false
var previous_walk_animation_phase := -1.0
var hit_reaction_tween: Tween
var hit_reaction_base_y := 0.0
var foot_plant: FOOT_PLANT
var gait_skeleton: Skeleton3D
var replay_previous_position := Vector3.ZERO
var last_walk_phase := 0.0
var gait_lift := 0.0
var gait_contact_scale := 1.0


func _ready() -> void:
	# Visual setup lives with animation because both concerns operate on the
	# imported character subtree rather than the physics body.
	if character != null:
		_configure_character_visuals(character)
		primary_animation_player = _find_animation_player(character)
	if fallback_character != null:
		_configure_character_visuals(fallback_character)
		fallback_animation_player = _find_animation_player(fallback_character)

	if pivot != null:
		hit_reaction_base_y = pivot.position.y

	if primary_animation_player != null:
		primary_animation_player.callback_mode_process = (AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL)
	if fallback_animation_player != null:
		fallback_animation_player.callback_mode_process = (AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL)
	if character != null:
		foot_plant = character.find_child("FootPlant", true, false) as FOOT_PLANT
		if foot_plant != null:
			gait_skeleton = foot_plant.get_skeleton()
			gait_skeleton.modifier_callback_mode_process = (Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL)
	_resolve_animation_sources()
	_set_animation_loop(idle_animation_player, idle_animation)
	_set_animation_loop(walk_animation_player, walk_animation)
	_play_selected_animation(idle_character, idle_animation_player, idle_animation)


## Gameplay pauses walking and jumping while the authored hit reaction is active.
func is_staggering() -> bool:
	return playback_state == PlaybackState.Stagger


## Held movement can cancel the reaction once its minimum authored fraction has played.
func try_interrupt_stagger(direction: Vector3) -> bool:
	if not is_staggering() or direction.is_zero_approx() or animation_player == null:
		return false
	var length := animation_player.get_animation(stagger_animation).length
	if length - stagger_remaining + 0.000001 < length * GAIT_SETTINGS.stagger_interrupt_fraction:
		return false
	playback_state = PlaybackState.Locomotion
	stagger_remaining = 0.0
	if pivot != null:
		var parent := pivot.get_parent() as Node3D
		var local_direction := parent.global_basis.inverse() * direction
		pivot.rotation.y = atan2(local_direction.x, local_direction.z)
	return true


## Physics supplies actual displacement after collisions, acceleration and braking.
func update_movement(displacement: Vector3, delta: float, grounded: bool) -> void:
	if delta <= 0.0:
		return
	var movement_delta := delta
	if playback_state == PlaybackState.Death:
		return
	if playback_state == PlaybackState.Stagger:
		if pivot != null:
			pivot.rotation.y = stagger_facing_yaw
		var consumed := minf(delta, stagger_remaining)
		animation_player.advance(consumed)
		stagger_remaining = maxf(stagger_remaining - consumed, 0.0)
		if gait_skeleton != null:
			gait_skeleton.advance(0.0)
		if stagger_remaining > 0.0:
			return
		# Movement turns before animation updates. Release the attacker's facing
		# before showing a walk pose so travel cannot briefly look backwards.
		if pivot != null:
			pivot.rotation.y = pre_stagger_facing_yaw
			if Vector2(displacement.x, displacement.z).length() / movement_delta > GAIT_SETTINGS.stationary_speed:
				var parent := pivot.get_parent() as Node3D
				var direction := parent.global_basis.inverse() * displacement
				pivot.rotation.y = atan2(direction.x, direction.z)
		playback_state = PlaybackState.Locomotion
		delta -= consumed
		# Select the next pose on this tick even if stagger consumed the whole tick.
		delta = maxf(delta, 0.000001)
	var distance := Vector2(displacement.x, displacement.z).length()
	var walking := distance / movement_delta > GAIT_SETTINGS.stationary_speed
	gait_contact_scale = GAIT_SETTINGS.contact_scale(distance / movement_delta)
	if not walking:
		_clear_gait_lift()
		_play_selected_animation(idle_character, idle_animation_player, idle_animation)
		if animation_player != null:
			animation_player.speed_scale = 1.0
			animation_player.advance(delta)
		_update_foot_plant(false, grounded, last_walk_phase)
		_reset_footstep_phase()
		return

	_play_selected_animation(walk_character, walk_animation_player, walk_animation)
	if animation_player == null or walk_animation.is_empty():
		return
	var clip := animation_player.get_animation(walk_animation)
	var legacy := walk_animation_player == fallback_animation_player
	animation_player.speed_scale = GAIT_SETTINGS.playback_speed(distance, movement_delta, clip.length, legacy)
	var stride := GAIT_SETTINGS.legacy_cycle_distance if legacy else GAIT_SETTINGS.cycle_distance
	var steps := maxi(1, ceili(distance / maxf(stride * GAIT_SETTINGS.maximum_phase_step, 0.001)))
	_clear_gait_lift()
	var visual := walk_character
	var final_position := visual.global_position
	# Substeps retain every contact transition, even when one physics frame spans
	# much of a short walk cycle. Only the visual moves; physics has already finished.
	for step in range(steps):
		visual.global_position = final_position - displacement * (1.0 - float(step + 1) / steps)
		animation_player.advance(delta / steps)
		last_walk_phase = animation_player.current_animation_position / clip.length
		gait_lift = (
			GAIT_SETTINGS.get_transfer_height(last_walk_phase, gait_contact_scale) if not legacy and grounded else 0.0
		)
		visual.position.y += gait_lift
		_update_foot_plant(true, grounded, last_walk_phase)
		_update_footstep_phase()
	visual.global_position = final_position
	visual.position.y += gait_lift


func _clear_gait_lift() -> void:
	if character is Node3D:
		(character as Node3D).position.y -= gait_lift
	gait_lift = 0.0


func _update_foot_plant(walking: bool, grounded: bool, phase: float) -> void:
	if foot_plant == null or gait_skeleton == null:
		return
	if active_character != character:
		foot_plant.reset()
	else:
		var left_was_planted := foot_plant.left_planted
		var right_was_planted := foot_plant.right_planted
		foot_plant.set_motion(walking, grounded, phase, gait_contact_scale)
		foot_plant.sample_contacts()
		if (
			walking
			and (
				(foot_plant.left_planted and not left_was_planted)
				or (foot_plant.right_planted and not right_was_planted)
			)
		):
			footstep_phase_reached.emit()
	gait_skeleton.advance(0.0)


## Death playback remains time based while the body settles.
func update_dead_animation(delta: float) -> void:
	if animation_player != null:
		animation_player.advance(delta)
	# Manual skeleton updates also refresh bone attachments used by death blood.
	if gait_skeleton != null:
		gait_skeleton.advance(0.0)


## Clear live reactions and face a lethal attacker while waiting in the authored idle pose.
func prepare_enemy_attack(attacker_position: Vector3) -> void:
	playback_state = PlaybackState.Locomotion
	stagger_remaining = 0.0
	_stop_hit_reaction(true)
	_clear_gait_lift()
	if foot_plant != null:
		foot_plant.reset()
	if pivot != null:
		var parent := pivot.get_parent() as Node3D
		var direction := parent.to_local(attacker_position) - pivot.position
		if Vector2(direction.x, direction.z).length_squared() > 0.000001:
			pivot.rotation.y = atan2(direction.x, direction.z)
	_play_selected_animation(idle_character, idle_animation_player, idle_animation)
	if animation_player != null:
		animation_player.speed_scale = 1.0
		animation_player.advance(0.0)
	_update_foot_plant(false, false, last_walk_phase)
	_reset_footstep_phase()


func play_death() -> void:
	# Death animation is intentionally slower for readability during the camera
	# close-up.
	playback_state = PlaybackState.Death
	stagger_remaining = 0.0
	_stop_hit_reaction(true)
	_clear_gait_lift()
	if foot_plant != null:
		foot_plant.reset()
	_play_selected_animation(death_character, death_animation_player, death_animation)
	if animation_player != null:
		animation_player.speed_scale = 0.5
	_reset_footstep_phase()


## Replay cadence uses recorded position changes, including collisions and carried weight.
func update_replay(_input_strength: float, is_dead: bool, delta: float) -> void:
	var actor := get_parent() as Node3D
	var position := actor.global_position if actor != null else replay_previous_position
	var displacement := position - replay_previous_position
	replay_previous_position = position
	if is_dead:
		play_death()
		update_dead_animation(delta)
		return
	# Recorded previews lack live floor collisions; vertical travel releases the feet.
	update_movement(displacement, delta, absf(displacement.y) <= 0.001)


## Establishes a fresh distance origin when a recorded-run preview starts or restarts.
func prepare_replay() -> void:
	playback_state = PlaybackState.Locomotion
	stagger_remaining = 0.0
	_clear_gait_lift()
	var actor := get_parent() as Node3D
	replay_previous_position = actor.global_position if actor != null else Vector3.ZERO
	if foot_plant != null:
		foot_plant.reset()


## Zombie punches play the authored clip once without changing physics movement.
func play_stagger(attacker_position: Vector3 = Vector3.INF) -> void:
	# Repeated damage cannot restart the mandatory recovery window.
	if playback_state == PlaybackState.Death or is_staggering():
		return
	if stagger_animation_player == null or stagger_animation.is_empty():
		play_hit_reaction()
		return
	_stop_hit_reaction(true)
	_clear_gait_lift()
	if pivot != null:
		if playback_state != PlaybackState.Stagger:
			pre_stagger_facing_yaw = pivot.rotation.y
		if attacker_position.is_finite():
			var parent := pivot.get_parent() as Node3D
			var direction := parent.to_local(attacker_position) - pivot.position
			if Vector2(direction.x, direction.z).length_squared() > 0.000001:
				pivot.rotation.y = atan2(direction.x, direction.z)
		stagger_facing_yaw = pivot.rotation.y
	if foot_plant != null:
		foot_plant.reset()
	var clip := stagger_animation_player.get_animation(stagger_animation)
	clip.loop_mode = Animation.LOOP_NONE
	_play_selected_animation(stagger_character, stagger_animation_player, stagger_animation)
	animation_player.speed_scale = 1.0
	animation_player.seek(0.0, true)
	stagger_remaining = clip.length
	playback_state = PlaybackState.Stagger
	_reset_footstep_phase()


func play_hit_reaction() -> void:
	if pivot == null:
		return

	_stop_hit_reaction(false)
	pivot.position.y = hit_reaction_base_y
	hit_reaction_tween = create_tween()
	hit_reaction_tween.set_trans(Tween.TRANS_SINE)
	hit_reaction_tween.set_ease(Tween.EASE_OUT)
	hit_reaction_tween.tween_property(
		pivot, "position:y", hit_reaction_base_y + maxf(hit_reaction_height, 0.0), maxf(hit_reaction_up_seconds, 0.01)
	)
	hit_reaction_tween.set_ease(Tween.EASE_IN)
	hit_reaction_tween.tween_property(pivot, "position:y", hit_reaction_base_y, maxf(hit_reaction_down_seconds, 0.01))


func _resolve_animation_sources() -> void:
	stagger_animation = _find_animation(primary_animation_player, STAGGER_ANIMATION_CANDIDATES)
	stagger_animation_player = primary_animation_player
	stagger_character = character as Node3D
	if stagger_animation.is_empty():
		stagger_animation = _find_animation(fallback_animation_player, STAGGER_ANIMATION_CANDIDATES)
		stagger_animation_player = fallback_animation_player
		stagger_character = fallback_character as Node3D
	primary_has_animations = _has_authored_animations(primary_animation_player)
	var primary_idle := _find_animation(primary_animation_player, IDLE_ANIMATION_CANDIDATES)
	var primary_walk := _find_animation(primary_animation_player, WALK_ANIMATION_CANDIDATES)
	var primary_death := _find_animation(primary_animation_player, DEATH_ANIMATION_CANDIDATES)
	var fallback_idle := _find_animation(fallback_animation_player, IDLE_ANIMATION_CANDIDATES)
	var fallback_walk := _find_animation(fallback_animation_player, WALK_ANIMATION_CANDIDATES)
	var fallback_death := _find_animation(fallback_animation_player, DEATH_ANIMATION_CANDIDATES)

	idle_uses_t_pose = not primary_has_animations
	if not primary_idle.is_empty():
		idle_character = character as Node3D
		idle_animation_player = primary_animation_player
		idle_animation = primary_idle
	elif idle_uses_t_pose:
		idle_character = character as Node3D
	else:
		idle_character = fallback_character as Node3D
		idle_animation_player = fallback_animation_player
		idle_animation = fallback_idle

	if not primary_walk.is_empty():
		walk_character = character as Node3D
		walk_animation_player = primary_animation_player
		walk_animation = primary_walk
	else:
		walk_character = fallback_character as Node3D
		walk_animation_player = fallback_animation_player
		walk_animation = fallback_walk

	if not primary_death.is_empty():
		death_character = character as Node3D
		death_animation_player = primary_animation_player
		death_animation = primary_death
	else:
		death_character = fallback_character as Node3D
		death_animation_player = fallback_animation_player
		death_animation = fallback_death

	if walk_character == null:
		walk_character = character as Node3D
	if death_character == null:
		death_character = character as Node3D


func _play_selected_animation(
	selected_character: Node3D, selected_player: AnimationPlayer, selected_animation: String
) -> void:
	if selected_character == null:
		return
	var selection_is_unchanged := (
		active_character == selected_character
		and animation_player == selected_player
		and current_animation == selected_animation
	)
	_set_active_character(selected_character)
	if selection_is_unchanged:
		return

	if animation_player != null and animation_player != selected_player:
		animation_player.stop()
	animation_player = selected_player
	current_animation = selected_animation
	if animation_player != null and not current_animation.is_empty():
		animation_player.play(current_animation, 0.15)


func _set_active_character(selected_character: Node3D) -> void:
	active_character = selected_character
	if character is Node3D:
		(character as Node3D).visible = selected_character == character
	if fallback_character is Node3D:
		(fallback_character as Node3D).visible = selected_character == fallback_character


func _update_footstep_phase() -> void:
	# The new rig emits footsteps at its authored contact windows; the legacy
	# model retains its established phase crossings because it has no foot targets.
	if foot_plant != null and active_character == character:
		return
	if (
		animation_player == null
		or animation_player != walk_animation_player
		or current_animation != walk_animation
		or walk_animation.is_empty()
	):
		_reset_footstep_phase()
		return

	var animation := animation_player.get_animation(walk_animation)
	if animation == null or animation.length <= 0.0:
		_reset_footstep_phase()
		return

	var current_phase := animation_player.current_animation_position / animation.length
	if GDAudio.did_cross_footstep_animation_phase(previous_walk_animation_phase, current_phase):
		footstep_phase_reached.emit()
	previous_walk_animation_phase = current_phase


func _reset_footstep_phase() -> void:
	previous_walk_animation_phase = -1.0


func _find_animation(player: AnimationPlayer, candidates: Array) -> String:
	if player == null:
		return ""
	# Imported animation libraries may prefix authored clip names.
	for candidate in candidates:
		for animation_name in player.get_animation_list():
			var normalized_name := String(animation_name).to_lower()
			if normalized_name == candidate or normalized_name.ends_with("/" + candidate):
				return String(animation_name)

	return ""


func _has_authored_animations(player: AnimationPlayer) -> bool:
	if player == null:
		return false
	for animation_name in player.get_animation_list():
		var normalized_name := String(animation_name).to_lower()
		if normalized_name != "reset" and not normalized_name.ends_with("/reset"):
			return true
	return false


func _set_animation_loop(player: AnimationPlayer, animation_name: String) -> void:
	# Idle and walk should loop forever. Death is intentionally not passed here.
	if player == null or animation_name.is_empty():
		return

	var animation := player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR


func _configure_character_visuals(node: Node) -> void:
	# The imported mesh uses a dedicated light layer and has real shadow casting
	# disabled because player.tscn provides a controlled flat contact shadow.
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = CHARACTER_LIGHT_LAYER

	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for child in node.get_children():
		_configure_character_visuals(child)


func _find_animation_player(node: Node) -> AnimationPlayer:
	# Recursive search keeps the player script resilient to GLB hierarchy changes.
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result

	return null


func _stop_hit_reaction(reset_position: bool) -> void:
	if hit_reaction_tween != null and hit_reaction_tween.is_valid():
		hit_reaction_tween.kill()
	hit_reaction_tween = null

	if reset_position and pivot != null:
		pivot.position.y = hit_reaction_base_y
