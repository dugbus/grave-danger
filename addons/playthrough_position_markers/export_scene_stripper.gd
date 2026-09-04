extends RefCounted
class_name GDPlaythroughPositionExportSceneStripper

const CONTAINER_METADATA: StringName = &"playthrough_position_markers"


## Removes generated authoring markers from the scene copy prepared for export.
func strip_marker_groups(scene_root: Node) -> bool:
	if scene_root == null:
		return false
	return _strip_marker_children(scene_root)


func _strip_marker_children(parent: Node) -> bool:
	var removed_marker_group := false
	for child_value in parent.get_children():
		var child := child_value as Node
		if child.has_meta(CONTAINER_METADATA):
			parent.remove_child(child)
			child.free()
			removed_marker_group = true
		elif _strip_marker_children(child):
			removed_marker_group = true
	return removed_marker_group
