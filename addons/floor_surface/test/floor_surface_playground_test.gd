extends "res://tests/test_case.gd"

const SUBJECT := preload("res://addons/floor_surface/test/floor_surface_playground.gd")
const PLAYGROUND_PATH := "res://addons/floor_surface/test/floor_surface_playground.tscn"
const CAMERA_SCRIPT := preload("res://game/follow_camera.gd")
const SURFACE_SCRIPT := preload("res://addons/floor_surface/floor_surface.gd")
const GRIDMAP_REPAIRER := preload("res://addons/png_to_gridmap/png_to_gridmap_repairer.gd")
const GRAVEYARD_REPAIR_SETTINGS_PATH := (
	"res://addons/png_to_gridmap/settings/png_to_gridmap_configuration_for_graveyard.tres"
)
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
	var gradient_walls := playground.get_node_or_null("GradientWallGridMap") as GridMap
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
		324,
		"The M10 fixture retains earlier cases and adds four bounded pyramid approaches."
	)
	expect_equal(surface.validate_configuration(), [], "The saved floor surface has no configuration warnings.")
	expect_equal(surface.styles.size(), 2, "The playground exposes both reusable material styles.")
	expect(not surface.sample_surface(Vector3.ZERO).valid, "The central 2x2 hole still has no sampled floor.")
	expect_equal(surface.get_cell_elevation(Vector2i(3, 0)), 4, "The obstruction platform is exactly 1m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-5, 8)), 4, "The pyramid outer terrace is 1m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-3, 8)), 12, "The pyramid middle terrace is 3m high.")
	expect_equal(surface.get_cell_elevation(Vector2i(-1, 8)), 24, "The pyramid centre reaches 6m.")
	_test_gradient_wall_alignment(surface, gradient_walls)
	expect(
		not _contains_floating_label(playground),
		"The human fixture no longer obscures its geometry with floating world-space text."
	)
	_test_pyramid_routes(surface, player)
	_test_pyramid_collision(surface)
	var grounded_objects := playground.get_node_or_null("GroundedObjects") as Node3D
	expect(
		grounded_objects != null and grounded_objects.get_child_count() == 3,
		"The playground retains upright, slope-aligned and absolute editable grounding samples."
	)
	expect_equal(
		surface.floor_map.get_cell_transition(Vector2i(4, 3)),
		surface.floor_map.Transition.Ramp,
		"The retained five-tile route still stores explicit ramp intent."
	)
	var ramp_sample := surface.sample_surface(Vector3(4.5, 0.0, 3.5))
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
	var next_start := playground.get_node("ResetPosition") as Node3D
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


func _test_pyramid_routes(surface: SURFACE_SCRIPT, player: CharacterBody3D) -> void:
	var routes: Array[Array] = [
		_make_horizontal_route(-8, -1, 8),
		_make_horizontal_route(7, 0, 9),
		_make_vertical_route(1, 8, -1),
		_make_vertical_route(16, 9, 0),
	]
	for route in routes:
		for route_index in range(route.size() - 1):
			var from_cell := route[route_index] as Vector2i
			var to_cell := route[route_index + 1] as Vector2i
			expect_equal(
				surface.classify_edge(from_cell, to_cell),
				surface.elevation_profile.TraversalClass.Flat,
				"Every authored pyramid ramp seam is continuous from base to summit."
			)
	expect_equal(
		surface.classify_edge(Vector2i(-4, 7), Vector2i(-3, 7)),
		surface.elevation_profile.TraversalClass.BlockedLedge,
		"Unpainted terrace boundaries remain blocked shortcuts."
	)
	expect_equal(
		surface.elevation_profile.classify_edge(4, 12),
		surface.elevation_profile.classify_edge(12, 20),
		"Equal local deltas classify identically at different absolute heights."
	)
	var high_ramp_sample := surface.sample_surface(Vector3(0.5, 0.0, 10.5))
	expect(
		high_ramp_sample.valid and high_ramp_sample.world_height > 2.5,
		"High-elevation pyramid ramps provide interpolated surface samples."
	)
	if player != null:
		expect(
			high_ramp_sample.surface_normal.angle_to(Vector3.UP) <= player.floor_max_angle + 0.001,
			"Pyramid routes stay within the actual production player's maximum floor angle."
		)
	expect_equal(surface.floor_map.get_cell_style(Vector2i(0, 12)), 0, "The south landing exercises the first style.")
	expect_equal(surface.floor_map.get_cell_style(Vector2i(0, 11)), 1, "Its route continues through the second style.")


