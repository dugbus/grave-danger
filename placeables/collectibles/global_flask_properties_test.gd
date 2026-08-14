extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/collectibles/global_flask_properties.gd")
const SUBJECT_PATH := "res://placeables/collectibles/global_flask_properties.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var properties := load(
		"res://placeables/collectibles/global_flask_properties.tres"
	) as GDGlobalFlaskProperties
	expect(
		properties != null \
			and is_equal_approx(
				properties.breathing_space_expansion_transition_seconds,
				1.0
			) \
			and is_equal_approx(
				properties.breathing_space_contraction_transition_seconds,
				4.0
			),
		"Breathing space expands in one second and contracts four times slower."
	)
