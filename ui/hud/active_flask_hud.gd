extends Control
class_name GDActiveFlaskHud


const FLASK_SCENE := preload("res://Assets/environment/flask.glb")
const LIQUID_MATERIAL_NAME := "FlaskLiquidMaterial"
const SLOT_SIZE := Vector2(328.0, 408.0)
const VIEWPORT_SIZE := Vector2i(288, 288)
const SLOT_GAP := 16
const LIQUID_EMISSION_ENERGY := 1.35
const PREVIEW_CAMERA_PADDING := 1.12
const EFFECT_LABELS := {
	&"health_flask": "Healing",
	&"breathing_space": "Expand",
	&"pause_boundary": "Freeze",
	&"poison": "Poisoned",
	&"pickup_radius": "Easy Pickup",
	&"bigger_sack": "Big Sack",
	&"no_boundary": "Safety",
}

@export var top_margin := 20.0
@export var right_margin := 24.0
@export var max_width := 1500.0
@export var flask_spin_speed := 1.4

var container: HBoxContainer
var active_effects: Array[Dictionary] = []
var last_viewport_size := Vector2.ZERO


func _ready() -> void:
	add_to_group("active_flask_hud")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_container()
	_apply_layout()


func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if not viewport_size.is_equal_approx(last_viewport_size):
		_apply_layout()

	for effect in active_effects.duplicate():
		var remaining := float(effect["remaining"]) - delta
		effect["remaining"] = remaining

		var visual := effect["visual"] as Node3D
		if is_instance_valid(visual):
			visual.rotation.y += flask_spin_speed * delta

		var label := effect["label"] as Label
		if is_instance_valid(label):
			label.text = _format_time(remaining)

		if remaining <= 0.0:
			_remove_effect(effect)


func show_flask_effect(effect_id: StringName, color: Color, duration: float) -> void:
	duration = maxf(duration, 0.0)
	if duration <= 0.0:
		return

	var slot := _create_effect_slot(color, _get_effect_label(effect_id))
	container.add_child(slot["root"])
	active_effects.append({
		"remaining": duration,
		"root": slot["root"],
		"visual": slot["visual"],
		"label": slot["label"],
	})
	(slot["label"] as Label).text = _format_time(duration)


func _create_container() -> void:
	container = HBoxContainer.new()
	container.name = "ActiveFlaskContainer"
	container.alignment = BoxContainer.ALIGNMENT_END
	container.add_theme_constant_override("separation", SLOT_GAP)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)


func _apply_layout() -> void:
	var viewport_size := get_viewport_rect().size
	last_viewport_size = viewport_size

	var width := minf(max_width, maxf(SLOT_SIZE.x, viewport_size.x - right_margin * 2.0))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	if container == null:
		return

	container.anchor_left = 1.0
	container.anchor_top = 0.0
	container.anchor_right = 1.0
	container.anchor_bottom = 0.0
	container.offset_left = -width - right_margin
	container.offset_top = top_margin
	container.offset_right = -right_margin
	container.offset_bottom = top_margin + SLOT_SIZE.y


