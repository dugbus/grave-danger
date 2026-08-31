extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_settings.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_settings.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var settings := GDKillBoundary2Settings.new()
	expect(
		settings.boundary_segments >= 8 and settings.flame_height > 0.0,
		"Shared defaults create usable geometry."
	)
	var source := (SUBJECT as Script).get_source_code()
	expect(
		source.contains("Raise this when curves look faceted")
		and source.contains("0 hides the flame")
		and source.contains("artwork without disabling damage")
		and source.contains("More negative values are quieter")
		and source.contains("values above 1 keep it quieter until the player is close"),
		"Shared settings explain their visible or gameplay effect in plain-language hover help."
	)
