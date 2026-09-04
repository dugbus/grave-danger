extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/playthrough_position_markers/playthrough_position_sampling_settings.gd"
)
const SUBJECT_PATH := \
	"res://addons/playthrough_position_markers/playthrough_position_sampling_settings.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var settings := SUBJECT.new() as Resource
	expect_equal(
		settings.get("sample_interval_seconds"),
		2.0,
		"Position sampling defaults to one marker every two seconds."
	)
