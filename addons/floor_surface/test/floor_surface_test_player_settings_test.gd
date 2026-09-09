extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_test_player_settings.gd")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_test_player_settings.gd"
	)
	var settings := SUBJECT.new()
	expect(
		settings.get_maximum_floor_angle_radians() > atan2(3.0, 1.0),
		"The playground controller treats a three-metre rise over one tile as floor."
	)
	settings.gravity = 20.0
	settings.normal_jump_height = 0.9
	expect(
		is_equal_approx(settings.get_jump_velocity(), 6.0),
		"Jump velocity is derived deterministically from gravity and height."
	)
	settings.unencumbered_jump_height = 1.2
	expect(
		settings.get_jump_velocity(SUBJECT.TraversalMode.Unencumbered) \
			> settings.get_jump_velocity(SUBJECT.TraversalMode.Normal),
		"The temporary unencumbered mode has a stronger test jump."
	)
	settings.maximum_floor_angle_degrees = 40.0
	expect(
		is_equal_approx(settings.get_maximum_floor_angle_radians(), deg_to_rad(40.0)),
		"Floor-angle tuning is converted to the CharacterBody unit."
	)
