extends CanvasLayer
class_name GDVampireProximityFog


const FOG_CANVAS_LAYER := 2

## Full-screen rectangle containing the purple fog shader material.
@export var fog_rect_path: NodePath = ^"FogRect"

var vampire: Node3D
var player: Node3D
var settings: Resource
var target_intensity := 0.0
var visible_intensity := 0.0
var suppressed := false

@onready var fog_rect := get_node_or_null(fog_rect_path) as ColorRect


func _ready() -> void:
	layer = FOG_CANVAS_LAYER
	if fog_rect != null:
		fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fog_rect.visible = false
		if fog_rect.material != null:
			fog_rect.material = fog_rect.material.duplicate() as Material
	_apply_intensity()


func _process(delta: float) -> void:
	if suppressed:
		return
	if vampire == null or player == null or settings == null \
		or not is_instance_valid(vampire) or not is_instance_valid(player):
		target_intensity = 0.0
	else:
		var horizontal_distance := Vector2(
			vampire.global_position.x - player.global_position.x,
			vampire.global_position.z - player.global_position.z
		).length()
		target_intensity = calculate_intensity(horizontal_distance)

	var smooth_weight := 1.0 - exp(-settings.proximity_fog_response_speed * delta) \
		if settings != null \
		else 1.0
	visible_intensity = lerpf(visible_intensity, target_intensity, smooth_weight)
	_apply_intensity()


func configure(vampire_node: Node3D, target_player: Node3D, vampire_settings: Resource) -> void:
	vampire = vampire_node
	player = target_player
	settings = vampire_settings


## Converts a world distance into the configured purple fog strength.
func calculate_intensity(distance: float) -> float:
	if settings == null:
		return 0.0

	var start_distance: float = settings.proximity_fog_distance
	var full_distance: float = minf(settings.proximity_fog_full_distance, start_distance - 0.01)
	var distance_ratio := clampf(
		(start_distance - distance) / maxf(start_distance - full_distance, 0.01),
		0.0,
		1.0
	)
	var eased_ratio := distance_ratio * distance_ratio * (3.0 - 2.0 * distance_ratio)
	return eased_ratio * settings.proximity_fog_max_intensity


func get_target_intensity() -> float:
	return target_intensity


## Hides and clears the effect while its owning vampire is disabled for development.
func set_suppressed(value: bool) -> void:
	suppressed = value
	visible = not suppressed
	if suppressed:
		target_intensity = 0.0
		visible_intensity = 0.0
		_apply_intensity()


## Returns whether the development disable has suppressed this effect.
func is_suppressed() -> bool:
	return suppressed


func _apply_intensity() -> void:
	if fog_rect == null:
		return

	fog_rect.visible = visible_intensity > 0.001
	var shader_material := fog_rect.material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"intensity", visible_intensity)
