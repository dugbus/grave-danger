extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/result_screen.gd")
const SUBJECT_PATH := "res://ui/screens/result_screen.gd"
const RESULT_LAYOUT := preload("res://ui/screens/result_screen_layout.tscn")
const WIN_SCREEN := preload("res://ui/screens/win_screen.tscn")
const LOSE_LAYOUT := preload("res://ui/screens/lose_screen.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	expect(
		(SUBJECT as Script).get_source_code().contains("_precache_result_actions"),
		"Result actions prepare both retry and level-selection scenes in the background."
	)
	_expect_composed_result_layout()
	_expect_edge_anchored_layout(WIN_SCREEN, "Win")
	_expect_edge_anchored_layout(LOSE_LAYOUT, "Lose")


func _expect_composed_result_layout() -> void:
	var screen := WIN_SCREEN.instantiate() as GDResultScreen
	var screen_container := screen.get_node(^"ScreenContainer") as Control
	expect(
		screen_container.scene_file_path == RESULT_LAYOUT.resource_path,
		"Win results compose the shared canvas so export cannot flatten an inherited root layout."
	)
	screen.free()


func _expect_edge_anchored_layout(layout: PackedScene, outcome_name: String) -> void:
	var screen := layout.instantiate() as Control
	var screen_container := screen.get_node(^"ScreenContainer") as Control
	var title := screen_container.get_node(^"ScreenTitleLabel") as Label
	var result_frame := screen_container.get_node(^"ResultFrame") as NinePatchRect
	var actions := screen_container.get_node(^"BottomActions") as HBoxContainer
	screen_container.size = Vector2(1600.0, 900.0)

	expect(
		title.anchor_right == 1.0
			and title.position.y >= 32.0
			and result_frame.anchor_right == 1.0
			and result_frame.anchor_bottom == 1.0,
		"%s results anchor their title and content frame within the available canvas." % outcome_name
	)
	expect(
		actions.anchor_top == 1.0
			and actions.anchor_bottom == 1.0
			and is_equal_approx(actions.offset_bottom, -40.0),
		"%s result actions stay at the bottom with a visible border gap." % outcome_name
	)
	screen.free()
