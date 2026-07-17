extends Control
class_name GDResultScreen


const TITLE_SCENE := "res://ui/screens/title_screen.tscn"
const SCREEN_FADE := preload("res://ui/screens/screen_fade.gd")
const VALUE_LAYER_NAME := "ValueLayer"
const VALUE_LAYER_INDEX := 20
const FADE_LAYER_NAME := "ResultFadeLayer"
const FADE_LAYER_INDEX := 100

## Background image displayed behind the final result values.
@export var result_texture: Texture2D
## Seconds used by both fade-in and return-to-title fade transitions.
@export var fade_duration := 0.8
## Fallback rectangle, in source image pixels, used only if the scene has no TreasureValue label.
@export var treasure_rect := Rect2(581.0, 522.0, 382.0, 90.0)
## Fallback rectangle, in source image pixels, used only if the scene has no PercentageValue label.
@export var percentage_rect := Rect2(581.0, 609.0, 382.0, 90.0)
## Color used for result value text.
@export var text_color := Color(0.96, 0.89, 0.63)
## Color used for result value text shadow.
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.9)
## Padding kept inside editable value boxes when fitting dynamic text.
@export var value_padding := Vector2(16.0, 10.0)

var returning_to_title := false
var result_image: TextureRect
var value_layer: CanvasLayer
var treasure_label: Label
var percentage_label: Label
var value_overlay: ResultValueOverlay
var authored_treasure_rect := Rect2()
var authored_percentage_rect := Rect2()
var has_authored_treasure_rect := false
var has_authored_percentage_rect := false
var authored_screen_size := Vector2(1920.0, 1080.0)


func _ready() -> void:
	authored_screen_size = _get_current_screen_size()
	_prepare_screen_root()
	_bind_result_image()
	_bind_value_layer()
	_bind_labels()
	_bind_value_overlay()
	_record_level_result()
	_update_result_text()
	_layout_value_labels()
	call_deferred("_layout_value_labels")
	_fade_in()
	set_process_unhandled_input(true)
	resized.connect(_layout_value_labels)
	get_viewport().size_changed.connect(_sync_screen_layout)


func _unhandled_input(event: InputEvent) -> void:
	if returning_to_title:
		return

	if _is_primary_event(event):
		get_viewport().set_input_as_handled()
		_return_to_title()


func _prepare_screen_root() -> void:
	var project_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	var viewport_size := get_viewport_rect().size

	position = Vector2.ZERO
	size = Vector2(maxf(viewport_size.x, project_size.x), maxf(viewport_size.y, project_size.y))
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _bind_result_image() -> void:
	result_image = get_node_or_null("ResultImage") as TextureRect
	if result_image == null:
		result_image = TextureRect.new()
		result_image.name = "ResultImage"
		add_child(result_image)
	else:
		move_child(result_image, 0)

	if result_texture != null:
		result_image.texture = result_texture
	result_image.z_index = -10
	result_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bind_value_layer() -> void:
	value_layer = get_node_or_null(VALUE_LAYER_NAME) as CanvasLayer
	if value_layer == null:
		value_layer = CanvasLayer.new()
		value_layer.name = VALUE_LAYER_NAME
		add_child(value_layer)

	value_layer.layer = VALUE_LAYER_INDEX


func _bind_labels() -> void:
	treasure_label = value_layer.get_node_or_null("TreasureValue") as Label
	if treasure_label == null:
		treasure_label = get_node_or_null("TreasureValue") as Label
	if treasure_label == null:
		treasure_label = _create_value_label("TreasureValue")
		value_layer.add_child(treasure_label)
	else:
		authored_treasure_rect = _screen_rect_to_image_rect(_get_label_rect(treasure_label), authored_screen_size)
		has_authored_treasure_rect = true
		_reparent_value_label_to_layer(treasure_label)
		_configure_value_label(treasure_label)

	percentage_label = value_layer.get_node_or_null("PercentageValue") as Label
	if percentage_label == null:
		percentage_label = get_node_or_null("PercentageValue") as Label
	if percentage_label == null:
		percentage_label = _create_value_label("PercentageValue")
		value_layer.add_child(percentage_label)
	else:
		authored_percentage_rect = _screen_rect_to_image_rect(_get_label_rect(percentage_label), authored_screen_size)
		has_authored_percentage_rect = true
		_reparent_value_label_to_layer(percentage_label)
		_configure_value_label(percentage_label)

	treasure_label.visible = false
	percentage_label.visible = false


func _bind_value_overlay() -> void:
	value_overlay = value_layer.get_node_or_null("ValueOverlay") as ResultValueOverlay
	if value_overlay == null:
		value_overlay = ResultValueOverlay.new()
		value_overlay.name = "ValueOverlay"
		value_layer.add_child(value_overlay)

	value_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_overlay.z_index = 100
	value_overlay.position = Vector2.ZERO
	value_overlay.size = size


