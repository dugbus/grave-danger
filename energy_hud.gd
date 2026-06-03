extends CanvasLayer

@export var death_controller_path: NodePath = ^"../Player/PlayerDeath"
@export_range(120.0, 900.0, 1.0, "suffix:px") var bar_width := 420.0:
	set(value):
		bar_width = maxf(value, 120.0)
		_apply_bar_size()

@export_range(12.0, 80.0, 1.0, "suffix:px") var bar_height := 26.0:
	set(value):
		bar_height = maxf(value, 12.0)
		_apply_bar_size()

var death_controller: Node
var energy_bar: EnergyBarDisplay


func _ready() -> void:
	layer = 35

	energy_bar = EnergyBarDisplay.new()
	energy_bar.name = "EnergyBar"
	energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(energy_bar)
	_apply_bar_size()

	_resolve_death_controller()


func _process(_delta: float) -> void:
	if not is_instance_valid(death_controller):
		_resolve_death_controller()

	var energy_ratio := 1.0
	var is_dead := false
	if death_controller != null:
		var max_energy := float(death_controller.get("max_flame_energy"))
		var current_energy := float(death_controller.get("flame_energy"))
		if max_energy > 0.0:
			energy_ratio = clampf(current_energy / max_energy, 0.0, 1.0)

		var dead_value = death_controller.get("is_dead")
		is_dead = dead_value is bool and dead_value

	energy_bar.set_energy_ratio(energy_ratio, is_dead)


func _resolve_death_controller() -> void:
	death_controller = get_node_or_null(death_controller_path)


func _apply_bar_size() -> void:
	if energy_bar == null:
		return

	energy_bar.bar_width = bar_width
	energy_bar.bar_height = bar_height
	energy_bar.queue_redraw()


class EnergyBarDisplay:
	extends Control

	const TRACK_BACKGROUND := Color(0.0, 0.0, 0.0, 0.0025)
	const SHELL_BORDER := Color(0.92, 0.83, 0.58, 0.58)
	const INNER_BORDER := Color(0.96, 0.98, 0.9, 0.36)
	const HIGHLIGHT := Color(1.0, 1.0, 0.9, 0.34)
	const WARNING := Color(1.0, 0.18, 0.08, 0.82)

	var target_ratio := 1.0
	var visible_ratio := 1.0
	var damage_flash := 0.0
	var elapsed := 0.0
	var dead := false
	var bar_width := 420.0
	var bar_height := 26.0


	func _ready() -> void:
		set_process(true)


	func set_energy_ratio(value: float, is_dead: bool) -> void:
		var next_ratio := clampf(value, 0.0, 1.0)
		if next_ratio < target_ratio:
			damage_flash = 1.0

		target_ratio = next_ratio
		dead = is_dead


	func _process(delta: float) -> void:
		elapsed += delta
		var smooth_t := 1.0 - exp(-12.0 * delta)
		visible_ratio = lerpf(visible_ratio, target_ratio, smooth_t)
		damage_flash = maxf(damage_flash - delta * 2.8, 0.0)
		queue_redraw()


	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return

		var resolved_width := minf(bar_width, maxf(size.x - 32.0, 120.0))
		var resolved_height := minf(bar_height, maxf(size.y * 0.18, 12.0))
		var bar_top := 20.0 if size.x >= 600.0 else 14.0
		var track_rect := Rect2(
			Vector2((size.x - resolved_width) * 0.5, bar_top),
			Vector2(resolved_width, resolved_height)
		)
		var fill_rect := track_rect.grow(-2.0)
		var fill_width := fill_rect.size.x * visible_ratio

		_draw_capsule(track_rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.18))
		_draw_capsule(track_rect, SHELL_BORDER)
		_draw_capsule(track_rect.grow(-1.5), INNER_BORDER)
		_draw_capsule(fill_rect, TRACK_BACKGROUND)

		if fill_width > 0.5:
			var active_fill := Rect2(fill_rect.position, Vector2(fill_width, fill_rect.size.y))
			if visible_ratio >= 0.995:
				active_fill = fill_rect
			_draw_gradient_capsule(active_fill)
			_draw_fill_flourishes(active_fill)

		_draw_tick_marks(fill_rect)
		_draw_top_glass(track_rect)

		if damage_flash > 0.0:
			var flash_color := Color(1.0, 0.92, 0.56, 0.28 * damage_flash)
			_draw_capsule(track_rect.grow(1.0 + damage_flash * 5.0), flash_color)

		if target_ratio <= 0.22 and not dead:
			var pulse := (sin(elapsed * 9.0) + 1.0) * 0.5
			_draw_capsule_with_border(
				track_rect.grow(2.0 + pulse * 5.0),
				Color(1.0, 0.08, 0.02, 0.02 + pulse * 0.06),
				Color(WARNING.r, WARNING.g, WARNING.b, 0.25 + pulse * 0.45),
				2.0
			)

		if dead:
			_draw_capsule(track_rect, Color(0.02, 0.0, 0.0, 0.42))


	func _draw_gradient_capsule(rect: Rect2) -> void:
		if rect.size.x <= rect.size.y:
			_draw_capsule(rect, _energy_color(0.0))
			return

		var radius := rect.size.y * 0.5
		var body_x := rect.position.x + radius
		var body_width := maxf(rect.size.x - radius * 2.0, 0.0)
		var segment_count := maxi(1, int(ceil(body_width / 4.0)))

		draw_circle(rect.position + Vector2(radius, radius), radius, _energy_color(0.0))
		for i in range(segment_count):
			var t0 := float(i) / float(segment_count)
			var t1 := float(i + 1) / float(segment_count)
			var x0 := body_x + body_width * t0
			var x1 := body_x + body_width * t1
			var color_t := clampf((x0 + (x1 - x0) * 0.5 - rect.position.x) / rect.size.x, 0.0, 1.0)
			draw_rect(
				Rect2(Vector2(x0, rect.position.y), Vector2(maxf(x1 - x0 + 1.0, 1.0), rect.size.y)),
				_energy_color(color_t)
			)
		draw_circle(rect.position + Vector2(rect.size.x - radius, radius), radius, _energy_color(1.0))


	func _draw_fill_flourishes(rect: Rect2) -> void:
		var inset := maxf(rect.size.y * 0.18, 2.0)
		var shine_rect := Rect2(
			rect.position + Vector2(rect.size.y * 0.5, inset),
			Vector2(maxf(rect.size.x - rect.size.y, 0.0), maxf(rect.size.y * 0.24, 1.0))
		)
		if shine_rect.size.x > 1.0:
			draw_rect(shine_rect, HIGHLIGHT)

		if rect.size.x > rect.size.y * 1.4:
			var spark_phase := fmod(elapsed * 0.42, 1.0)
			var spark_x := rect.position.x + rect.size.x * spark_phase
			var spark_color := Color(1.0, 1.0, 0.78, 0.46)
			draw_line(
				Vector2(spark_x - 5.0, rect.position.y + 3.0),
				Vector2(spark_x + 4.0, rect.position.y + rect.size.y - 4.0),
				spark_color,
				2.0
			)


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


	func _energy_color(t: float) -> Color:
		var value := clampf(t, 0.0, 1.0)
		if target_ratio <= 0.22:
			return Color(1.0, 0.1, 0.06).lerp(Color(1.0, 0.58, 0.1), value)
		if value < 0.45:
			return Color(0.34, 0.97, 0.78).lerp(Color(0.92, 1.0, 0.42), value / 0.45)
		return Color(0.92, 1.0, 0.42).lerp(Color(1.0, 0.68, 0.22), (value - 0.45) / 0.55)
