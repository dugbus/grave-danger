extends Control


const TITLE_SCENE := "res://title_screen.tscn"

@export var result_texture: Texture2D
@export var fade_duration := 0.8
@export var coins_rect := Rect2(581.0, 522.0, 382.0, 90.0)
@export var percentage_rect := Rect2(581.0, 609.0, 382.0, 90.0)
@export var text_color := Color(0.96, 0.89, 0.63)
@export var shadow_color := Color(0.0, 0.0, 0.0, 0.9)

var returning_to_title := false
var result_image: TextureRect
var coins_label: Label
var percentage_label: Label


func _ready() -> void:
	_create_result_image()
	_create_labels()
	_update_result_text()
	_layout_labels()
	_fade_in()
	set_process_unhandled_input(true)
	resized.connect(_layout_labels)


func _unhandled_input(event: InputEvent) -> void:
	if returning_to_title:
		return

	if _is_primary_event(event):
		get_viewport().set_input_as_handled()
		_return_to_title()


func _create_result_image() -> void:
	result_image = TextureRect.new()
	result_image.name = "ResultImage"
	result_image.texture = result_texture
	result_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result_image)


func _create_labels() -> void:
	coins_label = _create_value_label("CoinsValue")
	percentage_label = _create_value_label("PercentageValue")
	add_child(coins_label)
	add_child(percentage_label)


func _create_value_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _update_result_text() -> void:
	var stats := get_node_or_null("/root/ResultStats")
	if stats == null:
		coins_label.text = "0"
		percentage_label.text = "0"
		return

	coins_label.text = "%d" % stats.coins_collected
	percentage_label.text = "%d" % stats.get_completion_percentage()


func _layout_labels() -> void:
	if result_texture == null or coins_label == null or percentage_label == null:
		return

	_place_label(coins_label, coins_rect)
	_place_label(percentage_label, percentage_rect)


func _place_label(label: Label, image_rect: Rect2) -> void:
	var screen_rect := _image_rect_to_screen_rect(image_rect)
	label.position = screen_rect.position
	label.size = screen_rect.size
	_fit_label_font_size(label, screen_rect.size)


func _image_rect_to_screen_rect(image_rect: Rect2) -> Rect2:
	var texture_size := result_texture.get_size()
	var viewport_size := size
	var scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var image_size := texture_size * scale
	var image_offset := (viewport_size - image_size) * 0.5

	return Rect2(image_offset + image_rect.position * scale, image_rect.size * scale)


func _fit_label_font_size(label: Label, box_size: Vector2) -> void:
	var font := label.get_theme_default_font()
	if font == null:
		return

	var available_size := box_size - Vector2(16.0, 10.0)
	var best_size := 1
	var low := 1
	var high := maxi(1, floori(box_size.y))

	while low <= high:
		var test_size := (low + high) / 2
		var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, test_size)
		if text_size.x <= available_size.x and text_size.y <= available_size.y:
			best_size = test_size
			low = test_size + 1
		else:
			high = test_size - 1

	label.add_theme_font_size_override("font_size", best_size)


func _fade_in() -> void:
	var fade := _create_fade_overlay(Color.BLACK)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_duration)
	tween.finished.connect(fade.queue_free)


func _return_to_title() -> void:
	returning_to_title = true
	var fade := _create_fade_overlay(Color(0.0, 0.0, 0.0, 0.0))
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_duration)
	await tween.finished

	get_tree().change_scene_to_file(TITLE_SCENE)


func _create_fade_overlay(color: Color) -> ColorRect:
	var fade := ColorRect.new()
	fade.name = "ResultFade"
	fade.color = color
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	return fade


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
