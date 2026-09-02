extends "res://tests/test_case.gd"

const SUBJECT := preload("res://autoload/result_stats.gd")
const SUBJECT_PATH := "res://autoload/result_stats.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_completion_percentage_rounds_down()


func _test_completion_percentage_rounds_down() -> void:
	var result_stats := SUBJECT.new() as GDResultStats
	result_stats.set_result(199, 200)

	expect_equal(
		result_stats.get_completion_percentage(),
		99,
		"An incomplete treasure total cannot be reported as 100 percent."
	)
	result_stats.set_result(2, 3)
	expect_equal(
		result_stats.get_completion_percentage(),
		66,
		"Fractional completion percentages always round down."
	)

	result_stats.set_result(200, 200)
	expect_equal(
		result_stats.get_completion_percentage(),
		100,
		"Collecting every available treasure value reports 100 percent."
	)
	result_stats.free()
