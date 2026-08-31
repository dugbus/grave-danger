@tool
class_name GDKillBoundary2Geometry
extends Node

## Produces the one canonical perimeter used by every boundary consumer.

signal geometry_changed(points: PackedVector2Array)

const MINIMUM_HALF_SIZE := 0.05

var state_root: Node3D
var segment_count := 32
var points := PackedVector2Array()


func configure(new_state_root: Node3D, new_segment_count: int) -> void:
	state_root = new_state_root
	segment_count = maxi(new_segment_count, 8)


func apply_state(state: GDKillBoundary2State, size_multiplier := 1.0) -> void:
	if state_root != null:
		state_root.position = state.position
		state_root.rotation = Vector3(0.0, state.yaw_radians, 0.0)
	points = build_points(state.size * maxf(size_multiplier, 0.01), state.rounding, segment_count)
	geometry_changed.emit(points)


## Builds stable rectangle-distance samples around a rectangle-to-ellipse superellipse profile.
static func build_points(
	size: Vector2, rounding: float, requested_segments: int
) -> PackedVector2Array:
	var safe_segments := maxi(requested_segments, 8)
	var half_size := Vector2(
		maxf(size.x * 0.5, MINIMUM_HALF_SIZE), maxf(size.y * 0.5, MINIMUM_HALF_SIZE)
	)
	var safe_rounding := clampf(rounding, 0.0, 1.0)
	var rectangle_points := _build_rectangle_points(half_size, safe_segments)
	if safe_rounding <= 0.000001:
		return rectangle_points
	var result := PackedVector2Array()
	for rectangle_point in rectangle_points:
		var angle := atan2(rectangle_point.y, rectangle_point.x)
		result.append(_sample_profile(half_size, safe_rounding, angle))
	return result


static func get_signed_distance(point: Vector2, polygon: PackedVector2Array) -> float:
	if polygon.size() < 3:
		return -INF
	var closest_distance := INF
	for index in polygon.size():
		closest_distance = minf(
			closest_distance,
			_distance_to_segment(point, polygon[index], polygon[(index + 1) % polygon.size()])
		)
	return closest_distance if Geometry2D.is_point_in_polygon(point, polygon) else -closest_distance


func get_signed_distance_world(world_position: Vector3) -> float:
	if state_root == null:
		return -INF
	var local_position := state_root.global_transform.affine_inverse() * world_position
	return get_signed_distance(Vector2(local_position.x, local_position.z), points)


func get_world_points(local_y := 0.0) -> PackedVector3Array:
	var world_points := PackedVector3Array()
	if state_root == null:
		return world_points
	for point in points:
		world_points.append(state_root.global_transform * Vector3(point.x, local_y, point.y))
	return world_points


static func _sample_profile(half_size: Vector2, rounding: float, angle: float) -> Vector2:
	var direction := Vector2(cos(angle), sin(angle))
	var exponent := 2.0 / rounding
	var x_ratio := absf(direction.x) / half_size.x
	var y_ratio := absf(direction.y) / half_size.y
	var largest_ratio := maxf(x_ratio, y_ratio)
	var scaled_sum := (
		pow(x_ratio / largest_ratio, exponent) + pow(y_ratio / largest_ratio, exponent)
	)
	var radius := pow(scaled_sum, -1.0 / exponent) / largest_ratio
	return direction * radius


static func _build_rectangle_points(half_size: Vector2, target_count: int) -> PackedVector2Array:
	# Starting at the right-edge midpoint keeps segment ordering aligned with rounded profiles.
	var key_points := PackedVector2Array(
		[
			Vector2(half_size.x, 0.0),
			Vector2(half_size.x, half_size.y),
			Vector2(0.0, half_size.y),
			Vector2(-half_size.x, half_size.y),
			Vector2(-half_size.x, 0.0),
			Vector2(-half_size.x, -half_size.y),
			Vector2(0.0, -half_size.y),
			Vector2(half_size.x, -half_size.y),
		]
	)
	var edge_segment_counts := PackedInt32Array()
	var segments_per_edge := floori(float(target_count) / float(key_points.size()))
	var extra_segments := target_count % key_points.size()
	for index in key_points.size():
		# Counts depend only on the configured total, never on animated size or rounding.
		# This keeps every visual, collision, and ghost index on the same part of the perimeter.
		edge_segment_counts.append(segments_per_edge + (1 if index < extra_segments else 0))
	var result := PackedVector2Array()
	for edge_index in key_points.size():
		var edge_start := key_points[edge_index]
		var edge_finish := key_points[(edge_index + 1) % key_points.size()]
		var edge_segment_count := edge_segment_counts[edge_index]
		for segment_index in edge_segment_count:
			result.append(
				edge_start.lerp(edge_finish, float(segment_index) / float(edge_segment_count))
			)
	return result


static func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * ratio)
