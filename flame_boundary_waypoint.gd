@tool
extends Marker3D
class_name FlameBoundaryWaypoint


enum EasingMode {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
}

const PREVIEW_CONTAINER_NAME := "EditorPreview"
const PREVIEW_LINE_THICKNESS := 0.08
const PREVIEW_VERTICAL_THICKNESS := 0.04

var editor_preview_snapshot := ""

@export_range(0.1, 200.0, 0.1) var width := 5.0:
	set(value):
		width = maxf(value, 0.1)
		_refresh_preview_when_editing()

@export_range(0.1, 200.0, 0.1) var height := 5.0:
	set(value):
		height = maxf(value, 0.1)
		_refresh_preview_when_editing()

# Seconds used to reach this waypoint from the previous waypoint. When the
# controller loops, the first waypoint's time is used for the final return leg.
@export_range(0.0, 300.0, 0.05) var time := 0.0

@export_enum("Linear", "Ease In", "Ease Out", "Ease In Out") var easing: int = EasingMode.LINEAR

@export var lock_to_ground := true:
	set(value):
		lock_to_ground = value
		_snap_to_ground_when_needed()

@export var ground_y := 0.0:
	set(value):
		ground_y = value
		_snap_to_ground_when_needed()

@export var preview_color := Color(1.0, 0.22, 0.05, 0.55):
	set(value):
		preview_color = value
		_refresh_preview_when_editing()


func _ready() -> void:
	set_notify_local_transform(true)
	_snap_to_ground_when_needed()

	if Engine.is_editor_hint():
		_refresh_editor_preview()
		set_process(true)
	else:
		_clear_editor_preview()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	var snapshot := _get_editor_preview_snapshot()
	if snapshot == editor_preview_snapshot:
		return

	_refresh_editor_preview(snapshot)


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_snap_to_ground_when_needed()


func get_flame_boundary_origin() -> Vector2:
	return Vector2(position.x, position.z)


func get_flame_boundary_size() -> Vector2:
	return Vector2(width, height)


func ease_value(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)

	match easing:
		EasingMode.EASE_IN:
			return t * t
		EasingMode.EASE_OUT:
			return 1.0 - ((1.0 - t) * (1.0 - t))
		EasingMode.EASE_IN_OUT:
			return smoothstep(0.0, 1.0, t)
		_:
			return t


func _refresh_preview_when_editing() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	call_deferred("_refresh_editor_preview")


func _snap_to_ground_when_needed() -> void:
	if not lock_to_ground:
		return

	if is_equal_approx(position.y, ground_y):
		return

	var grounded_position := position
	grounded_position.y = ground_y
	position = grounded_position


func _refresh_editor_preview(snapshot := "") -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return

	editor_preview_snapshot = snapshot if not snapshot.is_empty() else _get_editor_preview_snapshot()

	var preview_container := _get_or_create_preview_container()
	for child in preview_container.get_children(true):
		preview_container.remove_child(child)
		child.free()

	var material := _create_preview_material()
	var half_width := width * 0.5
	var half_height := height * 0.5

	if _is_selected_in_editor():
		_add_preview_strip(
			preview_container,
			"North",
			Vector3(0.0, PREVIEW_VERTICAL_THICKNESS * 0.5, -half_height),
			Vector3(width, PREVIEW_VERTICAL_THICKNESS, PREVIEW_LINE_THICKNESS),
			material
		)
		_add_preview_strip(
			preview_container,
			"South",
			Vector3(0.0, PREVIEW_VERTICAL_THICKNESS * 0.5, half_height),
			Vector3(width, PREVIEW_VERTICAL_THICKNESS, PREVIEW_LINE_THICKNESS),
			material
		)
		_add_preview_strip(
			preview_container,
			"West",
			Vector3(-half_width, PREVIEW_VERTICAL_THICKNESS * 0.5, 0.0),
			Vector3(PREVIEW_LINE_THICKNESS, PREVIEW_VERTICAL_THICKNESS, height),
			material
		)
		_add_preview_strip(
			preview_container,
			"East",
			Vector3(half_width, PREVIEW_VERTICAL_THICKNESS * 0.5, 0.0),
			Vector3(PREVIEW_LINE_THICKNESS, PREVIEW_VERTICAL_THICKNESS, height),
			material
		)

	var origin_marker := MeshInstance3D.new()
	origin_marker.name = "Origin"
	var origin_mesh := SphereMesh.new()
	origin_mesh.radius = 0.16
	origin_mesh.height = 0.32
	origin_marker.mesh = origin_mesh
	origin_marker.material_override = material
	origin_marker.position.y = 0.18
	preview_container.add_child(origin_marker, false, Node.INTERNAL_MODE_BACK)
	_lock_preview_node(origin_marker)
	origin_marker.owner = null

	var order_label := Label3D.new()
	order_label.name = "OrderLabel"
	order_label.text = str(_get_waypoint_order())
	order_label.font_size = 96
	order_label.pixel_size = 0.012
	order_label.position = Vector3(0.0, 0.58, 0.0)
	order_label.modulate = Color(1.0, 0.92, 0.2, 1.0)
	order_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	order_label.outline_size = 10
	order_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	preview_container.add_child(order_label, false, Node.INTERNAL_MODE_BACK)
	_lock_preview_node(order_label)
	order_label.owner = null


func _get_editor_preview_snapshot() -> String:
	return "%s|%s|%.3f|%.3f|%s" % [_is_selected_in_editor(), _get_waypoint_order(), width, height, preview_color]


func _is_selected_in_editor() -> bool:
	if not Engine.is_editor_hint():
		return false

	var selection := EditorInterface.get_selection()
	if selection == null:
		return false

	var selected_nodes: Array = selection.get_selected_nodes()
	return selected_nodes.has(self)


func _get_waypoint_order() -> int:
	var parent_node := get_parent()
	if parent_node == null:
		return 1

	var order := 1
	for sibling in parent_node.get_children():
		if sibling == self:
			return order

		if sibling.has_method("get_flame_boundary_origin") and sibling.has_method("get_flame_boundary_size"):
			order += 1

	return order


func _add_preview_strip(parent: Node3D, strip_name: String, strip_position: Vector3, strip_size: Vector3, material: Material) -> void:
	var strip := MeshInstance3D.new()
	strip.name = strip_name
	var mesh := BoxMesh.new()
	mesh.size = strip_size
	strip.mesh = mesh
	strip.material_override = material
	strip.position = strip_position
	parent.add_child(strip, false, Node.INTERNAL_MODE_BACK)
	_lock_preview_node(strip)
	strip.owner = null


func _get_or_create_preview_container() -> Node3D:
	var existing := get_node_or_null(PREVIEW_CONTAINER_NAME) as Node3D
	if existing != null:
		return existing

	var preview_container := Node3D.new()
	preview_container.name = PREVIEW_CONTAINER_NAME
	add_child(preview_container, false, Node.INTERNAL_MODE_BACK)
	_lock_preview_node(preview_container)
	preview_container.owner = null
	return preview_container


func _lock_preview_node(node: Node) -> void:
	node.set_meta("_edit_lock_", true)


func _clear_editor_preview() -> void:
	var preview_container := get_node_or_null(PREVIEW_CONTAINER_NAME)
	if preview_container == null:
		return

	remove_child(preview_container)
	preview_container.queue_free()


func _create_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = preview_color
	material.emission_enabled = true
	material.emission = Color(preview_color.r, preview_color.g, preview_color.b)
	material.emission_energy_multiplier = 0.8
	return material