func _create_effect_slot(color: Color, effect_label: String) -> Dictionary:
	var root := VBoxContainer.new()
	root.custom_minimum_size = SLOT_SIZE
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 0)

	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(VIEWPORT_SIZE)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.size = VIEWPORT_SIZE
	viewport.transparent_bg = true
	viewport.world_3d = World3D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	var world := Node3D.new()
	world.name = "FlaskPreviewWorld"
	viewport.add_child(world)

	var visual := Node3D.new()
	visual.name = "FlaskPreviewVisual"
	world.add_child(visual)

	var flask_model := FLASK_SCENE.instantiate() as Node3D
	visual.add_child(flask_model)
	_apply_liquid_color(flask_model, color)

	var light := DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.light_energy = 2.6
	light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	world.add_child(light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "PreviewFillLight"
	fill_light.light_energy = 1.0
	fill_light.omni_range = 4.0
	fill_light.position = Vector3(-1.5, 1.2, 2.0)
	world.add_child(fill_light)

	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	_frame_camera_to_model(camera, flask_model)
	camera.current = true
	world.add_child(camera)

	var name_label := Label.new()
	name_label.name = "EffectName"
	name_label.text = effect_label
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(SLOT_SIZE.x, 48.0)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GDGameFont.apply_to_label(name_label)
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	name_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(name_label)

	var label := Label.new()
	label.name = "Countdown"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(SLOT_SIZE.x, 54.0)
	GDGameFont.apply_to_label(label)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(label)

	return {
		"root": root,
		"visual": visual,
		"label": label,
	}


func _remove_effect(effect: Dictionary) -> void:
	active_effects.erase(effect)

	var root := effect["root"] as Node
	if is_instance_valid(root):
		root.queue_free()


func _format_time(seconds: float) -> String:
	return "%.1fs" % maxf(seconds, 0.0)


func _get_effect_label(effect_id: StringName) -> String:
	if EFFECT_LABELS.has(effect_id):
		return EFFECT_LABELS[effect_id]

	return String(effect_id).capitalize()


func _frame_camera_to_model(camera: Camera3D, model: Node3D) -> void:
	var bounds := _get_node_mesh_bounds(model)
	if bounds.size.is_zero_approx():
		camera.look_at_from_position(Vector3(0.0, 0.5, 1.5), Vector3(0.0, 0.5, 0.0), Vector3.UP)
		return

	var center := bounds.get_center()
	var aspect := float(VIEWPORT_SIZE.x) / float(VIEWPORT_SIZE.y)
	var vertical_size := maxf(bounds.size.y, bounds.size.x / maxf(aspect, 0.001)) * PREVIEW_CAMERA_PADDING
	var camera_distance := maxf(bounds.size.z * 2.0, 1.0)

	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(vertical_size, 0.01)
	camera.near = 0.01
	camera.far = camera_distance + bounds.size.z * 4.0
	camera.look_at_from_position(center + Vector3(0.0, 0.0, camera_distance), center, Vector3.UP)


func _get_node_mesh_bounds(root: Node3D) -> AABB:
	var state := {
		"has_bounds": false,
		"bounds": AABB(),
	}
	_collect_mesh_bounds(root, Transform3D.IDENTITY, state)
	return state["bounds"] as AABB


func _collect_mesh_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var node_transform := parent_transform
	if node is Node3D:
		node_transform = parent_transform * (node as Node3D).transform

	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var mesh_bounds := _transform_aabb(mesh_instance.mesh.get_aabb(), node_transform)
			if bool(state["has_bounds"]):
				state["bounds"] = (state["bounds"] as AABB).merge(mesh_bounds)
			else:
				state["bounds"] = mesh_bounds
				state["has_bounds"] = true

	for child in node.get_children():
		_collect_mesh_bounds(child, node_transform, state)


func _transform_aabb(bounds: AABB, transform: Transform3D) -> AABB:
	var min_point := transform * bounds.position
	var max_point := min_point
	for x in 2:
		for y in 2:
			for z in 2:
				var corner := bounds.position + Vector3(bounds.size.x * x, bounds.size.y * y, bounds.size.z * z)
				var transformed_corner := transform * corner
				min_point = min_point.min(transformed_corner)
				max_point = max_point.max(transformed_corner)

	return AABB(min_point, max_point - min_point)


func _apply_liquid_color(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		_apply_liquid_color_to_mesh(node as MeshInstance3D, color)

	for child in node.get_children():
		_apply_liquid_color(child, color)


func _apply_liquid_color_to_mesh(mesh_instance: MeshInstance3D, color: Color) -> void:
	if mesh_instance.mesh == null:
		return

	for surface_index in mesh_instance.mesh.get_surface_count():
		var surface_material := mesh_instance.get_active_material(surface_index)
		if surface_material == null or surface_material.resource_name != LIQUID_MATERIAL_NAME:
			continue

		var color_material := surface_material.duplicate() as Material
		if color_material is BaseMaterial3D:
			var base_material := color_material as BaseMaterial3D
			base_material.albedo_color = color
			base_material.emission_enabled = true
			base_material.emission = color
			base_material.emission_energy_multiplier = LIQUID_EMISSION_ENERGY
		mesh_instance.set_surface_override_material(surface_index, color_material)
