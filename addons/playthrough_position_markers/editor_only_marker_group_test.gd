extends "res://tests/test_case.gd"

const SUBJECT := preload(
	"res://addons/playthrough_position_markers/editor_only_marker_group.gd"
)
const SUBJECT_PATH := \
	"res://addons/playthrough_position_markers/editor_only_marker_group.gd"


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var marker_group := SUBJECT.new() as Node3D
	marker_group._enter_tree()
	expect(
		not marker_group.visible,
		"The generated marker group hides itself outside the editor."
	)
	marker_group.free()
