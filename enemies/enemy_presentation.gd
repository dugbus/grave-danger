extends RefCounted
class_name GDEnemyPresentation

## Shared visual operations; movement, animation selection, and spawn timing remain with each enemy.


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var animation_player := find_animation_player(child)
		if animation_player != null:
			return animation_player
	return null


static func resolve_animation_name(animation_player: AnimationPlayer, animation_name: String) -> String:
	if animation_player == null or animation_name.is_empty():
		return ""
	if animation_player.has_animation(animation_name):
		return animation_name
	var requested := animation_name.to_lower()
	for imported_animation_name in animation_player.get_animation_list():
		var imported := String(imported_animation_name)
		var normalized := imported.to_lower()
		if normalized == requested or normalized.ends_with("/" + requested):
			return imported
	return ""


static func collect_geometry(node: Node) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	_collect_geometry_recursive(node, result)
	return result


static func collect_fade_geometry(drop_pivot: Node3D, shadow: Node3D) -> Array[GeometryInstance3D]:
	var result: Array[GeometryInstance3D] = []
	if drop_pivot != null:
		_collect_geometry_recursive(drop_pivot, result)
	if shadow != null:
		_collect_geometry_recursive(shadow, result)
	return result


static func set_geometry_transparency(node: Node, transparency: float) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).transparency = transparency
	for child in node.get_children():
		set_geometry_transparency(child, transparency)


static func set_shadow_casting(node: Node, visual_layer: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = visual_layer
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		set_shadow_casting(child, visual_layer)


static func configure_light(
	light: OmniLight3D,
	color: Color,
	energy: float,
	light_range: float,
	attenuation: float,
	enabled: bool,
	visual_layers: int,
	shadow_caster_mask: int
) -> void:
	if light == null:
		return
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = attenuation
	light.light_cull_mask = visual_layers
	light.shadow_caster_mask = shadow_caster_mask
	light.shadow_enabled = true
	light.visible = enabled


static func _collect_geometry_recursive(node: Node, result: Array[GeometryInstance3D]) -> void:
	if node is GeometryInstance3D:
		result.append(node as GeometryInstance3D)
	for child in node.get_children():
		_collect_geometry_recursive(child, result)
