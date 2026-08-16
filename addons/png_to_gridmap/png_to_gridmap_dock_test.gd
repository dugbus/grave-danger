extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/png_to_gridmap/png_to_gridmap_dock.gd")
const SUBJECT_PATH := "res://addons/png_to_gridmap/png_to_gridmap_dock.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	_test_option_selection_tracks_available_metadata()
	_test_missing_option_remains_visible()


func _test_option_selection_tracks_available_metadata() -> void:
	var dock := SUBJECT.new()
	var option := OptionButton.new()
	option.add_item("First")
	option.set_item_metadata(0, "res://first.tres")
	option.add_item("Second")
	option.set_item_metadata(1, "res://second.tres")
	expect(
		dock._select_option_by_metadata(option, "res://second.tres"),
		"A refreshed dropdown selects the currently configured available resource."
	)
	expect_equal(option.selected, 1, "The matching refreshed option is selected.")
	option.free()
	dock.free()


func _test_missing_option_remains_visible() -> void:
	var dock := SUBJECT.new()
	var option := OptionButton.new()
	option.add_item("Unassigned")
	option.set_item_metadata(0, "")
	var missing_path := "res://removed/wall-corner.tres"
	dock._select_option_or_append_missing(option, missing_path, "Missing wall piece")
	expect_equal(option.item_count, 2, "A missing configured value gets a visible dropdown entry.")
	expect_equal(
		option.get_item_metadata(option.selected),
		missing_path,
		"The missing configured value remains selected instead of becoming unassigned."
	)
	expect(
		option.get_item_text(option.selected).begins_with("Missing wall piece:"),
		"The unavailable choice is clearly labelled as missing."
	)
	option.free()
	dock.free()
