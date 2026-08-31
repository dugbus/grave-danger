@tool
extends EditorPlugin

## Mandatory registration shim for Kill Boundary 2's colocated editor implementation.

const BottomPanel := preload(
	"res://placeables/kill-boundary-2/editor/kill_boundary_2_bottom_panel.gd"
)
const GizmoPlugin := preload(
	"res://placeables/kill-boundary-2/editor/kill_boundary_2_gizmo_plugin.gd"
)
const EditorOverlay := preload(
	"res://placeables/kill-boundary-2/editor/kill_boundary_2_editor_overlay.gd"
)

var _bottom_panel: GDKillBoundary2BottomPanel
var _bottom_panel_button: Button
var _gizmo_plugin: GDKillBoundary2GizmoPlugin
var _editor_overlay: GDKillBoundary2EditorOverlay
var _selected_boundary: GDKillBoundary2


func _enter_tree() -> void:
	_bottom_panel = BottomPanel.new() as GDKillBoundary2BottomPanel
	_bottom_panel.configure_editor_interface(get_editor_interface())
	_bottom_panel_button = add_control_to_bottom_panel(_bottom_panel, "Kill Boundary 2")
	_bottom_panel.visible = false
	_bottom_panel_button.visible = false
	_gizmo_plugin = GizmoPlugin.new(get_editor_interface()) as GDKillBoundary2GizmoPlugin
	_gizmo_plugin.configure_undo_redo(get_undo_redo())
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	_editor_overlay = EditorOverlay.new() as GDKillBoundary2EditorOverlay
	add_child(_editor_overlay)
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


func _exit_tree() -> void:
	var selection := get_editor_interface().get_selection()
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)
	_set_selected_boundary(null)
	if _editor_overlay != null:
		_editor_overlay.queue_free()
		_editor_overlay = null
	if _gizmo_plugin != null:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
	if _bottom_panel != null:
		remove_control_from_bottom_panel(_bottom_panel)
		_bottom_panel.queue_free()
		_bottom_panel = null
	_bottom_panel_button = null


func _on_selection_changed() -> void:
	var selected: GDKillBoundary2
	for node in get_editor_interface().get_selection().get_selected_nodes():
		selected = _resolve_selected_boundary(node)
		if selected != null:
			break
	_set_selected_boundary(selected)


## Resolves implementation children and pose descendants to the boundary they author.
static func _resolve_selected_boundary(node: Node) -> GDKillBoundary2:
	var ancestor := node
	var selected_pose: GDKillBoundary2Pose
	while ancestor != null:
		if selected_pose == null and ancestor is GDKillBoundary2Pose:
			selected_pose = ancestor as GDKillBoundary2Pose
		if ancestor is GDKillBoundary2:
			var owning_boundary := ancestor as GDKillBoundary2
			if selected_pose != null:
				var pose_index := owning_boundary.sequence.get_pose_index(selected_pose)
				if pose_index >= 0:
					owning_boundary.set_editor_active_pose(pose_index)
			return owning_boundary
		ancestor = ancestor.get_parent()
	return null


func _set_selected_boundary(boundary: GDKillBoundary2) -> void:
	var previous := _selected_boundary
	_selected_boundary = boundary
	if _bottom_panel != null:
		_bottom_panel.bind_boundary(boundary, get_undo_redo())
		_bottom_panel.visible = boundary != null
	if _bottom_panel_button != null:
		_bottom_panel_button.visible = boundary != null
	if _gizmo_plugin != null:
		_gizmo_plugin.bind_boundary(boundary)
	if _editor_overlay != null:
		_editor_overlay.bind_boundary(boundary)
	if previous != null and is_instance_valid(previous) and previous.sequence != null:
		for pose in previous.sequence.get_poses():
			pose.update_gizmos()
	if boundary != null and boundary.sequence != null:
		for pose in boundary.sequence.get_poses():
			pose.update_gizmos()
