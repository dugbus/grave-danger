extends CanvasLayer
class_name GDElapsedTimeHud


## Node that provides the elapsed time value through get_elapsed_time().
@export var time_source_path: NodePath
## Existing label to update. If missing, a fallback label is created.
@export var elapsed_label_path: NodePath = ^"ElapsedLabel"
## Screen position of the top-left corner of the elapsed time label.
@export var label_position := Vector2(16.0, 128.0)
## Font size used for the elapsed time label.
@export var font_size := 48

var time_source: Node
var elapsed_label: Label
var elapsed_seconds := 0.0


func _ready() -> void:
	layer = 40
	_bind_label()
	_resolve_time_source()
	_update_label()


func _process(delta: float) -> void:
	elapsed_seconds += delta

	if elapsed_label == null:
		_bind_label()
	if not is_instance_valid(time_source):
		_resolve_time_source()

	_update_label()


func set_runtime_references(time_source_node: Node) -> void:
	time_source = time_source_node
	_update_label()


func _bind_label() -> void:
	elapsed_label = get_node_or_null(elapsed_label_path) as Label
	if elapsed_label != null:
		GDGameFont.apply_to_label(elapsed_label)
		return

	elapsed_label = _create_fallback_label()
	add_child(elapsed_label)


func _create_fallback_label() -> Label:
	var label := Label.new()
	label.name = "ElapsedLabel"
	label.position = label_position
	GDGameFont.apply_to_label(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _resolve_time_source() -> void:
	if time_source_path.is_empty():
		return

	time_source = get_node_or_null(time_source_path)


func _update_label() -> void:
	if elapsed_label == null:
		return

	elapsed_label.visible = true
	elapsed_label.text = "Elapsed %s" % _format_elapsed_seconds(elapsed_seconds)
	if _is_boundary_animation_active():
		elapsed_label.text += "\nBoundary %s / %s" % [
			_format_elapsed_seconds(float(time_source.get_boundary_animation_position())),
			_format_elapsed_seconds(float(time_source.get_boundary_animation_duration())),
		]


func _is_boundary_animation_active() -> bool:
	if time_source == null:
		return false
	if not time_source.has_method("get_boundary_animation_position") or not time_source.has_method("get_boundary_animation_duration"):
		return false
	var visible_value: Variant = time_source.get("visible")
	if visible_value is bool and not visible_value:
		return false
	if time_source.has_method("get_bounds_size"):
		var bounds_size: Variant = time_source.get_bounds_size()
		if bounds_size is Vector2 and (bounds_size as Vector2).is_zero_approx():
			return false

	return float(time_source.get_boundary_animation_duration()) > 0.0


func _format_elapsed_seconds(seconds: float) -> String:
	var clamped_seconds := maxf(seconds, 0.0)
	var minutes := int(floorf(clamped_seconds / 60.0))
	var remaining_seconds := clamped_seconds - float(minutes * 60)
	if minutes <= 0:
		return "%.1fs" % remaining_seconds

	return "%d:%04.1f" % [minutes, remaining_seconds]
