extends "res://tests/test_case.gd"

const REGION := preload("res://placeables/kill_boundary/sepia/sepia_boundary_mode.gd")
const PATROL_TEST := preload("res://enemies/patrol_timing_test.gd")
const SKELETON := preload("res://enemies/skeleton.tscn")


func run(tree: SceneTree) -> void:
	var root := Node3D.new()
	var boundary := _legacy_boundary(Vector2(4.0, 6.0))
	root.add_child(boundary)
	var target := CharacterBody3D.new()
	target.position.x = 3.0
	target.add_to_group(&"player")
	var collision := CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	target.add_child(collision)
	root.add_child(target)
	tree.root.add_child(root)
	boundary.set_physics_process(false)
	await tree.process_frame
	var region := boundary.get_node(^"SepiaMode") as REGION
	expect(
		region.contains_position(Vector3(0.0, 500.0, 0.0)),
		"The actual kill boundary INTERIOR is sepia at every height."
	)
	expect(not region.contains_position(Vector3(3.0, 0.0, 0.0)), "Everything OUTSIDE the kill boundary remains colour.")
	_expect_perimeter(boundary, region)
	expect(not REGION.allows_interaction(target, Vector3.ZERO), "A concealed source cannot reach outside the boundary.")
	expect(
		REGION.allows_interaction(target, Vector3(4.0, 0.0, 0.0)), "Outside the boundary, interactions remain normal."
	)
	target.position.x = 2.0
	expect(
		REGION.allows_interaction(target, Vector3(3.0, 0.0, 0.0)),
		"The outside half of a crossing capsule stays exposed."
	)
	expect(
		not REGION.allows_interaction(target, Vector3(1.0, 0.0, 0.0)), "The enclosed half of the capsule is concealed."
	)
	boundary.rotation.y = PI * 0.5
	expect(region.contains_position(Vector3(2.5, 0.0, 0.0)), "Sepia follows the existing boundary's actual rotation.")
	boundary.shape_morph = 0.65
	boundary.runtime_bounds_multiplier = 1.4
	boundary.get_node(^"BoundaryCenter").position = Vector3(5.0, 0.0, 2.0)
	_expect_perimeter(boundary, region)
	expect(
		not region.contains_position(Vector3.ZERO),
		"Moving the boundary moves sepia; there is no separate fixed region."
	)
	for collider in boundary.blocker_collisions:
		expect(collider.disabled, "Sepia mode disables the kill boundary's own invisible walls.")
	var second := _legacy_boundary(Vector2(4.0, 4.0))
	root.add_child(second)
	second.set_physics_process(false)
	boundary.near_flame_audio_player.stream = null
	boundary.render_effect = boundary.RenderEffect.Ghost
	expect(REGION.is_sepia(target, Vector3.ZERO), "A second sepia kill boundary retains union membership.")
	second.remove_for_level(0.0, 0.0)
	expect(not REGION.is_sepia(target, Vector3.ZERO), "The existing removal potion API removes the sepia view.")
	root.free()
	await tree.process_frame
	await _test_composed_boundary(tree)
	await _test_inverted_boundaries(tree)
	await _test_live_patrol(tree)
	await _test_gameplay_interactions(tree)


func _legacy_boundary(size: Vector2) -> GDKillBoundary3D:
	var boundary := load("res://placeables/kill_boundary/kill_boundary.tscn").instantiate() as GDKillBoundary3D
	boundary.boundary_animation = Animation.new()
	boundary.autoplay_boundary_animation = false
	boundary.bounds_size = size
	boundary.render_effect = boundary.RenderEffect.Sepia
	return boundary


func _expect_perimeter(boundary: GDKillBoundary3D, region: Node3D) -> void:
	var canonical := boundary._get_boundary_points()
	var expected := PackedVector2Array()
	var world_perimeter := PackedVector3Array()
	var transform := boundary.get_bounds_transform()
	for point in canonical:
		var world := transform * Vector3(point.x, 0.0, point.y)
		expected.append(Vector2(world.x, world.z))
		world_perimeter.append(world)
	expect_equal(
		region.get_world_polygon(),
		expected,
		"Sepia uses every exact perimeter point from the boundary's collision/visual geometry."
	)

	_expect_veil(region, world_perimeter)


func _expect_veil(region: Node3D, expected: PackedVector3Array) -> void:
	var view := region.get_node(^"View")
	view._update_regions()
	var veil := view.get_node(^"TimeVeil")
	var starts := PackedVector3Array()
	for index in expected.size():
		starts.append(veil._vertices[index * 6])
	expect_equal(starts, expected, "The visible veil uses the owning boundary's exact live 3D perimeter.")
	var elapsed: float = region.get_parent().elapsed_time
	veil.advance_visual(1.0)
	expect_equal(region.get_parent().elapsed_time, elapsed, "Morphing the veil cannot advance the boundary clock.")


