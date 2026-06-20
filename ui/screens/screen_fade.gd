extends RefCounted
class_name GDScreenFade

const DEFAULT_LAYER := 100


static func fade_in(owner: Node, fade_name: String, duration: float, start_color := Color.BLACK, layer_name := "", layer_index := DEFAULT_LAYER) -> Tween:
	var fade := create_overlay(owner, fade_name, start_color, layer_name, layer_index)
	var tween := tween_alpha(owner, fade, 0.0, duration)
	tween.finished.connect(fade.queue_free)
	return tween


static func fade_out(owner: Node, fade_name: String, duration: float, layer_name := "", layer_index := DEFAULT_LAYER) -> Tween:
	var fade := create_overlay(owner, fade_name, Color(0.0, 0.0, 0.0, 0.0), layer_name, layer_index)
	return tween_alpha(owner, fade, 1.0, duration)


static func create_overlay(owner: Node, fade_name: String, color: Color, layer_name := "", layer_index := DEFAULT_LAYER) -> ColorRect:
	var parent := owner
	if not layer_name.is_empty():
		var layer := CanvasLayer.new()
		layer.name = layer_name
		layer.layer = layer_index
		owner.add_child(layer)
		parent = layer

	var fade := ColorRect.new()
	fade.name = fade_name if not fade_name.is_empty() else "ScreenFade"
	fade.color = color
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(fade)

	return fade


static func tween_alpha(owner: Node, fade: ColorRect, target_alpha: float, duration: float) -> Tween:
	var tween := owner.create_tween()
	tween.tween_property(fade, "color:a", target_alpha, maxf(duration, 0.0))
	return tween