func _reparent_value_label_to_layer(label: Label) -> void:
	if label.get_parent() == value_layer:
		return

	var global_label_position := label.global_position
	label.reparent(value_layer)
	label.global_position = global_label_position


func _create_value_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name if not label_name.is_empty() else "ValueLabel"
	_configure_value_label(label)
	return label


func _configure_value_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	GDGameFont.apply_to_label(label)
	if not label.has_theme_color_override("font_color"):
		label.add_theme_color_override("font_color", text_color)
	if not label.has_theme_color_override("font_shadow_color"):
		label.add_theme_color_override("font_shadow_color", shadow_color)
	if not label.has_theme_constant_override("shadow_offset_x"):
		label.add_theme_constant_override("shadow_offset_x", 3)
	if not label.has_theme_constant_override("shadow_offset_y"):
		label.add_theme_constant_override("shadow_offset_y", 3)


func _update_result_text() -> void:
	var stats := get_node_or_null("/root/ResultStats")
	if stats == null:
		treasure_label.text = "0"
		percentage_label.text = "0"
		_update_value_overlay_text()
		_layout_value_labels()
		return

	treasure_label.text = "%d" % stats.treasure_collected
	percentage_label.text = "%d" % stats.get_completion_percentage()
	_update_value_overlay_text()
	_layout_value_labels()


func _record_level_result() -> void:
	var stats := get_node_or_null("/root/ResultStats")
	if stats == null or stats.max_treasure_value <= 0:
		return

	var level_selection := get_node_or_null("/root/LevelSelection")
	if level_selection != null and level_selection.has_method("record_selected_level_result"):
		level_selection.record_selected_level_result(
			stats.treasure_collected,
			stats.get_completion_percentage()
		)


func _sync_screen_layout() -> void:
	_prepare_screen_root()
	_layout_value_labels()


func _layout_value_labels() -> void:
	_place_label_in_rect(treasure_label, _get_treasure_value_rect())
	_place_label_in_rect(percentage_label, _get_percentage_value_rect())
	_fit_value_labels()
	_layout_value_overlay()


func _layout_value_overlay() -> void:
	if value_overlay == null:
		return

	value_overlay.size = size
	value_overlay.set_value_layout(
		_get_treasure_value_rect(),
		_get_percentage_value_rect(),
		value_padding,
		_resolve_label_color(treasure_label, "font_color", text_color),
		_resolve_label_color(treasure_label, "font_shadow_color", shadow_color),
		Vector2(
			float(treasure_label.get_theme_constant("shadow_offset_x")),
			float(treasure_label.get_theme_constant("shadow_offset_y"))
		)
	)


func _update_value_overlay_text() -> void:
	if value_overlay != null:
		value_overlay.set_value_text(treasure_label.text, percentage_label.text)


func _resolve_label_color(label: Label, color_name: StringName, fallback: Color) -> Color:
	if label != null and label.has_theme_color_override(color_name):
		return label.get_theme_color(color_name)

	return fallback


func _place_label_from_source_rect(label: Label, image_rect: Rect2) -> void:
	if label == null:
		return
	if result_texture == null:
		return

	_place_label_in_rect(label, _image_rect_to_screen_rect(image_rect))


func _place_label_in_rect(label: Label, screen_rect: Rect2) -> void:
	if label == null:
		return

	label.position = screen_rect.position
	label.size = screen_rect.size


func _get_label_rect(label: Label) -> Rect2:
	return Rect2(label.position, label.size)


func _get_treasure_value_rect() -> Rect2:
	if has_authored_treasure_rect:
		return _image_rect_to_screen_rect(authored_treasure_rect)

	return _image_rect_to_screen_rect(treasure_rect)


func _get_percentage_value_rect() -> Rect2:
	if has_authored_percentage_rect:
		return _image_rect_to_screen_rect(authored_percentage_rect)

	return _image_rect_to_screen_rect(percentage_rect)


func _get_current_screen_size() -> Vector2:
	if size.x > 0.0 and size.y > 0.0:
		return size

	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)


func _screen_rect_to_image_rect(screen_rect: Rect2, screen_size: Vector2) -> Rect2:
	if result_texture == null:
		return screen_rect

	var texture_size := result_texture.get_size()
	var image_scale := maxf(screen_size.x / texture_size.x, screen_size.y / texture_size.y)
	var image_size := texture_size * image_scale
	var image_offset := (screen_size - image_size) * 0.5

	return Rect2((screen_rect.position - image_offset) / image_scale, screen_rect.size / image_scale)


