extends Control
class_name GDHudStatusBar

var outer_color := Color(0.82, 0.82, 0.82, 1.0)
var track_color := Color(0.65, 0.65, 0.65, 1.0)
var inset_pixels := 4.0

var safe_color := Color(0.25, 1.0, 0.15, 1.0)
var danger_color := Color(1.0, 0.05, 0.02, 1.0)
var warning_flash_frequency := 12.0
var warning_flash_intensity := 0.35
var warning_threshold = 0.25

const TRACK_BACKGROUND := Color(0.0, 0.0, 0.0, 0.0025)
const SHELL_BORDER := Color(0.92, 0.83, 0.58, 0.58)
const INNER_BORDER := Color(0.96, 0.98, 0.9, 0.36)
const HIGHLIGHT := Color(1.0, 1.0, 0.9, 0.34)
const WARNING := Color(1.0, 0.18, 0.08, 0.82)

var warning_at_top := false

var target_ratio := 1.0
var visible_ratio := 1.0

var elapsed := 0.0
var inactive := false
var bar_width := 420.0
var bar_height := 26.0
var bar_top := 20.0
var warning_enabled := true
var fill_start_color := Color(1.0,1.0,1.0)
var fill_mid_color := Color(1.0,1.0,1.0)
var fill_end_color := Color(1.0,1.0,1.0)
var warning_start_color := Color(1.0, 0.1, 0.06)
var warning_end_color := Color(1.0, 0.1, 0.1)

var label_text := ""
var label_font_size := 64
var label_lane_width := 0
var label_color := Color(0.0, 0.0, 0.0, 1.0)
var label_shadow_color := Color(1.0, 1.0, 1.0, 0.75)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_viewport_rect()
	get_viewport().size_changed.connect(_sync_viewport_rect)
	set_process(true)


func set_ratio(value: float, is_inactive: bool = false) -> void:
	var next_ratio := clampf(value, 0.0, 1.0)

	target_ratio = next_ratio
	inactive = is_inactive


func configure_size(width: float, height: float, top: float) -> void:
	bar_width = maxf(width, 120.0)
	bar_height = maxf(height, 12.0)
	bar_top = maxf(top, 0.0)
	queue_redraw()


func configure_fill(start_color: Color, mid_color: Color, end_color: Color) -> void:
	fill_start_color = start_color
	fill_mid_color = mid_color
	fill_end_color = end_color
	queue_redraw()


func configure_label_text(text: String) -> void:
	label_text = text
	queue_redraw()


func _process(delta: float) -> void:
	_sync_viewport_rect()
	elapsed += delta
	var smooth_t := 1.0 - exp(-12.0 * delta)
	visible_ratio = lerpf(visible_ratio, target_ratio, smooth_t)
	queue_redraw()


func _sync_viewport_rect() -> void:
	var project_size := Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)
	var viewport_size := get_viewport_rect().size
	var target_size := Vector2(maxf(viewport_size.x, project_size.x), maxf(viewport_size.y, project_size.y))

	if DisplayServer.get_name() != "headless":
		var window_size := Vector2(DisplayServer.window_get_size())
		target_size = Vector2(maxf(target_size.x, window_size.x), maxf(target_size.y, window_size.y))

	position = Vector2.ZERO
	size = target_size


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var resolved_width := minf(bar_width, maxf(size.x - 32.0, 120.0))
	var resolved_height := minf(bar_height, maxf(size.y * 0.18, 12.0))

	var outer_rect := Rect2(
		Vector2((size.x - resolved_width) * 0.5, bar_top),
		Vector2(resolved_width, resolved_height)
	)

	var track_rect := outer_rect.grow(-inset_pixels)
	if track_rect.size.x <= 0.0 or track_rect.size.y <= 0.0:
		return

	var fill_width := track_rect.size.x * visible_ratio
	var fill_rect := Rect2(track_rect.position, Vector2(fill_width, track_rect.size.y))

	_draw_capsule(outer_rect, outer_color)
	_draw_capsule(track_rect, track_color)

	
	var fill_color := _fill_color(visible_ratio)

	_draw_capsule(fill_rect, fill_color)

	if not label_text.is_empty():
		var label_rect := Rect2(outer_rect.position, Vector2(outer_rect.size.x, outer_rect.size.y))
		_draw_label(label_rect)

	if inactive:
		_draw_capsule(outer_rect, Color(0.0, 0.0, 0.0, 0.45))


func configure_style(
	p_outer_color: Color = Color(0.82, 0.82, 0.82, 1.0),
	p_track_color: Color = Color(0.45, 0.45, 0.45, 1.0),
	p_inset_pixels: float = 4.0,
	p_warning_threshold: float = 0.15
) -> void:
	outer_color = p_outer_color
	track_color = p_track_color
	inset_pixels = maxf(p_inset_pixels, 0.0)
	warning_threshold = clampf(p_warning_threshold, 0.0, 1.0)
	queue_redraw()


func _is_warning_active() -> bool:
	if not warning_enabled or inactive:
		return false

	if warning_at_top:
		return target_ratio >= 1.0 - warning_threshold

	return target_ratio <= warning_threshold


