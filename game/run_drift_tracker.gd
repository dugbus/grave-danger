extends RefCounted
class_name GDRunDriftTracker

const SKELETON_GROUP: StringName = &"skeleton"
const SMART_ZOMBIE_GROUP: StringName = &"smart_zombie"
const PUSHABLE_GROUP: StringName = &"pushable"

var tracked_nodes: Dictionary = {}
var tracked_paths: Array[String] = []


func discover(recording_root: Node) -> void:
	tracked_nodes.clear()
	tracked_paths.clear()
	if recording_root == null:
		return

	for node in _get_descendants(recording_root):
		var tracked_node := _get_representative(node)
		if tracked_node == null:
			continue
		var relative_path := String(recording_root.get_path_to(tracked_node))
		tracked_nodes[relative_path] = tracked_node
		tracked_paths.append(relative_path)
	tracked_paths.sort()


func capture(frame_index: int, frame_time: float) -> Dictionary:
	if tracked_nodes.is_empty():
		return {}

	var states: Array[Dictionary] = []
	for stored_path in tracked_paths:
		var stored_node: Variant = tracked_nodes.get(stored_path)
		if not is_instance_valid(stored_node):
			continue
		var tracked_node := stored_node as Node3D
		if tracked_node == null:
			continue
		var position := tracked_node.global_position
		states.append({
			"path": stored_path,
			"position": [position.x, position.y, position.z],
		})
	return {
		"frame": frame_index,
		"time": frame_time,
		"states": states,
	}


func _get_representative(node: Node) -> Node3D:
	if node.is_in_group(SKELETON_GROUP):
		return node.get_node_or_null(^"PathFollow3D") as Node3D
	if node.is_in_group(SMART_ZOMBIE_GROUP):
		return node.get_node_or_null(^"ZombieBody") as Node3D
	if node.is_in_group(PUSHABLE_GROUP):
		return node as Node3D
	if node is GDKillBoundary3D:
		return node.get_node_or_null(^"BoundaryCenter") as Node3D
	return null


func _get_descendants(node: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(_get_descendants(child))
	return descendants
