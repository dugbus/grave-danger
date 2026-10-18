extends "res://tests/test_case.gd"

const SUBJECT := preload("res://ui/screens/level_run_playback.gd")
const SUBJECT_PATH := "res://ui/screens/level_run_playback.gd"
const TUTORIAL_5_PATH := "res://levels/tutorial-5/level.tscn"


func run(tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var preview := PreviewStub.new()
	var viewport := SubViewport.new()
	viewport.name = "PlaybackViewport"
	preview.add_child(viewport)
	tree.root.add_child(preview)
	var world := Node3D.new()
	var actor := Node3D.new()
	actor.name = "Actor"
	world.add_child(actor)
	viewport.add_child(world)
	preview.playback_session_root = world
	preview.playback_level = world
	preview.active_level_id = "aesthetic-preview-test"
	preview.pending_level_id = "queued-preview"
	preview.load_state = SUBJECT.LoadState.Playing
	preview.visible = true
	preview.recording = {
		"run_metadata":
		{
			"level_id": "aesthetic-preview-test",
			"drift_checkpoints":
			[
				{"time": 0.0, "states": [{"path": "Actor", "position": [0.0, 0.0, 0.0]}]},
			]
		}
	}
	preview._report_playback_drift()
	expect(preview.removed_levels.is_empty(), "Matching recordings are not deleted.")
	expect(preview.visible, "Matching recordings keep their preview visible.")
	actor.position.x = 1.0
	preview.drift_checkpoint_index = 0
	preview._report_playback_drift()
	expect_equal(
		preview.removed_levels, ["aesthetic-preview-test"], "Only the actively drifted level recording is removed."
	)
	expect(not preview.visible, "The drifted preview is immediately hidden.")
	expect_equal(preview.load_state, SUBJECT.LoadState.Idle, "The drifted preview stops replaying.")
	expect(not preview.is_processing(), "A discarded preview no longer processes frames.")
	expect(preview.recording.is_empty(), "The stale recording is released from memory.")
	expect(preview.pending_level_id.is_empty(), "Queued requests cannot reload the stale recording.")
	expect(preview.playback_level == null, "The simulated level is released.")
	preview._report_playback_drift()
	expect_equal(preview.removed_levels.size(), 1, "The same playback is discarded only once.")
	preview.free()
	await _expect_drift_cleanup_leaves_frontend_responsive(tree)
	await _expect_scene_loading_keeps_frontend_responsive(tree)
	await _expect_scene_loading_cancellation(tree)


class PreviewStub:
	extends SUBJECT

	var removed_levels: Array[String] = []

	func _remove_drifted_recording() -> void:
		removed_levels.append(active_level_id)


func _expect_drift_cleanup_leaves_frontend_responsive(tree: SceneTree) -> void:
	var frontend := FrontendProbe.new()
	frontend.size = Vector2(400.0, 200.0)
	tree.root.add_child(frontend)
	var button := Button.new()
	button.text = "Continue"
	button.size = Vector2(100.0, 40.0)
	frontend.add_child(button)
	button.pressed.connect(frontend.on_button_pressed)
	button.grab_focus()
	var preview := ProcessingPreview.new()
	var viewport := SubViewport.new()
	viewport.name = "PlaybackViewport"
	preview.add_child(viewport)
	frontend.add_child(preview)
	var world := Node3D.new()
	viewport.add_child(world)
	preview.playback_session_root = world
	preview.playback_level = world
	preview.active_level_id = "processing-drift-test"
	preview.load_state = SUBJECT.LoadState.Playing
	preview.visible = true
	preview.recording = {
		"run_metadata":
		{
			"level_id": "processing-drift-test",
			"drift_checkpoints":
			[
				{"time": 0.0, "states": [{"path": "MissingActor", "position": [0.0, 0.0, 0.0]}]},
			]
		}
	}
	preview.drift_on_next_frame = true
	for _frame in 4:
		await tree.process_frame
	expect(preview.checked_drift, "Drift retirement runs inside the preview's process callback.")
	expect(preview.world_queued_before_callback_returns, "World deletion is deferred beyond the active callback.")
	expect(
		preview.world_disabled_before_callback_returns, "The retiring world stops rendering and processing immediately."
	)
	expect(not is_instance_valid(world), "The retired world is released at a later frame boundary.")
	expect(frontend.processed_frames >= 2, "The frontend continues processing after drift retirement.")
	expect(frontend.is_processing(), "Only the replay stops; frontend processing remains enabled.")
	expect(not tree.paused, "Discarding a playback does not pause the frontend tree.")
	expect(button.has_focus(), "Preview retirement preserves focus on frontend controls.")
	var accept := InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = true
	frontend.get_viewport().push_input(accept)
	accept = InputEventAction.new()
	accept.action = &"ui_accept"
	accept.pressed = false
	frontend.get_viewport().push_input(accept)
	expect_equal(frontend.button_presses, 1, "Frontend buttons still accept input after drift cleanup.")
	frontend.free()


class FrontendProbe:
	extends Control

	var processed_frames := 0
	var button_presses := 0

	func on_button_pressed() -> void:
		button_presses += 1

	func _process(_delta: float) -> void:
		processed_frames += 1


class ProcessingPreview:
	extends PreviewStub

	var drift_on_next_frame := false
	var checked_drift := false
	var world_queued_before_callback_returns := false
	var world_disabled_before_callback_returns := false

	func _process(_delta: float) -> void:
		if not drift_on_next_frame:
			return
		drift_on_next_frame = false
		var world := playback_session_root
		_report_playback_drift()
		checked_drift = true
		world_queued_before_callback_returns = is_instance_valid(world) and world.is_queued_for_deletion()
		world_disabled_before_callback_returns = (
			is_instance_valid(world) and not world.visible and world.process_mode == Node.PROCESS_MODE_DISABLED
		)


class PendingSceneLoader:
	extends GDSceneLoader
	var requested_paths: Array[String] = []
	var request_error := OK

	func _ready() -> void:
		set_process(false)

	func request_scene(path: String, _high_priority := false) -> Error:
		requested_paths.append(path)
		if request_error == OK and not scene_states.has(path):
			scene_states[path] = SceneLoadState.Loading
		return request_error


class SceneLoadingPreview:
	extends SUBJECT
	var created_scenes: Array[PackedScene] = []

	func _create_preview(scene: PackedScene) -> void:
		created_scenes.append(scene)
		load_state = LoadState.Playing
		visible = true


func _make_loading_preview(parent: Node, loader: PendingSceneLoader) -> SceneLoadingPreview:
	var preview := SceneLoadingPreview.new()
	var viewport := SubViewport.new()
	viewport.name = "PlaybackViewport"
	preview.add_child(viewport)
	parent.add_child(loader)
	parent.add_child(preview)
	preview.scene_loader = loader
	preview.active_level_id = "tutorial_5"
	preview.active_scene_path = TUTORIAL_5_PATH
	preview.active_generation = preview.request_generation
	return preview


func _expect_scene_loading_keeps_frontend_responsive(tree: SceneTree) -> void:
	var frontend := FrontendProbe.new()
	tree.root.add_child(frontend)
	var loader := PendingSceneLoader.new()
	var preview := _make_loading_preview(frontend, loader)
	var button := Button.new()
	frontend.add_child(button)
	button.pressed.connect(frontend.on_button_pressed)
	button.grab_focus()
	# Complete a real recording thread so the scene request runs from the same _process callback as selection.
	preview.recording_thread = Thread.new()
	preview.recording_thread.start(func() -> Dictionary: return {"camera_fov": 34.0})
	preview.load_state = SUBJECT.LoadState.ReadingRecording
	var deadline := Time.get_ticks_msec() + 2000
	while preview.load_state == SUBJECT.LoadState.ReadingRecording and Time.get_ticks_msec() < deadline:
		await tree.process_frame
	var frames_before := frontend.processed_frames
	for frame in 4:
		await tree.process_frame
	expect_equal(loader.requested_paths, [TUTORIAL_5_PATH], "A decoded replay joins the shared Tutorial 5 load once.")
	expect_equal(preview.load_state, SUBJECT.LoadState.LoadingScene, "An unfinished scene stays in a polling state.")
	expect(preview.created_scenes.is_empty(), "A pending scene is never synchronously loaded or instantiated.")
	expect(frontend.processed_frames > frames_before, "The actual loading callback leaves frontend frames running.")
	expect(button.has_focus(), "Waiting for Tutorial 5 preserves frontend button focus.")
	for pressed in [true, false]:
		var accept := InputEventAction.new()
		accept.action = &"ui_accept"
		accept.pressed = pressed
		frontend.get_viewport().push_input(accept)
	expect_equal(frontend.button_presses, 1, "Frontend buttons respond while the scene load remains unfinished.")
	var scene := PackedScene.new()
	loader.cached_scenes[TUTORIAL_5_PATH] = scene
	loader.scene_states[TUTORIAL_5_PATH] = GDSceneLoader.SceneLoadState.Loaded
	for frame in 3:
		await tree.process_frame
	expect_equal(preview.created_scenes, [scene], "The preview starts exactly once after the complete graph is ready.")
	frontend.free()


func _expect_scene_loading_cancellation(tree: SceneTree) -> void:
	var frontend := Node.new()
	tree.root.add_child(frontend)
	var loader := PendingSceneLoader.new()
	var preview := _make_loading_preview(frontend, loader)
	expect(preview._load_active_level_scene(), "A preview can request Tutorial 5 asynchronously.")
	preview.show_level_run("tutorial_4", "res://levels/tutorial-4/level.tscn")
	preview.request_delay_remaining = 60.0
	loader.cached_scenes[TUTORIAL_5_PATH] = PackedScene.new()
	loader.scene_states[TUTORIAL_5_PATH] = GDSceneLoader.SceneLoadState.Loaded
	await tree.process_frame
	await tree.process_frame
	expect(preview.created_scenes.is_empty(), "A late load cannot replace the newly highlighted level.")
	preview.pending_level_id = ""
	preview.active_generation = preview.request_generation
	preview.active_scene_path = TUTORIAL_5_PATH
	preview._load_active_level_scene()
	await preview.stop_for_scene_change()
	await tree.process_frame
	expect(preview.created_scenes.is_empty(), "Leaving the frontend cancels pending preview presentation.")
	expect(not preview.is_processing(), "Scene shutdown stops polling without waiting for a worker.")
	preview.set_process(false)
	preview.active_generation = preview.request_generation
	preview.active_scene_path = TUTORIAL_5_PATH
	loader.request_error = ERR_CANT_OPEN
	expect(not preview._load_active_level_scene(), "Rejected requests leave the preview idle.")
	expect_equal(preview.load_state, SUBJECT.LoadState.Idle, "A scene request failure does not leave a spinner state.")
	loader.request_error = OK
	preview._load_active_level_scene()
	loader.scene_states[TUTORIAL_5_PATH] = GDSceneLoader.SceneLoadState.Failed
	preview._poll_level_scene()
	expect_equal(preview.load_state, SUBJECT.LoadState.Idle, "Asynchronous scene failures also leave the preview idle.")
	frontend.free()
