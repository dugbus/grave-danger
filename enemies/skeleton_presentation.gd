extends RefCounted
class_name GDSkeletonPresentation


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var animation_player := find_animation_player(child)
		if animation_player != null:
			return animation_player
	return null


static func resolve_animation_name(
	animation_player: AnimationPlayer,
	animation_name: String
) -> String:
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
	var geometry_instances: Array[GeometryInstance3D] = []
	_collect_geometry_recursive(node, geometry_instances)
	return geometry_instances


static func _collect_geometry_recursive(
	node: Node,
	geometry_instances: Array[GeometryInstance3D]
) -> void:
	if node is GeometryInstance3D:
		geometry_instances.append(node as GeometryInstance3D)
	for child in node.get_children():
		_collect_geometry_recursive(child, geometry_instances)