func _image_rect_to_screen_rect(image_rect: Rect2) -> Rect2:
	var texture_size := result_texture.get_size()
	var viewport_size := size
	var image_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var image_size := texture_size * image_scale
	var image_offset := (viewport_size - image_size) * 0.5

	return Rect2(image_offset + image_rect.position * image_scale, image_rect.size * image_scale)


func _fit_value_labels() -> void:
	_fit_label_font_size(treasure_label)
	_fit_label_font_size(percentage_label)


func _fit_label_font_size(label: Label) -> void:
	if label == null:
		return

	var font := label.get_theme_default_font()
	if font == null:
		return

	var box_size := label.size
	var available_size := box_size - value_padding
	var best_size := 1
	var low := 1
	var high := maxi(1, floori(box_size.y))

	while low <= high:
		var test_size := floori(float(low + high) / 2.0)
		var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, test_size)
		if text_size.x <= available_size.x and text_size.y <= available_size.y:
			best_size = test_size
			low = test_size + 1
		else:
			high = test_size - 1

	label.add_theme_font_size_override("font_size", best_size)


func _fade_in() -> void:
	SCREEN_FADE.fade_in(self, "ResultFade", fade_duration, Color.BLACK, FADE_LAYER_NAME, FADE_LAYER_INDEX)


func _return_to_title() -> void:
	returning_to_title = true
	var tween := SCREEN_FADE.fade_out(self, "ResultFade", fade_duration, FADE_LAYER_NAME, FADE_LAYER_INDEX)
	await tween.finished

	get_tree().change_scene_to_file(TITLE_SCENE)


func _is_primary_event(event: InputEvent) -> bool:
	if InputMap.has_action("drop_carried") and event.is_action_pressed("drop_carried"):
		return true

	if InputMap.has_action("ui_accept") and event.is_action_pressed("ui_accept"):
		return true

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventJoypadButton:
		return event.pressed and event.button_index == JOY_BUTTON_A

	if event is InputEventKey:
		return event.pressed and not event.echo and (
			event.physical_keycode == KEY_ENTER
			or event.physical_keycode == KEY_SPACE
		)

	return false


class ResultValueOverlay:
	extends Control

	var treasure_text := ""
	var percentage_text := ""
	var treasure_box := Rect2()
	var percentage_box := Rect2()
	var value_padding := Vector2(16.0, 10.0)
	var text_color := Color.WHITE
	var shadow_color := Color(0.0, 0.0, 0.0, 0.9)
	var shadow_offset := Vector2(3.0, 3.0)


	func set_value_text(next_treasure_text: String, next_percentage_text: String) -> void:
		treasure_text = next_treasure_text
		percentage_text = next_percentage_text
		queue_redraw()


	func set_value_layout(
		next_treasure_box: Rect2,
		next_percentage_box: Rect2,
		next_padding: Vector2,
		next_text_color: Color,
		next_shadow_color: Color,
		next_shadow_offset: Vector2
	) -> void:
		treasure_box = next_treasure_box
		percentage_box = next_percentage_box
		value_padding = next_padding
		text_color = next_text_color
		shadow_color = next_shadow_color
		shadow_offset = next_shadow_offset
		queue_redraw()


	func _draw() -> void:
		_draw_centered_value(treasure_text, treasure_box)
		_draw_centered_value(percentage_text, percentage_box)


	func _draw_centered_value(value: String, box: Rect2) -> void:
		if value.is_empty() or box.size.x <= 0.0 or box.size.y <= 0.0:
			return

		var font: Font = GDGameFont.get_almendra_font()
		if font == null:
			font = ThemeDB.fallback_font
		if font == null:
			return

		var font_size := _fit_font_size(font, value, box.size)
		var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
		var text_height := font.get_ascent(font_size) + font.get_descent(font_size)
		var text_position := box.position + Vector2(
			(box.size.x - text_size.x) * 0.5,
			(box.size.y - text_height) * 0.5 + font.get_ascent(font_size)
		)

		draw_string(font, text_position + shadow_offset, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, shadow_color)
		draw_string(font, text_position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color)


	func _fit_font_size(font: Font, value: String, box_size: Vector2) -> int:
		var available_size := box_size - value_padding
		var best_size := 1
		var low := 1
		var high := maxi(1, floori(box_size.y))

		while low <= high:
			var test_size := floori(float(low + high) / 2.0)
			var text_size := font.get_string_size(value, HORIZONTAL_ALIGNMENT_CENTER, -1.0, test_size)
			var text_height := font.get_ascent(test_size) + font.get_descent(test_size)
			if text_size.x <= available_size.x and text_height <= available_size.y:
				best_size = test_size
				low = test_size + 1
			else:
				high = test_size - 1

		return best_size
