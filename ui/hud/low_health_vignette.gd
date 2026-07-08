extends CanvasLayer
class_name GDLowHealthVignette

## Full-screen warning vignette shown above gameplay but behind gameplay HUD when player health is low.

const VIGNETTE_LAYER := 30

## Control containing the vignette shader material.
@export var vignette_rect_path: NodePath = ^"VignetteRect"
## Health ratio where the vignette first starts to appear, just below three default health bars.
@export_range(0.0, 1.0, 0.01) var start_health_ratio := 0.50
## Health ratio where the vignette reaches full strength, before the default HUD reaches one health bar.
@export_range(0.0, 1.0, 0.01) var full_health_ratio := 0.20
## How quickly the visible vignette catches up to health changes.
@export_range(0.1, 40.0, 0.1) var response_speed := 7.0

var target_intensity := 0.0
var visible_intensity := 0.0

@onready var vignette_rect: ColorRect = get_node(vignette_rect_path) as ColorRect


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = VIGNETTE_LAYER
    _configure_rect()
    _apply_intensity()


func set_health_ratio(ratio: float, is_dead: bool = false) -> void:
    var health_ratio := clampf(ratio, 0.0, 1.0)
    if is_dead:
        target_intensity = 1.0
        return

    var denominator := maxf(start_health_ratio - full_health_ratio, 0.001)
    target_intensity = clampf((start_health_ratio - health_ratio) / denominator, 0.0, 1.0)


func get_target_intensity() -> float:
    return target_intensity


func _process(delta: float) -> void:
    var smooth_t := 1.0 - exp(-response_speed * delta)
    visible_intensity = lerpf(visible_intensity, target_intensity, smooth_t)
    _apply_intensity()


func _configure_rect() -> void:
    if vignette_rect == null:
        return

    vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    vignette_rect.visible = false


func _apply_intensity() -> void:
    if vignette_rect == null:
        return

    vignette_rect.visible = visible_intensity > 0.001
    var shader_material := vignette_rect.material as ShaderMaterial
    if shader_material != null:
        shader_material.set_shader_parameter(&"intensity", visible_intensity)
