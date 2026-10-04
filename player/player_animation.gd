extends Node
class_name GDPlayerAnimation


signal footstep_phase_reached

# Animation owns imported-character setup and playback decisions. It searches
# the GLB subtree at runtime because imported scenes often nest AnimationPlayer
# nodes differently after asset updates.

# Doubled animation speed range used by analogue movement to prevent foot sliding.
const MIN_WALK_ANIMATION_SPEED = 0.9
const MAX_WALK_ANIMATION_SPEED = 2.0

# Lowest animation speed multiplier when carrying the maximum treasure weight.
const MIN_WEIGHT_ANIMATION_MULTIPLIER = 0.65

# The character mesh is lit separately from the point light carried by the player.
const CHARACTER_LIGHT_LAYER = 2

# Names to search for in the imported character animation list.
const IDLE_ANIMATION_CANDIDATES = ["idle", "static"]
const WALK_ANIMATION_CANDIDATES = ["walk", "sprint", "move-forward"]
const DEATH_ANIMATION_CANDIDATES = ["death", "die", "fall"]


## New character subtree preferred whenever it supplies the requested animation.
@export var character_path: NodePath = ^"../Pivot/Character/NewCharacter"
## Legacy character subtree shown only when the new character lacks a requested animation.
@export var fallback_character_path: NodePath = ^"../Pivot/Character/LegacyCharacter"
## Visual pivot used for quick hit reactions.
@export var pivot_path: NodePath = ^"../Pivot"
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
var primary_has_animations := false
var idle_uses_t_pose := false
var previous_walk_animation_phase := -1.0
var hit_reaction_tween: Tween
var hit_reaction_base_y := 0.0


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

	_resolve_animation_sources()
	_set_animation_loop(idle_animation_player, idle_animation)
	_set_animation_loop(walk_animation_player, walk_animation)
	_play_selected_animation(idle_character, idle_animation_player, idle_animation)


func update_movement(input_strength: float, inventory: Node) -> void:
	# Movement returns the same analogue strength it used for speed, so animation
	# playback can stay visually synchronized with actual movement.
	if input_strength <= 0.05:
		_play_selected_animation(idle_character, idle_animation_player, idle_animation)
		if animation_player != null:
			animation_player.speed_scale = 1.0
		_reset_footstep_phase()
		return

	_play_selected_animation(walk_character, walk_animation_player, walk_animation)
	if animation_player != null:
		# Carrying gold slows the walk cycle as well as the player's movement.
		var weight_animation_multiplier: float = inventory.weight_multiplier(1.0, MIN_WEIGHT_ANIMATION_MULTIPLIER)
		animation_player.speed_scale = (
			lerpf(MIN_WALK_ANIMATION_SPEED, MAX_WALK_ANIMATION_SPEED, input_strength)
			* weight_animation_multiplier
		)
	_update_footstep_phase()


func play_death() -> void:
	# Death animation is intentionally slower for readability during the camera
	# close-up.
	_stop_hit_reaction(true)
	_play_selected_animation(death_character, death_animation_player, death_animation)
	if animation_player != null:
		animation_player.speed_scale = 0.5
	_reset_footstep_phase()


## Mirrors live animation fallback in recorded-run previews without inventory state.
func update_replay(input_strength: float, is_dead: bool, delta: float) -> void:
	if is_dead:
		_play_selected_animation(death_character, death_animation_player, death_animation)
		if animation_player != null:
			animation_player.speed_scale = 0.5
	elif input_strength > 0.05:
		_play_selected_animation(walk_character, walk_animation_player, walk_animation)
		if animation_player != null:
			animation_player.speed_scale = lerpf(
				MIN_WALK_ANIMATION_SPEED,
				MAX_WALK_ANIMATION_SPEED,
				clampf(input_strength, 0.0, 1.0)
			)
	else:
		_play_selected_animation(idle_character, idle_animation_player, idle_animation)
		if animation_player != null:
			animation_player.speed_scale = 1.0
	if animation_player != null:
		animation_player.advance(delta)


## Disables automatic clip advancement so recorded-run previews can step exact frame deltas.
func prepare_replay() -> void:
	if primary_animation_player != null:
		primary_animation_player.process_mode = Node.PROCESS_MODE_DISABLED
	if fallback_animation_player != null:
		fallback_animation_player.process_mode = Node.PROCESS_MODE_DISABLED


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


func _resolve_animation_sources() -> void:
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
	selected_character: Node3D,
	selected_player: AnimationPlayer,
	selected_animation: String
) -> void:
	if selected_character == null:
		return
	var selection_is_unchanged := active_character == selected_character \
		and animation_player == selected_player \
		and current_animation == selected_animation
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
	if animation_player == null \
			or animation_player != walk_animation_player \
			or current_animation != walk_animation \
			or walk_animation.is_empty():
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