func _test_composed_boundary(tree: SceneTree) -> void:
	var root := Node3D.new()
	var boundary := load("res://placeables/kill-boundary-2/kill_boundary_2.tscn").instantiate() as GDKillBoundary2
	boundary.settings = boundary.settings.duplicate() as GDKillBoundary2Settings
	boundary.settings.boundary_segments = 64
	boundary.render_effect = GDKillBoundary2Settings.RenderEffect.Sepia
	boundary.autoplay_boundary_animation = false
	# Exercise mode/audio state without racing a native MP3 decoder at fixture teardown.
	var original_audio := boundary.get_node(^"ProximityAudio")
	boundary.remove_child(original_audio)
	original_audio.free()
	var audio := AudioHarness.new()
	audio.name = "ProximityAudio"
	boundary.add_child(audio)
	root.add_child(boundary)
	tree.root.add_child(root)
	boundary.set_physics_process(false)
	await tree.process_frame
	var region := boundary.get_node(^"SepiaMode") as REGION
	var expected := PackedVector2Array()
	for point in boundary.get_boundary_world_points():
		expected.append(Vector2(point.x, point.z))
	expect_equal(
		region.get_world_polygon(), expected, "Kill Boundary 2 uses its existing canonical geometry without resampling."
	)
	expect_equal(expected.size(), 64, "The shader accepts the authored perimeter segment count above 32.")
	_expect_veil(region, boundary.get_boundary_world_points())
	expect(
		not boundary.damage.effects_enabled and not boundary.blockers.effects_enabled,
		"Sepia has no lethal or blocking component."
	)
	var elapsed := boundary.elapsed_time
	boundary._physics_process(0.2)
	expect(is_equal_approx(boundary.elapsed_time, elapsed + 0.2), "Sepia mode keeps the boundary's own clock running.")
	boundary.render_effect = GDKillBoundary2Settings.RenderEffect.Flame
	expect(
		boundary.damage.effects_enabled and boundary.blockers.effects_enabled,
		"Changing the mode back restores ordinary lethal behaviour."
	)
	expect(not region.enabled, "Changing the owning boundary mode deactivates its sepia view.")
	var veil := region.get_node(^"View/TimeVeil")
	expect(not veil.visible and not veil.is_processing(), "Switching away from Sepia hides and stops the veil.")
	expect(boundary.blockers.blocking_enabled, "Sepia preserves the authored blocking setting for a later lethal mode.")
	for blocker in boundary.blockers.blockers:
		expect(
			not blocker.get_node(^"CollisionShape3D").disabled,
			"Returning to Flame restores actual perimeter collision."
		)
	root.free()
	await tree.process_frame


func _test_inverted_boundaries(tree: SceneTree) -> void:
	for scene_path in [
		"res://placeables/kill_boundary/kill_boundary.tscn", "res://placeables/kill-boundary-2/kill_boundary_2.tscn"
	]:
		var root := Node3D.new()
		var boundary := (load(scene_path) as PackedScene).instantiate() as Node
		boundary.render_effect = (
			GDKillBoundary3D.RenderEffect.Sepia
			if boundary is GDKillBoundary3D
			else GDKillBoundary2Settings.RenderEffect.Sepia
		)
		boundary.autoplay_boundary_animation = false
		boundary.sepia_inverted = true
		root.add_child(boundary)
		var player := CharacterBody3D.new()
		root.add_child(player)
		tree.root.add_child(root)
		boundary.set_physics_process(false)
		await tree.process_frame
		var region := boundary.get_node(^"SepiaMode") as REGION
		var inside: Vector3 = boundary.get_bounds_center()
		var outside := inside + Vector3(100.0, 0.0, 0.0)
		player.position = inside
		expect(
			not region.contains_position(inside) and region.contains_position(outside),
			"Both boundaries support an authored colour-inside, sepia-outside flag."
		)
		expect(REGION.allows_interaction(player, inside), "The coloured interior permits ordinary player interactions.")
		expect(
			not REGION.allows_interaction(player, outside),
			"Concealed exterior sources cannot reach through an inverted edge."
		)
		player.position = outside
		expect(
			not REGION.allows_interaction(player, inside),
			"A player on the safe exterior cannot collect or receive attacks across the edge."
		)
		var view := region.get_node(^"View")
		view._update_regions()
		expect_equal(view._last_inversions.x, 1, "The render mask receives the authored inversion flag.")
		var perimeter := region.get_world_perimeter()
		var elapsed: float = boundary.elapsed_time
		boundary.sepia_inverted = false
		view._update_regions()
		expect(
			region.contains_position(inside) and not region.contains_position(outside),
			"Turning inversion off immediately restores the default safe side."
		)
		expect_equal(
			view._last_inversions.x, 0, "A stationary boundary still updates its shader mask when inversion changes."
		)
		expect_equal(region.get_world_perimeter(), perimeter, "Inversion does not change the canonical perimeter.")
		expect_equal(boundary.elapsed_time, elapsed, "Inversion does not advance or rewind the boundary clock.")
		root.free()
		await tree.process_frame
	await _test_mixed_inversions(tree)


