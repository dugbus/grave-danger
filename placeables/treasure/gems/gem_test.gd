extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/treasure/gems/gem.gd")
const SUBJECT_PATH := "res://placeables/treasure/gems/gem.gd"
const GEM_VARIANT_SCENES: Array[PackedScene] = [
	preload("res://placeables/treasure/gems/amethyst.tscn"),
	preload("res://placeables/treasure/gems/diamond.tscn"),
	preload("res://placeables/treasure/gems/emerald.tscn"),
	preload("res://placeables/treasure/gems/ruby.tscn"),
	preload("res://placeables/treasure/gems/sapphire.tscn"),
]

const EXPECTED_VISUAL_SCALE := Vector3(2.0, 2.0, 2.0)
const EXPECTED_PHYSICS_SIZE := Vector3(0.48, 0.2928, 0.48)
const EXPECTED_PICKUP_POSITION := Vector3(0.0, 0.146, 0.0)
const EXPECTED_PICKUP_RADIUS := 0.84


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	for gem_scene in GEM_VARIANT_SCENES:
		_expect_doubled_gem_dimensions(gem_scene)


func _expect_doubled_gem_dimensions(gem_scene: PackedScene) -> void:
	var gem := gem_scene.instantiate() as RigidBody3D
	expect(gem != null, "%s instantiates as a physical gem." % gem_scene.resource_path)
	if gem == null:
		return

	var visual := gem.get_node_or_null(^"GemVisual") as Node3D
	expect(
		visual != null and visual.scale.is_equal_approx(EXPECTED_VISUAL_SCALE),
		"%s uses the doubled shared visual scale." % gem_scene.resource_path
	)

	var body_collision := gem.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	var body_shape := body_collision.shape as ConvexPolygonShape3D if body_collision != null else null
	expect(
		body_shape != null and _get_point_bounds(body_shape.points).size.is_equal_approx(
			EXPECTED_PHYSICS_SIZE
		),
		"%s has collision matching its doubled visual size." % gem_scene.resource_path
	)

	var pickup_collision := gem.get_node_or_null(^"PickupArea/CollisionShape3D") as CollisionShape3D
	var pickup_shape := pickup_collision.shape as SphereShape3D if pickup_collision != null else null
	expect(
		pickup_collision != null \
				and pickup_collision.position.is_equal_approx(EXPECTED_PICKUP_POSITION) \
				and pickup_shape != null \
				and is_equal_approx(pickup_shape.radius, EXPECTED_PICKUP_RADIUS),
		"%s doubles its pickup volume with the larger gem." % gem_scene.resource_path
	)
	gem.free()


func _get_point_bounds(points: PackedVector3Array) -> AABB:
	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds
