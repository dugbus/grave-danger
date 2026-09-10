extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_playground.gd")
const PLAYGROUND_PATH := "res://addons/floor_surface/test/floor_surface_playground.tscn"
const CAMERA_SCRIPT := preload("res://game/follow_camera.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const VISIBILITY_SCRIPT := preload(
	"res://player/visibility/player_occlusion_silhouette.gd"
)


func run(tree: SceneTree) -> void:
	expect_script_contract(
		SUBJECT,
		"res://addons/floor_surface/test/floor_surface_playground.gd"
	)
	var playground_scene := load(PLAYGROUND_PATH) as PackedScene
	var playground := playground_scene.instantiate() as SUBJECT
	expect(playground != null, "The standalone playground scene instantiates safely.")
	if playground == null:
		return

	tree.root.add_child(playground)
	await tree.process_frame
	var player := playground.get_node_or_null("Player") as CharacterBody3D
	var camera := playground.get_node_or_null("Camera3D") as CAMERA_SCRIPT
	var status := playground.get_node_or_null("HUD/Panel/Margin/Rows/Status") as Label
	var hud := playground.get_node_or_null("HUD") as CanvasLayer
	var surface := playground.get_node_or_null("FloorSurface") as SURFACE_SCRIPT
	var visibility := playground.get_node_or_null(
		"Player/PlayerOcclusionSilhouette"
	) as VISIBILITY_SCRIPT
	expect(
		player != null and player.get_script().resource_path == "res://player/player.gd",
		"The M7 visual fixture instances the actual GDPlayer scene."
	)
	expect(player != null and player.is_in_group(&"player"), "The production player lifecycle runs in the fixture.")
	expect(
		camera != null and camera.current and camera.projection == Camera3D.PROJECTION_PERSPECTIVE,
		"The active M7 camera uses the production perspective follow behaviour."
	)
	expect(camera != null and camera.target == player, "The production camera follows the actual player.")
	expect(surface != null, "The M2 fixture remains an isolated FloorSurface.")
	expect(visibility != null, "The M7 fixture uses the same player-owned renderer as gameplay levels.")
	expect(
		visibility != null and visibility.get_silhouette_mesh_count() > 0 \
			and visibility.is_silhouette_active(),
		"The actual imported player visuals receive isolated depth/stencil silhouette passes."
	)
	expect(
		surface.floor_map.resource_local_to_scene,
		"Authoring trials persist an independent map with the playground scene."
	)
	expect_equal(
		surface.get_generated_cell_count(),
		184,
		"The M7 fixture adds its pyramid cells without losing accepted earlier surfaces."
	)
	expect_equal(surface.validate_configuration(), [], "The saved floor surface has no configuration warnings.")
	expect_equal(surface.styles.size(), 2, "The playground exposes both reusable material styles.")
	expect(not surface.sample_surface(Vector3.ZERO).valid, "The central 2x2 hole still has no sampled floor.")
	expect_equal(surface.get_cell_elevation(Vector2i(3, 0)), 4, "The obstruction platform is exactly 1m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-5, 8)), 4, "The pyramid outer terrace is 1m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-3, 8)), 12, "The pyramid middle terrace is 3m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-1, 8)), 24, "The pyramid centre reaches 6m.")
	expect_equal(
		surface.floor_map.get_cell_transition(Vector2i(-4, 3)),
		surface.floor_map.Transition.Ramp,
		"The retained five-tile route still stores explicit ramp intent."
	)
	var ramp_sample := surface.sample_surface(Vector3(-1.5, 0.0, 3.5))
	expect(
		is_equal_approx(ramp_sample.world_height, 1.5),
		"The retained ramp midpoint remains physically and visually aligned."
	)
	expect(
		surface.top_mesh.get_surface_override_material(0) == null \
			and surface.top_mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
		"The visibility assist does not alter FloorSurface materials or shadow ownership."
	)
	expect(
		status != null and status.text.contains("Actual GDPlayer"),
		"Diagnostics state that the production player is under test."
	)
	expect(hud != null and not hud.visible, "Detailed diagnostics start hidden so they do not block play.")
	var first_trial_name := playground.get_trial_name()
	playground.cycle_trial()
	expect(playground.get_trial_name() != first_trial_name, "A human can cycle obstruction cases.")
	var next_start := playground.get_node("LowLaneStart") as Node3D
	expect(
		player.global_position.is_equal_approx(next_start.global_position),
		"Trial cycling resets the actual player to a repeatable authored start."
	)
	var first_view_name := playground.get_camera_view_name()
	playground.cycle_camera_view()
	expect(
		playground.get_camera_view_name() != first_view_name,
		"A human can cycle named production-camera angles."
	)
	visibility.set_visibility_enabled(false)
	expect(
		not visibility.is_silhouette_active(),
		"The F-key comparison disables the silhouette without changing the floor."
	)
	playground.queue_free()
	await tree.process_frame
	expect(not is_instance_valid(playground), "The standalone scene tears down without retained nodes.")
	playground_scene = null
