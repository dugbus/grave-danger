extends MeshInstance3D
class_name GDFlaskEffectText


const EFFECT_LABELS := {
	&"health_flask": "Healing",
	&"breathing_space": "Expand",
	&"pause_boundary": "Freeze",
	&"poison": "Poisoned",
	&"pickup_radius": "Easy Pickup",
	&"bigger_sack": "Big Sack",
	&"no_boundary": "Safety",
}
const CREEPSTER_FONT_PATH := "res://Assets/fonts/creepster_regular.ttf"
const TEXT_SHADER := preload("res://player/flask_effect_text.gdshader")
const TEXT_VISUAL_LAYER := 1 << 19
const FADE_IN_DURATION := 0.3

@export_range(0.1, 1.0, 0.01) var text_opacity := 0.5:
	set(value):
		text_opacity = clampf(value, 0.1, 1.0)
		_apply_effect_color(current_color)
@export_range(16, 180, 1) var font_size := 92:
	set(value):
		font_size = maxi(value, 16)
		_configure_text_mesh()
@export_range(0.001, 0.05, 0.001) var pixel_size := 0.009:
	set(value):
		pixel_size = maxf(value, 0.001)
		_configure_text_mesh()
@export_range(0.0, 0.25, 0.005, "suffix:m") var text_depth := 0.08:
	set(value):
		text_depth = maxf(value, 0.0)
		_configure_text_mesh()
@export_range(0.5, 20.0, 0.1, "suffix:m") var camera_distance := 10.0
@export_range(-1.0, 1.0, 0.01) var viewport_x_offset := 0.0
@export_range(-1.0, 1.0, 0.01) var viewport_y_offset := 0.36
@export_range(-25.0, 25.0, 0.5, "suffix:deg") var perspective_yaw_degrees := -12.0
@export_range(-25.0, 25.0, 0.5, "suffix:deg") var perspective_pitch_degrees := 6.0
@export_group("Text Light")
@export var light_offset := Vector3(-1.15, 0.9, 1.35)
@export_range(0.0, 40.0, 0.1) var light_energy := 6.5
@export_range(0.1, 20.0, 0.1, "suffix:m") var light_range := 5.5
@export var light_color := Color(1.0, 0.88, 0.68)
@export_range(0.0, 4.0, 0.05, "suffix:m") var light_sweep_padding := 0.5
@export_range(0.0, 6.0, 0.05, "suffix:Hz") var light_sweep_speed := 0.42

var active_effects: Array[Dictionary] = []
var text_mesh: TextMesh
var text_material: ShaderMaterial
var text_light: OmniLight3D
var creepster_font: FontFile
var current_color := Color.WHITE
var current_opacity := 0.0
var current_light_sweep_width := 1.0
var light_elapsed := 0.0


func _init() -> void:
	_configure_text_mesh()
	_configure_material()


func _ready() -> void:
	visible = false
	top_level = true
	layers = TEXT_VISUAL_LAYER
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_configure_text_mesh()
	_configure_material()
	_ensure_text_light()
	_bind_to_parent()


func _process(delta: float) -> void:
	light_elapsed += delta
	_update_active_effects(delta)
	_update_transform()


func show_flask_effect(effect_id: StringName, liquid_color: Color, duration: float) -> void:
	duration = maxf(duration, 0.0)
	if duration <= 0.0:
		return

	var effect := _find_effect(effect_id)
	if effect.is_empty():
		active_effects.append({
			"id": effect_id,
			"label": _get_effect_label(effect_id),
			"remaining": duration,
			"duration": duration,
			"color": liquid_color,
		})
	else:
		effect["remaining"] = duration
		effect["duration"] = duration
		effect["color"] = liquid_color
		active_effects.erase(effect)
		active_effects.append(effect)

	_update_text()


func _bind_to_parent() -> void:
	var player: Node = get_parent()
	if player == null or not player.has_signal("flask_effect_started"):
		return
	if player.flask_effect_started.is_connected(show_flask_effect):
		return

	player.flask_effect_started.connect(show_flask_effect)


func _configure_text_mesh() -> void:
	if text_mesh == null:
		text_mesh = mesh as TextMesh
		if text_mesh == null:
			text_mesh = TextMesh.new()
			mesh = text_mesh

	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font := _get_creepster_font()
	if font != null:
		text_mesh.font = font
	text_mesh.font_size = font_size
	text_mesh.pixel_size = pixel_size
	text_mesh.depth = text_depth
	text_mesh.text = ""


func _configure_material() -> void:
	if text_material == null:
		text_material = material_override as ShaderMaterial
		if text_material == null:
			text_material = ShaderMaterial.new()
			material_override = text_material

	text_material.shader = TEXT_SHADER
	_apply_effect_color(current_color)


func _update_active_effects(delta: float) -> void:
	var changed := false
	for effect in active_effects.duplicate():
		var remaining := float(effect["remaining"]) - delta
		effect["remaining"] = remaining
		if remaining <= 0.0:
			active_effects.erase(effect)
			changed = true

	if changed or visible:
		_update_text()


