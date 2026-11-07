extends Node

## A scene pass clips concealed items, then a spatially masked aged-colour print grades surfaces and background.
const OVERLAY_ORDER := preload("res://ui/hud/overlay_render_order.gd")
const REGION := preload("res://placeables/kill_boundary/sepia/sepia_boundary_mode.gd")
const MATERIALS := preload("res://placeables/kill_boundary/sepia/sepia_materials.gd")
const SETTINGS := preload("res://placeables/kill_boundary/sepia/sepia_boundary_settings.tres")
const COMPOSITE_PATH := "res://placeables/kill_boundary/sepia/sepia_composite.gdshader"
const COMPOSITE_LAYER := 1 << 16

@onready var composite := $Composite as MeshInstance3D
@onready var veil := $TimeVeil as MeshInstance3D
@onready var contacts := $Contacts

var source_camera: Camera3D
var adapters := MATERIALS.new()
var _source_mask := 0
var _composite_material: ShaderMaterial
var _registered: Dictionary[int, bool] = {}
var _active := false
var _last_points := PackedVector2Array()
var _last_counts := Vector4i.ZERO
var _last_inversions := Vector4i.ZERO
var _last_plane_heights := Vector4.ZERO
var _height_player: Node3D
var _last_region_count := -1
var _last_signature := 0
var _lights: Dictionary[Light3D, float] = {}


func _ready() -> void:
	process_priority = 200
	if Engine.is_editor_hint():
		set_process(false)
		return
	get_tree().node_added.connect(_on_node_added)
	_start.call_deferred()


func _start() -> void:
	if _active:
		return
	var region := get_parent() as REGION
	var world := region.get_world_3d()
	if not world.has_meta(REGION.REGISTRY_META):
		return
	var registry := world.get_meta(REGION.REGISTRY_META) as Array[Node3D]
	if registry.front() != region:
		return
	_active = true
	contacts.set_physics_process(true)
	veil.set_active(true)
	_register_subtree(region.get_registration_root(), false)
	if DisplayServer.get_name() == "headless":
		return
	_composite_material = ShaderMaterial.new()
	_composite_material.shader = load(COMPOSITE_PATH) as Shader
	_composite_material.render_priority = OVERLAY_ORDER.DrawPass.WorldTreatment
	_composite_material.set_shader_parameter(&"sepia_tint", SETTINGS.sepia_tint)
	_composite_material.set_shader_parameter(&"sepia_shadow_tint", SETTINGS.sepia_shadow_tint)
	_composite_material.set_shader_parameter(&"sepia_exposure", SETTINGS.sepia_exposure)
	_composite_material.set_shader_parameter(&"colour_retention", SETTINGS.colour_retention)
	_composite_material.set_shader_parameter(&"photo_strength", SETTINGS.photo_strength)
	_composite_material.set_shader_parameter(&"film_grain_strength", SETTINGS.film_grain_strength)
	_composite_material.set_shader_parameter(&"film_vignette_strength", SETTINGS.film_vignette_strength)
	composite.material_override = _composite_material
	composite.visible = true


func _process(_delta: float) -> void:
	if not _active:
		_start()
		return
	_update_regions()
	_update_player_height()
	_update_lights()
	if _composite_material == null:
		return
	var active_camera := (get_parent() as Node3D).get_viewport().get_camera_3d()
	if active_camera == null:
		composite.visible = false
		return
	composite.visible = true
	if source_camera != active_camera:
		_restore_camera()
		source_camera = active_camera
		_source_mask = source_camera.cull_mask
		source_camera.cull_mask = _source_mask | COMPOSITE_LAYER
	composite.global_transform = source_camera.global_transform


func _update_regions() -> void:
	var world := (get_parent() as Node3D).get_world_3d()
	if not world.has_meta(REGION.REGISTRY_META):
		return
	var registry := world.get_meta(REGION.REGISTRY_META) as Array[Node3D]
	var signature := registry.size()
	for node in registry:
		var region := node as REGION
		signature = signature * 31 + hash(region.get_world_perimeter())
		signature = signature * 31 + int(region.enabled)
		signature = signature * 31 + int(region.inverted)
	if signature == _last_signature and _last_region_count >= 0:
		return
	_last_signature = signature
	var points := PackedVector2Array()
	var perimeters: Array[PackedVector3Array] = []
	var counts := Vector4i.ZERO
	var inversions := Vector4i.ZERO
	var plane_heights := Vector4.ZERO
	var background_bounds := PackedVector4Array()
	background_bounds.resize(REGION.MAX_REGIONS)
	var count := 0
	for node in registry:
		var region := node as REGION
		if not region.enabled:
			continue
		var polygon := region.get_world_polygon()
		if polygon.size() < 3:
			continue
		var perimeter := region.get_world_perimeter()
		perimeters.append(perimeter)
		var height := 0.0
		var bounds := Rect2(polygon[0], Vector2.ZERO)
		for index in perimeter.size():
			height += perimeter[index].y
			bounds = bounds.expand(polygon[index])
		plane_heights[count] = height / float(perimeter.size())
		background_bounds[count] = Vector4(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y)
		counts[count] = polygon.size()
		inversions[count] = int(region.inverted)
		points.append_array(polygon)
		count += 1
	veil.set_perimeters(perimeters)
	points.resize(REGION.MAX_REGIONS * REGION.POINTS_PER_REGION)
	if (
		points == _last_points
		and counts == _last_counts
		and inversions == _last_inversions
		and plane_heights == _last_plane_heights
		and count == _last_region_count
	):
		return
	_last_points = points
	_last_counts = counts
	_last_inversions = inversions
	_last_plane_heights = plane_heights
	_last_region_count = count
	adapters.set_regions(points, counts, count, SETTINGS.edge_feather, inversions)
	if _composite_material != null:
		_composite_material.set_shader_parameter(&"sepia_points", points)
		_composite_material.set_shader_parameter(&"sepia_counts", counts)
		_composite_material.set_shader_parameter(&"sepia_inversions", inversions)
		_composite_material.set_shader_parameter(&"sepia_plane_heights", plane_heights)
		_composite_material.set_shader_parameter(&"sepia_background_bounds", background_bounds)
		_composite_material.set_shader_parameter(&"sepia_region_count", count)
		_composite_material.set_shader_parameter(&"sepia_feather", SETTINGS.edge_feather)


