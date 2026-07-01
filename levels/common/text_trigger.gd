@tool
class_name GDTextTrigger
extends Area3D


const TEXT_SHADER := preload("res://player/flask_effect_text.gdshader")
const TEXT_VISUAL_LAYER := 1 << 19
const FADE_IN_DURATION := 0.2
const MIN_TRIGGER_SIZE := 0.05
const FLASK_EFFECT_TEXT_GROUP := &"flask_effect_text"
const CONTINUE_ACTIONS: Array[StringName] = [&"ui_accept", &"drop_carried"]
const DIM_OVERLAY_DISTANCE_PADDING := 0.35

@export_group("Content")
@export_multiline var heading := "A Warning":
	set(value):
		heading = value
		_update_text_content()
@export_multiline var text := "There is danger ahead.":
	set(value):
		text = value
		_update_text_content()
@export_range(0.1, 120.0, 0.1, "or_greater", "suffix:s") var minimum_time_on_screen := 3.0
@export var pause_game_with_text := false
@export_group("Trigger Volume")
@export var trigger_size := Vector3.ONE:
	set(value):
		trigger_size = Vector3(
			maxf(value.x, MIN_TRIGGER_SIZE),
			maxf(value.y, MIN_TRIGGER_SIZE),
			maxf(value.z, MIN_TRIGGER_SIZE)
		)
		_apply_trigger_size()
@export_group("Detection")
@export var player_group: StringName = &"player"
@export_group("Text Layout")
@export_range(16, 120, 1) var heading_font_size := 54:
	set(value):
		heading_font_size = maxi(value, 16)
		_configure_text_meshes()
@export_range(12, 90, 1) var body_font_size := 34:
	set(value):
		body_font_size = maxi(value, 12)
		_configure_text_meshes()
@export_range(8, 100, 1) var heading_characters_per_line := 28:
	set(value):
		heading_characters_per_line = maxi(value, 8)
		_update_text_content()
@export_range(12, 140, 1) var body_characters_per_line := 54:
	set(value):
		body_characters_per_line = maxi(value, 12)
		_update_text_content()
@export_range(0.001, 0.05, 0.001) var pixel_size := 0.009:
	set(value):
		pixel_size = maxf(value, 0.001)
		_configure_text_meshes()
@export_range(0.0, 0.25, 0.005, "suffix:m") var text_depth := 0.08:
	set(value):
		text_depth = maxf(value, 0.0)
		_configure_text_meshes()
@export_range(0.5, 20.0, 0.1, "suffix:m") var camera_distance := 10.0
@export_range(-1.0, 1.0, 0.01) var viewport_x_offset := 0.0
@export_range(-1.0, 1.0, 0.01) var viewport_y_offset := 0.42
@export_range(-2.0, 2.0, 0.01, "suffix:m") var heading_y_offset := 0.32
@export_range(-2.0, 2.0, 0.01, "suffix:m") var body_y_offset := -0.24
@export_range(-25.0, 25.0, 0.5, "suffix:deg") var perspective_yaw_degrees := -12.0
@export_range(-25.0, 25.0, 0.5, "suffix:deg") var perspective_pitch_degrees := 6.0
@export_group("Text Style")
@export var text_color := Color(1.0, 0.94, 0.78, 1.0):
	set(value):
		text_color = value
		_apply_text_opacity()
@export_range(0.1, 1.0, 0.01) var text_opacity := 0.72:
	set(value):
		text_opacity = clampf(value, 0.1, 1.0)
		_apply_text_opacity()
@export_group("Text Light")
@export var light_offset := Vector3(-1.15, 0.9, 1.35)
@export_range(0.0, 40.0, 0.1) var light_energy := 6.5
@export_range(0.1, 20.0, 0.1, "suffix:m") var light_range := 5.5
@export var light_color := Color(1.0, 0.88, 0.68)
@export_range(0.0, 4.0, 0.05, "suffix:m") var light_sweep_padding := 0.5
@export_range(0.0, 6.0, 0.05, "suffix:Hz") var light_sweep_speed := 0.42
@export_group("Pause Overlay")
@export_range(0.0, 1.0, 0.01) var dim_opacity := 0.5:
	set(value):
		dim_opacity = clampf(value, 0.0, 1.0)
		_apply_dim_overlay_opacity()

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var heading_text_mesh_instance: MeshInstance3D
var body_text_mesh_instance: MeshInstance3D
var dim_overlay_mesh_instance: MeshInstance3D
var dim_overlay_mesh: QuadMesh
var dim_overlay_material: StandardMaterial3D
var text_light: OmniLight3D
var pause_layer: CanvasLayer
var continue_button: Button
var heading_text_mesh: TextMesh
var body_text_mesh: TextMesh
var heading_text_material: ShaderMaterial
var body_text_material: ShaderMaterial
var bodies_in_trigger: Array[Node3D] = []
var is_showing := false
var elapsed_visible := 0.0
var current_opacity := 0.0
var light_elapsed := 0.0
var current_light_sweep_width := 1.0
var dismissed_until_exit := false
var paused_by_trigger := false
var tree_was_paused := false
var suppressing_flask_effect_text := false
var continue_button_has_focus := false
var continue_requested := false
var has_completed_text := false


