extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/floor_elevation_profile.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://addons/floor_surface/floor_elevation_profile.gd")
	var profile := SUBJECT.new()
	profile.elevation_unit = 0.25
	expect(is_equal_approx(profile.elevation_to_world(24), 6.0), "Twenty-four units equal six metres.")
	expect(is_equal_approx(profile.elevation_to_world(-2), -0.5), "Negative absolute elevations remain valid.")
	profile.elevation_unit = 0.0
	expect_equal(profile.validate().size(), 1, "A non-positive elevation unit is reported.")