func _test_mixed_inversions(tree: SceneTree) -> void:
	var root := Node3D.new()
	var outer := _legacy_boundary(Vector2(8.0, 8.0))
	outer.sepia_inverted = true
	var inner := _legacy_boundary(Vector2(2.0, 2.0))
	root.add_child(outer)
	root.add_child(inner)
	tree.root.add_child(root)
	await tree.process_frame
	var view := outer.get_node(^"SepiaMode/View")
	view._update_regions()
	expect(
		REGION.is_sepia(root, Vector3.ZERO),
		"A normal inner boundary keeps its selected safe interior in a mixed union."
	)
	expect(
		not REGION.is_sepia(root, Vector3(2.0, 0.0, 0.0)),
		"The gap between normal inner and inverted outer boundaries stays coloured."
	)
	expect(
		REGION.is_sepia(root, Vector3(10.0, 0.0, 0.0)),
		"An inverted outer boundary contributes its exterior to the safe union."
	)
	expect_equal(
		view._last_inversions,
		Vector4i(1, 0, 0, 0),
		"Each boundary retains its own inversion in the shared shader arrays."
	)
	root.free()
	await tree.process_frame


func _test_live_patrol(tree: SceneTree) -> void:
	var timing := PATROL_TEST.new()
	var baseline := await timing.record_patrol(tree, SKELETON, PATROL_TEST.PatrolCase.Immediate) as Dictionary
	var hidden := await timing.record_patrol(tree, SKELETON, PATROL_TEST.PatrolCase.Immediate, true) as Dictionary
	expect_equal(
		hidden, baseline, "Sepia never changes actual fixed-tick patrol positions, animation, RNG or audio cues."
	)


# Flow: Real gameplay APIs reject hidden rewards/damage while enemy animation and item physics stay live.
func _test_gameplay_interactions(tree: SceneTree) -> void:
	var host := GDAudio.PLAYBACK_HOST
	var previous_executor := host.executor
	host.executor = func(audio: Node) -> void: audio.queue_free()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var root := Node3D.new()
	viewport.add_child(root)
	var region := _legacy_boundary(Vector2(20.0, 20.0))
	root.add_child(region)
	var player := load("res://player/player.tscn").instantiate() as GDPlayer
	var original_death := player.get_node(^"PlayerDeath")
	player.remove_child(original_death)
	original_death.free()
	var test_death := DeathHarness.new()
	test_death.name = "PlayerDeath"
	player.add_child(test_death)
	root.add_child(player)
	player.set_physics_process(false)
	var coin := load("res://placeables/treasure/gold_coin.tscn").instantiate() as GDGoldCoin
	root.add_child(coin)
	coin.set_physics_process(false)
	coin.can_be_collected = true
	var was_frozen := coin.freeze
	var flask := load("res://placeables/collectibles/health_flask.tscn").instantiate() as GDFlaskBase
	root.add_child(flask)
	flask.set_physics_process(false)
	var spike := load("res://placeables/spike_trap/spike_trap.tscn").instantiate() as GDSpikeTrap
	root.add_child(spike)
	spike.set_physics_process(false)
	var skeleton := SKELETON.instantiate() as GDSkeletonPath
	root.add_child(skeleton)
	skeleton.set_physics_process(false)
	var death := player.death_controller as GDPlayerDeath
	death.flame_energy = 50.0
	expect(not coin._try_collect(player), "Hidden coins reject direct/polling collection.")
	expect(not flask._try_collect(player), "Hidden flasks reject deferred/direct collection.")
	expect(not spike._damage_target(player), "A hidden spike strike cannot damage the player.")
	expect_equal(death.flame_energy, 50.0, "Hidden strikes and potions do not change health.")
	expect_equal(coin.freeze, was_frozen, "Hiding rewards does not change rigid-body simulation.")
	expect(not skeleton.attack_controller.try_start(player), "Hidden skeleton contact cannot reserve a player lock.")
	region.near_flame_audio_player.stream = null
	region.render_effect = region.RenderEffect.None
	expect(coin._try_collect(player), "Exposing a reward immediately permits ordinary collection.")
	expect(
		skeleton.attack_controller.try_start(player), "Exposed skeleton contact retains the existing attack contract."
	)
	region.render_effect = region.RenderEffect.Sepia
	player.update_skeleton_attack_wait(0.0)
	expect(
		not player.is_dead() and not player.is_waiting_for_skeleton_attack(), "Sepia releases a pending player lock."
	)
	expect(skeleton.attack_controller.is_attacking(), "Releasing the player never resets the enemy's running attack.")
	skeleton.attack_controller.finish_attack()
	expect(not player.is_dead(), "Later animation completion cannot deliver concealed or stale damage.")
	viewport.free()
	await tree.process_frame
	host.executor = previous_executor


class DeathHarness:
	extends GDPlayerDeath

	func _ready() -> void:
		# Keep the real encounter logic without loading an unrelated result screen on a worker.
		pass


class AudioHarness:
	extends GDKillBoundary2Audio

	func set_render_effect(value: GDKillBoundary2Settings.RenderEffect) -> void:
		render_effect = value
