extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_geometry.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_geometry.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var rectangle := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.0, 32)
	var rounded := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.5, 32)
	var nearly_sharp := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.01, 32)
	var lightly_rounded := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.2, 32)
	var heavily_rounded := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.8, 32)
	var ellipse := GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 1.0, 32)
	var circle := GDKillBoundary2Geometry.build_points(Vector2(8.0, 8.0), 1.0, 32)
	expect(
		rectangle.size() == 32 and ellipse.size() == 32,
		"Every shape uses the configured canonical segment count."
	)
	expect(
		_maximum_x(ellipse) > 3.99 and _maximum_y(ellipse) > 1.99,
		"Full rounding preserves both ellipse axes."
	)
	expect(
		_is_on_rectangle_edge(rectangle, Vector2(4.0, 2.0)),
		"Zero rounding produces an exact rectangular perimeter."
	)
	expect(
		_contains_all_rectangle_corners(rectangle, Vector2(4.0, 2.0)),
		"Zero rounding preserves all four sharp rectangle vertices during resampling."
	)
	expect(
		rounded != rectangle and rounded != ellipse,
		"Intermediate rounding produces a distinct rounded rectangle."
	)
	expect(
		_maximum_x(nearly_sharp) > 3.99 and _maximum_y(nearly_sharp) > 1.99,
		"Near-zero rounding preserves the authored width and depth."
	)
	expect(
		_maximum_corner_reach(nearly_sharp, Vector2(4.0, 2.0)) > 0.8,
		"Near-zero rounding approaches the authored rectangle corners without shrinking."
	)
	expect(
		_has_stable_sample_directions(lightly_rounded, heavily_rounded),
		"Rounding moves canonical samples across the profile without scrolling their indices."
	)
	expect(
		_has_stable_normalized_topology(
			GDKillBoundary2Geometry.build_points(Vector2(8.0, 4.0), 0.35, 32),
			Vector2(4.0, 2.0),
			GDKillBoundary2Geometry.build_points(Vector2(4.0, 8.0), 0.35, 32),
			Vector2(2.0, 4.0)
		),
		"Animated aspect-ratio changes never reassign canonical perimeter indices."
	)
	var almost_rectangle := GDKillBoundary2Geometry.build_points(
		Vector2(8.0, 4.0), 0.00001, 32
	)
	expect(
		_maximum_point_shift(rectangle, almost_rectangle) < 0.001,
		"The final rounded-to-sharp step remains visually continuous."
	)
	expect(_is_circle(circle, 4.0), "Full rounding is circular only for equal axes.")
	expect(
		GDKillBoundary2Geometry.get_signed_distance(Vector2.ZERO, ellipse) > 0.0,
		"The shape reports interior distance as positive."
	)
	expect(
		GDKillBoundary2Geometry.get_signed_distance(Vector2(10.0, 0.0), ellipse) < 0.0,
		"The shape reports exterior distance as negative."
	)


func _maximum_x(points: PackedVector2Array) -> float:
	var result := 0.0
	for point in points:
		result = maxf(result, absf(point.x))
	return result


func _maximum_y(points: PackedVector2Array) -> float:
	var result := 0.0
	for point in points:
		result = maxf(result, absf(point.y))
	return result


func _is_on_rectangle_edge(points: PackedVector2Array, half_size: Vector2) -> bool:
	for point in points:
		if (
			not is_equal_approx(absf(point.x), half_size.x)
			and not is_equal_approx(absf(point.y), half_size.y)
		):
			return false
	return true


func _contains_all_rectangle_corners(points: PackedVector2Array, half_size: Vector2) -> bool:
	for x_sign in [-1.0, 1.0]:
		for y_sign in [-1.0, 1.0]:
			if not points.has(Vector2(half_size.x * x_sign, half_size.y * y_sign)):
				return false
	return true


func _is_circle(points: PackedVector2Array, radius: float) -> bool:
	for point in points:
		if not is_equal_approx(point.length(), radius):
			return false
	return true


func _maximum_corner_reach(points: PackedVector2Array, half_size: Vector2) -> float:
	var result := 0.0
	for point in points:
		result = maxf(result, minf(absf(point.x) / half_size.x, absf(point.y) / half_size.y))
	return result


func _has_stable_sample_directions(first: PackedVector2Array, second: PackedVector2Array) -> bool:
	if first.size() != second.size():
		return false
	for index in first.size():
		var first_direction := first[index].normalized()
		var second_direction := second[index].normalized()
		if absf(first_direction.cross(second_direction)) > 0.0001:
			return false
		if first_direction.dot(second_direction) <= 0.0:
			return false
	return true


func _has_stable_normalized_topology(
	first: PackedVector2Array,
	first_half_size: Vector2,
	second: PackedVector2Array,
	second_half_size: Vector2
) -> bool:
	if first.size() != second.size():
		return false
	for index in first.size():
		var first_normalized := first[index] / first_half_size
		var second_normalized := second[index] / second_half_size
		if not first_normalized.is_equal_approx(second_normalized):
			return false
	return true


func _maximum_point_shift(first: PackedVector2Array, second: PackedVector2Array) -> float:
	if first.size() != second.size():
		return INF
	var result := 0.0
	for index in first.size():
		result = maxf(result, first[index].distance_to(second[index]))
	return result
