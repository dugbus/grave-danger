class_name GDGeneratedMazeLayoutBuilder
extends RefCounted

## Replaces GeneratedMaze's complete scene-authored Layout container.

const LAYOUT_SCENE_PATH := "res://levels/vampire-maze/generated_maze/generated_maze_layout.tscn"
const LAYOUT_PATH := ^"Layout"


static func replace(host: Node3D) -> Node3D:
	var previous_layout := host.get_node_or_null(LAYOUT_PATH) as Node3D
	if previous_layout != null:
		_clear_editor_owners(previous_layout)
		host.remove_child(previous_layout)
		previous_layout.free()

	var layout_scene := load(LAYOUT_SCENE_PATH) as PackedScene
	if layout_scene == null:
		return null
	var layout := layout_scene.instantiate() as Node3D
	if layout == null:
		return null
	host.add_child(layout)
	_make_layout_inspectable(host, layout)
	return layout


static func _make_layout_inspectable(host: Node3D, layout: Node3D) -> void:
	if not Engine.is_editor_hint() or not host.is_inside_tree():
		return
	var edited_scene_root := host.get_tree().edited_scene_root
	if edited_scene_root == null \
			or (edited_scene_root != layout and not edited_scene_root.is_ancestor_of(layout)):
		return
	layout.owner = edited_scene_root
	if not layout.scene_file_path.is_empty():
		edited_scene_root.set_editable_instance(layout, true)


static func _clear_editor_owners(node: Node) -> void:
	for child in node.get_children():
		_clear_editor_owners(child)
	if node.owner != null:
		node.owner = null