func _update_player_height() -> void:
	if not is_instance_valid(_height_player) or not _height_player.is_inside_tree():
		_height_player = null
		for player in contacts.players:
			if is_instance_valid(player) and player.is_inside_tree():
				_height_player = player
				break
	if _height_player == null:
		veil.clear_player_height()
	else:
		veil.set_player_height(_height_player.global_position.y)


func _on_node_added(node: Node) -> void:
	if _active:
		_register_added_node.call_deferred(weakref(node))


func _register_added_node(reference: WeakRef) -> void:
	var node := reference.get_ref() as Node
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var region := get_parent() as REGION
	if not region.get_registration_root().is_ancestor_of(node):
		return
	if node is Node3D and (node as Node3D).get_world_3d() != region.get_world_3d():
		return
	var ancestor := node
	var hidden := false
	while ancestor != null:
		if ancestor is REGION:
			return
		hidden = hidden or _is_participant(ancestor)
		ancestor = ancestor.get_parent()
	_register_subtree(node, hidden)
	# Deferred spawns can arrive after this frame's process callback; arm their mask now.
	if _last_region_count >= 0:
		adapters.set_regions(_last_points, _last_counts, _last_region_count, SETTINGS.edge_feather, _last_inversions)
	else:
		_update_regions()


func _register_subtree(node: Node, hidden: bool) -> void:
	if node is REGION:
		return
	# A trigger or flask message can be parented under an enemy. Its screen-space geometry and
	# dedicated light remain HUD content rather than inheriting that ancestor's concealment.
	if node is GeometryInstance3D and (node as GeometryInstance3D).layers == OVERLAY_ORDER.SCREEN_TEXT_VISUAL_LAYER:
		return
	if node is Light3D and (node as Light3D).light_cull_mask == OVERLAY_ORDER.SCREEN_TEXT_VISUAL_LAYER:
		return
	hidden = hidden or _is_participant(node)
	if node is PhysicsBody3D and node.is_in_group(&"player"):
		var player := node as PhysicsBody3D
		if player not in contacts.players:
			contacts.register_player(player)
			for child in player.get_children():
				if child is CollisionShape3D and (child as CollisionShape3D).shape is CapsuleShape3D:
					player.set_meta(REGION.CONTACT_SHAPE_META, child)
					break
	if hidden and not _registered.has(node.get_instance_id()):
		_registered[node.get_instance_id()] = true
		if node is Light3D:
			var light := node as Light3D
			_lights[light] = light.light_energy
		if node is GeometryInstance3D:
			adapters.bind_geometry(node as GeometryInstance3D)
		if node is PhysicsBody3D:
			contacts.register_body(node as PhysicsBody3D)
	for child in node.get_children():
		_register_subtree(child, hidden)


func _is_participant(node: Node) -> bool:
	return (
		node.is_in_group(&"enemy")
		or node.is_in_group(&"inventory_pickup")
		or node.is_in_group(&"flask_pickup")
		or node.is_in_group(&"kill_boundary")
		or node is GDSpikeTrap
		or node is GDBatNest
	)


func _update_lights() -> void:
	for light in _lights:
		if not is_instance_valid(light):
			continue
		if light.light_energy > 0.0:
			_lights[light] = light.light_energy
		light.light_energy = 0.0 if REGION.is_sepia(light, light.global_position) else _lights[light]


func _restore_camera() -> void:
	if is_instance_valid(source_camera):
		source_camera.cull_mask = _source_mask
	source_camera = null


func _exit_tree() -> void:
	deactivate()


func deactivate() -> void:
	_active = false
	_height_player = null
	if is_instance_valid(veil):
		veil.set_active(false)
		veil.clear_player_height()
	_restore_camera()
	adapters.restore()
	for light in _lights:
		if is_instance_valid(light):
			light.light_energy = _lights[light]
	_lights.clear()
	_registered.clear()
	_last_region_count = -1
	if is_instance_valid(composite):
		composite.visible = false
		composite.material_override = null
	_composite_material = null
	if is_instance_valid(contacts):
		contacts.reset()