func _test_gradient_wall_alignment(surface: SURFACE_SCRIPT, gradient_walls: GridMap) -> void:
	expect(gradient_walls != null, "An editable GridMap provides the gradient wall comparison.")
	if gradient_walls == null:
		return
	expect(gradient_walls.mesh_library != null, "The wall fixture uses the existing graveyard MeshLibrary.")
	expect_equal(
		gradient_walls.cell_size,
		Vector3(1.0, 0.25, 1.0),
		"The GridMap vertical unit matches the floor's quarter-metre elevation unit."
	)
	expect(not gradient_walls.cell_center_y, "GridMap wall coordinates describe their base height.")
	var wall_cells := gradient_walls.get_used_cells()
	expect_equal(wall_cells.size(), 6, "Six walls span six small successive floor heights.")
	for wall_index in range(wall_cells.size()):
		var wall_cell := wall_cells[wall_index]
		var floor_cell := Vector2i(wall_cell.x, wall_cell.z)
		expect_equal(
			surface.get_cell_elevation(floor_cell),
			wall_cell.y,
			"Each GridMap wall's Y cell matches its supporting floor elevation."
		)
		expect(
			is_equal_approx(
				gradient_walls.map_to_local(wall_cell).y,
				surface.get_world_height_at_cell(floor_cell)
			),
			"Each wall base resolves to the exact generated floor-top height."
		)
		if wall_index > 0:
			expect_equal(
				wall_cell.y - wall_cells[wall_index - 1].y,
				1,
				"Adjacent wall bases rise by one quarter-metre grid unit."
			)
	var mesh_library := gradient_walls.mesh_library
	expect_equal(
		mesh_library.get_item_name(gradient_walls.get_cell_item(Vector3i(2, 0, 14))),
		"WallEnd",
		"The calculated low endpoint uses the graveyard wall-end mesh."
	)
	expect_equal(
		mesh_library.get_item_name(gradient_walls.get_cell_item(Vector3i(7, 5, 14))),
		"WallEnd",
		"The calculated high endpoint uses the graveyard wall-end mesh."
	)
	for step in range(1, 5):
		expect_equal(
			mesh_library.get_item_name(
				gradient_walls.get_cell_item(Vector3i(2 + step, step, 14))
			),
			"Wall",
			"Calculated interior gradient cells remain straight graveyard walls."
		)
	expect(
		gradient_walls.get_cell_item_orientation(Vector3i(2, 0, 14))
			!= gradient_walls.get_cell_item_orientation(Vector3i(7, 5, 14)),
		"The calculated wall-end meshes face opposite directions."
	)
	var repair_settings := load(GRAVEYARD_REPAIR_SETTINGS_PATH) as Resource
	var repair_plan: Dictionary = GRIDMAP_REPAIRER.new().build_plan(
		repair_settings,
		gradient_walls,
		{}
	)
	expect_equal(repair_plan["errors"], [], "The real graveyard GridMap correction profile succeeds.")
	expect_equal(
		repair_plan["changes"],
		[],
		"Running actual GridMap correction confirms the saved gradient wall is already correct."
	)


func _contains_floating_label(node: Node) -> bool:
	if node is Label3D:
		return true
	for child in node.get_children():
		if _contains_floating_label(child):
			return true
	return false


func _make_horizontal_route(first_x: int, last_x: int, z_coordinate: int) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var direction := 1 if first_x < last_x else -1
	for x_coordinate in range(first_x, last_x + direction, direction):
		route.append(Vector2i(x_coordinate, z_coordinate))
	return route


func _make_vertical_route(first_z: int, last_z: int, x_coordinate: int) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var direction := 1 if first_z < last_z else -1
	for z_coordinate in range(first_z, last_z + direction, direction):
		route.append(Vector2i(x_coordinate, z_coordinate))
	return route


func _test_pyramid_collision(surface: SURFACE_SCRIPT) -> void:
	var sample_positions: Array[Vector3] = [
		Vector3(-3.5, 0.0, 8.5),
		Vector3(2.5, 0.0, 9.5),
		Vector3(-0.5, 0.0, 6.5),
		Vector3(0.5, 0.0, 10.5),
	]
	var space_state := surface.get_world_3d().direct_space_state
	for sample_position in sample_positions:
		var sample := surface.sample_surface(sample_position)
		var query := PhysicsRayQueryParameters3D.create(
			sample_position + Vector3.UP * 8.0,
			sample_position + Vector3.DOWN * 2.0
		)
		var hit := space_state.intersect_ray(query)
		expect(not hit.is_empty(), "Every pyramid route has generated ramp collision.")
		if not hit.is_empty():
			expect(
				is_equal_approx((hit["position"] as Vector3).y, sample.world_height),
				"Pyramid route collision matches the interpolated visible top."
			)