func _update_text() -> void:
	if text_mesh == null:
		return

	if active_effects.is_empty():
		text_mesh.text = ""
		visible = false
		_set_text_light_visible(false)
		current_opacity = 0.0
		return

	var effect: Dictionary = active_effects.back()
	var label := str(effect["label"])
	var remaining := maxf(float(effect["remaining"]), 0.0)
	var duration := maxf(float(effect.get("duration", remaining)), 0.001)
	var elapsed := maxf(duration - remaining, 0.0)
	var fade_in := clampf(elapsed / FADE_IN_DURATION, 0.0, 1.0)
	current_color = effect["color"] as Color
	current_opacity = clampf(remaining / duration, 0.0, 1.0) * fade_in
	text_mesh.text = label
	_update_light_sweep_width()
	_apply_effect_color(current_color)
	visible = true
	_set_text_light_visible(true)


func _update_transform() -> void:
	if not visible:
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var desired_position := _get_camera_overlay_position(camera)
	var perspective_basis := camera.global_transform.basis
	perspective_basis = perspective_basis.rotated(perspective_basis.y.normalized(), deg_to_rad(perspective_yaw_degrees))
	perspective_basis = perspective_basis.rotated(perspective_basis.x.normalized(), deg_to_rad(perspective_pitch_degrees))
	global_transform = Transform3D(perspective_basis, desired_position)
	_update_text_light(camera, desired_position)


func _get_camera_overlay_position(camera: Camera3D) -> Vector3:
	var distance := maxf(camera_distance, camera.near + 0.01)
	var camera_basis := camera.global_transform.basis
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var half_height := 0.0
	var half_width := 0.0

	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		half_height = camera.size * 0.5
		half_width = half_height * aspect
	else:
		half_height = tan(deg_to_rad(camera.fov) * 0.5) * distance
		half_width = half_height * aspect

	var overlay_position := camera.global_position - camera_basis.z.normalized() * distance
	overlay_position += camera_basis.x.normalized() * half_width * viewport_x_offset
	overlay_position += camera_basis.y.normalized() * half_height * viewport_y_offset
	return overlay_position


func _apply_effect_color(_color: Color) -> void:
	if text_material == null:
		return

	var display_color := _color.lerp(Color.WHITE, 0.42)
	display_color.a = text_opacity * current_opacity
	text_material.set_shader_parameter("text_color", display_color)


func _ensure_text_light() -> void:
	if text_light != null and is_instance_valid(text_light):
		return

	text_light = get_node_or_null(^"PotionEffectTextLight") as OmniLight3D
	if text_light == null:
		text_light = OmniLight3D.new()
		text_light.name = "PotionEffectTextLight"
		add_child(text_light)

	text_light.top_level = true
	text_light.visible = false
	text_light.light_cull_mask = TEXT_VISUAL_LAYER
	text_light.shadow_enabled = false
	text_light.light_color = light_color
	text_light.light_energy = light_energy
	text_light.omni_range = light_range


func _update_text_light(camera: Camera3D, text_position: Vector3) -> void:
	if text_light == null or not is_instance_valid(text_light):
		_ensure_text_light()
	if text_light == null:
		return

	var camera_basis := camera.global_transform.basis
	var sweep_offset := sin(light_elapsed * TAU * light_sweep_speed) * current_light_sweep_width * 0.5
	text_light.light_color = light_color
	text_light.light_energy = light_energy
	text_light.omni_range = light_range
	text_light.light_cull_mask = TEXT_VISUAL_LAYER
	text_light.global_position = (
		text_position
		+ camera_basis.x.normalized() * (light_offset.x + sweep_offset)
		+ camera_basis.y.normalized() * light_offset.y
		+ camera_basis.z.normalized() * light_offset.z
	)


func _set_text_light_visible(should_be_visible: bool) -> void:
	if text_light == null or not is_instance_valid(text_light):
		_ensure_text_light()
	if text_light != null:
		text_light.visible = should_be_visible


func _update_light_sweep_width() -> void:
	if text_mesh == null:
		return

	var bounds := text_mesh.get_aabb()
	current_light_sweep_width = maxf(bounds.size.x + light_sweep_padding, 0.1)


func _find_effect(effect_id: StringName) -> Dictionary:
	for effect in active_effects:
		if effect["id"] == effect_id:
			return effect

	return {}


func _get_creepster_font() -> FontFile:
	if creepster_font != null:
		return creepster_font

	var font := FontFile.new()
	var load_error := font.load_dynamic_font(CREEPSTER_FONT_PATH)
	if load_error != OK:
		push_warning("Unable to load potion effect font: %s" % CREEPSTER_FONT_PATH)
		return null

	creepster_font = font
	return creepster_font


func _get_effect_label(effect_id: StringName) -> String:
	if EFFECT_LABELS.has(effect_id):
		return EFFECT_LABELS[effect_id]

	return String(effect_id).capitalize()