func _ready() -> void:
	_apply_trigger_size()
	if Engine.is_editor_hint():
		return

	collision_layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_runtime_nodes()
	_configure_text_nodes()
	_configure_pause_layer()
	_hide_text()
	_detect_initial_overlaps.call_deferred()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	light_elapsed += delta
	_prune_invalid_bodies()

	if is_showing:
		elapsed_visible += delta
		_update_continue_button()
		_update_visibility_state()
		_update_transform()
		_consume_pending_continue()


func _input(event: InputEvent) -> void:
	if not pause_game_with_text or not is_showing:
		return
	if not _is_continue_input(event):
		return

	get_viewport().set_input_as_handled()
	_request_continue()


func _exit_tree() -> void:
	_release_flask_effect_text()
	if paused_by_trigger and not tree_was_paused:
		get_tree().paused = false


func _configure_text_nodes() -> void:
	heading_text_mesh_instance.top_level = true
	heading_text_mesh_instance.layers = TEXT_VISUAL_LAYER
	heading_text_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_text_mesh_instance.top_level = true
	body_text_mesh_instance.layers = TEXT_VISUAL_LAYER
	body_text_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dim_overlay_mesh_instance.top_level = true
	dim_overlay_mesh_instance.layers = TEXT_VISUAL_LAYER
	dim_overlay_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	text_light.top_level = true
	text_light.light_cull_mask = TEXT_VISUAL_LAYER
	text_light.shadow_enabled = false
	_configure_text_meshes()
	_configure_materials()
	_update_text_content()


func _create_runtime_nodes() -> void:
	heading_text_mesh_instance = MeshInstance3D.new()
	heading_text_mesh_instance.name = "HeadingText"
	add_child(heading_text_mesh_instance)

	body_text_mesh_instance = MeshInstance3D.new()
	body_text_mesh_instance.name = "BodyText"
	add_child(body_text_mesh_instance)

	dim_overlay_mesh_instance = MeshInstance3D.new()
	dim_overlay_mesh_instance.name = "DimOverlay"
	add_child(dim_overlay_mesh_instance)

	text_light = OmniLight3D.new()
	text_light.name = "TextLight"
	add_child(text_light)

	pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseLayer"
	pause_layer.layer = 190
	add_child(pause_layer)

	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	continue_button.offset_left = -110.0
	continue_button.offset_top = -112.0
	continue_button.offset_right = 110.0
	continue_button.offset_bottom = -56.0
	continue_button.focus_mode = Control.FOCUS_ALL
	continue_button.disabled = false
	continue_button.add_theme_font_size_override("font_size", 32)
	continue_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78, 1.0))
	continue_button.add_theme_color_override("font_focus_color", Color.WHITE)
	continue_button.add_theme_color_override("font_hover_color", Color.WHITE)
	continue_button.add_theme_stylebox_override("focus", _create_continue_focus_style())
	pause_layer.add_child(continue_button)


func _apply_trigger_size() -> void:
	var trigger_collision_shape := _get_collision_shape()
	if trigger_collision_shape != null:
		var box_shape := trigger_collision_shape.shape as BoxShape3D
		if box_shape == null:
			box_shape = BoxShape3D.new()
			trigger_collision_shape.shape = box_shape
		box_shape.size = trigger_size


func _configure_text_meshes() -> void:
	if heading_text_mesh_instance == null or body_text_mesh_instance == null:
		return

	heading_text_mesh = _get_or_create_text_mesh(heading_text_mesh_instance, heading_font_size)
	body_text_mesh = _get_or_create_text_mesh(body_text_mesh_instance, body_font_size)
	_configure_dim_overlay_mesh()


func _get_or_create_text_mesh(mesh_instance: MeshInstance3D, font_size: int) -> TextMesh:
	var configured_text_mesh := mesh_instance.mesh as TextMesh
	if configured_text_mesh == null:
		configured_text_mesh = TextMesh.new()
		mesh_instance.mesh = configured_text_mesh

	configured_text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	configured_text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font := GDGameFont.get_almendra_font()
	if font != null:
		configured_text_mesh.font = font
	configured_text_mesh.font_size = font_size
	configured_text_mesh.pixel_size = pixel_size
	configured_text_mesh.depth = text_depth
	return configured_text_mesh


