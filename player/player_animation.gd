extends Node
class_name GDPlayerAnimation


signal footstep_phase_reached

# Animation owns imported-character setup and playback decisions. It searches
# the GLB subtree at runtime because imported scenes often nest AnimationPlayer
# nodes differently after asset updates.

# Animation speed range used by analogue movement.
const MIN_WALK_ANIMATION_SPEED = 0.45
const MAX_WALK_ANIMATION_SPEED = 1.0

# Lowest animation speed multiplier when carrying the maximum number of coins.
const MIN_WEIGHT_ANIMATION_MULTIPLIER = 0.65

# The character mesh is lit separately from the point light carried by the player.
const CHARACTER_LIGHT_LAYER = 2

# Names to search for in the imported character animation list.
const IDLE_ANIMATION_CANDIDATES = ["idle", "static"]
const WALK_ANIMATION_CANDIDATES = ["walk", "sprint", "move-forward"]
const DEATH_ANIMATION_CANDIDATES = ["death", "die", "fall"]


## Imported character subtree that contains meshes and animation players.
@export var character_path: NodePath = ^"../Pivot/Character"
## Visual pivot used for quick hit reactions.
@export var pivot_path: NodePath = ^"../Pivot"
## Local Y offset used for the non-physics hit hop.
@export var hit_reaction_height := 0.16
## Seconds used to lift the visual on hit.
@export var hit_reaction_up_seconds := 0.055
## Seconds used to settle the visual after a hit.
@export var hit_reaction_down_seconds := 0.09

@onready var character: Node = get_node_or_null(character_path)
@onready var pivot := get_node_or_null(pivot_path) as Node3D

var animation_player: AnimationPlayer
var idle_animation := ""
var walk_animation := ""
var death_animation := ""
var current_animation := ""
var previous_walk_animation_phase := -1.0
var hit_reaction_tween: Tween
var hit_reaction_base_y := 0.0


func _ready() -> void:
	# Visual setup lives with animation because both concerns operate on the
	# imported character subtree rather than the physics body.
	if character != null:
		_configure_character_visuals(character)
		animation_player = _find_animation_player(character)

	if pivot != null:
		hit_reaction_base_y = pivot.position.y

	if animation_player == null:
		push_warning("Player character has no AnimationPlayer.")
		return

	idle_animation = _find_animation(IDLE_ANIMATION_CANDIDATES)
	walk_animation = _find_animation(WALK_ANIMATION_CANDIDATES)
	death_animation = _find_animation(DEATH_ANIMATION_CANDIDATES)

	_set_animation_loop(idle_animation)
	_set_animation_loop(walk_animation)
	_play_animation(idle_animation)


func update_movement(input_strength: float, gold_inventory: Node) -> void:
	# Movement returns the same analogue strength it used for speed, so animation
	# playback can stay visually synchronized with actual movement.
	if input_strength <= 0.05:
		if animation_player != null:
			animation_player.speed_scale = 1.0
		_play_animation(idle_animation)
		_reset_footstep_phase()
		return

	if animation_player != null:
		# Carrying gold slows the walk cycle as well as the player's movement.
		var weight_animation_multiplier: float = gold_inventory.weight_multiplier(1.0, MIN_WEIGHT_ANIMATION_MULTIPLIER)
		animation_player.speed_scale = (
			lerpf(MIN_WALK_ANIMATION_SPEED, MAX_WALK_ANIMATION_SPEED, input_strength)
			* weight_animation_multiplier
		)
	_play_animation(walk_animation)
	_update_footstep_phase()


func play_death() -> void:
	# Death animation is intentionally slower for readability during the camera
	# close-up.
	_stop_hit_reaction(true)
	if animation_player != null:
		animation_player.speed_scale = 0.5
	_play_animation(death_animation)
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
		pivot,
		"position:y",
		hit_reaction_base_y + maxf(hit_reaction_height, 0.0),
		maxf(hit_reaction_up_seconds, 0.01)
	)
	hit_reaction_tween.set_ease(Tween.EASE_IN)
	hit_reaction_tween.tween_property(
		pivot,
		"position:y",
		hit_reaction_base_y,
		maxf(hit_reaction_down_seconds, 0.01)
	)


func _play_animation(animation_name: String) -> void:
	# Avoid restarting the same animation every frame; only crossfade when the
	# requested state actually changes.
	if animation_player == null or animation_name.is_empty() or current_animation == animation_name:
		return

	current_animation = animation_name
	animation_player.play(animation_name, 0.15)


func _update_footstep_phase() -> void:
	if animation_player == null or current_animation != walk_animation or walk_animation.is_empty():
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


func _find_animation(candidates: Array) -> String:
	# Imported animation names vary by asset. Prefer known semantic names, then
	# fall back to the first available animation so the character still moves.
	for candidate in candidates:
		for animation_name in animation_player.get_animation_list():
			if animation_name.to_lower() == candidate:
				return animation_name

	return animation_player.get_animation_list()[0] if not animation_player.get_animation_list().is_empty() else ""


func _set_animation_loop(animation_name: String) -> void:
	# Idle and walk should loop forever. Death is intentionally not passed here.
	if animation_name.is_empty():
		return

	var animation := animation_player.get_animation(animation_name)
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
