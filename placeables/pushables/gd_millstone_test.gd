extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/pushables/gd_millstone.gd")
const SUBJECT_PATH := "res://placeables/pushables/gd_millstone.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var millstone := Millstone.new()
	millstone.position = Vector3.ZERO
	millstone.linear_velocity = Vector3(0.2, 0.0, 0.0)
	expect(
		not millstone.can_kill_enemy_by_rolling(Vector3(0.3, 0.0, 0.0)),
		"Tiny millstone movement cannot crush an enemy."
	)

	millstone.linear_velocity = Vector3(1.0, 0.0, 0.0)
	expect(
		millstone.can_kill_enemy_by_rolling(Vector3(0.5, 0.0, 0.1)),
		"A fast millstone crushes an enemy directly ahead in its rolling lane."
	)
	expect(
		not millstone.can_kill_enemy_by_rolling(Vector3(0.05, 0.0, 0.65)),
		"A fast millstone does not crush an enemy beside its rolling lane."
	)
	expect(
		not millstone.can_kill_enemy_by_rolling(Vector3(-0.3, 0.0, 0.0)),
		"A fast millstone does not crush an enemy behind its travel direction."
	)
	millstone.free()