func _configure_materials() -> void:
	heading_text_material = _get_or_create_text_material(heading_text_mesh_instance)
	body_text_material = _get_or_create_text_material(body_text_mesh_instance)
	_apply_text_opacity()


func _get_or_create_text_material(mesh_instance: MeshInstance3D) -> ShaderMaterial:
	var configured_material := mesh_instance.material_override as ShaderMaterial
	if configured_material == null:
		configured_material = ShaderMaterial.new()
		mesh_instance.material_override = configured_material

	configured_material.shader = TEXT_SHADER
	return configured_material


func _configure_dim_overlay_mesh() -> void:
	if dim_overlay_mesh_instance == null:
		return

	dim_overlay_mesh = dim_overlay_mesh_instance.mesh as QuadMesh
	if dim_overlay_mesh == null:
		dim_overlay_mesh = QuadMesh.new()
		dim_overlay_mesh_instance.mesh = dim_overlay_mesh

	dim_overlay_material = dim_overlay_mesh_instance.material_override as StandardMaterial3D
	if dim_overlay_material == null:
		dim_overlay_material = StandardMaterial3D.new()
		dim_overlay_mesh_instance.material_override = dim_overlay_material

	dim_overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dim_overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dim_overlay_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dim_overlay_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_apply_dim_overlay_opacity()


func _get_collision_shape() -> CollisionShape3D:
	if collision_shape != null:
		return collision_shape
	return get_node_or_null(^"CollisionShape3D") as CollisionShape3D


func _configure_pause_layer() -> void:
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.text = "Continue"
	continue_button.pressed.connect(_on_continue_button_pressed)
	GDGameFont.apply_to_button(continue_button)


func _update_text_content() -> void:
	if heading_text_mesh == null or body_text_mesh == null:
		return

	heading_text_mesh.text = _wrap_text(heading, heading_characters_per_line)
	body_text_mesh.text = _wrap_text(text, body_characters_per_line)
	_update_light_sweep_width()


func _show_text() -> void:
	if dismissed_until_exit or has_completed_text:
		return

	elapsed_visible = 0.0
	is_showing = true
	continue_button_has_focus = false
	continue_requested = false
	_suppress_flask_effect_text()
	heading_text_mesh_instance.visible = true
	body_text_mesh_instance.visible = true
	text_light.visible = true
	if pause_game_with_text:
		dim_overlay_mesh_instance.visible = true
		tree_was_paused = get_tree().paused
		paused_by_trigger = true
		get_tree().paused = true
		pause_layer.visible = true
	_update_continue_button()
	_update_visibility_state()


func _hide_text() -> void:
	is_showing = false
	current_opacity = 0.0
	heading_text_mesh_instance.visible = false
	body_text_mesh_instance.visible = false
	dim_overlay_mesh_instance.visible = false
	text_light.visible = false
	pause_layer.visible = false
	_apply_text_opacity()
	_release_flask_effect_text()
	if paused_by_trigger and not tree_was_paused:
		get_tree().paused = false
	paused_by_trigger = false


func _update_visibility_state() -> void:
	var fade_in := clampf(elapsed_visible / FADE_IN_DURATION, 0.0, 1.0)
	current_opacity = fade_in
	_apply_text_opacity()

	if pause_game_with_text:
		return
	if not bodies_in_trigger.is_empty():
		return
	if elapsed_visible >= minimum_time_on_screen:
		_complete_text()


func _update_transform() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var base_position := _get_camera_overlay_position(camera)
	var camera_basis := camera.global_transform.basis
	var perspective_basis := camera_basis
	perspective_basis = perspective_basis.rotated(perspective_basis.y.normalized(), deg_to_rad(perspective_yaw_degrees))
	perspective_basis = perspective_basis.rotated(perspective_basis.x.normalized(), deg_to_rad(perspective_pitch_degrees))

	heading_text_mesh_instance.global_transform = Transform3D(
		perspective_basis,
		base_position + camera_basis.y.normalized() * heading_y_offset
	)
	body_text_mesh_instance.global_transform = Transform3D(
		perspective_basis,
		base_position + camera_basis.y.normalized() * body_y_offset
	)
	_update_dim_overlay(camera)
	_update_text_light(camera, base_position)


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


func _update_dim_overlay(camera: Camera3D) -> void:
	if not pause_game_with_text or not dim_overlay_mesh_instance.visible:
		return

	var distance := maxf(camera_distance + DIM_OVERLAY_DISTANCE_PADDING, camera.near + 0.01)
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

	dim_overlay_mesh.size = Vector2(half_width * 2.0, half_height * 2.0)
	dim_overlay_mesh_instance.global_transform = Transform3D(
		camera_basis,
		camera.global_position - camera_basis.z.normalized() * distance
	)


