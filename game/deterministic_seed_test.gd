extends "res://tests/test_case.gd"

const DETERMINISTIC_SEED := preload("res://game/deterministic_seed.gd")


func run(_tree: SceneTree) -> void:
	var first_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
	var second_seed := DETERMINISTIC_SEED.from_text("stable-source", 23)
	var different_seed := DETERMINISTIC_SEED.from_text("stable-source", 24)

	expect_equal(first_seed, second_seed, "Deterministic seeds repeat for matching inputs.")
	expect(first_seed != different_seed, "Changing the salt changes the deterministic seed.")