func _draw_gradient_capsule(rect: Rect2) -> void:
	if rect.size.x <= rect.size.y:
		_draw_capsule(rect, _fill_color(0.0))
		return

	var radius := rect.size.y * 0.5
	var body_x := rect.position.x + radius
	var body_width := maxf(rect.size.x - radius * 2.0, 0.0)
	var segment_count := maxi(1, int(ceil(body_width / 4.0)))

	_draw_capsule_cap(rect.position + Vector2(radius, radius), radius, _fill_color(0.0))
	for i in range(segment_count):
		var t0 := float(i) / float(segment_count)
		var t1 := float(i + 1) / float(segment_count)
		var x0 := body_x + body_width * t0
		var x1 := body_x + body_width * t1
		var color_t := clampf((x0 + (x1 - x0) * 0.5 - rect.position.x) / rect.size.x, 0.0, 1.0)
		draw_rect(
			Rect2(Vector2(x0, rect.position.y), Vector2(maxf(x1 - x0 + 1.0, 1.0), rect.size.y)),
			_fill_color(color_t)
		)
	_draw_capsule_cap(rect.position + Vector2(rect.size.x - radius, radius), radius, _fill_color(1.0))


func _draw_fill_flourishes(rect: Rect2) -> void:
	var inset := maxf(rect.size.y * 0.18, 2.0)
	var shine_rect := Rect2(
		rect.position + Vector2(rect.size.y * 0.5, inset),
		Vector2(maxf(rect.size.x - rect.size.y, 0.0), maxf(rect.size.y * 0.24, 1.0))
	)
	if shine_rect.size.x > 1.0:
		draw_rect(shine_rect, HIGHLIGHT)


func _draw_tick_marks(rect: Rect2) -> void:
	for marker in [0.25, 0.5, 0.75]:
		var marker_x: float = rect.position.x + rect.size.x * marker
		var alpha := 0.20 if marker > visible_ratio else 0.48
		draw_line(
			Vector2(marker_x, rect.position.y + 2.0),
			Vector2(marker_x, rect.position.y + rect.size.y - 2.0),
			Color(1.0, 0.96, 0.76, alpha),
			1.0
		)


func _draw_top_glass(rect: Rect2) -> void:
	var radius := rect.size.y * 0.5
	var glass_rect := Rect2(
		rect.position + Vector2(radius, 3.0),
		Vector2(maxf(rect.size.x - radius * 2.0, 0.0), 3.0)
	)
	if glass_rect.size.x > 1.0:
		draw_rect(glass_rect, Color(1.0, 1.0, 1.0, 0.18))


func _draw_label(rect: Rect2) -> void:
	if label_text.is_empty() or rect.size.x <= 1.0:
		return

	var font: Font = GDGameFont.get_almendra_font()
	if font == null:
		font = ThemeDB.fallback_font
	# Center the label in the bar.
	var font_size := float(label_font_size)
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(font_size))
	var text_position := rect.position + Vector2(
		(rect.size.x - text_size.x) * 0.5,
		(rect.size.y - text_size.y) * 0.5 + font.get_ascent(int(font_size))
	)

	draw_string(font, text_position + Vector2(1.0, 1.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(font_size), label_shadow_color)
	draw_string(font, text_position, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, int(font_size), label_color)


func _draw_capsule_with_border(rect: Rect2, fill_color: Color, border_color: Color, border_width: float) -> void:
	_draw_capsule(rect, border_color)
	_draw_capsule(rect.grow(-border_width), fill_color)


func _draw_capsule(rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0 or color.a <= 0.0:
		return

	var radius := minf(rect.size.x, rect.size.y) * 0.5
	if rect.size.x <= rect.size.y:
		draw_colored_polygon(_create_circle_points(rect.position + rect.size * 0.5, radius), color)
		return

	draw_colored_polygon(_create_capsule_points(rect, radius), color)


func _draw_capsule_cap(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(_create_circle_points(center, radius), color)


func _create_capsule_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segment_count := _get_arc_segment_count(radius)
	var left_center := rect.position + Vector2(radius, radius)
	var right_center := rect.position + Vector2(rect.size.x - radius, radius)

	for i in range(segment_count + 1):
		var angle := lerpf(-PI * 0.5, PI * 0.5, float(i) / float(segment_count))
		points.append(right_center + Vector2(cos(angle), sin(angle)) * radius)

	for i in range(segment_count + 1):
		var angle := lerpf(PI * 0.5, PI * 1.5, float(i) / float(segment_count))
		points.append(left_center + Vector2(cos(angle), sin(angle)) * radius)

	return points


func _create_circle_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segment_count := _get_arc_segment_count(radius) * 2
	for i in range(segment_count):
		var angle := TAU * float(i) / float(segment_count)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _get_arc_segment_count(radius: float) -> int:
	return clampi(int(ceil(radius * 0.55)), 12, 32)

func _fill_color(t: float) -> Color:
	var value := clampf(t, 0.0, 1.0)

	var color_value := value
	if warning_at_top:
		color_value = 1.0 - value

	var base_color: Color
	if color_value < 0.45:
		base_color = fill_start_color.lerp(fill_mid_color, color_value / 0.45)
	else:
		base_color = fill_mid_color.lerp(fill_end_color, (color_value - 0.45) / 0.55)

	var warning_active := false
	if warning_enabled:
		if warning_at_top:
			warning_active = target_ratio >= 1.0 - warning_threshold
		else:
			warning_active = target_ratio <= warning_threshold

	if warning_active:
		var flash_on := int(elapsed * 6.0) % 2 == 0
		if flash_on:
			return Color(0.0,0.0,0.0,0.0)

	return base_color
