extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_elevation_profile.gd")
	_test_absolute_height_and_validation()
	_test_local_traversal_classification()


func _test_absolute_height_and_validation() -> void:
	var profile := SUBJECT.new()
	profile.elevation_unit = 0.25
	expect(is_equal_approx(profile.elevation_to_world(24), 6.0), "Twenty-four units equal six metres.")
	expect(is_equal_approx(profile.elevation_to_world(-2), -0.5), "Negative absolute elevations remain valid.")
	profile.elevation_unit = 0.0
	expect_equal(profile.validate().size(), 1, "A non-positive elevation unit is reported.")


func _test_local_traversal_classification() -> void:
	var profile := SUBJECT.new()
	expect_equal(
		profile.classify_edge(0, 0),
		SUBJECT.TraversalClass.Flat,
		"Matching neighbours are flat."
	)
	expect_equal(
		profile.classify_edge(0, 1),
		SUBJECT.TraversalClass.WalkableStep,
		"One unit is a walkable step."
	)
	expect_equal(
		profile.classify_edge(0, 2),
		SUBJECT.TraversalClass.NormalJump,
		"Two units require the normal jump."
	)
	expect_equal(
		profile.classify_edge(20, 22),
		SUBJECT.TraversalClass.NormalJump,
		"The same local delta has the same meaning at a high absolute elevation."
	)
	expect_equal(
		profile.classify_edge(0, 3),
		SUBJECT.TraversalClass.UnencumberedOnlyJump,
		"Three units reserve the unencumbered jump."
	)
	expect_equal(
		profile.classify_edge(0, 4),
		SUBJECT.TraversalClass.BlockedLedge,
		"Four units form a blocked ledge."
	)
	expect_equal(
		profile.classify_edge(4, 3),
		SUBJECT.TraversalClass.WalkableStepDown,
		"A small downward edge is classified explicitly."
	)
	expect_equal(profile.classify_edge(3, 0), SUBJECT.TraversalClass.Drop, "An ordinary descent is a drop.")
	expect_equal(
		profile.classify_edge(5, 0),
		SUBJECT.TraversalClass.TallDrop,
		"Drops beyond the ordinary threshold remain explicitly distinct."
	)
	expect(
		not profile.can_traverse_upward(0, 3, false) \
			and profile.can_traverse_upward(20, 23, true),
		"Only the unencumbered mode admits its reserved local threshold."
	)
	expect_equal(
		profile.validate_controller_limits(0.25, 0.65, 0.9),
		[],
		"The provisional controller physically meets all three upward thresholds."
	)
	expect_equal(
		profile.validate_controller_limits(0.1, 0.4, 0.7).size(),
		3,
		"Every undersized controller movement limit is reported."
	)
