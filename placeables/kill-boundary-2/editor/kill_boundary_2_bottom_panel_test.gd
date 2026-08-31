extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/editor/kill_boundary_2_bottom_panel.gd")
const BOUNDARY_SCENE := preload("res://placeables/kill-boundary-2/kill_boundary_2.tscn")


func run(_tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT, "res://placeables/kill-boundary-2/editor/kill_boundary_2_bottom_panel.gd"
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("Select the boundary root to manage or delete it")
		and (SUBJECT as Script).get_source_code().contains("_on_edit_pose_pressed"),
		"The panel separates root management from explicit pose viewport editing."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("edit_node(pose)"),
		"Previous and Next select the authored pose node in the scene tree and Inspector."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("Loop return easing")
		and (SUBJECT as Script).get_source_code().contains("set_loop_return_seconds"),
		"The panel exposes and explains the closing Loop transition timing."
	)
	expect(
		(SUBJECT as Script).get_source_code().contains("_pose_option.add_item")
		and (SUBJECT as Script).get_source_code().contains("_on_pose_selected"),
		"The panel provides a synchronized pose-number and absolute-time dropdown."
	)
	var panel := GDKillBoundary2BottomPanel.new()
	var boundary := GDKillBoundary2.new()
	boundary.sequence.add_default_pose()
	panel._build_interface()
	panel.bind_boundary(boundary)
	expect_equal(panel.boundary, boundary, "The panel binds only the supplied Kill Boundary 2.")
	expect(
		panel._edit_pose_button != null and panel._edit_pose_button.text == "Edit Pose",
		"The panel provides an explicit way to leave root management and edit the active pose."
	)
	expect(
		_all_authoring_controls_have_help(panel),
		"Every interactive bottom-panel control provides plain-language hover help."
	)
	expect(
		panel._scrubber.get_parent().get_parent() == panel
		and panel._scrubber.get_parent() != panel._speed_spin.get_parent()
		and panel._scrubber.size_flags_horizontal & Control.SIZE_EXPAND != 0,
		"The timeline scrubber has its own full-width row beneath the transport controls."
	)
	expect(
		panel._pose_option.item_count == 2
		and panel._pose_option.get_item_text(1).contains("Pose 2")
		and panel._pose_option.get_item_text(1).contains("1.00 s"),
		"The pose dropdown lists every pose with its absolute authored time."
	)
	panel._on_pose_selected(1)
	expect_equal(
		boundary.editor_active_pose_index,
		1,
		"Choosing a pose from the dropdown synchronizes the active viewport pose."
	)
	panel.bind_boundary(null)
	expect(panel.boundary == null, "The panel disconnects cleanly on deselection.")
	panel.free()
	boundary.free()

	var preview_boundary := BOUNDARY_SCENE.instantiate() as GDKillBoundary2
	preview_boundary.animator = preview_boundary.get_node(^"Animator") as GDKillBoundary2Animator
	var second_pose := preview_boundary.sequence.add_default_pose()
	preview_boundary.sequence.set_pose_transform(second_pose, Vector3(4.0, 0.0, 0.0), 0.0)
	preview_boundary.playback_mode = GDKillBoundary2Animator.PlaybackMode.Loop
	preview_boundary.loop_return_seconds = 1.0
	preview_boundary.animator.configure(
		preview_boundary.sequence, GDKillBoundary2Animator.PlaybackMode.Loop, 1.0, 1.0
	)
	var preview_panel := GDKillBoundary2BottomPanel.new()
	preview_panel.bind_boundary(preview_boundary)
	preview_boundary.preview_play()
	preview_panel._process(0.5)
	expect(
		is_equal_approx(preview_boundary.get_boundary_animation_position(), 0.5),
		"The editor panel owns a reliable preview clock for the selected boundary."
	)
	preview_boundary.preview_seek(1.5)
	expect(
		is_equal_approx(preview_boundary.get_boundary_animation_duration(), 2.0)
		and is_equal_approx(preview_boundary.animator.state.position.x, 2.0),
		"The editor scrubber timeline includes and evaluates the closing Loop transition."
	)
	preview_panel.bind_boundary(null)
	expect(not preview_boundary.animator.playing, "Deselecting freezes the current preview state.")
	preview_panel.free()
	preview_boundary.free()


func _all_authoring_controls_have_help(parent: Node) -> bool:
	for child in parent.get_children():
		if (
			child is Button
			or child is SpinBox
			or child is HSlider
		) and (child as Control).tooltip_text.is_empty():
			return false
		if not _all_authoring_controls_have_help(child):
			return false
	return true
