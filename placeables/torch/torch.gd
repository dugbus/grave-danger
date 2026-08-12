class_name GDTorch
extends "res://placeables/placeable.gd"
## A wall-mounted torch that permanently lights when the player stands still beside it.

signal lit

const PLAYER_GROUP: StringName = &"player"
const TORCH_GEOMETRY_VISUAL_LAYER := 1 << 17
const ALL_VISUAL_LAYERS := (1 << 20) - 1
const ALL_SHADOW_CASTER_LAYERS := (1 << 32) - 1
const TORCH_SHADOW_CASTER_MASK := ALL_SHADOW_CASTER_LAYERS & ~TORCH_GEOMETRY_VISUAL_LAYER
const DEFAULT_LIGHT_ENERGY := 5.0
const DEFAULT_LIGHT_RANGE := 7.0
const FLICKER_SPEED := 11.0
const FLICKER_AMOUNT := 0.12

## Optional persistent identity; leave empty to use this placed node's stable scene path.
@export var torch_id: StringName
## Seconds the player must remain still beside this torch before it lights.
@export_range(0.1, 10.0, 0.05, "suffix:s") var activation_duration_seconds := 0.5
## Furthest distance from which the player can light this torch.
@export_range(0.5, 10.0, 0.1, "suffix:m") var activation_distance := 3.0
## Maximum residual movement speed still considered stationary for activation.
@export_range(0.0, 0.5, 0.01, "suffix:m/s") var activation_still_speed := 0.05
## Distance at which an unlit torch's subtle guidance outline begins to appear.
@export_range(0.5, 12.0, 0.1, "suffix:m") var outline_activation_distance := 4.5
## Distance at which the unlit guidance outline reaches its full intensity.
@export_range(0.1, 10.0, 0.1, "suffix:m") var outline_full_intensity_distance := 1.5

var is_lit := false
var activation_elapsed_seconds := 0.0
var flicker_elapsed := 0.0

@onready var flame_particles := get_node_or_null("%FlameParticles") as GPUParticles3D
@onready var ember_particles := get_node_or_null("%EmberParticles") as CPUParticles3D
@onready var flame_light := get_node_or_null("%FlameLight") as OmniLight3D
@onready var outline_mesh := get_node_or_null(
	"RaisedWallMount/Model/RootNode/Torch1"
) as MeshInstance3D


func _ready() -> void:
	_configure_self_shadow_exclusion()
	_apply_lit_visuals(false)
	var level_selection := _get_level_selection()
	if level_selection != null and level_selection.has_method("is_torch_lit"):
		if level_selection.is_torch_lit(_get_persistence_id()):
			_set_lit(false)
	super._ready()


func _physics_process(delta: float) -> void:
	if is_lit:
		return

	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	update_outline_for_player(player)
	update_activation_for_player(player, delta)


func _process(delta: float) -> void:
	if not is_lit or flame_light == null:
		return

	flicker_elapsed += delta
	var first_wave := sin(flicker_elapsed * FLICKER_SPEED)
	var second_wave := sin(flicker_elapsed * FLICKER_SPEED * 1.73 + 1.2)
	flame_light.light_energy = DEFAULT_LIGHT_ENERGY * (
		1.0 + first_wave * FLICKER_AMOUNT + second_wave * FLICKER_AMOUNT * 0.35
	)


## Advances activation while the player remains still within the configured distance.
func update_activation_for_player(player: Node3D, delta: float) -> void:
	if is_lit:
		return

	if not _is_player_still(player) or not _is_player_within_activation_distance(player):
		activation_elapsed_seconds = 0.0
		return

	activation_elapsed_seconds += maxf(delta, 0.0)
	if activation_elapsed_seconds >= activation_duration_seconds:
		_set_lit(true)


## Updates the subtle unlit outline from the player's proximity to this torch.
func update_outline_for_player(player: Node3D) -> void:
	if is_lit or player == null:
		_set_outline_intensity(0.0)
		return

	var fade_distance := maxf(outline_activation_distance, outline_full_intensity_distance + 0.01)
	var distance_to_player := global_position.distance_to(player.global_position)
	var intensity := 1.0 - smoothstep(
		outline_full_intensity_distance,
		fade_distance,
		distance_to_player
	)
	_set_outline_intensity(intensity)


func _is_player_within_activation_distance(player: Node3D) -> bool:
	if player == null:
		return false

	var to_torch := global_position - player.global_position
	to_torch.y = 0.0
	return to_torch.length_squared() <= activation_distance * activation_distance


func _is_player_still(player: Node3D) -> bool:
	if player == null:
		return false
	if not player is CharacterBody3D:
		return true

	var body := player as CharacterBody3D
	return body.velocity.length_squared() <= activation_still_speed * activation_still_speed


func _set_lit(should_persist: bool) -> void:
	if is_lit:
		return

	is_lit = true
	activation_elapsed_seconds = activation_duration_seconds
	_set_outline_intensity(0.0)
	_apply_lit_visuals(true)
	if should_persist:
		var level_selection := _get_level_selection()
		if level_selection != null and level_selection.has_method("mark_torch_lit"):
			level_selection.mark_torch_lit(_get_persistence_id())
	lit.emit()


func _apply_lit_visuals(enabled: bool) -> void:
	if flame_particles != null:
		flame_particles.emitting = enabled
		flame_particles.visible = enabled
	if ember_particles != null:
		ember_particles.emitting = enabled
		ember_particles.visible = enabled
	if flame_light != null:
		flame_light.visible = enabled
		flame_light.light_energy = DEFAULT_LIGHT_ENERGY
		flame_light.omni_range = DEFAULT_LIGHT_RANGE


func _configure_self_shadow_exclusion() -> void:
	if outline_mesh != null:
		outline_mesh.layers = TORCH_GEOMETRY_VISUAL_LAYER
	if flame_light != null:
		flame_light.light_cull_mask = ALL_VISUAL_LAYERS
		flame_light.shadow_caster_mask = TORCH_SHADOW_CASTER_MASK
		flame_light.shadow_enabled = true


func _set_outline_intensity(intensity: float) -> void:
	if outline_mesh == null:
		return

	var clamped_intensity := clampf(intensity, 0.0, 1.0)
	outline_mesh.set_instance_shader_parameter(&"outline_intensity", clamped_intensity)


func _get_persistence_id() -> StringName:
	if not torch_id.is_empty():
		return torch_id
	return StringName(get_path())


func _get_level_selection() -> Node:
	return get_node_or_null("/root/LevelSelection")
