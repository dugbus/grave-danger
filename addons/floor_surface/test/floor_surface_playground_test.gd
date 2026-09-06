extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_playground.gd")
const PLAYGROUND := preload("res://addons/floor_surface/test/floor_surface_playground.tscn")
const PLAYER_SCRIPT := preload("res://addons/floor_surface/test/floor_surface_test_player.gd")


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
	expect(player != null, "The playground owns its independent test player.")
	expect(camera != null and camera.current, "The playground owns an active fixed camera.")
	expect(
		playground.get_node_or_null("TemporaryPad/CollisionShape3D") != null,
		"The M1 fixture has a temporary collision pad that can be walked off."
	)
	expect(
		status != null and status.text.contains("Floor surface: unavailable (M2)"),
		"The debug panel marks deferred floor data as unavailable."
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
