extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_playground.gd")
const PLAYGROUND := preload("res://addons/floor_surface/test/floor_surface_playground.tscn")
const PLAYER_SCRIPT := preload("res://addons/floor_surface/test/floor_surface_test_player.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")


func run(tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_playground.gd"
	)
	var playground := PLAYGROUND.instantiate() as SUBJECT
	expect(playground != null, "The standalone playground scene instantiates safely.")
	if playground == null:
		return

	tree.root.add_child(playground)
	await tree.process_frame
	var player := playground.get_node_or_null("Player") as PLAYER_SCRIPT
	var camera := playground.get_node_or_null("Camera3D") as Camera3D
	var status := playground.get_node_or_null("HUD/Panel/Margin/Rows/Status") as Label
	var surface := playground.get_node_or_null("FloorSurface") as SURFACE_SCRIPT
	expect(player != null, "The playground owns its independent test player.")
	expect(camera != null and camera.current, "The playground owns an active fixed camera.")
	expect(surface != null, "The M2 fixture replaces its temporary pad with FloorSurface.")
	expect_equal(surface.get_generated_cell_count(), 116, "The saved map generates 120 cells minus its four-cell hole.")
	expect_equal(surface.validate_configuration(), [], "The saved M2 surface has no configuration warnings.")
	expect(not surface.sample_surface(Vector3.ZERO).valid, "The central 2x2 hole has no sampled floor.")
	expect(
		status != null and status.text.contains("Floor surface: valid"),
		"The debug panel shows the player's live M2 floor sample."
	)
	var first_view_name := playground.get_camera_view_name()
	playground.cycle_camera_view()
	expect(
		playground.get_camera_view_name() != first_view_name,
		"A human can cycle to a named alternate camera arrangement."
	)
	playground.queue_free()
	await tree.process_frame
	expect(not is_instance_valid(playground), "The standalone scene tears down without retained nodes.")
