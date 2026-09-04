extends RefCounted
class_name GDPlaythroughPositionMarkerBuilder

const MARKER_GROUP_SCRIPT := preload(
	"res://addons/playthrough_position_markers/editor_only_marker_group.gd"
)
const CONTAINER_NAME := "PlaythroughPositionMarkers"
const CONTAINER_METADATA: StringName = &"playthrough_position_markers"
const WALKED_PATH_NAME := "WalkedPath"
const LABEL_COLOR := Color(1.0, 0.88, 0.4, 1.0)
const LABEL_OFFSET := Vector3(0.24, 0.2, 0.24)
const LABEL_PIXEL_SIZE := 0.01
const LABEL_FONT_SIZE := 28
const LABEL_OUTLINE_SIZE := 3


## Replaces a level's previous playthrough with a grouped set of editor-only markers.
func replace_markers(scene_root: Node3D, samples: Array) -> Node3D:
	if scene_root == null:
		return null

	var previous_container := find_marker_container(scene_root)
	if previous_container != null:
		previous_container.free()

	var container := MARKER_GROUP_SCRIPT.new() as Node3D
	container.name = CONTAINER_NAME
	container.set_meta(CONTAINER_METADATA, true)
	container.editor_description = \
		"Editor-only positions sampled from the most recent debug playthrough."
	scene_root.add_child(container)
	container.owner = scene_root
	_add_route(container, scene_root, samples)

	for sample_index in samples.size():
		var sample := samples[sample_index] as Dictionary
		_add_marker(container, scene_root, sample, sample_index)
	return container


## Finds the replaceable marker group without relying only on its editable display name.
func find_marker_container(scene_root: Node3D) -> Node3D:
	if scene_root == null:
		return null
	for child in scene_root.get_children():
		if child is Node3D and (
			child.has_meta(CONTAINER_METADATA) or child.name == CONTAINER_NAME
		):
			return child as Node3D
	return null


## Returns the generated route selected for the repository's prominent Path3D overlay.
func find_walked_path(container: Node3D) -> Path3D:
	if container == null:
		return null
	return container.get_node_or_null(WALKED_PATH_NAME) as Path3D


## Formats a single arrival time or the inclusive sampled occupancy range.
func format_time_range(start_time: float, end_time: float) -> String:
	var start_text := _format_time(start_time)
	if is_equal_approx(start_time, end_time):
		return start_text
	return "%s–%s" % [start_text, _format_time(end_time)]


func _add_route(container: Node3D, scene_root: Node3D, samples: Array) -> void:
	if samples.size() < 2:
		return

	var route_curve := Curve3D.new()
	route_curve.resource_local_to_scene = true
	for sample_value in samples:
		var sample := sample_value as Dictionary
		var position := sample.get("position", Vector3.ZERO) as Vector3
		route_curve.add_point(position)

	var route := Path3D.new()
	route.name = WALKED_PATH_NAME
	route.curve = route_curve
	route.editor_description = \
		"Sampled player route; select it to show the prominent directional path overlay."
	container.add_child(route)
	route.owner = scene_root


func _add_marker(
	container: Node3D,
	scene_root: Node3D,
	sample: Dictionary,
	sample_index: int
) -> void:
	var marker_root := Node3D.new()
	marker_root.name = "Sample_%03d" % sample_index
	marker_root.position = sample.get("position", Vector3.ZERO) as Vector3
	container.add_child(marker_root)
	marker_root.owner = scene_root

	var marker := Marker3D.new()
	marker.name = "Position"
	marker.gizmo_extents = 0.35
	marker_root.add_child(marker)
	marker.owner = scene_root

	var start_time := float(sample.get("start_time", 0.0))
	var end_time := float(sample.get("end_time", start_time))
	var label := Label3D.new()
	label.name = "Time"
	label.text = format_time_range(start_time, end_time)
	label.position = LABEL_OFFSET
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = false
	label.pixel_size = LABEL_PIXEL_SIZE
	label.no_depth_test = true
	label.modulate = LABEL_COLOR
	label.outline_modulate = Color(0.08, 0.03, 0.01, 1.0)
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = LABEL_OUTLINE_SIZE
	marker_root.add_child(label)
	label.owner = scene_root


func _format_time(time_seconds: float) -> String:
	var total_seconds := maxi(roundi(maxf(time_seconds, 0.0)), 0)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%d:%02d" % [minutes, seconds]