func _update_text_light(camera: Camera3D, text_position: Vector3) -> void:
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


func _apply_text_opacity() -> void:
	var display_color := text_color
	display_color.a = text_opacity * current_opacity
	if heading_text_material != null:
		heading_text_material.set_shader_parameter("text_color", display_color)
	if body_text_material != null:
		body_text_material.set_shader_parameter("text_color", display_color)


func _apply_dim_overlay_opacity() -> void:
	if dim_overlay_material == null:
		return

	dim_overlay_material.albedo_color = Color(0.0, 0.0, 0.0, dim_opacity)


func _update_light_sweep_width() -> void:
	var heading_width := 0.0
	if heading_text_mesh != null:
		heading_width = heading_text_mesh.get_aabb().size.x
	var body_width := 0.0
	if body_text_mesh != null:
		body_width = body_text_mesh.get_aabb().size.x
	current_light_sweep_width = maxf(maxf(heading_width, body_width) + light_sweep_padding, 0.1)


func _update_continue_button() -> void:
	if continue_button == null:
		return

	if continue_button_has_focus:
		return

	continue_button.grab_focus()
	continue_button_has_focus = true


func _create_continue_focus_style() -> StyleBoxFlat:
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(1.0, 0.94, 0.78, 0.18)
	focus_style.border_color = Color(1.0, 0.94, 0.78, 0.95)
	focus_style.set_border_width_all(2)
	focus_style.set_corner_radius_all(4)
	focus_style.set_expand_margin_all(4.0)
	return focus_style


func _is_continue_input(event: InputEvent) -> bool:
	if event.is_echo():
		return false

	for action: StringName in CONTINUE_ACTIONS:
		if event.is_action_pressed(action):
			return true

	return false


func _suppress_flask_effect_text() -> void:
	if suppressing_flask_effect_text:
		return

	get_tree().call_group(FLASK_EFFECT_TEXT_GROUP, "suppress_flask_effect_text")
	suppressing_flask_effect_text = true


func _release_flask_effect_text() -> void:
	if not suppressing_flask_effect_text:
		return

	get_tree().call_group(FLASK_EFFECT_TEXT_GROUP, "release_flask_effect_text")
	suppressing_flask_effect_text = false


func _on_body_entered(body: Node3D) -> void:
	if not _is_player_body(body):
		return

	if not bodies_in_trigger.has(body):
		bodies_in_trigger.append(body)
	if not is_showing:
		_show_text()


func _detect_initial_overlaps() -> void:
	await get_tree().physics_frame
	for body in get_overlapping_bodies():
		if body is Node3D:
			_on_body_entered(body as Node3D)


func _on_body_exited(body: Node3D) -> void:
	bodies_in_trigger.erase(body)
	if bodies_in_trigger.is_empty():
		dismissed_until_exit = false


func _on_continue_button_pressed() -> void:
	_request_continue()


func _request_continue() -> void:
	if pause_game_with_text:
		_complete_text()
		return

	continue_requested = true
	_consume_pending_continue()


func _consume_pending_continue() -> void:
	if not continue_requested or elapsed_visible < minimum_time_on_screen:
		return

	continue_requested = false
	dismissed_until_exit = not bodies_in_trigger.is_empty()
	_complete_text()


func _complete_text() -> void:
	if has_completed_text:
		return

	has_completed_text = true
	dismissed_until_exit = true
	_disable_trigger_area()
	_hide_text()


func _disable_trigger_area() -> void:
	bodies_in_trigger.clear()
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0


func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	if player_group != &"" and body.is_in_group(player_group):
		return true
	return player_group == &""


func _prune_invalid_bodies() -> void:
	for body in bodies_in_trigger.duplicate():
		if not is_instance_valid(body):
			bodies_in_trigger.erase(body)


func _wrap_text(source_text: String, max_characters_per_line: int) -> String:
	var wrapped_paragraphs: Array[String] = []
	for paragraph: String in source_text.split("\n", false):
		wrapped_paragraphs.append(_wrap_paragraph(paragraph, max_characters_per_line))
	return "\n".join(wrapped_paragraphs)


func _wrap_paragraph(paragraph: String, max_characters_per_line: int) -> String:
	var words := paragraph.split(" ", false)
	if words.is_empty():
		return ""

	var lines: Array[String] = []
	var current_line := ""
	for word: String in words:
		if current_line.is_empty():
			current_line = word
			continue

		var candidate_line := "%s %s" % [current_line, word]
		if candidate_line.length() <= max_characters_per_line:
			current_line = candidate_line
		else:
			lines.append(current_line)
			current_line = word

	if not current_line.is_empty():
		lines.append(current_line)
	return "\n".join(lines)
